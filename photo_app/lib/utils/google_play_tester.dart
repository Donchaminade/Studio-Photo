import 'package:Picon/api_service.dart';

/// Compte Google Play autorisé à terminer une commande sans USSD réel.
const String kGooglePlayTesterEmail = 'playtester@photopicon.com';

/// Détection robuste (lowercase + trim) via [ApiService.userEmail].
bool isGooglePlayTester() {
  final email = (ApiService.userEmail ?? '').trim().toLowerCase();
  return email == kGooglePlayTesterEmail;
}
