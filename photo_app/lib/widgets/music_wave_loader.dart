import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:Picon/utils/colors.dart';

class MusicWaveLoader extends StatefulWidget {
  const MusicWaveLoader({super.key});

  @override
  State<MusicWaveLoader> createState() => _MusicWaveLoaderState();
}

class _MusicWaveLoaderState extends State<MusicWaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final media = MediaQuery.of(context);
    _reduced = media.disableAnimations || media.accessibleNavigation;
    if (_reduced) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduced) {
      return _bars(0.6);
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => _bars(_controller.value),
    );
  }

  Widget _bars(double t) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        final wave = _reduced ? 0.55 : (math.sin((t + index / 3) * math.pi * 2) + 1) / 2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 10 + (wave * 28),
          width: 8,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }
}
