# Publier Picon sur Google Play Store

## Identifiants de l'application

| Champ | Valeur |
|-------|--------|
| **Nom Play Store** | `Picon` |
| **Package (applicationId)** | `com.photopicon.app` |
| **Version** | 1.0.0 (build 4) |
| **API** | `https://api.photopicon.com/api` (prod par défaut) |

## Keystore (IMPORTANT — sauvegarder)

Fichiers locaux (ne jamais committer) :
- `photo_app/android/picon-upload.keystore`
- `photo_app/android/key.properties`

| Paramètre | Valeur |
|-----------|--------|
| Alias | `picon` |
| Mot de passe | `PiconUpload2026!` |

**Copiez le keystore sur une clé USB / cloud privé.** Sans lui, vous ne pourrez plus publier de mises à jour.

---

## Refus Play Store (READ_MEDIA_IMAGES)

Si Google refuse l'app pour **permissions photos/vidéos** :

1. L'app utilise maintenant le **sélecteur photo Android** (sans `READ_MEDIA_IMAGES`)
2. Play Console → **Contenu de l'app** → **Autorisations photos** → indiquer que l'app **n'utilise plus** cette permission
3. Uploader un nouveau `.aab` avec `versionCode` supérieur (ex. build 3)
4. Cliquer **Afficher les détails** sur chaque refus pour lire le motif exact

Autres causes fréquentes de refus :
- **Politique de confidentialité** : coller `https://gist.github.com/Donchaminade/fc889db6cd328e7f4e33d2c94f7fd0fc` (Gist public Markdown picon-privacy-policy.md — pas besoin de redeploy backend)
- **Sécurité des données** formulaire incomplet
- **Suppression de compte** : obligatoire si inscription utilisateur (URL ou procédure dans l'app) — procédure décrite sur la page privacy (contacter le studio)
- **Accès app** : identifiants test pour les examinateurs Google

---

## 1. Générer le fichier pour Play Store (.aab)

```powershell
cd "C:\Users\chami\Desktop\FLUTTER PROJECTS\Studio-Photo\photo_app"
flutter clean
flutter pub get
flutter build appbundle --release
```

Fichier produit :
```
photo_app\build\app\outputs\bundle\release\app-release.aab
```

---

## 2. Créer l'application sur Play Console

1. [Google Play Console](https://play.google.com/console) — compte développeur (25 $)
2. **Créer une application**
   - Nom : `Picon`
   - Package : **`com.photopicon.app`** (exactement)
   - Langue : Français (France)
   - Type : **Appli**
   - **Sans frais**
   - Protection Play : **Oui**

---

## 3. Play App Signing

À la 1ère upload, Google propose **Play App Signing** → acceptez.
- Vous uploadez avec `picon-upload.keystore` (clé upload)
- Google signe la version distribuée (clé app signing)

---

## 4. Uploader le .aab

**Production** (ou **Test interne** pour essai rapide) → **Créer une version** → uploader `app-release.aab`.

---

## 5. Fiche Play Store (obligatoire)

| Élément | Détail |
|---------|--------|
| **Description courte** | max 80 caractères |
| **Description complète** | présentation du studio photo |
| **Icône** | 512×512 PNG |
| **Capture d'écran** | min. 2 (téléphone) |
| **Politique de confidentialité** | `https://gist.github.com/Donchaminade/fc889db6cd328e7f4e33d2c94f7fd0fc` |
| **E-mail de contact** | `contact@photopicon.com` |
| **Catégorie** | Photographie ou Shopping |

**URL politique de confidentialité (à coller dans Play Console) :**

```
https://gist.github.com/Donchaminade/fc889db6cd328e7f4e33d2c94f7fd0fc
```

Fichier Gist : `picon-privacy-policy.md` (Markdown public). Couvre : autorisations Android (Internet, sélecteur photo système **sans** `READ_MEDIA_IMAGES`, `CALL_PHONE` / `READ_PHONE_STATE` / `READ_PHONE_NUMBERS` pour USSD), données collectées, usage des images (impression uniquement, pas de vente), finalités, partage, conservation, suppression de compte, enfants 13+, contact WhatsApp +228 98 52 62 26.

Raw Markdown : `https://gist.githubusercontent.com/Donchaminade/fc889db6cd328e7f4e33d2c94f7fd0fc/raw/picon-privacy-policy.md`

Pas de redeploy backend requis. Alias backend (optionnel) : `https://api.photopicon.com/privacy`

Exemple description courte :
> Imprimez vos photos depuis votre mobile chez Picon Studio.

---

## 6. Conformité

- **Classification du contenu** : questionnaire Play Console
- **Sécurité des données** : déclarer email, téléphone, photos, paiement
- **Public cible** : tranche d'âge (ex. 13+ ou 18+)
- **Tests** : test interne recommandé avant production

---

## 6bis. Accès appli — identifiants testeurs (Play Console)

Play Console → **Contenu de l'app** → **Accès à l'application** → indiquer que un **login est requis**, puis coller les instructions ci-dessous.

### Compte CLIENT pour les examinateurs Google (déjà créé en prod)

| Champ | Valeur |
|-------|--------|
| **Email** | `playtester@photopicon.com` |
| **Mot de passe** | `PlayTest2026!` |
| **PIN (code secret)** | `2468` |
| **Téléphone** | `0611223344` |

**Texte à coller dans « Instructions de test » :**

```
Connexion obligatoire dans l'app Picon.

1. Ouvrir l'app → écran Connexion / Inscription
2. Se connecter avec :
   - Email : playtester@photopicon.com
   - Mot de passe : PlayTest2026!
3. Si demandé (réinitialisation / récupération) :
   - PIN / code secret : 2468
4. Parcours à tester : parcourir formats/cadres, créer une commande photo, consulter le profil.
API : https://api.photopicon.com
```

### Compte ADMIN (tests internes uniquement — PAS pour Google)

Disponible **après redéploiement** du JAR (créé au boot par `AdminUserInitializer`) :

| Champ | Valeur |
|-------|--------|
| **Email** | `admin@photopicon.com` |
| **Mot de passe** | `AdminTest2026!` |
| **Panel** | `https://api.photopicon.com/admin/login` |

Ne pas fournir le compte admin aux examinateurs Play Store.

---

## 7. Soumettre pour examen

Vérifier que toutes les sections ont une coche verte → **Envoyer pour examen**.

Délai habituel : **1 à 7 jours** (parfois plus la 1ère fois).

---

## Mises à jour futures

1. Incrémenter dans `pubspec.yaml` : `version: 1.0.1+2` (+1 sur le nombre après `+`)
2. `flutter build appbundle --release`
3. Play Console → nouvelle version → upload du `.aab`

---

## Dépannage

| Problème | Solution |
|----------|----------|
| Keystore incorrect | Vérifier `android/key.properties` |
| Package déjà pris | Le nom `com.photopicon.app` doit être unique sur Play |
| API ne répond pas | Vérifier `https://api.photopicon.com/api/promotions` |
