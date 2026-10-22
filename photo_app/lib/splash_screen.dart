import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Picon/screens/app_bootstrap_screen.dart';
import 'package:Picon/utils/colors.dart';
import 'package:Picon/widgets/picon_ui.dart';
import 'package:video_player/video_player.dart';

/// Ancien splash vidéo (conservé, plus utilisé depuis v6).
class LegacyVideoSplashScreen extends StatefulWidget {
  const LegacyVideoSplashScreen({super.key});

  @override
  State<LegacyVideoSplashScreen> createState() => _SplashScreenState();
}

/// v6 : splash premium animé avec le nouveau logo (picon-mark), centré.
class SplashScreen extends StatefulWidget {
  final bool autoNavigate;
  const SplashScreen({super.key, this.autoNavigate = true});

  @override
  State<SplashScreen> createState() => _PremiumSplashState();
}

class _PremiumSplashState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(() {
      if (!mounted || !widget.autoNavigate) return;
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const AppBootstrapScreen(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final logo = _iv(0.0, 0.45, Curves.easeOutBack);
          final ring = _iv(0.15, 0.75);
          final word = _iv(0.40, 0.70);
          final tag = _iv(0.55, 0.85);
          final bar = _iv(0.30, 1.0, Curves.easeInOut);
          return DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
              ),
            ),
            child: SafeArea(
              child: Column(children: [
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(alignment: Alignment.center, children: [
                      for (final k in [1.0, 0.72])
                        Opacity(
                          opacity: (1 - ring) * 0.5 * k,
                          child: Container(
                            width: 120 + 120 * ring * k,
                            height: 120 + 120 * ring * k,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                            ),
                          ),
                        ),
                      Transform.rotate(
                        angle: (1 - logo) * -2.4,
                        child: Transform.scale(
                          scale: 0.4 + 0.6 * logo,
                          child: Opacity(
                            opacity: logo.clamp(0.0, 1.0),
                            child: Container(
                              width: 132,
                              height: 132,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(38),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.55),
                                    blurRadius: 40,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const PiconMark(size: 96),
                            ),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: word,
                  child: Transform.translate(
                    offset: Offset(0, 14 * (1 - word)),
                    child: const Text('PICON',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900, letterSpacing: 8)),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: tag,
                  child: Text('Vos souvenirs, imprimés avec soin',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 15)),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: bar,
                        minHeight: 4,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _SplashScreenState extends State<LegacyVideoSplashScreen> {
  VideoPlayerController? _controller;
  Timer? _timer;
  int _token = 0;
  int _currentVideoIndex = 0;
  bool _ready = false;
  final List<String> _videoAssets = [
    'assets/splash.mp4',
    'assets/splash1.mp4',
  ];

  @override
  void initState() {
    super.initState();
    _playVideo(index: 0);
  }

  void _playVideo({required int index}) {
    _timer?.cancel();
    final token = ++_token;
    if (index >= _videoAssets.length) {
      _navigateToHome();
      return;
    }

    _currentVideoIndex = index;
    final previous = _controller;
    _controller = VideoPlayerController.asset(_videoAssets[index]);
    previous?.dispose();
    _ready = false;
    if (mounted) setState(() {});

    _controller!.initialize().then((_) {
      if (!mounted || token != _token) return;
      setState(() => _ready = true);
      _controller?.play();
    }).catchError((Object _) {
      if (!mounted || token != _token) return;
      _playVideo(index: index + 1);
    });

    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted || token != _token) return;
      _playVideo(index: _currentVideoIndex + 1);
    });
  }

  void _navigateToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AppBootstrapScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _token++;
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final showVideo = _ready && controller != null && controller.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (showVideo)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: controller.value.size.width,
                height: controller.value.size.height,
                child: VideoPlayer(controller),
              ),
            )
          else
            const ColoredBox(
              color: Colors.white,
              child: Center(child: BrandLogo(height: 140)),
            ),
          if (showVideo)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.paddingOf(context).bottom + 20,
              child: const Center(child: BrandLogo(height: 64)),
            ),
          if (!showVideo)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
