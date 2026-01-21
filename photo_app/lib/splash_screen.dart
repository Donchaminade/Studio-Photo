import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_app/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller1;
  late VideoPlayerController _controller2;
  bool _showSecondVideo = false;

  @override
  void initState() {
    super.initState();
    _controller1 = VideoPlayerController.asset('assets/splash.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown
        setState(() {});
        _controller1.play();
        _controller1.setLooping(true);
      });

    _controller2 = VideoPlayerController.asset('assets/splash1.mp4')
      ..initialize().then((_) {
        setState(() {});
        _controller2.setLooping(true);
      });

    // Timer to switch to the second video
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showSecondVideo = true;
          _controller1.pause();
          _controller2.play();
        });
      }
    });

    // Timer to navigate to LoginScreen
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedCrossFade(
          firstChild: _buildVideoPlayer(_controller1),
          secondChild: _buildVideoPlayer(_controller2),
          crossFadeState: _showSecondVideo
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    return controller.value.isInitialized
        ? AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller),
          )
        : const CircularProgressIndicator();
  }
}
