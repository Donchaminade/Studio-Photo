import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Picon/api_service.dart';
import 'package:Picon/services/session_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage sécurisé simulé, partagé entre « processus » comme le Keystore.
class _FakeSecrets implements SecretStore {
  static final Map<String, String> disk = {};
  @override
  Future<String?> read(String key) async => disk[key];
  @override
  Future<void> write(String key, String value) async => disk[key] = value;
  @override
  Future<void> delete(String key) async => disk.remove(key);
}

class _BrokenSecrets implements SecretStore {
  @override
  Future<String?> read(String key) => throw Exception('indisponible');
  @override
  Future<void> write(String key, String value) => throw Exception('indisponible');
  @override
  Future<void> delete(String key) => throw Exception('indisponible');
}

const _session = UserSession(
  userId: 7,
  userName: 'Tega',
  dialCode: '+229',
  phone: '97000000',
  token: 'jeton-test',
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _FakeSecrets.disk.clear();
    SessionStore.instance = SessionStore(secrets: _FakeSecrets());
  });

  test('la session survit à la destruction du processus', () async {
    await SessionStore.instance.save(_session);
    // Nouveau processus : aucun état en mémoire, seulement le disque.
    final restored = await SessionStore(secrets: _FakeSecrets()).restore();
    expect(restored, isNotNull);
    expect(restored!.userId, 7);
    expect(restored.userName, 'Tega');
    expect(restored.dialCode, '+229');
    expect(restored.token, 'jeton-test');
  });

  test('déconnexion : la session est effacée', () async {
    await SessionStore.instance.save(_session);
    await SessionStore.instance.clear();
    expect(await SessionStore(secrets: _FakeSecrets()).restore(), isNull);
  });

  test('repli si le stockage sécurisé est indisponible', () async {
    final store = SessionStore(secrets: _BrokenSecrets());
    await store.save(_session);
    expect((await SessionStore(secrets: _BrokenSecrets()).restore())?.token, 'jeton-test');
  });

  test("l'indicatif pays de l'inscription est enregistré", () async {
    await SessionStore.instance.saveSignupContact(dialCode: '+225', phone: '0700000000');
    expect(await SessionStore.instance.signupDialCode(), '+225');
  });

  test('vraie auth : le jeton JWT survit au redémarrage (ApiService.init)', () async {
    await ApiService.init();
    await ApiService.saveAuthDetails({
      'token': 'jwt-test',
      'refreshToken': 'refresh-test',
      'id': 42,
      'firstname': 'Tega',
      'lastname': 'A.',
      'email': 'tega@studio.tg',
      'phone': '+22890000000',
    });
    // Simule la mort du processus : on relit uniquement le disque.
    await ApiService.init();
    expect(ApiService.authToken, 'jwt-test');
    expect(ApiService.userId, 42);
    expect(ApiService.userName, 'Tega');
  });

  testWidgets('30 s en arrière-plan puis retour : la session reste en place', (tester) async {
    await ApiService.init();
    await ApiService.saveAuthDetails({
      'token': 'jwt-test',
      'id': 42,
      'firstname': 'Tega',
      'lastname': 'A.',
      'email': 'tega@studio.tg',
    });
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump(const Duration(seconds: 30));
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    await ApiService.init();
    expect(ApiService.authToken, 'jwt-test');
    expect(ApiService.userId, 42);
  });
}
