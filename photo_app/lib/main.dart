import 'package:flutter/material.dart';
import 'package:photo_app/home_screen.dart';
import 'package:photo_app/login_screen.dart';
import 'package:photo_app/signup_screen.dart';
import 'package:photo_app/splash_screen.dart';
import 'package:photo_app/utils/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo App',
      theme: buildPiconTheme(),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _PiconScrollBehavior(),
      initialRoute: '/splash',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          case '/login':
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
          case '/signup':
            return MaterialPageRoute(
              builder: (context) => const SignupScreen(),
            );
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?; // Récupération des arguments
            return MaterialPageRoute(
              builder: (context) => HomeScreen(
                userName: args?['userName'] ?? 'Utilisateur',
                userId: args?['userId'] ?? '',
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
        }
      },
    );
  }
}

class _PiconScrollBehavior extends MaterialScrollBehavior {
  const _PiconScrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
