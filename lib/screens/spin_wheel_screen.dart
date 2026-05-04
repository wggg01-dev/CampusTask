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
  double _targetAngle = 0;

  final List<_WheelSegment> _segments = [
    _WheelSegment(label: 'Try Again', color: Color(0xFF334155)),
    _WheelSegment(label: '₦20', color: Color(0xFF10B981)),
    _WheelSegment(label: 'Try Again', color: Color(0xFF1E293B)),
    _WheelSegment(label: '₦100\nJackpot', color: Color(0xFFFFBF00)),
    _WheelSegment(label: 'Try Again', color: Color(0xFF334155)),
    _WheelSegment(label: '₦20', color: Color(0xFF10B981)),
    _WheelSegment(label: 'Try Again', color: Color(0xFF1E293B)),
    _WheelSegment(label: '₦50\nBonus', color: Color(0xFF3B82F6)),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> _doSpin() async {
    if (_isSpinning) return;

    // Start wheel animation
    final fullSpins = 5 * 2 * pi;
    final randomLand = Random().nextDouble() * 2 * pi;
    _targetAngle = fullSpins + randomLand;

    _animation = Tween<double>(begin: 0, end: _targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    setState(() => _isSpinning = true);
    _controller.reset();

    // Run animation and Edge Function call in parallel
    await Future.wait([
      _controller.forward(),
      _handleSpin(),
    ]);

    setState(() => _isSpinning = false);
  }

  Future<void> _handleSpin() async {
    try {
      final response = await Supabase.instance.client.functions
          .invoke('daily-spin');
      final winAmount = response.data['win'] as num;

      if (!mounted) return;

      if (winAmount > 0) {
        _showSuccessAnimation(winAmount);
      } else {
        _showTryAgainMessage();
      }
    } catch (e) {
      if (!mounted) return;
      _showError("You've already spun today! Come back tomorrow.");
    }
  }

  void _showSuccessAnimation(num winAmount) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 Jackpot!',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              '₦$winAmount',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'has been added to your pending balance.',
              style: TextStyle(color: Colors.white60, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Awesome!'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTryAgainMessage() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Better luck tomorrow!',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'No reward this time. You get a fresh spin every day — keep coming back!',
          style: TextStyle(color: Colors.white60, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hold on!',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white60, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF334155),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Got it'),
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
      body: Column(
        children: [
          const SizedBox(height: 24),

          // HEADER
          const Text(
            'Spin & Earn ₦5000 Daily',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You have 1 free spin today. Good luck!',
            style: TextStyle(color: Colors.white54),
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
                onPressed: _isSpinning ? null : _doSpin,
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
                  _isSpinning ? 'Spinning...' : 'SPIN NOW',
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
  const _WheelSegment({required this.label, required this.color});
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
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        Paint()..color = segments[i].color,
      );

      // Segment border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        Paint()
          ..color = Colors.white12
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
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
    canvas.drawCircle(center, 24, Paint()..color = const Color(0xFF0F172A));
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
