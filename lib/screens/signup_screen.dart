import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  final String? initialReferralCode;
  const SignupScreen({super.key, this.initialReferralCode});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Account fields
  final _passwordController = TextEditingController();
  final _friendCodeController = TextEditingController();

  // Bio-data fields
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void initState() {
    super.initState();
    if (widget.initialReferralCode != null) {
      _friendCodeController.text = widget.initialReferralCode!;
    }
  }

  Future<String?> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final web = await info.webBrowserInfo;
        return web.userAgent;
      } else if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.id;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor;
      }
    } catch (_) {}
    return null;
  }

  String _generateRefCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Converts a phone number to a synthetic email for Supabase auth.
  /// e.g. +2348012345678 → 2348012345678@campustask.app
  String _phoneToEmail(String phone) {
    final sanitized = phone.trim().replaceAll('+', '').replaceAll(' ', '');
    return '$sanitized@campustask.app';
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      final syntheticEmail = _phoneToEmail(phone);
      final deviceId = await _getDeviceId();

      // 1. Create auth user using synthetic email derived from phone
      final res = await Supabase.instance.client.auth.signUp(
        email: syntheticEmail,
        password: _passwordController.text.trim(),
      );
      final newUser = res.user;
      if (newUser == null) throw Exception('Signup failed. Please try again.');

      // 2. Generate ref code
      final refCode = _generateRefCode();

      // 3. Resolve referrer
      String? referredBy;
      final friendCode = _friendCodeController.text.trim();
      if (friendCode.isNotEmpty) {
        final referrer = await Supabase.instance.client
            .from('profiles')
            .select('id')
            .eq('ref_code', friendCode)
            .maybeSingle();
        referredBy = referrer?['id'] as String?;
      }

      // 4. Create profile with bio-data + device ID for fraud detection
      await Supabase.instance.client.from('profiles').upsert({
        'id': newUser.id,
        'ref_code': refCode,
        if (referredBy != null) 'referred_by': referredBy,
        'has_accepted_rules': false,
        'available_balance_ngn': 0,
        'pending_balance_ngn': 0,
        'full_name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _selectedGender,
        'phone': phone,
        'location': _locationController.text.trim(),
        'phone_verified': false,
        if (deviceId != null) 'device_id': deviceId,
      });

      // 5. Trigger referral reward if applicable
      if (referredBy != null) {
        await Supabase.instance.client.functions.invoke(
          'handle-referral',
          body: {'new_user_id': newUser.id, 'ref_code': friendCode},
        );
      }

      // 6. Send WhatsApp OTP — gate will show OtpScreen reactively
      await Supabase.instance.client.functions.invoke(
        'send-whatsapp-otp',
        body: {'phone': phone},
      );

      // AuthGate + _OnboardingGate will detect the session and route to OtpScreen
    } catch (e) {
      if (mounted) {
        final errorStr = e.toString();
        final message = errorStr.contains('unique_device_per_profile')
            ? 'An account already exists for this device.'
            : errorStr;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _friendCodeController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, {String? hint, Widget? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFF1E293B),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
      );

  Widget _sectionHeader(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981))),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create account,',
                  style:
                      TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Start earning today.',
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                const SizedBox(height: 36),

                // ── BIO DATA ──────────────────────────────────────────────
                _sectionHeader(
                    'Your Details', 'Used for task matching'),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDeco('Full Name', hint: 'e.g. Chidera Okonkwo'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // AGE
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: _inputDeco('Age', hint: '21'),
                        validator: (v) {
                          final n = int.tryParse(v ?? '');
                          if (n == null) return 'Required';
                          if (n < 16 || n > 60) return '16–60';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // GENDER
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
                const SizedBox(height: 14),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDeco(
                    'WhatsApp Number',
                    hint: '+2348012345678',
                    suffix: const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF25D366), size: 18),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.trim().startsWith('+')) {
                      return 'Include country code (+)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _inputDeco('Location', hint: 'e.g. Lagos, Nigeria'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 32),

                // ── ACCOUNT ───────────────────────────────────────────────
                _sectionHeader('Password', 'At least 6 characters'),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDeco(
                    'Password',
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6
                      ? 'Password must be at least 6 characters'
                      : null,
                ),

                const SizedBox(height: 32),

                // ── REFERRAL (optional) ───────────────────────────────────
                _sectionHeader('Referral', 'Optional'),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _friendCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _inputDeco(
                    "Friend's Referral Code (optional)",
                    suffix: const Icon(Icons.card_giftcard_outlined,
                        color: Colors.white38, size: 18),
                  ),
                ),

                const SizedBox(height: 36),

                // SIGN UP BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      disabledBackgroundColor: const Color(0x4010B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?',
                        style: TextStyle(color: Colors.white54)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
