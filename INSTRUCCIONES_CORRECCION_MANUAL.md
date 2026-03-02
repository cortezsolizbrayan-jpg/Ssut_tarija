# Instrucciones para Corrección Manual del Error de Sintaxis

## Problema
El archivo `lib/features/sistema/screens/perfil/perfil_screen.dart` tiene errores de sintaxis persistentes en las líneas 848 y 853 que no se pueden resolver automáticamente.

## Errores Reportados
```
error - Expected to find ']' - lib\features\sistema\screens\perfil\perfil_screen.dart:848:31
error - Expected to find ')' - lib\features\sistema\screens\perfil\perfil_screen.dart:853:21
```

## Pasos para Corregir Manualmente

### 1. Abre el archivo en tu IDE
Abre `lib/features/sistema/screens/perfil/perfil_screen.dart` en VS Code, Android Studio o tu editor preferido.

### 2. Usa la función de "Bracket Matching"
La mayoría de los IDEs tienen una función para resaltar brackets coincidentes:
- **VS Code**: Coloca el cursor en un bracket y presiona `Ctrl+Shift+\` para saltar al bracket coincidente
- **Android Studio**: Coloca el cursor en un bracket y presiona `Ctrl+Shift+M`

### 3. Verifica el método `_buildAchievementsCircle()`
Este método empieza en la línea 513. Busca específicamente:

#### a) El GestureDetector con Stack (alrededor de línea 645)
```dart
child: Stack(
  children: [
    // Grupo de medallas que gira como ruleta
    Transform.rotate(
      angle: _wheelAngle,
      child: Stack(
        children: [
          // Medallas distribuidas uniformemente en círculo
          ..._buildUniformMedals(circleSize),
        ],  // <-- VERIFICA QUE ESTE ],  ESTÉ AQUÍ
      ),
    ),
    // Etiqueta "Cumplido Diplomado"
    Positioned(
      ...
    ),
    // Mascota en el centro
    Positioned.fill(
      ...
    ),
  ],  // <-- VERIFICA QUE ESTE ],  ESTÉ AQUÍ
),
```

#### b) Cuenta manualmente los brackets
Desde la línea donde dice `child: Stack(` (alrededor de línea 645):
1. Cuenta cuántos `[` hay
2. Cuenta cuántos `]` hay
3. Deben ser iguales

### 4. Verifica el spread operator
Busca la línea que dice:
```dart
..._buildUniformMedals(circleSize),
```

Asegúrate de que:
- Tiene la coma al final
- Está dentro de un array `children: [...]`
- El array se cierra correctamente con `],`

### 5. Usa el formateador del IDE
Una vez que creas haber encontrado el problema:
1. Guarda el archivo
2. Formatea el archivo completo:
   - **VS Code**: `Shift+Alt+F`
   - **Android Studio**: `Ctrl+Alt+L`
3. Si el formateador falla, te dirá exactamente dónde está el problema

### 6. Busca caracteres invisibles
A veces hay caracteres Unicode invisibles que causan problemas:
1. En VS Code, abre la paleta de comandos (`Ctrl+Shift+P`)
2. Busca "Change File Encoding"
3. Asegúrate de que esté en "UTF-8"
4. Busca "Show Whitespace" para ver espacios y tabs

### 7. Compara con una versión anterior
Si tienes Git:
```bash
git diff HEAD~1 lib/features/sistema/screens/perfil/perfil_screen.dart
```

Esto te mostrará qué cambió recientemente y puede ayudarte a identificar dónde se introdujo el error.

## Solución Alternativa: Reemplazar la Sección Problemática

Si no puedes encontrar el error, puedes reemplazar toda la sección del GestureDetector. Busca desde la línea que dice:

```dart
return GestureDetector(
  onPanStart: (details) {
```

Hasta la línea que dice:

```dart
);
```

Y reemplázala con una versión simplificada sin animaciones complejas temporalmente, solo para que compile.

## Después de Corregir

1. Guarda el archivo
2. Ejecuta: `flutter analyze lib/features/sistema/screens/perfil/perfil_screen.dart`
3. Si no hay errores, ejecuta: `flutter run -d d3e8b53c`

## Notas Importantes

- El error está ANTES de la línea 848, no EN la línea 848
- El parser llega a la línea 848 pensando que todavía está dentro de un array no cerrado
- Probablemente es un `],` faltante o un `)` extra en algún lugar entre las líneas 645-820

## Contacto

Si después de seguir estos pasos aún tienes problemas, considera:
1. Crear un nuevo branch en Git
2. Revertir el archivo a una versión anterior que funcionaba
3. Aplicar los cambios gradualmente para identificar qué los rompió
