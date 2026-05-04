import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isSpinning = false;
  bool _hasSpunToday = false;
  bool _isNewUser = false;
  bool _isLoading = true;
  int _result = 0;
  double _targetAngle = 0;

  // Wheel segments: label, color, value
  final List<_WheelSegment> _segments = [
    _WheelSegment(label: 'Try Again', color: Color(0xFF334155), value: 0),
    _WheelSegment(label: '₦20', color: Color(0xFF10B981), value: 20),
    _WheelSegment(label: 'Try Again', color: Color(0xFF1E293B), value: 0),
    _WheelSegment(label: '₦100\nJackpot', color: Color(0xFFFFBF00), value: 100),
    _WheelSegment(label: 'Try Again', color: Color(0xFF334155), value: 0),
    _WheelSegment(label: '₦20', color: Color(0xFF10B981), value: 20),
    _WheelSegment(label: 'Try Again', color: Color(0xFF1E293B), value: 0),
    _WheelSegment(label: '₦50\nBonus', color: Color(0xFF3B82F6), value: 50),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _checkSpinStatus();
  }

  Future<void> _checkSpinStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final data = await Supabase.instance.client
        .from('profiles')
        .select('last_spin_date, created_at')
        .eq('id', user.id)
        .single();

    final lastSpin = data['last_spin_date'];
    final createdAt = DateTime.tryParse(data['created_at'] ?? '');
    final now = DateTime.now();

    final isNewUser = createdAt != null &&
        now.difference(createdAt).inDays < 1 &&
        lastSpin == null;

    final hasSpunToday = lastSpin != null &&
        DateTime.tryParse(lastSpin)?.toLocal().day == now.day &&
        DateTime.tryParse(lastSpin)?.toLocal().month == now.month &&
        DateTime.tryParse(lastSpin)?.toLocal().year == now.year;

    setState(() {
      _isNewUser = isNewUser;
      _hasSpunToday = hasSpunToday;
      _isLoading = false;
    });
  }

  int _spin() {
    final r = Random().nextInt(100);
    if (_isNewUser) return 50;
    if (r < 95) return 0;
    if (r < 99) return 20;
    return 100;
  }

  int _segmentIndexForValue(int value) {
    if (value == 100) return 3;
    if (value == 50) return 7;
    if (value == 20) return 1;
    return 0; // "Try Again"
  }

  Future<void> _doSpin() async {
    if (_isSpinning || _hasSpunToday) return;

    final winAmount = _spin();
    final segmentIndex = _segmentIndexForValue(winAmount);

    // Calculate target angle to land on chosen segment
    final segmentAngle = (2 * pi) / _segments.length;
    final segmentCenter = segmentIndex * segmentAngle + segmentAngle / 2;
    final fullSpins = 5 * 2 * pi;
    _targetAngle = fullSpins + (2 * pi - segmentCenter);

    _animation = Tween<double>(begin: 0, end: _targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    setState(() {
      _isSpinning = true;
      _result = winAmount;
    });

    _controller.reset();
    await _controller.forward();

    // Save result to Supabase
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client.from('profiles').update({
        'last_spin_date': DateTime.now().toIso8601String(),
        if (winAmount > 0)
          'total_earned_ngn': _getIncrementExpression(winAmount),
      }).eq('id', user.id);

      if (winAmount > 0) {
        await Supabase.instance.client.from('payouts').insert({
          'user_id': user.id,
          'amount_ngn': winAmount,
          'status': 'sent',
        });
      }
    }

    setState(() {
      _isSpinning = false;
      _hasSpunToday = true;
    });

    _showResultDialog(winAmount);
  }

  // Supabase doesn't support server-side increment in flutter SDK easily,
  // so we fetch current value and add to it
  dynamic _getIncrementExpression(int amount) => amount;

  void _showResultDialog(int amount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          amount > 0 ? '🎉 You Won!' : 'Better Luck Tomorrow!',
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          amount > 0
              ? '₦$amount has been added to your balance.'
              : 'No reward this time. Come back tomorrow for another spin!',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daily Spin',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),

                // HEADER TEXT
                const Text(
                  'Spin to earn!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _hasSpunToday
                      ? 'Come back tomorrow for another spin.'
                      : _isNewUser
                          ? '🎁 First spin bonus guaranteed!'
                          : 'You have 1 free spin today.',
                  style: const TextStyle(color: Colors.white54),
                ),

                const SizedBox(height: 40),

                // WHEEL
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) {
                        return Transform.rotate(
                          angle: _controller.isAnimating
                              ? _animation.value
                              : _targetAngle % (2 * pi),
                          child: CustomPaint(
                            size: const Size(300, 300),
                            painter: _WheelPainter(segments: _segments),
                          ),
                        );
                      },
                    ),
                    // Pointer arrow
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 48,
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                // SPIN BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isSpinning || _hasSpunToday) ? null : _doSpin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        disabledBackgroundColor:
                            const Color(0xFF10B981).withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _hasSpunToday
                            ? 'Already Spun Today'
                            : _isSpinning
                                ? 'Spinning...'
                                : 'SPIN NOW',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Wheel painter ────────────────────────────────────────────────────────────

class _WheelSegment {
  final String label;
  final Color color;
  final int value;
  const _WheelSegment(
      {required this.label, required this.color, required this.value});
}

class _WheelPainter extends CustomPainter {
  final List<_WheelSegment> segments;
  _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;

      // Segment fill
      final paint = Paint()..color = segments[i].color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        borderPaint,
      );

      // Label
      final textAngle = startAngle + segmentAngle / 2;
      final textRadius = radius * 0.65;
      final textX = center.dx + textRadius * cos(textAngle);
      final textY = center.dy + textRadius * sin(textAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(textAngle + pi / 2);

      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: 70);
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    // Center circle
    canvas.drawCircle(
      center,
      24,
      Paint()..color = const Color(0xFF0F172A),
    );
    canvas.drawCircle(
      center,
      24,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}
