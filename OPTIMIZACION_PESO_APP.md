# Optimización del Peso de la Aplicación

## 🎯 Problema Identificado

La app ha aumentado significativamente de peso debido a:
1. **PaddleOCR**: Librerías nativas (~50-80 MB)
2. **ML Kit**: Modelos de visión (~20-30 MB)
3. **Assets**: Imágenes y recursos (~10-15 MB)

## 📊 Análisis de Peso Actual

### Librerías Pesadas Identificadas

#### 1. PaddleOCR (android/paddle_lite/)
```
android/paddle_lite/
├── inference_lite_lib.android.armv7.gcc.c++_shared.with_cv/ (~40 MB)
├── inference_lite_lib.android.armv8.gcc.c++_shared.with_cv/ (~40 MB)
├── arm64.tar.gz
└── armv7.tar.gz
```

**Peso estimado**: 80-100 MB

#### 2. ML Kit (Google)
- Modelos de texto recognition
- Modelos de face detection
- Librerías nativas

**Peso estimado**: 20-30 MB

#### 3. Assets
- Imágenes sin optimizar
- Rive animations
- Fonts múltiples

**Peso estimado**: 10-15 MB

**PESO TOTAL ESTIMADO**: 110-145 MB

## 🚀 Estrategias de Optimización

### Estrategia 1: Carga Lazy de Servicios OCR ⭐ RECOMENDADO

#### Implementación

**Paso 1: Crear un gestor de servicios lazy**

```dart
// lib/core/services/lazy_service_manager.dart
class LazyServiceManager {
  static final LazyServiceManager _instance = LazyServiceManager._internal();
  factory LazyServiceManager() => _instance;
  LazyServiceManager._internal();

  // Servicios pesados que se cargan bajo demanda
  ServicioOcrIaAvanzado? _ocrService;
  ServicioOcrInteligente? _ocrInteligente;
  
  bool _isOcrLoaded = false;
  bool _isLoading = false;

  /// Carga el servicio OCR solo cuando se necesita
  Future<ServicioOcrIaAvanzado> getOcrService() async {
    if (_ocrService != null) return _ocrService!;
    
    if (_isLoading) {
      // Esperar a que termine la carga actual
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _ocrService!;
    }

    _isLoading = true;
    try {
      _ocrService = ServicioOcrIaAvanzado();
      await _ocrService!.initialize();
      _isOcrLoaded = true;
      return _ocrService!;
    } finally {
      _isLoading = false;
    }
  }

  /// Libera memoria del servicio OCR cuando no se usa
  void disposeOcrService() {
    _ocrService?.dispose();
    _ocrService = null;
    _isOcrLoaded = false;
  }

  /// Verifica si el servicio está cargado
  bool get isOcrLoaded => _isOcrLoaded;
}
```

**Paso 2: Modificar servicios para carga lazy**

```dart
// En pantalla_subida_identidad.dart
Future<void> _iniciarEscaneo() async {
  setState(() => _isLoading = true);
  
  try {
    // Mostrar loader mientras carga el servicio
    final ocrService = await LazyServiceManager().getOcrService();
    
    // Ahora usar el servicio
    final resultado = await ocrService.procesarImagen(imagen);
    
    // Procesar resultado...
  } finally {
    setState(() => _isLoading = false);
  }
}

@override
void dispose() {
  // Liberar servicio cuando se sale de la pantalla
  LazyServiceManager().disposeOcrService();
  super.dispose();
}
```

**Beneficios:**
- ✅ Reduce memoria inicial en ~80 MB
- ✅ Carga solo cuando se usa OCR
- ✅ Libera memoria al salir
- ✅ No afecta funcionalidad

### Estrategia 2: Eliminar PaddleOCR (Usar solo ML Kit) ⭐⭐ MÁS EFECTIVO

#### Análisis

PaddleOCR es el componente más pesado. ML Kit de Google es suficiente para OCR básico.

**Comparación:**

| Característica | PaddleOCR | ML Kit |
|----------------|-----------|--------|
| Peso | ~80 MB | ~20 MB |
| Precisión | 95% | 90% |
| Velocidad | Rápido | Muy rápido |
| Offline | Sí | Sí |
| Mantenimiento | Manual | Google |

#### Implementación

**Paso 1: Remover dependencias de PaddleOCR**

```yaml
# pubspec.yaml
dependencies:
  # REMOVER:
  # paddle_ocr: ^x.x.x
  
  # MANTENER:
  google_mlkit_text_recognition: ^0.13.1
  google_mlkit_face_detection: ^0.11.1
```

**Paso 2: Eliminar carpetas pesadas**

```bash
# Eliminar librerías nativas de PaddleOCR
rm -rf android/paddle_lite/
rm -rf android/cxx/
rm -rf android/java/
```

**Paso 3: Actualizar servicios OCR**

```dart
// Usar solo ML Kit
class ServicioOcrOptimizado {
  final textRecognizer = TextRecognizer();
  
  Future<Map<String, String>> extraerTextoCI(File imagen) async {
    final inputImage = InputImage.fromFile(imagen);
    final recognizedText = await textRecognizer.processImage(inputImage);
    
    // Procesar texto con regex mejorados
    return _extraerDatosCI(recognizedText.text);
  }
}
```

**Beneficios:**
- ✅ Reduce APK en ~80 MB
- ✅ Más rápido de compilar
- ✅ Mantenimiento por Google
- ✅ Suficiente para CI boliviano

### Estrategia 3: Optimizar Assets

#### Imágenes

**Antes:**
```yaml
assets:
  - assets/images/  # Todas las imágenes
```

**Después:**
```yaml
assets:
  # Solo imágenes necesarias
  - assets/images/logoposgrado.png
  - assets/images/ceub.png
  - assets/images/19.png
  - assets/images/mascot.png
  # Remover imágenes no usadas
```

#### Optimización de Imágenes

```bash
# Comprimir imágenes PNG
pngquant --quality=65-80 assets/images/*.png

# Convertir JPG a WebP (más ligero)
cwebp -q 80 assets/images/*.jpg -o assets/images/*.webp
```

**Ahorro estimado**: 5-8 MB

### Estrategia 4: App Bundles (Android)

#### Configuración

```gradle
// android/app/build.gradle.kts
android {
    bundle {
        language {
            enableSplit = true
        }
        density {
            enableSplit = true
        }
        abi {
            enableSplit = true
        }
    }
}
```

**Beneficios:**
- ✅ Google Play entrega solo recursos necesarios
- ✅ Reduce descarga en ~30-40%
- ✅ Usuario descarga solo su arquitectura (arm64 o armv7)

### Estrategia 5: Descarga de Modelos Bajo Demanda

#### Implementación

```dart
class ModelDownloadManager {
  static const String MODEL_URL = 'https://tu-servidor.com/models/';
  
  Future<bool> isModelDownloaded(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelName');
    return file.existsSync();
  }
  
  Future<void> downloadModel(String modelName, {
    Function(double)? onProgress,
  }) async {
    if (await isModelDownloaded(modelName)) return;
    
    final dir = await getApplicationDocumentsDirectory();
    final modelPath = '${dir.path}/models/$modelName';
    
    // Descargar modelo
    final response = await Dio().download(
      '$MODEL_URL$modelName',
      modelPath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress?.call(received / total);
        }
      },
    );
  }
  
  Future<void> deleteModel(String modelName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/models/$modelName');
    if (file.existsSync()) {
      await file.delete();
    }
  }
}
```

**Uso:**

```dart
// Primera vez que usa OCR
if (!await ModelDownloadManager().isModelDownloaded('ocr_model.nb')) {
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Descargar Modelo OCR'),
      content: Text('Se descargará el modelo de OCR (50 MB). ¿Continuar?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            await ModelDownloadManager().downloadModel(
              'ocr_model.nb',
              onProgress: (progress) {
                // Mostrar progreso
              },
            );
          },
          child: Text('Descargar'),
        ),
      ],
    ),
  );
}
```

**Beneficios:**
- ✅ APK inicial muy ligero (~20 MB)
- ✅ Usuario descarga solo lo que usa
- ✅ Puede eliminar modelos no usados

## 📋 Plan de Implementación Recomendado

### Fase 1: Optimización Inmediata (1 hora)

1. **Eliminar PaddleOCR** ⭐ Prioridad Alta
   ```bash
   # Remover carpetas pesadas
   rm -rf android/paddle_lite/
   rm -rf android/cxx/
   rm -rf android/java/
   ```

2. **Actualizar pubspec.yaml**
   ```yaml
   # Remover paddle_ocr
   # Mantener solo ML Kit
   ```

3. **Actualizar servicios OCR**
   - Usar solo ML Kit
   - Eliminar referencias a PaddleOCR

**Ahorro**: ~80 MB

### Fase 2: Optimización de Assets (30 min)

1. **Comprimir imágenes**
   ```bash
   pngquant --quality=65-80 assets/images/*.png
   ```

2. **Remover assets no usados**
   - Revisar qué imágenes se usan realmente
   - Eliminar las no referenciadas

**Ahorro**: ~5-8 MB

### Fase 3: App Bundles (15 min)

1. **Configurar build.gradle**
   - Habilitar splits por ABI
   - Habilitar splits por densidad

**Ahorro**: ~30-40% en descarga

### Fase 4: Carga Lazy (2 horas) - Opcional

1. **Implementar LazyServiceManager**
2. **Modificar pantallas que usan OCR**
3. **Agregar loaders de carga**

**Ahorro**: ~80 MB en memoria inicial

## 📊 Resultados Esperados

### Antes de Optimización
- **APK Size**: ~150 MB
- **Memoria inicial**: ~120 MB
- **Tiempo de inicio**: ~3-4 segundos

### Después de Optimización (Fase 1-3)
- **APK Size**: ~60 MB (-60%)
- **Memoria inicial**: ~40 MB (-67%)
- **Tiempo de inicio**: ~1-2 segundos (-50%)

### Con App Bundle
- **Descarga usuario**: ~40 MB (-73%)
- **Instalación**: ~60 MB

## 🔧 Comandos Útiles

### Analizar tamaño del APK
```bash
# Generar APK de release
flutter build apk --release --analyze-size

# Ver desglose de tamaño
flutter build apk --release --target-platform android-arm64 --analyze-size
```

### Generar App Bundle
```bash
flutter build appbundle --release
```

### Analizar dependencias pesadas
```bash
flutter pub deps --style=compact | grep -E "MB|KB"
```

## ⚠️ Consideraciones

### Si Eliminas PaddleOCR

**Pros:**
- ✅ Reduce 80 MB
- ✅ Más fácil de mantener
- ✅ ML Kit es suficiente

**Contras:**
- ❌ Precisión ligeramente menor (90% vs 95%)
- ❌ Menos control sobre el modelo

**Recomendación**: Eliminar PaddleOCR y usar solo ML Kit. La diferencia de precisión es mínima para CI boliviano.

### Si Usas Descarga Bajo Demanda

**Pros:**
- ✅ APK muy ligero
- ✅ Usuario controla qué descarga

**Contras:**
- ❌ Requiere conexión primera vez
- ❌ Más complejo de implementar
- ❌ Necesitas servidor para modelos

**Recomendación**: Solo si el APK sigue siendo muy pesado después de Fase 1-3.

## 🎯 Recomendación Final

**Implementar Fase 1-3 AHORA:**

1. ✅ Eliminar PaddleOCR (usar solo ML Kit)
2. ✅ Optimizar imágenes
3. ✅ Configurar App Bundles

**Resultado esperado:**
- APK: 150 MB → 60 MB (-60%)
- Descarga: 150 MB → 40 MB (-73%)
- Memoria: 120 MB → 40 MB (-67%)

**Tiempo de implementación**: 2 horas

**Impacto en funcionalidad**: Mínimo (ML Kit es suficiente)

---

**¿Quieres que implemente la Fase 1 ahora?** (Eliminar PaddleOCR y usar solo ML Kit)
