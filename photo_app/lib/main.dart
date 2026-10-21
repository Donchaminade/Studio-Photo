import 'package:Picon/api_service.dart';
import 'package:Picon/home_screen.dart';
import 'package:Picon/login_screen.dart';
import 'package:Picon/screens/app_bootstrap_screen.dart';
import 'package:Picon/signup_screen.dart';
import 'package:Picon/splash_screen.dart';
import 'package:Picon/utils/app_theme.dart';
import 'package:Picon/utils/session_controller.dart';
import 'package:Picon/widgets/connectivity_wrapper.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await ApiService.init();
  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    SessionController.bind(_navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        child = DevicePreview.appBuilder(context, child);
        return ConnectivityWrapper(child: child);
      },
      navigatorKey: _navigatorKey,
      title: 'Photo App',
      theme: buildPiconTheme(),
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _PiconScrollBehavior(),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            return MaterialPageRoute(builder: (context) => const SplashScreen());
          case '/bootstrap':
            return MaterialPageRoute(
              builder: (context) => const AppBootstrapScreen(),
            );
          case '/login':
            return MaterialPageRoute(builder: (context) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (context) => const SignupScreen());
          case '/home':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => HomeScreen(
                userName: args?['userName'] as String? ?? 'Utilisateur',
                userLastName: args?['userLastName'] as String? ?? '',
                userEmail: args?['userEmail'] as String? ?? '',
                userId: args?['userId'] as int? ?? 0,
              ),
            );
          default:
            return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
      },
    );
  }
}

class _PiconScrollBehavior extends MaterialScrollBehavior {
  const _PiconScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
