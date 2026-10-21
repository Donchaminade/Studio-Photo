import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 35),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          size: Size.infinite,
          painter: _GeometricPainter(_controller.value),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _GeometricPainter extends CustomPainter {
  final double t;
  final Random _random = Random(7);

  _GeometricPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    /// 🎨 FOND
    final bgPaint = Paint()..color = const Color.fromARGB(255, 255, 255, 255);
    canvas.drawRect(Offset.zero & size, bgPaint);

    /// 📐 LIGNES FINES ANIMÉES
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (int i = 0; i < 25; i++) {
      final y = (size.height / 25) * i;
      final shift = sin(t * 2 * pi + i) * 40;

      canvas.drawLine(
        Offset(0 + shift, y),
        Offset(size.width + shift, y),
        linePaint,
      );
    }

    /// ◻ PANNEAUX LÉGERS FLOTTANTS
    for (int i = 0; i < 8; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;

      final dx = cos(t * 2 * pi + i) * 20;
      final dy = sin(t * 2 * pi + i) * 20;

      final rect = Rect.fromCenter(
        center: Offset(x + dx, y + dy),
        width: 120,
        height: 60,
      );

      final panelPaint = Paint()
        ..color = const Color.fromARGB(255, 0, 112, 163).withOpacity(0.03);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(12)),
        panelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GeometricPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}
