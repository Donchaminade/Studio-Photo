import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session utilisateur persistée sur l'appareil.
///
/// Le profil (non sensible) est stocké dans SharedPreferences, le jeton de
/// session dans le stockage sécurisé (Keychain / Keystore). La session ne
/// dépend donc plus de l'état en mémoire : elle survit à la mise en arrière-plan,
/// à la destruction du processus par le système et au redémarrage.
@immutable
class UserSession {
  final int userId;
  final String userName;
  final String email;
  final String dialCode;
  final String phone;
  final String token;

  const UserSession({
    required this.userId,
    required this.userName,
    this.email = '',
    this.dialCode = '',
    this.phone = '',
    required this.token,
  });

  Map<String, dynamic> toProfileJson() => {
        'userId': userId,
        'userName': userName,
        'email': email,
        'dialCode': dialCode,
        'phone': phone,
      };

  static UserSession? fromStored(String? profile, String? token) {
    if (profile == null || token == null || token.isEmpty) return null;
    try {
      final map = jsonDecode(profile) as Map<String, dynamic>;
      return UserSession(
        userId: (map['userId'] as num?)?.toInt() ?? 0,
        userName: '${map['userName'] ?? 'Utilisateur'}',
        email: '${map['email'] ?? ''}',
        dialCode: '${map['dialCode'] ?? ''}',
        phone: '${map['phone'] ?? ''}',
        token: token,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Stockage du secret, abstrait pour pouvoir être remplacé dans les tests.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureSecretStore implements SecretStore {
  const SecureSecretStore();
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Repli en mémoire + SharedPreferences si le stockage sécurisé est
/// indisponible (ex. navigateur sans WebCrypto) : on ne perd jamais la session.
class SessionStore {
  SessionStore({SecretStore? secrets})
      : _secrets = secrets ?? const SecureSecretStore();

  static SessionStore instance = SessionStore();

  static const profileKey = 'picon.session.profile';
  static const tokenKey = 'picon.session.token';
  static const _fallbackTokenKey = 'picon.session.token.fallback';
  static const dialCodeKey = 'picon.signup.dialCode';
  static const signupPhoneKey = 'picon.signup.phone';

  final SecretStore _secrets;

  /// Session courante, utile pour l'UI ; la source de vérité reste le disque.
  final ValueNotifier<UserSession?> current = ValueNotifier<UserSession?>(null);

  static String newToken() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(32, (_) => r.nextInt(256)));
  }

  Future<void> save(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(profileKey, jsonEncode(session.toProfileJson()));
    try {
      await _secrets.write(tokenKey, session.token);
      await prefs.remove(_fallbackTokenKey);
    } catch (_) {
      await prefs.setString(_fallbackTokenKey, session.token);
    }
    current.value = session;
  }

  Future<UserSession?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    String? token;
    try {
      token = await _secrets.read(tokenKey);
    } catch (_) {
      token = null;
    }
    token ??= prefs.getString(_fallbackTokenKey);
    final session = UserSession.fromStored(prefs.getString(profileKey), token);
    current.value = session;
    return session;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(profileKey);
    await prefs.remove(_fallbackTokenKey);
    try {
      await _secrets.delete(tokenKey);
    } catch (_) {}
    current.value = null;
  }

  /// Indicatif pays choisi à l'inscription (ex. +228).
  Future<void> saveSignupContact(
      {required String dialCode, required String phone}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(dialCodeKey, dialCode);
    await prefs.setString(signupPhoneKey, phone);
  }

  Future<String?> signupDialCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(dialCodeKey);
  }
}
