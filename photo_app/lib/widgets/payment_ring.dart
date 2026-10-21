import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_ui.dart';

class PaymentRing extends StatefulWidget {
  final String method;
  final VoidCallback onComplete;

  const PaymentRing({
    super.key,
    required this.method,
    required this.onComplete,
  });

  @override
  State<PaymentRing> createState() => _PaymentRingState();
}

class _PaymentRingState extends State<PaymentRing> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _done = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_done && mounted && !reduceMotion(context)) {
        _done = true;
        widget.onComplete();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (reduceMotion(context)) {
      _controller.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _done) return;
        _done = true;
        widget.onComplete();
      });
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final showCheck = t > 0.75;
            final scale = showCheck ? (0.7 + 0.3 * ((t - 0.75) / 0.25).clamp(0.0, 1.0)) : 1.0;
            return SizedBox(
              width: 210,
              height: 210,
              child: CustomPaint(
                painter: _RingPainter(t),
                child: Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Icon(
                      showCheck ? Icons.check_rounded : Icons.payments_outlined,
                      color: showCheck ? AppColors.success : Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final done = _controller.value > 0.75;
            return Text(
              done ? 'Paiement confirmé' : 'Paiement en cours',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          widget.method,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72), fontSize: 15),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;

  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    final fill = (t / 0.75).clamp(0.0, 1.0);
    final successT = ((t - 0.75) / 0.25).clamp(0.0, 1.0);
    final color = Color.lerp(AppColors.accent, AppColors.success, successT)!;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..color = Colors.white.withValues(alpha: 0.12);
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      fill * math.pi * 2,
      false,
      arc,
    );

    for (var i = 1; i <= 3; i++) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = color.withValues(alpha: (0.16 - i * 0.035) * (1 - successT));
      canvas.drawCircle(center, radius + i * 12, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.t != t;
}
