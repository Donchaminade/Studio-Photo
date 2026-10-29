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

      // Téléchargement flexible déjà terminé (session précédente) :
      // on redémarre pour installer.
      if (info.installStatus == InstallStatus.downloaded) {
        _promptedThisSession = true;
        if (context.mounted) _showRestartNotice(context);
        await InAppUpdate.completeFlexibleUpdate();
        return;
      }

      // Mise à jour immédiate déjà lancée puis interrompue : on la reprend.
      if (info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress &&
          info.immediateUpdateAllowed) {
        _promptedThisSession = true;
        await InAppUpdate.performImmediateUpdate();
        return;
      }

      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return;
      }
      if (!context.mounted) return;

      // Correctif critique (priorité Play >= 4) : mode immédiat.
      if (info.updatePriority >= criticalPriority &&
          info.immediateUpdateAllowed) {
        _promptedThisSession = true;
        await InAppUpdate.performImmediateUpdate();
        return;
      }
      if (!info.flexibleUpdateAllowed) return;

      _promptedThisSession = true;

      final shouldUpdate = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const AppUpdateAvailableDialog(),
      );
      if (shouldUpdate != true) return;
      if (!context.mounted) return;

      await _startFlexibleOrOpenStore(context);
    } catch (_) {
      // Sideload, émulateur, Play Core indisponible, etc.
    }
  }

  /// Priorité Play Console à partir de laquelle la mise à jour est immédiate.
  static const int criticalPriority = 4;

  /// Flexible : l'utilisateur continue d'utiliser l'app pendant le
  /// téléchargement ; une fois téléchargée, l'app redémarre pour installer.
  Future<void> _startFlexibleOrOpenStore(BuildContext context) async {
    try {
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result == AppUpdateResult.success) {
        if (context.mounted) _showRestartNotice(context);
        await Future<void>.delayed(const Duration(seconds: 2));
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

  void _showRestartNotice(BuildContext context) {
    try {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Mise à jour téléchargée. Picon redémarre pour l\'installer…',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (_) {}
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
