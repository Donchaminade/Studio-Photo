import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_app/home_screen.dart';
import 'package:photo_app/login_screen.dart';
import 'package:photo_app/services/session_store.dart';
import 'package:photo_app/utils/colors.dart';
import 'package:photo_app/widgets/picon_ui.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
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

  late final Future<UserSession?> _session = SessionStore.instance.restore();

  /// Ouvre l'accueil si une session est enregistrée, sinon la connexion.
  void _navigateToHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      UserSession? session;
      try {
        session = await _session;
      } catch (_) {
        session = null;
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => session == null
              ? const LoginScreen()
              : HomeScreen(userName: session.userName, userId: session.userId),
        ),
      );
    });
  }

  bool _precached = false;

  /// Précharge les visuels de la connexion et de l'accueil pendant le splash
  /// (mêmes tailles de décodage que les widgets : pas de second décodage).
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached) return;
    _precached = true;
    const logo = AssetImage('assets/images/pro.png');
    for (final width in const [288, 264, 192, 120]) {
      precacheImage(ResizeImage(logo, width: width), context)
          .catchError((Object _) {});
    }
    for (final asset in kPromoImages) {
      precacheImage(ResizeImage(AssetImage(asset), width: 800), context)
          .catchError((Object _) {});
    }
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
    final showVideo =
        _ready && controller != null && controller.value.isInitialized;
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
