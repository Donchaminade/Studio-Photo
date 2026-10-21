# Redéploiement backend prod (Windows)

Machine cible : serveur WinSW (~`192.168.1.110`), dossier de service = ce dossier `dossier_production/`.

## Depuis le PC de développement

1. Rebuild :
   ```powershell
   cd "C:\Users\chami\Desktop\FLUTTER PROJECTS\Studio-Photo\photo_app_backend"
   mvn clean package -DskipTests
   ```
2. Copier le JAR :
   ```powershell
   Copy-Item -Force `
     ".\target\photo-app-backend-0.0.1-SNAPSHOT.jar" `
     "..\dossier_production\photo-app-backend-0.0.1-SNAPSHOT.jar"
   ```
3. Transférer `dossier_production\photo-app-backend-0.0.1-SNAPSHOT.jar` vers le serveur
   (USB, partage réseau, RDP, etc.) dans le dossier du service WinSW.

## Sur le serveur Windows (Administrateur)

Dans le dossier du service (là où se trouvent `photo-backend-service.exe` et le JAR) :

```bat
REM Option A — script prévu
3_mettre_a_jour_service.bat

REM Option B — manuel
photo-backend-service.exe stop
timeout /t 5
REM (copier le nouveau JAR ici si pas déjà fait)
photo-backend-service.exe start
timeout /t 15
curl http://localhost:8081/actuator/health
```

Après démarrage, `AdminUserInitializer` crée/réinitialise :
- **Admin tests** : `admin@photopicon.com` / `AdminTest2026!`

## Vérifications API (depuis n’importe où)

```powershell
# Santé / contenu
Invoke-WebRequest https://api.photopicon.com/api/promotions

# Auth admin
Invoke-RestMethod -Method POST -Uri https://api.photopicon.com/api/auth/authenticate `
  -ContentType application/json `
  -Body '{"email":"admin@photopicon.com","password":"AdminTest2026!"}'

# Auth client Google Play
Invoke-RestMethod -Method POST -Uri https://api.photopicon.com/api/auth/authenticate `
  -ContentType application/json `
  -Body '{"email":"playtester@photopicon.com","password":"PlayTest2026!"}'
```

## Panel admin web

`https://api.photopicon.com/admin/login` (ou `http://192.168.1.110:8081/admin/login`)

## Fix ZIP admin + Privacy (à déployer)

Voir aussi **`CHECKLIST_ADMIN_PROD.md`** (actions admin + restauration images).

Le JAR local `dossier_production/photo-app-backend-0.0.1-SNAPSHOT.jar` inclut :
- ZIP admin via fichiers locaux (`F:/uploads`)
- Page `/privacy` (Play Store) — **après** redeploy : plus de 302 login

### Vérifier après redéploiement

1. `curl.exe -sI https://api.photopicon.com/privacy` → **HTTP 200**
2. Admin → commande → **Télécharger ZIP** → `.zip` HTTP 200 (ou 422 si fichiers absents)
3. Logs : `fichier manquant` / `ZIP genere avec N photo(s)`
