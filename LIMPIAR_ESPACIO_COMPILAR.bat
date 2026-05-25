@echo off
echo ========================================
echo SCRIPT DE LIMPIEZA PARA COMPILACION
echo Sistema Posgrado UPEA - Version 0.4.1
echo ========================================
echo.

echo [1/5] Cerrando procesos de Gradle y Android Studio...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM studio64.exe 2>nul
timeout /t 3 /nobreak >nul

echo.
echo [2/5] Limpiando cache de Gradle...
if exist "%USERPROFILE%\.gradle\caches" (
    echo Eliminando cache de Gradle...
    rd /s /q "%USERPROFILE%\.gradle\caches" 2>nul
    echo Cache de Gradle eliminado.
) else (
    echo No se encontro cache de Gradle.
)

echo.
echo [3/5] Limpiando proyecto Flutter...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: No se pudo limpiar el proyecto Flutter
    pause
    exit /b 1
)

echo.
echo [4/5] Obteniendo dependencias...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: No se pudieron obtener las dependencias
    pause
    exit /b 1
)

echo.
echo [5/5] Compilando APK Release (Split por ABI)...
echo Esto puede tomar varios minutos...
call flutter build apk --split-per-abi --release
if %errorlevel% neq 0 (
    echo ERROR: La compilacion fallo
    pause
    exit /b 1
)

echo.
echo ========================================
echo COMPILACION EXITOSA!
echo ========================================
echo.
echo APKs generadas en:
echo build\app\outputs\flutter-apk\
echo.
echo - app-arm64-v8a-release.apk (Dispositivos modernos 64-bit)
echo - app-armeabi-v7a-release.apk (Dispositivos antiguos 32-bit)
echo.
echo Version: 0.4.1+5
echo Incluye: Formulario de comprobante de pago habilitado
echo.
pause
