@echo off
echo ========================================
echo Instalando UPEA Posgrado en tu telefono
echo ========================================
echo.

REM Agregar ADB al PATH temporalmente
set PATH=%PATH%;C:\Users\ERICK\AppData\Local\Android\Sdk\platform-tools

REM Verificar que el dispositivo este conectado
echo Verificando dispositivo conectado...
adb devices
echo.

REM Instalar nueva version (reemplazando la anterior si existe)
echo Instalando nueva version...
adb install -r -d build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo.

echo ========================================
echo Instalacion completada!
echo ========================================
pause
