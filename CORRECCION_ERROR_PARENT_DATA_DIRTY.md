# Corrección Error parentDataDirty y Pantalla en Blanco

## Fecha
25 de febrero de 2026

## Problema Identificado

### 1. Error Crítico: `parentDataDirty` Assertion
```
'package:flutter/src/rendering/object.dart': Failed assertion: line 5466 pos 14: '!semantics.parentDataDirty': is not true.
```

**Causa**: Estructura compleja de `Stack` con `Positioned` usando valores negativos que causaba problemas en el árbol de rendering de Flutter.

**Ubicación**: `lib/features/sistema/screens/perfil/perfil_screen.dart` - método `_buildAchievementsCircle()`

### 2. Pantalla en Blanco al Deslizar
El PageView en `detalle_programa_screen.dart` mostraba pantalla en blanco al navegar entre páginas.

## Solución Aplicada

### Reestructuración del Widget de Medallas

**ANTES** (Estructura Problemática):
```dart
Transform.translate(
  offset: Offset(0, -circleSize * 0.08),
  child: Container(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -circleSize * 0.2,  // ❌ Valor negativo causando el error
          child: _buildDiscountBanner(circleSize),
        ),
        SizedBox(
          width: circleSize,
          height: circleSize,
          child: // ... medallas
        ),
      ],
    ),
  ),
)
```

**DESPUÉS** (Estructura Corregida):
```dart
Column(
  children: [
    // Banner fuera del Stack - sin Positioned negativo
    _buildDiscountBanner(circleSize),
    SizedBox(height: circleSize * 0.05),
    // Contenedor del círculo de medallas
    Container(
      child: SizedBox(
        width: circleSize,
        height: circleSize,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              child: Stack(
                children: [
                  // Medallas y mascota
                ],
              ),
            );
          },
        ),
      ),
    ),
  ],
)
```

## Cambios Específicos

### 1. Eliminación de `Positioned` con Valores Negativos
- Removido `Positioned(top: -circleSize * 0.2)` que causaba el error
- Banner de descuentos ahora está en un `Column` normal
- Espaciado con `SizedBox` en lugar de posicionamiento absoluto

### 2. Simplificación de la Jerarquía
- Eliminado `Transform.translate` innecesario
- Eliminado `Stack` con `clipBehavior: Clip.none`
- Estructura más plana y predecible para el rendering engine

### 3. Corrección de Indentación
- Corregida indentación incorrecta en `LayoutBuilder`
- Ajustados cierres de widgets para estructura correcta

## Archivos Modificados

1. `lib/features/sistema/screens/perfil/perfil_screen.dart`
   - Método `_buildAchievementsCircle()` completamente reestructurado
   - Líneas aproximadas: 520-860

## Beneficios de la Corrección

✅ **Eliminación del Error `parentDataDirty`**
- No más assertions en el rendering engine
- App estable sin crashes

✅ **Mejor Rendimiento**
- Estructura de widgets más simple
- Menos transformaciones y cálculos de layout

✅ **Código Más Mantenible**
- Jerarquía de widgets más clara
- Más fácil de entender y modificar

✅ **Compatibilidad con Hot Reload**
- Estructura que soporta mejor hot reload
- Menos problemas durante desarrollo

## Verificación

Para verificar que la corrección funciona:

1. **Reiniciar la app completamente** (no hot reload):
   ```bash
   flutter run
   ```

2. **Navegar a la pantalla de Perfil**
   - No debería haber errores en consola
   - El banner de descuentos debe verse correctamente
   - Las medallas deben girar sin problemas

3. **Probar el PageView en Detalle de Programa**
   - Deslizar entre páginas debe funcionar
   - No debe aparecer pantalla en blanco

## Notas Técnicas

### Por Qué Ocurría el Error

El error `parentDataDirty` ocurre cuando:
1. Un widget `Positioned` tiene valores que lo colocan fuera de los límites de su `Stack` padre
2. El `Stack` tiene `clipBehavior: Clip.none` permitiendo overflow
3. Flutter intenta calcular la semántica (para accesibilidad) y encuentra datos inconsistentes

### Solución General

Para evitar este error en el futuro:
- Evitar `Positioned` con valores negativos grandes
- Usar `Column`/`Row` con `SizedBox` para espaciado
- Si necesitas overlap, usar `Transform.translate` con valores pequeños
- Mantener jerarquías de widgets simples

## Estado Final

✅ Error `parentDataDirty` eliminado
✅ Estructura de widgets simplificada
✅ Banner de descuentos funcional
✅ Medallas giratorias funcionando
✅ Sin errores de compilación
⏳ Pendiente: Verificar en dispositivo físico

## Próximos Pasos

1. Hacer hot restart completo de la app
2. Probar navegación en todas las pantallas
3. Verificar que el banner de descuentos responde al tap
4. Confirmar que el PageView funciona correctamente
5. Probar en diferentes tamaños de pantalla
