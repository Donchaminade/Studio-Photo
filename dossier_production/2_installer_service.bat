@echo off
cd /d "%~dp0"
color 0B
echo ==============================================
echo Installation du service Backend Studio Photo
echo ==============================================
echo.
echo IMPORTANT : Ce fichier doit etre lance en tant qu'Administrateur !
pause

echo 1. Creation du dossier uploads (F:\uploads)...
if not exist "F:\uploads" mkdir "F:\uploads"

echo 2. Installation du service...
photo-backend-service.exe install

echo 3. Demarrage du service...
photo-backend-service.exe start

echo 4. Ouverture du port 8081 dans le pare-feu...
netsh advfirewall firewall add rule name="API Backend Photo 8081" dir=in action=allow protocol=TCP localport=8081

echo.
echo ==============================================
echo SUCCES ! Le service a ete installe et demarre !
echo ==============================================
pause
