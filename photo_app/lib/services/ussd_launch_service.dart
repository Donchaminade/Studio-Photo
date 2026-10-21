import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:Picon/utils/phone_payment_permissions.dart';
import 'package:url_launcher/url_launcher.dart';

/// Lance un code USSD sur la SIM correspondant au numéro Mobile Money (Android).
class UssdLaunchService {
  UssdLaunchService._();

  static const MethodChannel _channel = MethodChannel('com.picon/ussd');

  /// Ouvre le flux USSD paiement marchand (sans sélecteur « Ouvrir avec »).
  static Future<UssdLaunchResult> launchPaymentUssd({
    required String ussdCode,
    required String paymentPhone,
    required String operatorHint,
  }) async {
    if (!Platform.isAndroid) {
      return _launchViaDialerIos(ussdCode);
    }

    final hasPermission = await PhonePaymentPermissions.ensureGranted();
    if (!hasPermission) {
      return const UssdLaunchResult(
        success: false,
        usedDialerFallback: false,
        permissionDenied: true,
        message:
            'Autorisez l\'accès au téléphone pour lancer le paiement Mobile Money.',
      );
    }

    try {
      final raw = await _channel.invokeMethod<dynamic>('launchUssd', {
        'code': ussdCode,
        'paymentPhone': paymentPhone,
        'operatorHint': operatorHint,
      });

      if (raw is Map && raw['success'] == true) {
        final method = raw['method'] as String? ?? '';
        return UssdLaunchResult(
          success: true,
          usedDialerFallback: false,
          permissionDenied: false,
          message: method == 'ussd_dialog'
              ? 'Validez le paiement dans la fenêtre USSD (code secret Mobile Money).'
              : 'Validez le paiement dans la fenêtre qui s\'ouvre (code secret Mobile Money).',
        );
      }
    } on PlatformException catch (e) {
      debugPrint('USSD natif: ${e.code} ${e.message}');
    }

    return const UssdLaunchResult(
      success: false,
      usedDialerFallback: false,
      permissionDenied: false,
      message:
          'Impossible de lancer le paiement USSD. Vérifiez que l\'application Téléphone est bien installée.',
    );
  }

  /// iOS uniquement — Android n'utilise jamais url_launcher (évite Zoom / « Ouvrir avec »).
  static Future<UssdLaunchResult> _launchViaDialerIos(String ussdCode) async {
    final path = ussdCode.replaceAll('#', '%23');
    final uri = Uri(scheme: 'tel', path: path);
    final launched = await launchUrl(uri);
    return UssdLaunchResult(
      success: launched,
      usedDialerFallback: true,
      permissionDenied: false,
      message: launched
          ? 'Validez le paiement sur votre téléphone.'
          : 'Impossible d\'ouvrir le paiement USSD.',
    );
  }
}

class UssdLaunchResult {
  final bool success;
  final bool usedDialerFallback;
  final bool permissionDenied;
  final String message;

  const UssdLaunchResult({
    required this.success,
    required this.usedDialerFallback,
    this.permissionDenied = false,
    required this.message,
  });
}
