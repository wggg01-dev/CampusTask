import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BioDataScreen extends StatefulWidget {
  const BioDataScreen({super.key});

  @override
  State<BioDataScreen> createState() => _BioDataScreenState();
}

class _BioDataScreenState extends State<BioDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedGender;
  bool _isSaving = false;

  static const _genders = ['Male', 'Female', 'Prefer not to say'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      final phone = _phoneController.text.trim();

      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'phone': phone,
        'location': _locationController.text.trim(),
        'phone_verified': false,
      }).eq('id', user.id);

      // Trigger WhatsApp OTP
      await Supabase.instance.client.functions.invoke(
        'send-whatsapp-otp',
        body: {'phone': phone},
      );
      // Gate will react to full_name being set and move to OtpScreen automatically
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0x1F10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_pin_outlined,
                    color: Color(0xFF10B981),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Tell us about yourself',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This information is stored securely and used to match you to tasks.',
                  style: TextStyle(color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 32),

                // FULL NAME
                _FieldLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('e.g. Chidera Okonkwo'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),

                // AGE
                _FieldLabel('Age'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration('e.g. 21'),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null) return 'Enter a valid age';
                    if (n < 16 || n > 60) return 'Must be between 16 and 60';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // GENDER
                _FieldLabel('Gender'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedGender,
                    dropdownColor: const Color(0xFF1E293B),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    hint: const Text('Select gender',
                        style: TextStyle(color: Colors.white38)),
                    items: _genders
                        .map((g) => DropdownMenuItem(
                              value: g,
                              child: Text(g),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedGender = v),
                  ),
                ),
                const SizedBox(height: 20),

                // PHONE
                _FieldLabel('WhatsApp Phone Number'),
                const SizedBox(height: 4),
                const Text(
                  'Include country code — e.g. +2348012345678',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('+2348012345678'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.trim().startsWith('+')) {
                      return 'Include country code starting with +';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // LOCATION
                _FieldLabel('Location'),
                const SizedBox(height: 4),
                const Text(
                  'City or state where you are based',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locationController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('e.g. Lagos, Nigeria'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 36),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      disabledBackgroundColor: const Color(0x4010B981),
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                            'Save & Continue',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF10B981)),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Colors.white70,
      ),
    );
  }
}
