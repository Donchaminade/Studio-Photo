import 'package:flutter/material.dart';
import 'package:photo_app/home_screen.dart';
import 'package:photo_app/login_screen.dart';
import 'package:photo_app/signup_screen.dart';
import 'package:photo_app/splash_screen.dart';
import 'package:photo_app/utils/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photo App',
      theme: ThemeData(
        primarySwatch: MaterialColor(AppColors.primary.value, const <int, Color>{
          50: Color(0xFFE8EAF6),
          100: Color(0xFFC5CAE9),
          200: Color(0xFF9FA8DA),
          300: Color(0xFF7986CB),
          400: Color(0xFF5C6BC0),
          500: AppColors.primary,
          600: Color(0xFF3F51B5),
          700: Color(0xFF303F9F),
          800: Color(0xFF283593),
          900: Color(0xFF1A237E),
        }),
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
      ),
      debugShowCheckedModeBanner: false,
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
