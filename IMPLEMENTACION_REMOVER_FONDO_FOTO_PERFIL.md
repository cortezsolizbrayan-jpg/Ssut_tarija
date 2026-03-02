# Implementación: Remover Fondo Automático en Foto de Perfil

## Fecha
25 de febrero de 2026

## Objetivo

Aplicar automáticamente un fondo gris claro (plomo) a las fotos de perfil de los participantes, recortando el fondo original y dejando solo a la persona.

## Servicio Creado

**Archivo**: `lib/core/services/servicio_remover_fondo.dart`

### Métodos Disponibles

#### 1. `removerFondo()` - Método Principal
```dart
await ServicioRemoverFondo.removerFondo(
  imagePath: '/path/to/original.jpg',
  outputPath: '/path/to/output.png',
  useAPI: false, // true para usar Remove.bg API
);
```

#### 2. `procesarFotoPerfil()` - Procesamiento Completo
```dart
final processedBytes = await ServicioRemoverFondo.procesarFotoPerfil(
  imageBytes: originalImageBytes,
  targetSize: 512, // Tamaño en píxeles
);
```

#### 3. `aplicarFondoGrisABytes()` - Solo Fondo Gris
```dart
final withBackground = await ServicioRemoverFondo.aplicarFondoGrisABytes(
  imageBytes,
);
```

## Opciones de Implementación

### Opción 1: Procesamiento Local (Recomendado para empezar)

**Ventajas:**
- ✅ Gratis
- ✅ Funciona offline
- ✅ Sin límites de uso
- ✅ Privacidad total

**Desventajas:**
- ⚠️ Menos preciso que API
- ⚠️ Puede dejar restos de fondo

**Uso:**
```dart
final success = await ServicioRemoverFondo.removerFondo(
  imagePath: imagePath,
  outputPath: outputPath,
  useAPI: false, // Procesamiento local
);
```

### Opción 2: Remove.bg API (Mejor calidad)

**Ventajas:**
- ✅ Muy preciso
- ✅ Resultados profesionales
- ✅ Detecta personas automáticamente

**Desventajas:**
- ⚠️ Requiere API key
- ⚠️ Plan gratuito: 50 imágenes/mes
- ⚠️ Requiere internet

**Configuración:**

1. **Obtener API Key:**
   - Ir a https://remove.bg/api
   - Crear cuenta gratuita
   - Copiar API key

2. **Configurar en el código:**
   ```dart
   // En servicio_remover_fondo.dart línea 11
   static const String _removeBgApiKey = 'TU_API_KEY_AQUI';
   ```

3. **Usar:**
   ```dart
   final success = await ServicioRemoverFondo.removerFondo(
     imagePath: imagePath,
     outputPath: outputPath,
     useAPI: true, // Usar Remove.bg API
   );
   ```

### Opción 3: Google ML Kit (Futuro)

Para implementar en el futuro si se necesita mejor precisión sin costos:
- Usar `google_mlkit_image_labeling`
- Segmentación de personas
- Requiere más configuración

## Integración en el Flujo de Foto de Perfil

### Ubicación Actual

El servicio de procesamiento de foto de perfil está en:
`lib/core/services/servicio_procesador_imagen_perfil.dart`

### Modificación Sugerida

Agregar el procesamiento de fondo en el método `procesarImagenPerfil()`:

```dart
import 'package:refactor_template/core/services/servicio_remover_fondo.dart';

class ServicioProcesadorImagenPerfil {
  static Future<Map<String, dynamic>> procesarImagenPerfil({
    required File imagenOriginal,
    bool removerFondo = true, // Nuevo parámetro
  }) async {
    try {
      // ... código existente ...
      
      // NUEVO: Remover fondo si está habilitado
      File imagenProcesada = imagenOriginal;
      
      if (removerFondo) {
        final tempDir = await getTemporaryDirectory();
        final outputPath = '${tempDir.path}/profile_no_bg_${DateTime.now().millisecondsSinceEpoch}.png';
        
        final success = await ServicioRemoverFondo.removerFondo(
          imagePath: imagenOriginal.path,
          outputPath: outputPath,
          useAPI: false, // Cambiar a true para usar API
        );
        
        if (success) {
          imagenProcesada = File(outputPath);
          debugPrint('✅ Fondo removido automáticamente');
        } else {
          debugPrint('⚠️ No se pudo remover fondo, usando original');
        }
      }
      
      // Continuar con el procesamiento normal...
      final bytes = await imagenProcesada.readAsBytes();
      
      // ... resto del código ...
    } catch (e) {
      // ... manejo de errores ...
    }
  }
}
```

## Flujo de Usuario

### Antes (Sin Remover Fondo)
1. Usuario toma/selecciona foto
2. Se guarda foto original
3. Se muestra en perfil con fondo original

### Después (Con Remover Fondo)
1. Usuario toma/selecciona foto
2. **Se remueve fondo automáticamente** ✨
3. **Se aplica fondo gris claro (plomo)** ✨
4. Se guarda foto procesada
5. Se muestra en perfil con fondo uniforme

## Configuración Recomendada

### Para Desarrollo/Testing
```dart
// Usar procesamiento local (gratis, rápido)
useAPI: false
```

### Para Producción (Mejor calidad)
```dart
// Usar Remove.bg API con fallback a local
useAPI: true // Intenta API primero, luego local si falla
```

## Dependencias Requeridas

Agregar al `pubspec.yaml` si no están:

```yaml
dependencies:
  image: ^4.0.17  # Para procesamiento de imágenes
  dio: ^5.4.0     # Para llamadas HTTP a API
  path_provider: ^2.1.1  # Para rutas temporales
```

## Ejemplo de Uso Completo

```dart
import 'dart:io';
import 'package:refactor_template/core/services/servicio_remover_fondo.dart';

// En la pantalla de captura de foto de perfil
Future<void> procesarYGuardarFoto(File imagenOriginal) async {
  try {
    // Mostrar loader
    setState(() => _procesando = true);
    
    // Obtener ruta temporal
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.png';
    
    // Remover fondo
    final success = await ServicioRemoverFondo.removerFondo(
      imagePath: imagenOriginal.path,
      outputPath: outputPath,
      useAPI: false, // Cambiar según necesidad
    );
    
    if (success) {
      // Guardar imagen procesada
      final imagenProcesada = File(outputPath);
      await guardarFotoPerfil(imagenProcesada);
      
      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Foto de perfil actualizada con fondo profesional'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Usar imagen original si falla
      await guardarFotoPerfil(imagenOriginal);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Foto guardada (no se pudo procesar fondo)'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error al procesar foto'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    setState(() => _procesando = false);
  }
}
```

## Personalización del Fondo

### Cambiar Color de Fondo

En `servicio_remover_fondo.dart`, modificar:

```dart
// Para fondo blanco
img.fill(result, color: img.ColorRgb8(255, 255, 255));

// Para fondo gris oscuro
img.fill(result, color: img.ColorRgb8(128, 128, 128));

// Para fondo azul institucional
img.fill(result, color: img.ColorRgb8(0, 91, 172)); // #005BAC

// Para fondo gris claro (actual)
img.fill(result, color: img.ColorRgb8(224, 224, 224)); // #E0E0E0
```

### Ajustar Detección de Bordes

Modificar el umbral de brillo en `_aplicarFondoGris()`:

```dart
// Más sensible (remueve más fondo)
if (brightness < 220) { // Era 240

// Menos sensible (mantiene más del original)
if (brightness < 250) { // Era 240
```

## Optimizaciones

### 1. Caché de Imágenes Procesadas
```dart
// Guardar en caché para no reprocesar
final cacheKey = 'profile_${userId}_processed';
await LocalStorageService.saveImage(cacheKey, processedBytes);
```

### 2. Procesamiento en Background
```dart
// Usar compute() para no bloquear UI
final processed = await compute(
  ServicioRemoverFondo.aplicarFondoGrisABytes,
  imageBytes,
);
```

### 3. Compresión Adicional
```dart
// Comprimir después de procesar
final compressed = await FlutterImageCompress.compressWithList(
  processedBytes,
  quality: 85,
);
```

## Testing

### Casos de Prueba

1. **Foto con fondo blanco** ✅
   - Debe remover fondo blanco
   - Aplicar gris claro

2. **Foto con fondo oscuro** ✅
   - Debe detectar persona
   - Aplicar gris claro

3. **Foto con fondo complejo** ⚠️
   - Puede dejar restos (usar API para mejor resultado)

4. **Foto de baja calidad** ⚠️
   - Puede no detectar bien bordes
   - Considerar mejorar calidad primero

## Costos (Remove.bg API)

### Plan Gratuito
- 50 imágenes/mes
- Resolución: Preview (0.25 megapixels)
- Suficiente para testing

### Plan Pagado
- Desde $9/mes por 500 imágenes
- Resolución completa
- Para producción con muchos usuarios

## Recomendación Final

**Para empezar:**
1. Usar procesamiento local (`useAPI: false`)
2. Probar con fotos reales de usuarios
3. Evaluar calidad de resultados

**Si se necesita mejor calidad:**
1. Obtener API key de Remove.bg
2. Configurar en el código
3. Usar con fallback a local

**Alternativa futura:**
- Implementar Google ML Kit para balance entre calidad y costo
- Requiere más desarrollo pero es gratis

## Estado Actual

✅ Servicio creado y listo para usar
⏳ Pendiente: Integrar en flujo de foto de perfil
⏳ Pendiente: Testing con fotos reales
⏳ Pendiente: Decidir entre local vs API

## Próximos Pasos

1. Agregar dependencia `image` al pubspec.yaml
2. Integrar en `servicio_procesador_imagen_perfil.dart`
3. Probar con fotos de prueba
4. Ajustar parámetros según resultados
5. Decidir si usar API o procesamiento local
