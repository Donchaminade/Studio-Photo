import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:Picon/api_service.dart';
import 'package:Picon/utils/mobile_operator_utils.dart';

/// Carte SIM détectée sur l'appareil (Android).
class SimCardInfo {
  final int subscriptionId;
  final int slotIndex;
  final String carrierName;
  final String displayName;
  final String rawNumber;
  final String localDigits;

  const SimCardInfo({
    required this.subscriptionId,
    required this.slotIndex,
    required this.carrierName,
    required this.displayName,
    required this.rawNumber,
    required this.localDigits,
  });

  factory SimCardInfo.fromMap(Map<dynamic, dynamic> map) {
    final raw = (map['number'] as String?) ?? '';
    return SimCardInfo(
      subscriptionId: (map['subscriptionId'] as num?)?.toInt() ?? 0,
      slotIndex: (map['slotIndex'] as num?)?.toInt() ?? 0,
      carrierName: (map['carrierName'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      rawNumber: raw,
      localDigits: MobileOperatorUtils.normalizeLocalDigits(raw),
    );
  }

  String get label {
    final op = MobileOperatorUtils.detectOperator(localDigits);
    final opName = op != MobileOperator.unknown
        ? MobileOperatorUtils.operatorLabel(op)
        : carrierName;
    if (localDigits.length == 8) {
      return 'SIM ${slotIndex + 1} · $localDigits ($opName)';
    }
    return 'SIM ${slotIndex + 1} · $opName';
  }
}

/// Lecture des cartes SIM (numéro de la ligne pour préremplir Mobile Money).
class SimInfoService {
  SimInfoService._();

  static const MethodChannel _channel = MethodChannel('com.picon/ussd');

  static Future<List<SimCardInfo>> getSimCards() async {
    if (!Platform.isAndroid) return [];
    try {
      final list = await _channel.invokeMethod<List<dynamic>>('getSimCards');
      if (list == null) return [];
      return list
          .whereType<Map>()
          .map((e) => SimCardInfo.fromMap(e))
          .where((s) => s.localDigits.length == 8)
          .toList();
    } catch (e) {
      debugPrint('getSimCards: $e');
      return [];
    }
  }

  /// Numéro suggéré : profil utilisateur, sinon première SIM Togo valide.
  static Future<String?> suggestLocalPhone({String country = 'TG'}) async {
    if (country == 'TG') {
      final fromProfile =
          MobileOperatorUtils.normalizeLocalDigits(ApiService.userPhone);
      if (fromProfile.length == 8) return fromProfile;
    }

    final sims = await getSimCards();
    if (sims.isEmpty) return null;
    if (sims.length == 1 && sims.first.localDigits.length == 8) {
      return sims.first.localDigits;
    }

    for (final sim in sims) {
      if (sim.localDigits.length == 8) return sim.localDigits;
    }
    return null;
  }
}
