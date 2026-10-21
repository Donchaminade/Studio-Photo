import 'dart:io';

import 'package:Picon/utils/app_permissions_service.dart';
import 'package:Picon/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permissions nécessaires pour le paiement USSD sur la bonne carte SIM.
///
/// Aligné sur [AppPermissionsService] : téléphone uniquement, jamais photos.
/// Si refus définitif → [openAppSettings].
class PhonePaymentPermissions {
  PhonePaymentPermissions._();

  /// Vérifie / redemande l'autorisation téléphone avant un paiement.
  static Future<bool> ensureGranted() async {
    if (!Platform.isAndroid) return true;

    final current = await AppPermissionsService.phoneStatus();
    if (AppPermissionsService.isPhoneUsable(current)) return true;

    if (AppPermissionsService.needsAppSettings(current)) {
      await openAppSettings();
      return AppPermissionsService.isPhoneCurrentlyGranted();
    }

    final result = await AppPermissionsService.requestPhonePermission();
    if (AppPermissionsService.isPhoneUsable(result)) return true;

    if (AppPermissionsService.needsAppSettings(result)) {
      await openAppSettings();
      return AppPermissionsService.isPhoneCurrentlyGranted();
    }

    return false;
  }

  /// Dialogue explicatif si l'utilisateur a refusé (message rouge habituel).
  static Future<void> openSettings() => openAppSettings();

  static Future<bool> showDeniedDialog(BuildContext context) async {
    final retry = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sim_card, color: AppColors.primary),
            SizedBox(width: 10),
            Expanded(child: Text('Accès téléphone')),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Oui, c\'est normal : Picon demande cet accès pour le paiement Mobile Money.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'L\'app en a besoin pour :\n'
                '• repérer vos numéros sur les cartes SIM ;\n'
                '• lancer le pop-up USSD sur la bonne ligne (Yas ou Moov), '
                'sans choisir la SIM à la main.',
              ),
              SizedBox(height: 12),
              Text(
                'Ce n\'est pas pour vous appeler ni lire vos messages — '
                'uniquement pour le paiement marchand, comme sur 1xBet.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Paramètres'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
    return retry == true;
  }
}
