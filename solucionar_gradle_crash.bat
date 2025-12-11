@echo off
chcp 65001 > nul
color 0C
echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║     🔧 SOLUCIONAR CRASH DE GRADLE                            ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

echo Paso 1: Deteniendo todos los daemons de Gradle...
cd android
call gradlew.bat --stop
cd ..
echo.

echo Paso 2: Limpiando cache de Gradle...
if exist "%USERPROFILE%\.gradle\caches" (
    echo Limpiando cache de Gradle...
    rmdir /s /q "%USERPROFILE%\.gradle\caches" 2>nul
    echo Cache limpiado.
) else (
    echo No se encontró cache de Gradle.
)
echo.

echo Paso 3: Limpiando daemons de Gradle...
if exist "%USERPROFILE%\.gradle\daemon" (
    echo Limpiando daemons...
    rmdir /s /q "%USERPROFILE%\.gradle\daemon" 2>nul
    echo Daemons limpiados.
) else (
    echo No se encontraron daemons.
)
echo.

echo Paso 4: Limpiando proyecto Flutter...
cd /d "%~dp0"
flutter clean
echo.

echo Paso 5: Obteniendo dependencias...
flutter pub get
echo.

echo Paso 6: Limpiando build de Android...
cd android
if exist "build" (
    rmdir /s /q "build" 2>nul
    echo Build limpiado.
)
if exist "app\build" (
    rmdir /s /q "app\build" 2>nul
    echo App build limpiado.
)
cd ..
echo.

echo ═══════════════════════════════════════════════════════════════
echo   ✅ Limpieza completada
echo ═══════════════════════════════════════════════════════════════
echo.
echo Ahora intenta ejecutar nuevamente:
echo   flutter run
echo.
echo Si el problema persiste, verifica que tengas al menos 8GB de RAM
echo disponible y cierra otras aplicaciones pesadas.
echo.
pause

