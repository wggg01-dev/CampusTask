import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;
  String? _phone;
  String? _refCode;
  int _referralCount = 0;
  bool _isSaving = false;
  bool _isLoading = true;

  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('full_name, age, gender, phone, location, ref_code')
          .eq('id', user.id)
          .single();

      final referred = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('referred_by', user.id);

      _nameController.text = profile['full_name'] as String? ?? '';
      _ageController.text = profile['age']?.toString() ?? '';
      _locationController.text = profile['location'] as String? ?? '';
      _selectedGender = profile['gender'] as String?;
      _phone = profile['phone'] as String?;
      _refCode = profile['ref_code'] as String?;
      _referralCount = (referred as List).length;
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final age = int.tryParse(_ageController.text.trim());

    if (name.isEmpty || location.isEmpty || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client.from('profiles').update({
        'full_name': name,
        'age': age,
        'gender': _selectedGender,
        'location': location,
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                SizedBox(width: 8),
                Text('Profile updated.',
                    style: TextStyle(color: Colors.white)),
              ],
            ),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  InputDecoration _inputDeco(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
      );

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Log Out',
            onPressed: _signOut,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AVATAR + PHONE ─────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: const Color(0xFF10B981), width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_phone != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF25D366), size: 15),
                              const SizedBox(width: 6),
                              Text(_phone!,
                                  style: const TextStyle(
                                      color: Colors.white60, fontSize: 14)),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── REFERRAL STATS ─────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          icon: Icons.people_outline,
                          iconColor: const Color(0xFF10B981),
                          value: '$_referralCount',
                          label: 'Friends Referred',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _statCard(
                          icon: Icons.savings_outlined,
                          iconColor: const Color(0xFFFB923C),
                          value: '₦${(_referralCount * 500).toString()}',
                          label: 'Referral Earnings',
                          valueColor: const Color(0xFFFB923C),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // REFERRAL CODE + SHARE
                  if (_refCode != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: const Color(0x3310B981)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _refCode!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _refCode!));
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(const SnackBar(
                                            content: Text(
                                                'Referral code copied!')));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white70,
                                    side: const BorderSide(
                                        color: Colors.white24),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Copy'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Share.share(
                                      'Join me on CampusTask and start earning! Use my referral code $_refCode to sign up: https://campustask.app/signup?ref=$_refCode',
                                      subject: 'Earn money with CampusTask',
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  icon: const Icon(Icons.share,
                                      color: Colors.white, size: 16),
                                  label: const Text('Share',
                                      style:
                                          TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── EDITABLE DETAILS ───────────────────────────────────
                  const Text(
                    'Personal Details',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Changes here update your task submission data.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // FULL NAME
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('Full Name'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // AGE + GENDER
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _ageController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: _inputDeco('Age', hint: '21'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedGender,
                            dropdownColor: const Color(0xFF1E293B),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Gender',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            hint: const Text('Gender',
                                style:
                                    TextStyle(color: Colors.white38)),
                            items: _genders
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g,
                                          style: const TextStyle(
                                              fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGender = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // LOCATION
                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('Location',
                        hint: 'e.g. Lagos, Nigeria'),
                  ),
                  const SizedBox(height: 14),

                  // PHONE — read-only
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF25D366), size: 16),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('WhatsApp Number',
                                  style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(
                                _phone ?? '—',
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.lock_outline_rounded,
                            color: Colors.white24, size: 15),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Text(
                      'Phone number cannot be changed after verification.',
                      style: TextStyle(
                          color: Colors.white24, fontSize: 11),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0x4010B981),
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // LOG OUT
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(Icons.logout_rounded,
                          size: 18, color: Colors.redAccent),
                      label: const Text('Log Out',
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: Colors.redAccent, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}
