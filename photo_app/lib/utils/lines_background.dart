import 'dart:math';
import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return CustomPaint(
          painter: _AnimatedPainter(controller.value),
          size: Size.infinite,
        );
      },
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class _AnimatedPainter extends CustomPainter {
  final double animationValue;

  _AnimatedPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 1, 20, 65).withOpacity(0.05)
      ..strokeWidth = 1;

    final random = Random(1); // Use a fixed seed for consistent patterns

    for (int i = 0; i < 30; i++) {
      final startX = random.nextDouble() * size.width * 1.5 - size.width * 0.25;
      final startY =
          random.nextDouble() * size.height * 1.5 - size.height * 0.25;

      final endX = startX + (random.nextDouble() * 200) - 100;
      final endY = startY + (random.nextDouble() * 200) - 100;

      // Animate the lines based on the controller value
      final animatedStartX =
          startX + sin(animationValue * 2 * pi + (i * pi / 15)) * 50;
      final animatedStartY =
          startY + cos(animationValue * 2 * pi + (i * pi / 15)) * 50;
      final animatedEndX =
          endX - sin(animationValue * 2 * pi + (i * pi / 15)) * 50;
      final animatedEndY =
          endY - cos(animationValue * 2 * pi + (i * pi / 15)) * 50;

      canvas.drawLine(
        Offset(animatedStartX, animatedStartY),
        Offset(animatedEndX, animatedEndY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
