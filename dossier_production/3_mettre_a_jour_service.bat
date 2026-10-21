@echo off
cd /d "%~dp0"
color 0E
echo ==============================================
echo Mise a jour du Backend Studio Photo (WinSW)
echo ==============================================
echo.
echo IMPORTANT : Lancez en Administrateur si le service est installe.
echo.

echo 1. Arret du service...
photo-backend-service.exe stop
timeout /t 5 /nobreak >nul

echo 2. Sauvegarde de l ancien JAR (si present)...
if exist "photo-app-backend-0.0.1-SNAPSHOT.jar" (
    if not exist "backup" mkdir "backup"
    copy /Y "photo-app-backend-0.0.1-SNAPSHOT.jar" "backup\photo-app-backend-%date:~-4%%date:~3,2%%date:~0,2%-%time:~0,2%%time:~3,2%.jar" >nul
)

echo 3. Le nouveau JAR doit deja etre dans ce dossier
echo    (copie depuis votre PC de dev : dossier_production\)
echo.

echo 4. Demarrage du service...
photo-backend-service.exe start

echo.
echo 5. Verification (attente 15 s)...
timeout /t 15 /nobreak >nul
curl -s -o nul -w "HTTP %%{http_code}\n" http://localhost:8081/actuator/health

echo.
echo Consultez photo-backend-service.out.log en cas de probleme.
echo ==============================================
pause
