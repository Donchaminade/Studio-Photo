import 'dart:io';

import 'package:Picon/widgets/app_update_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mises à jour Google Play (Play Core) — Android uniquement, sans backend.
class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  static final playStoreListingUri = Uri.parse(
    'https://play.google.com/store/apps/details?id=com.photopicon.app',
  );

  bool _promptedThisSession = false;

  /// Un seul essai de dialogue par session. Échec = silence (pas de crash).
  Future<void> maybePrompt(BuildContext context) async {
    if (_promptedThisSession) return;
    if (kDebugMode || kIsWeb) return;
    if (!Platform.isAndroid) return;

    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (!context.mounted) return;

      _promptedThisSession = true;

      final shouldUpdate = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AppUpdateAvailableDialog(),
      );
      if (shouldUpdate != true) return;
      if (!context.mounted) return;

      await _startFlexibleOrOpenStore();
    } catch (_) {
      // Sideload, émulateur, Play Core indisponible, etc.
    }
  }

  Future<void> _startFlexibleOrOpenStore() async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }
      if (result == AppUpdateResult.inAppUpdateFailed) {
        await _openPlayStore();
      }
    } catch (_) {
      await _openPlayStore();
    }
  }

  Future<void> _openPlayStore() async {
    try {
      await launchUrl(
        playStoreListingUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }
}
