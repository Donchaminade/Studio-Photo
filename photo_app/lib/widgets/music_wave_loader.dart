import 'package:flutter/material.dart';
import 'package:photo_app/utils/colors.dart';

class MusicWaveLoader extends StatefulWidget {
  const MusicWaveLoader({super.key});

  @override
  _MusicWaveLoaderState createState() => _MusicWaveLoaderState();
}

class _MusicWaveLoaderState extends State<MusicWaveLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final double t =
                (_controller.value - (index * 0.2)).clamp(0.0, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 10 + (t * 40),
              width: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(5),
              ),
            );
          },
        );
      }),
    );
  }
}
