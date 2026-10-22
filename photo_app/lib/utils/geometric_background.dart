import 'package:flutter/material.dart';
import 'package:Picon/utils/colors.dart';

/// Fond clair de marque : dégradé statique, sans animation continue.
class GeometricBackground extends StatelessWidget {
  const GeometricBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.fieldFill,
                AppColors.surfaceTint,
                AppColors.background,
              ],
            ),
          ),
          child: CustomPaint(painter: _BrandWashPainter()),
        ),
      ),
    );
  }
}

class _BrandWashPainter extends CustomPainter {
  const _BrandWashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final a = Paint()..color = AppColors.primary.withValues(alpha: 0.08);
    final b = Paint()..color = AppColors.accent.withValues(alpha: 0.14);
    canvas.drawCircle(Offset(size.width * 0.95, size.height * 0.08), 140, b);
    canvas.drawCircle(Offset(-20, size.height * 0.78), 160, a);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
