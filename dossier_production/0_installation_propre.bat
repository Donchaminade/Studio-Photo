@echo off
cd /d "%~dp0"
color 0C
echo ==============================================
echo REINSTALLATION PROPRE - Backend Studio Photo
echo ==============================================
echo.
echo Lancez ce fichier EN TANT QU'ADMINISTRATEUR.
echo Dossier actuel : %CD%
echo.
pause

echo [1/6] Arret du service (si installe depuis ce dossier)...
if exist "photo-backend-service.exe" (
    photo-backend-service.exe stop 2>nul
    timeout /t 5 /nobreak >nul
    photo-backend-service.exe uninstall 2>nul
)

echo [2/6] Arret des processus Java sur le port 8081...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8081 ^| findstr LISTENING') do (
    echo   - Arret PID %%a
    taskkill /PID %%a /F 2>nul
)

echo [3/6] Creation du dossier photos F:\uploads ...
if not exist "F:\uploads" mkdir "F:\uploads"

echo [4/6] Verification Java...
java -version
if errorlevel 1 (
    echo ERREUR : Java 17+ requis. Installez-le puis relancez ce script.
    pause
    exit /b 1
)

echo [5/6] Installation du service Windows...
photo-backend-service.exe install

echo [6/6] Demarrage + pare-feu 8081...
photo-backend-service.exe start
netsh advfirewall firewall add rule name="API Backend Photo 8081" dir=in action=allow protocol=TCP localport=8081 2>nul

echo.
echo Attente demarrage (25 s)...
timeout /t 25 /nobreak >nul
curl -s http://localhost:8081/actuator/health
echo.

echo ==============================================
echo Termine. Verifiez la ligne ci-dessus : status UP
echo Logs : photo-backend-service.out.log / .err.log
echo ==============================================
pause
