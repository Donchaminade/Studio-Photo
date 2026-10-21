import 'package:Picon/api_service.dart';
import 'package:flutter/material.dart';

/// Redirige vers la connexion quand le jeton n’est plus valable.
class SessionController {
  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _redirecting = false;

  static void bind(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  static Future<void> expireToLogin({String? message}) async {
    if (_redirecting) return;
    _redirecting = true;
    try {
      await ApiService.clearAuthDetails();
      final nav = navigatorKey?.currentState;
      if (nav == null) return;
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
      final ctx = nav.context;
      final text = message ??
          'Votre session a expiré. Reconnectez-vous pour continuer.';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.maybeOf(ctx);
        messenger?.showSnackBar(
          SnackBar(
            content: Text(text),
            backgroundColor: const Color(0xFF01163E),
          ),
        );
      });
    } finally {
      _redirecting = false;
    }
  }
}
