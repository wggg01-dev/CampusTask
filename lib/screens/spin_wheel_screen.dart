import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Public entry point ────────────────────────────────────────────────────────

void showSpinWheelModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SpinWheelModal(),
  );
}

// ── Modal widget ──────────────────────────────────────────────────────────────

class _SpinWheelModal extends StatefulWidget {
  const _SpinWheelModal();

  @override
  State<_SpinWheelModal> createState() => _SpinWheelModalState();
}

class _SpinWheelModalState extends State<_SpinWheelModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _isSpinning = false;
  bool _hasSpun = false;
  bool _alreadySpunToday = false;
  double _currentAngle = 0;

  Timer? _countdownTimer;
  Duration _timeRemaining = Duration.zero;

  final List<_WheelSegment> _segments = const [
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
    _timeRemaining = _calcTimeUntilMidnight();
  }

  // ── Countdown helpers ─────────────────────────────────────────────────────

  Duration _calcTimeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _timeRemaining = _calcTimeUntilMidnight();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _calcTimeUntilMidnight();
      setState(() => _timeRemaining = remaining);
    });
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  // ── Spin logic ────────────────────────────────────────────────────────────

  Future<void> _doSpin() async {
    if (_isSpinning || _hasSpun) return;

    final fullSpins = 5 * 2 * pi;
    final randomLand = Random().nextDouble() * 2 * pi;
    final targetAngle = fullSpins + randomLand;

    _animation = Tween<double>(begin: 0, end: targetAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    setState(() => _isSpinning = true);
    _controller.reset();

    try {
      await Future.wait([
        _controller.forward(),
        _handleSpin(),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isSpinning = false;
          _hasSpun = true;
          _currentAngle = targetAngle % (2 * pi);
        });
        _startCountdown();
      }
    }
  }

  Future<void> _handleSpin() async {
    try {
      final response =
          await Supabase.instance.client.functions.invoke('daily-spin');
      final winAmount = response.data['win'] as num;
      if (!mounted) return;
      if (winAmount > 0) {
        _showResultDialog(
          title: '🎉 You Won!',
          body: '₦$winAmount has been added to your pending balance.',
          highlight: '₦$winAmount',
          buttonLabel: 'Awesome!',
          isWin: true,
        );
      } else {
        _showResultDialog(
          title: 'Better luck tomorrow!',
          body: 'No reward this time. You get a fresh spin every day — keep coming back!',
          buttonLabel: 'Got it',
          isWin: false,
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _alreadySpunToday = true);
      _startCountdown();
    }
  }

  void _showResultDialog({
    required String title,
    required String body,
    String? highlight,
    required String buttonLabel,
    required bool isWin,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (highlight != null) ...[
              const SizedBox(height: 6),
              Text(
                highlight,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              body,
              style: const TextStyle(color: Colors.white60, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isWin ? const Color(0xFF10B981) : const Color(0xFF334155),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(buttonLabel,
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isLocked = _hasSpun || _alreadySpunToday;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DRAG HANDLE
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // TITLE ROW
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daily Spin',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white54),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Text(
            _alreadySpunToday
                ? "You've already spun today."
                : isLocked
                    ? 'Spin complete! Come back tomorrow.'
                    : 'You have 1 free spin today. Good luck!',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),

          const SizedBox(height: 28),

          // WHEEL
          Opacity(
            opacity: isLocked ? 0.45 : 1.0,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    return Transform.rotate(
                      angle: _controller.isAnimating
                          ? _animation.value
                          : _currentAngle,
                      child: CustomPaint(
                        size: const Size(260, 260),
                        painter: _WheelPainter(segments: _segments),
                      ),
                    );
                  },
                ),
                const Icon(Icons.arrow_drop_down,
                    color: Colors.white, size: 44),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // SPIN BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isLocked || _isSpinning) ? null : _doSpin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                disabledBackgroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _isSpinning
                    ? 'Spinning...'
                    : isLocked
                        ? 'Come back tomorrow'
                        : 'SPIN NOW',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isLocked ? Colors.white24 : Colors.white,
                ),
              ),
            ),
          ),

          // COUNTDOWN
          if (isLocked) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Next spin in',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDuration(_timeRemaining),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Resets at midnight',
                    style: TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Wheel painter ─────────────────────────────────────────────────────────────

class _WheelSegment {
  final String label;
  final Color color;
  const _WheelSegment({required this.label, required this.color});
}

class _WheelPainter extends CustomPainter {
  final List<_WheelSegment> segments;
  const _WheelPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle - pi / 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        Paint()..color = segments[i].color,
      );

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

    canvas.drawCircle(center, 22, Paint()..color = const Color(0xFF0F172A));
    canvas.drawCircle(
      center,
      22,
      Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) => false;
}
