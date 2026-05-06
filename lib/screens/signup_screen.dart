import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  final String? initialReferralCode;
  const SignupScreen({super.key, this.initialReferralCode});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _friendCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialReferralCode != null) {
      _friendCodeController.text = widget.initialReferralCode!;
    }
  }

  String _generateRefCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      // 1. Create the auth user
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final newUser = res.user;
      if (newUser == null) throw Exception('Signup failed. Please try again.');

      // 2. Generate a unique ref code for the new user
      final refCode = _generateRefCode();

      // 3. Look up referrer if a friend code was entered
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

      // 4. Create the profile row
      await Supabase.instance.client.from('profiles').upsert({
        'id': newUser.id,
        'ref_code': refCode,
        if (referredBy != null) 'referred_by': referredBy,
        'has_accepted_rules': false,
        'available_balance_ngn': 0,
        'pending_balance_ngn': 0,
      });

      // 5. Trigger referral reward if a code was used
      if (referredBy != null) {
        await Supabase.instance.client.functions.invoke(
          'handle-referral',
          body: {'new_user_id': newUser.id, 'ref_code': friendCode},
        );
      }

      // AuthGate will detect the new session and navigate automatically
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _friendCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 80),
            const Text(
              'Create account,',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Start earning today.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),

            // EMAIL
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // PASSWORD
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // REFERRAL CODE (optional)
            TextField(
              controller: _friendCodeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: "Friend's Referral Code (optional)",
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.card_giftcard_outlined),
                helperText:
                    "Enter a friend's code to link your accounts for bonuses.",
                helperStyle: const TextStyle(color: Colors.white38),
              ),
            ),
            const SizedBox(height: 28),

            // SIGN UP BUTTON
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Create Account',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white),
                    ),
            ),

            const SizedBox(height: 20),

            // BACK TO LOGIN
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
    );
  }
}
