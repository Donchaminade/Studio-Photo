# Checklist admin production — Picon / Studio-Photo

Actions **obligatoires côté humain** (pas d’accès RDP/admin automatisé depuis l’agent).  
Panel : `https://api.photopicon.com/admin/login`

---

## 1. Redéployer le JAR backend (ZIP + privacy)

Le JAR dans `dossier_production/photo-app-backend-0.0.1-SNAPSHOT.jar` contient déjà :
- Fix ZIP admin (`resolveLocalImagePath` / lecture locale `F:/uploads`)
- `PrivacyPolicyController` + template `privacy.html`
- `SecurityConfig` : `GET /privacy` et `/politique-de-confidentialite` en `permitAll`

**Sur le serveur Windows** (dossier WinSW) :

```bat
3_mettre_a_jour_service.bat
```

Ou manuel :

```bat
photo-backend-service.exe stop
timeout /t 5
REM copier le nouveau JAR ici si besoin
photo-backend-service.exe start
timeout /t 15
curl http://localhost:8081/actuator/health
curl -sI http://localhost:8081/privacy
```

**Vérif après redeploy** (depuis n’importe où) :

```powershell
# Doit être 200 (plus 302 vers /admin/login)
(Invoke-WebRequest https://api.photopicon.com/privacy -MaximumRedirection 0 -EA SilentlyContinue).StatusCode
# ou
curl.exe -sI https://api.photopicon.com/privacy
```

Admin → commande → **Télécharger ZIP** → HTTP 200 (ou 422 si fichiers absents, plus de 500).

Détails : `COMMANDES_REDEPLOY.md`

---

## 2. Restaurer / re-uploader les images dimensions (10/11 en 404)

État API : **11** dimensions ; **1** image OK (`9x13`) ; **10** fichiers absents sur `F:/uploads`.

### 2a. Restauration partielle (2 fichiers dans le repo)

Copier depuis le PC vers `F:\uploads\` sur le serveur (même noms exacts) :

| Fichier (dossier `dossier_production/uploads_restore/`) | Dimension prod |
|---|---|
| `c317213e-b9ef-4219-a51f-583bf2a6fb64-cafe-vrac_01.webp` | 15x21 cm |
| `51bc4427-68fb-4ee1-a483-8b9005c6684f-or.jpg` | 30x45 cm |

Les 3 autres fichiers du dossier sont des **placeholders optionnels** (pas liés aux UUID manquants) — utilisables seulement si vous **ré-éditez** la dimension en admin et re-uploadez.

### 2b. Re-upload admin (8 formats restants — obligatoire)

Admin → **Dimensions** → éditer chaque ligne → remplacer l’image :

1. 10x15 cm — `b2bb9d05-…-10x15.jpg_(1).jpeg`
2. 13x18 cm — `c53163da-…-13x18.jpg_(1).jpeg`
3. 20x25 cm — `4fc0bef9-…-20x25.jpg_(1).jpeg`
4. 20x30 cm — `7b0c97cb-…-20x30.jpg_(1).jpeg`
5. 24x30 cm — `a32a2456-…-24x302116734187.jpg`
6. 30x40 cm — `69121528-…-30x40766305733.jpg`
7. 40x50 cm — `86c690c6-…-40x50.jpg_(1).jpeg`
8. 50x60 cm — `523326b4-…-50x60_(1).jpg`

(+ 15x21 et 30x45 si la copie fichier n’a pas été faite.)

**Ne pas** lancer un seed BDD : `DimensionDataInitializer` ne tourne que si `count()==0` ; la prod a déjà 11 lignes — un seed forcé écraserait prix/titres réels.

Vérif : `https://api.photopicon.com` + chemin image → HTTP 200.

---

## 3. Créer des promotions

API actuelle : `GET /api/promotions` → `[]`

Admin → **Promotions** → créer au moins 1 bannière :
- Image (compressée si > ~1 Mo)
- Titre
- Active = oui
- URL cible optionnelle

---

## 4. Créer du contenu Featured / portfolio home

API actuelle : `GET /api/featured-content` → `[]`  
(L’app affiche déjà un fallback local si vide.)

Admin → **Featured / Contenu mis en avant** → créer ≥ 1 entrée active (image + titre + priorité).

---

## 5. Vérifier Contact-info

Endpoint public OK aujourd’hui : `GET /api/public/contact-info` → 200  
(adresse Kodjoviakopé, tél. +228…, `infos@photopicon.com`)

Admin → **Contact** : vérifier / corriger si besoin (WhatsApp, Facebook, horaires).  
L’app a un **fallback local** si l’API échoue (404/réseau).

---

## 6. Play Store (état)

| Élément | État |
|--------|------|
| `pubspec` | `1.0.0+4` |
| AAB local | `photo_app/build/app/outputs/bundle/release/app-release.aab` (~54 Mo, 01/08/2026) |
| Privacy temporaire | Gist Markdown (voir `PLAYSTORE_DEPLOIEMENT.md`) |
| Privacy prod après redeploy | `https://api.photopicon.com/privacy` (viser 200) |

Si nouvel AAB requis : `flutter build appbundle --release` (bump `versionCode` si déjà uploadé en +4).

---

## Ordre recommandé (résumé ultra-court)

1. Copier JAR + `3_mettre_a_jour_service.bat` sur le serveur  
2. Copier `uploads_restore` → `F:\uploads\` (2 fichiers)  
3. Re-upload admin des 8 dimensions restantes  
4. Créer ≥ 1 promotion + ≥ 1 featured  
5. Vérifier contact-info + `/privacy` 200 + ZIP admin  
6. Play Console : AAB + privacy URL  
