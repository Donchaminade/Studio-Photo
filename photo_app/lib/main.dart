import 'package:flutter/material.dart';
import 'package:photo_app/home_screen.dart';
import 'package:photo_app/login_screen.dart';
import 'package:photo_app/services/firebase_bootstrap.dart';
import 'package:photo_app/services/session_store.dart';
import 'package:photo_app/signup_screen.dart';
import 'package:photo_app/splash_screen.dart';
import 'package:photo_app/utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase est optionnel tant que la configuration n'est pas fournie.
  await FirebaseBootstrap.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Au retour au premier plan, on recharge la session depuis le disque au
  /// lieu de la considérer comme perdue : aucun délai d'inactivité ne
  /// déconnecte l'utilisateur.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SessionStore.instance.restore();
    }
  }

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
            final args = settings.arguments
                as Map<String, dynamic>?; // Récupération des arguments
            final session = SessionStore.instance.current.value;
            return MaterialPageRoute(
              builder: (context) => HomeScreen(
                userName:
                    args?['userName'] ?? session?.userName ?? 'Utilisateur',
                userId: args?['userId'] ?? session?.userId ?? 0,
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
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
