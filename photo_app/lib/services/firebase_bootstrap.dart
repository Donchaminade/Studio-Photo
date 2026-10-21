import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initialise Firebase uniquement si une configuration est présente.
///
/// Sans google-services.json (Android), GoogleService-Info.plist (iOS) ou
/// options web, l'appel échoue : on l'intercepte pour que l'application
/// démarre normalement en mode local.
class FirebaseBootstrap {
  static bool _ready = false;
  static bool get isReady => _ready;

  static Future<bool> init({FirebaseOptions? options}) async {
    if (_ready) return true;
    // Sur le web, aucune option n'est fournie tant que `flutterfire configure`
    // n'a pas généré firebase_options.dart : inutile d'essayer.
    if (kIsWeb && options == null) return false;
    try {
      await Firebase.initializeApp(options: options)
          .timeout(const Duration(seconds: 5));
      _ready = true;
    } catch (error) {
      debugPrint('Firebase non configuré, démarrage sans Firebase : $error');
      _ready = false;
    }
    return _ready;
  }
}
