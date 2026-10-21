import 'dart:io';

import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Autorisations essentielles demandées une seule fois au premier lancement.
///
/// **Photos / stockage** : jamais exigés ici. Sur Android 13+ le Photo Picker
/// ne demande aucune permission. Sur Android ≤ 12, `image_picker` utilise
/// `ACTION_GET_CONTENT` (+ `READ_EXTERNAL_STORAGE` déclaré avec
/// `maxSdkVersion="32"` dans le manifest, sans `READ_MEDIA_*`).
///
/// **Téléphone** (seul obligatoire) : `CALL_PHONE` + `READ_PHONE_STATE`
/// (+ `READ_PHONE_NUMBERS` sur API 30+ via le groupe [Permission.phone]).
///
/// Si [needsAppSettings] est vrai après un refus, l'appelant doit ouvrir
/// les réglages via [openAppSettings] (pas d'auto-open ici).
class AppPermissionsService {
  AppPermissionsService._();

  static const String _prefsKey = 'essential_permissions_onboarding_v1';

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Demande le groupe téléphone (USSD / SIM). Ne touche jamais photos/storage.
  static Future<PermissionStatus> requestPhonePermission() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionStatus.granted;
    }

    final current = await Permission.phone.status;
    if (isPhoneUsable(current)) return current;

    // permanentlyDenied : request() ne montre plus de dialogue — l'appelant
    // ouvre les réglages.
    if (needsAppSettings(current)) return current;

    final result = await Permission.phone.request();
    if (isPhoneUsable(result)) return result;

    // Relecture après dialogue (certains OEM renvoient un statut intermédiaire).
    return Permission.phone.status;
  }

  static Future<PermissionStatus> phoneStatus() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return PermissionStatus.granted;
    }
    return Permission.phone.status;
  }

  static bool isPhoneUsable(PermissionStatus status) =>
      status.isGranted || status.isLimited;

  static Future<bool> isPhoneCurrentlyGranted() async {
    return isPhoneUsable(await phoneStatus());
  }

  /// true si le dialogue système ne s'affichera plus → ouvrir les réglages.
  static bool needsAppSettings(PermissionStatus status) =>
      status.isPermanentlyDenied || status.isRestricted;
}
