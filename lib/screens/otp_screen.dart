import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  bool _codeSent = false;
  int _resendCooldown = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  Future<void> _sendOtp() async {
    setState(() => _isSending = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'send-whatsapp-otp',
        body: {'phone': widget.phone},
      );
      if (mounted) {
        setState(() {
          _codeSent = true;
          _resendCooldown = 60;
        });
        _startResendTimer();
      }
    } catch (_) {
      // Still mark as sent — show UI so user can try resend
      if (mounted) setState(() => _codeSent = true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _fullCode =>
      _controllers.map((c) => c.text).join();

  bool get _isComplete => _fullCode.length == 4;

  Future<void> _verify() async {
    if (!_isComplete) return;
    setState(() => _isVerifying = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'verify-whatsapp-otp',
        body: {'otp': _fullCode, 'phone': widget.phone},
      );
      // Mark phone as verified — gate will react and move on
      final user = Supabase.instance.client.auth.currentUser!;
      await Supabase.instance.client
          .from('profiles')
          .update({'phone_verified': true}).eq('id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect code. Please try again.'),
          ),
        );
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // WHATSAPP ICON
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0x2225D366),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF25D366),
                  size: 30,
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Verify your number',
                style:
                    TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              // WHATSAPP NOTE
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 14, height: 1.6),
                  children: [
                    const TextSpan(text: 'A 4-digit code was sent to your '),
                    const TextSpan(
                      text: 'WhatsApp',
                      style: TextStyle(
                        color: Color(0xFF25D366),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' at\n'),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

              if (_isSending) ...[
                const SizedBox(height: 12),
                const Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF25D366)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sending code…',
                      style: TextStyle(
                          color: Color(0xFF25D366), fontSize: 13),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),

              // 4-DIGIT INPUT
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  return Padding(
                    padding: EdgeInsets.only(right: i < 3 ? 14 : 0),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: Color(0xFF10B981), width: 2),
                          ),
                        ),
                        onChanged: (val) {
                          if (val.isNotEmpty && i < 3) {
                            _focusNodes[i + 1].requestFocus();
                          }
                          if (val.isEmpty && i > 0) {
                            _focusNodes[i - 1].requestFocus();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 36),

              // VERIFY BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_isComplete && !_isVerifying) ? _verify : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor: const Color(0x4010B981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Verify Code',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // RESEND
              Center(
                child: _resendCooldown > 0
                    ? Text(
                        'Resend code in ${_resendCooldown}s',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 13),
                      )
                    : TextButton(
                        onPressed: _isSending ? null : _sendOtp,
                        child: const Text(
                          'Resend code via WhatsApp',
                          style: TextStyle(
                            color: Color(0xFF25D366),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
