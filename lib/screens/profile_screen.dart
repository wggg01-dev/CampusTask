import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
          .select('full_name, age, gender, phone, location')
          .eq('id', user.id)
          .single();

      _nameController.text = profile['full_name'] as String? ?? '';
      _ageController.text = profile['age']?.toString() ?? '';
      _locationController.text = profile['location'] as String? ?? '';
      _selectedGender = profile['gender'] as String?;
      _phone = profile['phone'] as String?;
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

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete your account and all your data. This cannot be undone.',
          style: TextStyle(color: Colors.white60, height: 1.6),
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
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Placeholder — wire to a Supabase edge function or admin API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Account deletion request sent. You will be contacted shortly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening support…'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // TODO: launch support URL or open in-app chat
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AVATAR + PHONE ────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
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
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10B981)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text
                              : '—',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        if (_phone != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF25D366), size: 13),
                              const SizedBox(width: 5),
                              Text(_phone!,
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 13)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── PERSONAL DETAILS ──────────────────────────────────
                  _sectionLabel('Personal Details',
                      'Changes here update your task submission data.'),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _inputDeco('Full Name'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),

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
                                style: TextStyle(color: Colors.white38)),
                            items: _genders
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g,
                                          style: const TextStyle(fontSize: 13)),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedGender = v),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _locationController,
                    textCapitalization: TextCapitalization.words,
                    decoration:
                        _inputDeco('Location', hint: 'e.g. Lagos, Nigeria'),
                  ),
                  const SizedBox(height: 12),

                  // PHONE — read-only row
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
                                      color: Colors.white38, fontSize: 11)),
                              const SizedBox(height: 2),
                              Text(_phone ?? '—',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
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
                      style: TextStyle(color: Colors.white24, fontSize: 11),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SAVE BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor: const Color(0x4010B981),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── ACCOUNT SETTINGS ──────────────────────────────────
                  _sectionLabel('Account Settings', null),
                  const SizedBox(height: 12),

                  _settingsTile(
                    icon: Icons.headset_mic_outlined,
                    iconColor: const Color(0xFF60A5FA),
                    label: 'Contact Support',
                    onTap: _contactSupport,
                  ),
                  const SizedBox(height: 10),
                  _settingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: Colors.white54,
                    label: 'Log Out',
                    onTap: _signOut,
                  ),
                  const SizedBox(height: 10),
                  _settingsTile(
                    icon: Icons.delete_outline_rounded,
                    iconColor: Colors.redAccent,
                    label: 'Delete Account',
                    labelColor: Colors.redAccent,
                    onTap: _deleteAccount,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String title, String? subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54)),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(subtitle,
                style:
                    const TextStyle(color: Colors.white24, fontSize: 11)),
          ],
        ],
      );

  Widget _settingsTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
