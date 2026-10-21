# Picon — Configuration et code complet USSD (Togo)

Document de référence pour réutilisation dans d'autres logiciels.  
Généré depuis le projet **Studio-Photo / Picon** — *2026-06-04*

## Table des matières

1. [Résumé des codes USSD marchand](#1-résumé-des-codes-ussd-marchand)
2. [Numéros marchands (constantes)](#2-numéros-marchands-constantes)
3. [Détection opérateur (préfixes Togo)](#3-détection-opérateur-préfixes-togo)
4. [Correspondance moyen de paiement ↔ réseau](#4-correspondance-moyen-de-paiement--réseau)
5. [Exemples concrets avec montants](#5-exemples-concrets-avec-montants)
6. [Algorithme de génération du code USSD](#6-algorithme-de-génération-du-code-ussd)
7. [Code Dart complet (génération + lancement)](#7-code-dart-complet-génération--lancement)
8. [Code Kotlin Android complet (lancement sur la bonne SIM)](#8-code-kotlin-android-complet-lancement-sur-la-bonne-sim)
9. [Permissions Android requises](#9-permissions-android-requises)
10. [Canal Flutter ↔ Android](#10-canal-flutter--android)
11. [Flux utilisateur dans Picon](#11-flux-utilisateur-dans-picon)
12. [Notes pour intégration dans un autre logiciel](#12-notes-pour-intégration-dans-un-autre-logiciel)
13. [Architecture sécurisée (codes côté serveur)](#13-architecture-sécurisée-codes-côté-serveur)

---

## 1. Résumé des codes USSD marchand

| Réseau | Moyen de paiement UI | Modèle USSD |
|--------|----------------------|-------------|
| Yas / Mixx | `"Mixx by Yas"`, `"Yas (Mixx)"` | `*145*5*{MONTANT}*1322683#` |
| Flooz / Moov | `"Flooz / Moov Money"`, etc. | `*155*2*2*140425*140425*{MONTANT}#` |

- **{MONTANT}** = montant entier en FCFA, sans décimales, sans séparateur.  
  Exemple : 1500 FCFA → `1500`
- Le caractère `#` final est **obligatoire** dans le code USSD complet.
- Sur iOS / fallback : encoder `#` en `%23` dans une URL `tel:`  
  Exemple Yas 1500 FCFA → `tel:*145*5*1500*1322683%23`

---

## 2. Numéros marchands (constantes)

### Yas / Mixx by Yas (Togocom)

- **Code marchand :** `1322683`
- **Séquence USSD :** `*145*5*{montant}*1322683#`

### Moov / Flooz

- **Code marchand :** `140425` (utilisé 2 fois dans la séquence)
- **Séquence USSD :** `*155*2*2*140425*140425*{montant}#`

---

## 3. Détection opérateur (préfixes Togo)

Numéro local Togo = **8 chiffres** (sans indicatif `+228`).

### Togocom — Yas / Mixx by Yas

Préfixes (2 premiers chiffres) :

- `90`, `91`, `92`, `93` (historique)
- `70`, `71`, `72`, `73` (récent)

### Moov Africa — Flooz

Préfixes (2 premiers chiffres) :

- `96`, `97`, `98`, `99` (historique)
- `78`, `79` (récent)

### Normalisation du numéro

Entrée quelconque → 8 chiffres locaux :

1. Supprimer tout sauf les chiffres
2. Si commence par `00228` → retirer `00228`
3. Sinon si commence par `228` et longueur ≥ 11 → retirer `228`
4. Si commence par `0` et longueur == 9 → retirer le `0` initial
5. Si longueur > 8 → garder les 8 derniers chiffres

---

## 4. Correspondance moyen de paiement ↔ réseau

Détection du réseau depuis le nom du moyen de paiement (insensible à la casse) :

| Condition | Réseau | USSD |
|-----------|--------|------|
| contient `"flooz"` OU `"moov"` | Flooz / Moov | `*155*...` |
| contient `"yas"` OU `"mixx"` | Yas / Mixx | `*145*...` |

**Noms utilisés dans l'app Picon :**

- Yas : `"Mixx by Yas"` / `"Yas (Mixx)"`
- Moov : `"Flooz / Moov Money"` / `"Flooz / Moov"`

**Indice SIM pour Android (`operatorHint`) :**

| Opérateur | Valeur |
|-----------|--------|
| Yas | `YAS` |
| Moov | `MOOV` |
| Inconnu | `UNKNOWN` |

---

## 5. Exemples concrets avec montants

### 500 FCFA

```
Yas  : *145*5*500*1322683#
Moov : *155*2*2*140425*140425*500#
```

### 1500 FCFA

```
Yas  : *145*5*1500*1322683#
Moov : *155*2*2*140425*140425*1500#
```

### 25000 FCFA

```
Yas  : *145*5*25000*1322683#
Moov : *155*2*2*140425*140425*25000#
```

### Vérification cohérence numéro / paiement

- Numéro `90123456` (préfixe `90` = Yas) + paiement Flooz → **avertissement**
- Numéro `96123456` (préfixe `96` = Moov) + paiement Yas → **avertissement**

---

## 6. Algorithme de génération du code USSD

> ℹ️ **Cet algorithme s'exécute désormais côté serveur** (backend Spring Boot),
> pas dans l'application mobile. Les modèles USSD sont stockés en base et
> modifiables depuis l'admin. Voir [section 13](#13-architecture-sécurisée-codes-côté-serveur).

### Entrée

- `paymentMethod` : string (ex. `"Mixx by Yas"` ou `"Flooz / Moov Money"`) — issu de la commande
- `totalAmount` : nombre (ex. `1500.50`) — issu de la commande (montant authoritatif serveur)

### Étapes

1. `amount` = arrondir `totalAmount` à l'entier le plus proche, format sans décimales
2. `method` = `paymentMethod` en minuscules
3. Si `method` contient `"flooz"` OU `"moov"` :  
   retourner `"*155*2*2*140425*140425*" + amount + "#"`
4. Sinon (Yas / Mixx par défaut) :  
   retourner `"*145*5*" + amount + "*1322683#"`

### Pseudo-code (langage neutre)

```text
function merchantUssdCode(paymentMethod, totalAmount):
    amount = formatInteger(totalAmount)   // "1500"
    m = lowercase(paymentMethod)
    if m contains "flooz" or m contains "moov":
        return "*155*2*2*140425*140425*" + amount + "#"
    return "*145*5*" + amount + "*1322683#"
```

---

## 7. Code Dart complet (génération + lancement)

> ⚠️ **SÉCURITÉ — Les codes marchands ne sont plus générés dans l'app.**
> Depuis la version sécurisée, les codes marchands (`1322683`, `140425`) ne
> sont **jamais embarqués dans l'application mobile**. Ils sont stockés et
> résolus **côté serveur**, puis fournis au client via un endpoint authentifié
> et lié à une commande. Voir la [section 13](#13-architecture-sécurisée-codes-côté-serveur).
> L'ancien fichier `payment_ussd_codes.dart` a été **supprimé**.

### `togo_mobile_prefixes.dart`

```dart
class TogoMobilePrefixes {
  TogoMobilePrefixes._();

  static const List<String> yas = [
    '90', '91', '92', '93',
    '70', '71', '72', '73',
  ];

  static const List<String> moov = [
    '96', '97', '98', '99',
    '78', '79',
  ];
}
```

### `mobile_operator_utils.dart` (extrait utile)

```dart
enum MobileOperator { yas, moov, unknown }
enum PaymentNetwork { yasMixx, floozMoov }

class MobileOperatorUtils {
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
    if (TogoMobilePrefixes.yas.contains(prefix)) return MobileOperator.yas;
    if (TogoMobilePrefixes.moov.contains(prefix)) return MobileOperator.moov;
    return MobileOperator.unknown;
  }

  static String operatorHintForUssd(MobileOperator op) {
    switch (op) {
      case MobileOperator.yas: return 'YAS';
      case MobileOperator.moov: return 'MOOV';
      case MobileOperator.unknown: return 'UNKNOWN';
    }
  }

  static String operatorHintFromPaymentMethod(String paymentMethod) {
    final m = paymentMethod.toLowerCase();
    if (m.contains('flooz') || m.contains('moov')) return 'MOOV';
    if (m.contains('yas') || m.contains('mixx')) return 'YAS';
    return 'UNKNOWN';
  }
}
```

### `ussd_launch_service.dart`

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class UssdLaunchService {
  static const MethodChannel _channel = MethodChannel('com.picon/ussd');

  static Future<UssdLaunchResult> launchPaymentUssd({
    required String ussdCode,
    required String paymentPhone,
    required String operatorHint,
  }) async {
    if (!Platform.isAndroid) {
      final path = ussdCode.replaceAll('#', '%23');
      final uri = Uri(scheme: 'tel', path: path);
      final launched = await launchUrl(uri);
      return UssdLaunchResult(
        success: launched,
        message: launched
            ? 'Validez le paiement sur votre téléphone.'
            : 'Impossible d\'ouvrir le paiement USSD.',
      );
    }

    final raw = await _channel.invokeMethod<dynamic>('launchUssd', {
      'code': ussdCode,
      'paymentPhone': paymentPhone,
      'operatorHint': operatorHint,
    });

    if (raw is Map && raw['success'] == true) {
      return UssdLaunchResult(success: true, message: 'Validez le paiement USSD.');
    }
    return UssdLaunchResult(
      success: false,
      message: 'Impossible de lancer le paiement USSD.',
    );
  }
}

class UssdLaunchResult {
  final bool success;
  final String message;
  UssdLaunchResult({required this.success, required this.message});
}
```

### Exemple d'appel (`confirmation_screen.dart`)

```dart
final ussdCode = PaymentUssdCodes.merchantCode(paymentMethod, totalAmount);

final phone = paymentPhone ?? userPhone;
final detected = MobileOperatorUtils.detectOperator(phone, country: 'TG');
final operatorHint = detected != MobileOperator.unknown
    ? MobileOperatorUtils.operatorHintForUssd(detected)
    : MobileOperatorUtils.operatorHintFromPaymentMethod(paymentMethod);

final result = await UssdLaunchService.launchPaymentUssd(
  ussdCode: ussdCode,
  paymentPhone: phone,
  operatorHint: operatorHint,
);
```

---

## 8. Code Kotlin Android complet (lancement sur la bonne SIM)

**Canal MethodChannel :** `com.picon/ussd`

### Méthodes exposées

| Méthode | Description |
|---------|-------------|
| `getSimCards` | Liste des SIM actives |
| `launchUssd` | Lance le code sur la SIM correspondante |

### Paramètres `launchUssd`

| Paramètre | Type | Exemple |
|-----------|------|---------|
| `code` | string | `"*145*5*1500*1322683#"` |
| `paymentPhone` | string? | Numéro Mobile Money du client |
| `operatorHint` | string? | `"YAS"`, `"MOOV"`, `"UNKNOWN"` |

### Stratégie de lancement (dans l'ordre)

1. `TelecomManager.placeCall()` sur la bonne SIM
2. `TelephonyManager.sendUssdRequest()` (Android 8+)
3. `Intent ACTION_CALL` vers le composeur par défaut uniquement (évite le sélecteur « Ouvrir avec » / Zoom)

### Sélection de la SIM (`resolveSubscriptionId`)

1. Comparer `paymentPhone` normalisé avec le numéro de chaque SIM
2. Sinon matcher `operatorHint` avec le nom de l'opérateur (`carrierName`)
   - `YAS` / `MIXX` / `TOGOCEL` → `yas`, `togocel`, `togocom`, `mix`
   - `MOOV` / `FLOOZ` → `moov`, `flooz`
3. Sinon première SIM active

### `MainActivity.kt` (code complet)

```kotlin
package com.example.picon

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telecom.PhoneAccountHandle
import android.telecom.TelecomManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.picon/ussd"
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSimCards" -> {
                        try {
                            result.success(getSimCards())
                        } catch (e: Exception) {
                            result.error("SIM_ERROR", e.message, null)
                        }
                    }
                    "launchUssd" -> {
                        val code = call.argument<String>("code")
                        if (code.isNullOrBlank()) {
                            result.error("INVALID", "Code USSD requis", null)
                            return@setMethodCallHandler
                        }
                        if (ContextCompat.checkSelfPermission(
                                this, Manifest.permission.CALL_PHONE
                            ) != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("PERMISSION", "Permission CALL_PHONE refusée", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val paymentPhone = call.argument<String>("paymentPhone")
                            val operatorHint = call.argument<String>("operatorHint")
                            val launchResult =
                                launchUssdOnMatchingSim(code, paymentPhone, operatorHint)
                            result.success(launchResult)
                        } catch (e: Exception) {
                            result.error("USSD_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun launchUssdOnMatchingSim(
        ussdCode: String,
        paymentPhone: String?,
        operatorHint: String?
    ): Map<String, Any?> {
        val subscriptionId = resolveSubscriptionId(paymentPhone, operatorHint)
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager

        if (launchUssdViaPlaceCall(ussdCode, subscriptionId, telecomManager)) {
            return mapOf("success" to true, "method" to "place_call")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && subscriptionId != null) {
            if (launchUssdViaTelephony(ussdCode, subscriptionId)) {
                return mapOf("success" to true, "method" to "ussd_dialog")
            }
        }
        if (launchUssdViaDefaultDialer(ussdCode)) {
            return mapOf("success" to true, "method" to "dialer_explicit")
        }
        return mapOf("success" to false, "method" to "failed")
    }

    private fun ussdTelUri(ussdCode: String): Uri {
        val encoded = ussdCode.replace("#", "%23")
        return Uri.parse("tel:$encoded")
    }

    private fun launchUssdViaPlaceCall(
        ussdCode: String,
        subscriptionId: Int?,
        telecomManager: TelecomManager
    ): Boolean {
        return try {
            val uri = ussdTelUri(ussdCode)
            val extras = Bundle()
            val handle = findPhoneAccountHandle(telecomManager, subscriptionId)
            if (handle != null) {
                extras.putParcelable(TelecomManager.EXTRA_PHONE_ACCOUNT_HANDLE, handle)
            }
            telecomManager.placeCall(uri, extras)
            true
        } catch (_: Exception) { false }
    }

    private fun launchUssdViaTelephony(ussdCode: String, subscriptionId: Int): Boolean {
        return try {
            val baseTm = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            val tm = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                baseTm.createForSubscriptionId(subscriptionId)
            } else baseTm
            tm.sendUssdRequest(ussdCode, object : TelephonyManager.UssdResponseCallback() {
                override fun onReceiveUssdResponse(
                    telephonyManager: TelephonyManager,
                    request: String,
                    response: CharSequence
                ) {}
                override fun onReceiveUssdResponseFailed(
                    telephonyManager: TelephonyManager,
                    request: String,
                    failureCode: Int
                ) {}
            }, mainHandler)
            true
        } catch (_: Exception) { false }
    }

    private fun launchUssdViaDefaultDialer(ussdCode: String): Boolean {
        val uri = ussdTelUri(ussdCode)
        val telecomManager = getSystemService(Context.TELECOM_SERVICE) as TelecomManager
        val candidates = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            telecomManager.defaultDialerPackage?.let { candidates.add(it) }
        }
        candidates.addAll(listOf(
            "com.google.android.dialer",
            "com.android.dialer",
            "com.samsung.android.dialer",
            "com.sh.smart.caller",
            "com.huawei.contacts"
        ))
        for (pkg in candidates.distinct()) {
            try {
                val intent = Intent(Intent.ACTION_CALL, uri).apply {
                    setPackage(pkg)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                if (intent.resolveActivity(packageManager) != null) {
                    startActivity(intent)
                    return true
                }
            } catch (_: Exception) {}
        }
        return false
    }

    private fun resolveSubscriptionId(paymentPhone: String?, operatorHint: String?): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP_MR1) return null
        val sm = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
        if (ActivityCompat.checkSelfPermission(
                this, Manifest.permission.READ_PHONE_STATE
            ) != PackageManager.PERMISSION_GRANTED
        ) return null
        val subs = sm.activeSubscriptionInfoList ?: return null
        if (subs.isEmpty()) return null

        val paymentLocal = normalizeLocalDigits(paymentPhone)
        if (paymentLocal.length >= 8) {
            val tail = paymentLocal.takeLast(8)
            for (info in subs) {
                val simLocal = normalizeLocalDigits(readNumberForSubscription(info))
                if (simLocal.isNotEmpty() &&
                    (simLocal == tail || simLocal.endsWith(tail) || tail.endsWith(simLocal))
                ) {
                    return info.subscriptionId
                }
            }
        }

        val hint = operatorHint?.uppercase() ?: ""
        if (hint.isNotEmpty()) {
            for (info in subs) {
                val label = "${info.carrierName} ${info.displayName}".lowercase()
                when {
                    hint.contains("YAS") || hint.contains("MIXX") || hint.contains("TOGOCEL") -> {
                        if (label.contains("yas") || label.contains("togocel") ||
                            label.contains("togocom") || label.contains("mix")
                        ) return info.subscriptionId
                    }
                    hint.contains("MOOV") || hint.contains("FLOOZ") -> {
                        if (label.contains("moov") || label.contains("flooz")) {
                            return info.subscriptionId
                        }
                    }
                }
            }
        }
        return subs.first().subscriptionId
    }

    private fun normalizeLocalDigits(phone: String?): String {
        if (phone.isNullOrBlank()) return ""
        var digits = phone.replace(Regex("[^0-9]"), "")
        if (digits.startsWith("00228")) digits = digits.substring(5)
        else if (digits.startsWith("228") && digits.length >= 11) digits = digits.substring(3)
        if (digits.startsWith("0") && digits.length == 9) digits = digits.substring(1)
        if (digits.length > 8) digits = digits.substring(digits.length - 8)
        return digits
    }

    // getSimCards(), readNumberForSubscription(), findPhoneAccountHandle() :
    // voir fichier source photo_app/android/.../MainActivity.kt
}
```

---

## 9. Permissions Android requises

### `AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CALL_PHONE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />
```

### Flutter (`permission_handler`)

`Permission.phone` regroupe `CALL_PHONE` + `READ_PHONE_STATE` + `READ_PHONE_NUMBERS`

### Packages composeur (queries Android 11+)

```xml
<package android:name="com.google.android.dialer" />
<package android:name="com.android.dialer" />
<package android:name="com.samsung.android.dialer" />
```

---

## 10. Canal Flutter ↔ Android

**Nom du canal :** `com.picon/ussd`

### `getSimCards`

| | |
|---|---|
| **Entrée** | (aucune) |
| **Sortie** | `List<Map>` avec `subscriptionId`, `slotIndex`, `carrierName`, `displayName`, `number` |

### `launchUssd`

**Entrée :**

| Champ | Type | Description |
|-------|------|-------------|
| `code` | string | Code USSD complet avec `#` |
| `paymentPhone` | string | Numéro client (recommandé) |
| `operatorHint` | string | `YAS` \| `MOOV` \| `UNKNOWN` |

**Sortie :**

| Champ | Valeurs possibles |
|-------|-------------------|
| `success` | `true` / `false` |
| `method` | `place_call` \| `ussd_dialog` \| `dialer_explicit` \| `failed` |

---

## 11. Flux utilisateur dans Picon

1. Client choisit photos + format
2. Client choisit moyen de paiement : Yas (Mixx) ou Flooz / Moov
3. Client saisit son numéro Mobile Money
4. Vérification cohérence numéro ↔ opérateur (avertissement si mismatch)
5. Commande créée côté backend
6. Écran confirmation → génération USSD + lancement automatique
7. Client valide dans la fenêtre USSD (code secret Mobile Money)
8. Client upload capture d'écran + référence paiement
9. Admin valide manuellement la commande

---

## 12. Notes pour intégration dans un autre logiciel

### PHP / Java / Python / Node.js (backend web)

- Implémenter uniquement la [section 6](#6-algorithme-de-génération-du-code-ussd) (`merchantUssdCode`)
- Le backend **ne peut pas** lancer l'USSD : c'est le téléphone qui le fait
- Retourner le code USSD au client ou l'afficher pour composition manuelle

### Application mobile Android native

- Reprendre la [section 8](#8-code-kotlin-android-complet-lancement-sur-la-bonne-sim) (Kotlin) + [permissions](#9-permissions-android-requises)
- Adapter le package name si besoin

### Application Flutter

- Reprendre [sections 7](#7-code-dart-complet-génération--lancement) + [8](#8-code-kotlin-android-complet-lancement-sur-la-bonne-sim) + dépendance `permission_handler`

### Application iOS

- Lancement limité via `tel:` URI ([section 7](#7-code-dart-complet-génération--lancement), branche iOS)
- Pas de sélection SIM programmatique sur iOS

### Variables à mettre à jour si les codes marchand changent

| Réseau | Constante | Emplacement (sécurisé) |
|--------|-----------|------------------------|
| Yas | `1322683` dans `*145*5*{montant}*1322683#` | **Base de données serveur** (`ussd_merchant_config.yas_template`), éditable en admin |
| Moov | `140425` dans `*155*2*2*140425*140425*{montant}#` | **Base de données serveur** (`ussd_merchant_config.moov_template`), éditable en admin |

> ⚠️ Ces constantes ne sont **plus présentes dans le code de l'app mobile**.

### Fichiers sources dans le projet Picon

```
# Mobile
photo_app/lib/utils/mobile_operator_utils.dart
photo_app/lib/utils/togo_mobile_prefixes.dart
photo_app/lib/services/ussd_launch_service.dart
photo_app/lib/services/sim_info_service.dart
photo_app/lib/utils/phone_payment_permissions.dart
photo_app/lib/confirmation_screen.dart        # récupère le code via l'API
photo_app/android/app/src/main/kotlin/com/example/photo_app/MainActivity.kt
photo_app/android/app/src/main/AndroidManifest.xml

# Backend (codes marchands - sources de vérité)
photo_app_backend/.../payment/UssdMerchantConfig.java
photo_app_backend/.../payment/UssdMerchantConfigRepository.java
photo_app_backend/.../payment/UssdCodeService.java
photo_app_backend/.../payment/AdminPaymentConfigController.java
photo_app_backend/.../order/OrderController.java        # endpoint GET .../ussd-code
photo_app_backend/src/main/resources/templates/admin/payment/config.html
```

---

## 13. Architecture sécurisée (codes côté serveur)

### Pourquoi

Les codes marchands embarqués dans l'app étaient extractibles en décompilant
l'APK, et une app modifiée pouvait **détourner les paiements** vers un autre
compte. La parade : sortir totalement les codes de l'app.

### Principe

1. Les **modèles USSD** (avec marqueur `{amount}`) sont stockés en base, côté serveur.
2. L'app **ne connaît aucun code marchand**. Au moment de payer, elle appelle un
   endpoint **authentifié**, lié à la **commande**.
3. Le serveur calcule le code final à partir du **moyen de paiement** et du
   **montant de la commande** (montant authoritatif serveur → pas de falsification).

### Endpoint

```
GET /api/orders/{id}/ussd-code
Authorization: Bearer <token>
```

- Exige un utilisateur authentifié.
- La commande doit **appartenir** à l'utilisateur (sinon `404`).
- Réponse :

```json
{ "ussdCode": "*155*2*2*140425*140425*1500#" }
```

### Génération côté serveur (`UssdCodeService`)

```java
String method = order.getPaymentMethod().toLowerCase();
String template = method.contains("flooz") || method.contains("moov")
        ? config.getMoovTemplate()   // *155*2*2*140425*140425*{amount}#
        : config.getYasTemplate();   // *145*5*{amount}*1322683#
return template.replace("{amount}", formatAmount(order.getTotalAmount()));
```

### Récupération côté app (`confirmation_screen.dart`)

```dart
final ussdCode = await ApiService.fetchOrderUssdCode(widget.orderId);
// puis composition via UssdLaunchService.launchPaymentUssd(...)
```

En cas d'échec réseau : message d'erreur, **aucun repli avec un vrai code**.

### Configuration en admin

- Menu **« Codes USSD »** → `/admin/payment-config` (rôle `ADMIN` requis).
- Modification des modèles Yas et Moov **sans republier l'app** (rotation possible
  si un code marchand change).

### Modèle de menace couvert

| Menace | Protection |
|--------|------------|
| Extraction des codes via décompilation APK | Codes absents de l'app |
| Détournement (modifier le code marchand dans l'app) | Code fourni par le serveur, sur HTTPS |
| Falsification du montant | Montant pris depuis la commande, côté serveur |
| Accès anonyme aux codes | Endpoint authentifié + commande détenue par l'utilisateur |
| Rotation d'un code compromis | Édition immédiate en admin, sans MAJ app |

### Migration base de données

Table `ussd_merchant_config` créée automatiquement si `ddl-auto=update`
(valeurs par défaut semées au 1er accès). Sinon :

```sql
CREATE TABLE ussd_merchant_config (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  yas_template VARCHAR(128),
  moov_template VARCHAR(128)
);
```
