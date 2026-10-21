import 'package:Picon/utils/togo_mobile_prefixes.dart';

/// Opérateur mobile détecté à partir du numéro (Togo).
enum MobileOperator { yas, moov, unknown }

/// Réseau choisi pour le paiement.
enum PaymentNetwork { yasMixx, floozMoov }

class PaymentOperatorMismatch {
  final MobileOperator detected;
  final PaymentNetwork selected;

  const PaymentOperatorMismatch({
    required this.detected,
    required this.selected,
  });

  String get message {
    if (detected == MobileOperator.yas &&
        selected == PaymentNetwork.floozMoov) {
      return 'Ce numéro semble être un compte Togocom (Yas / Mixx). '
          'Vous avez choisi Flooz / Moov : le paiement risque d\'échouer. '
          'Choisissez Yas (Mixx) ou utilisez un numéro Moov (96–99, 78–79).';
    }
    if (detected == MobileOperator.moov &&
        selected == PaymentNetwork.yasMixx) {
      return 'Ce numéro semble être un compte Moov (Flooz). '
          'Vous avez choisi Yas (Mixx) : le paiement risque d\'échouer. '
          'Choisissez Flooz / Moov ou utilisez un numéro Yas (90–93, 70–73).';
    }
    return 'Le numéro ne correspond pas au moyen de paiement sélectionné.';
  }

  String get suggestedAction {
    if (detected == MobileOperator.yas) {
      return 'Sélectionnez « Yas (Mixx) » pour continuer.';
    }
    if (detected == MobileOperator.moov) {
      return 'Sélectionnez « Flooz / Moov » pour continuer.';
    }
    return 'Vérifiez le numéro ou le moyen de paiement.';
  }
}

/// Utilitaires numéro ↔ opérateur ↔ moyen de paiement.
class MobileOperatorUtils {
  MobileOperatorUtils._();

  static const String mixxPaymentName = 'Mixx by Yas';
  static const String floozPaymentName = 'Flooz / Moov Money';

  /// Extrait les 8 chiffres locaux (Togo) depuis une saisie quelconque.
  static String normalizeLocalDigits(String? raw) {
    if (raw == null) return '';
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('00228')) {
      digits = digits.substring(5);
    } else if (digits.startsWith('228') && digits.length >= 11) {
      digits = digits.substring(3);
    }
    if (digits.startsWith('0') && digits.length == 9) {
      digits = digits.substring(1);
    }
    if (digits.length > 8) {
      digits = digits.substring(digits.length - 8);
    }
    return digits;
  }

  static MobileOperator detectOperator(String? phone, {String country = 'TG'}) {
    if (country != 'TG') return MobileOperator.unknown;
    final local = normalizeLocalDigits(phone);
    if (local.length < 2) return MobileOperator.unknown;
    final prefix = local.substring(0, 2);
    if (TogoMobilePrefixes.yas.contains(prefix)) {
      return MobileOperator.yas;
    }
    if (TogoMobilePrefixes.moov.contains(prefix)) {
      return MobileOperator.moov;
    }
    return MobileOperator.unknown;
  }

  static PaymentNetwork? networkFromPaymentMethod(String paymentMethod) {
    final m = paymentMethod.toLowerCase();
    if (m.contains('flooz') || m.contains('moov')) {
      return PaymentNetwork.floozMoov;
    }
    if (m.contains('yas') || m.contains('mixx')) {
      return PaymentNetwork.yasMixx;
    }
    return null;
  }

  static String operatorHintForUssd(MobileOperator op) {
    switch (op) {
      case MobileOperator.yas:
        return 'YAS';
      case MobileOperator.moov:
        return 'MOOV';
      case MobileOperator.unknown:
        return 'UNKNOWN';
    }
  }

  static String operatorHintFromPaymentMethod(String paymentMethod) {
    final net = networkFromPaymentMethod(paymentMethod);
    if (net == PaymentNetwork.floozMoov) return 'MOOV';
    if (net == PaymentNetwork.yasMixx) return 'YAS';
    return 'UNKNOWN';
  }

  /// `null` si cohérent ou numéro non reconnu.
  static PaymentOperatorMismatch? checkPaymentMatch({
    required String? phone,
    required String paymentMethod,
    String country = 'TG',
  }) {
    if (country != 'TG') return null;
    final detected = detectOperator(phone, country: country);
    final selected = networkFromPaymentMethod(paymentMethod);
    if (detected == MobileOperator.unknown || selected == null) {
      return null;
    }
    if (detected == MobileOperator.yas &&
        selected == PaymentNetwork.floozMoov) {
      return PaymentOperatorMismatch(
        detected: detected,
        selected: selected,
      );
    }
    if (detected == MobileOperator.moov &&
        selected == PaymentNetwork.yasMixx) {
      return PaymentOperatorMismatch(
        detected: detected,
        selected: selected,
      );
    }
    return null;
  }

  static String operatorLabel(MobileOperator op) {
    switch (op) {
      case MobileOperator.yas:
        return 'Togocom (Yas)';
      case MobileOperator.moov:
        return 'Moov (Flooz)';
      case MobileOperator.unknown:
        return 'inconnu';
    }
  }
}
