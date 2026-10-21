# Configuration Firebase (à fournir)

L'application démarre **sans** Firebase : `FirebaseBootstrap.init()` (lib/services/firebase_bootstrap.dart)
intercepte l'absence de configuration. Pour activer Firebase, il faut :

1. **Android** : `android/app/google-services.json` téléchargé depuis la console Firebase pour une
   application Android avec l'ID de package **`com.photopicon.app`** (+ empreintes SHA-1/SHA-256 de la
   clé de signature pour Google Sign-In). Puis ajouter le plugin `com.google.gms.google-services`
   dans `android/settings.gradle` et `android/app/build.gradle`.
2. **iOS** : `ios/Runner/GoogleService-Info.plist` pour le bundle ID **`com.photopicon.app`**, ajouté
   à la cible Runner dans Xcode (et le `REVERSED_CLIENT_ID` dans les URL types pour Google Sign-In).
3. **Web (optionnel)** : lancer `flutterfire configure --project=<id-projet>` pour générer
   `lib/firebase_options.dart`, puis passer `DefaultFirebaseOptions.currentPlatform` à
   `FirebaseBootstrap.init(options: ...)` dans `lib/main.dart`.
4. Dans la console : activer Authentication (e-mail/mot de passe, téléphone, Google) et Firestore.

Identifiant d'application : Android `applicationId`/`namespace` = `com.photopicon.app`,
iOS/macOS `PRODUCT_BUNDLE_IDENTIFIER` = `com.photopicon.app` (Play Store : `com.photopicon.app`).
