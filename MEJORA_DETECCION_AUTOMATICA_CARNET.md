# 🎯 Mejora: Detección Automática de Carnet con Captura Inteligente

## 📋 Problema Actual

**Comportamiento actual:**
- La cámara toma la foto inmediatamente al abrir
- No detecta si el carnet está en el encuadre
- El usuario no tiene tiempo para posicionar el documento
- Mala experiencia de usuario

**Lo que el usuario quiere:**
- Abrir la cámara y tener tiempo para buscar el carnet
- Que la app detecte automáticamente cuando el carnet está bien posicionado
- Captura automática cuando detecta el documento
- Similar a apps como CamScanner, Adobe Scan, etc.

## 🎯 Solución Propuesta

### Funcionalidad de Detección Automática

**Características:**
1. ✅ **Detección de bordes** del documento en tiempo real
2. ✅ **Overlay visual** mostrando el área de detección
3. ✅ **Feedback visual** cuando detecta el carnet (marco verde)
4. ✅ **Captura automática** después de 1-2 segundos de detección estable
5. ✅ **Botón manual** por si la detección falla

### Flujo de Usuario Mejorado

```
1. Usuario abre cámara
   ↓
2. Ve preview en tiempo real con overlay
   ↓
3. Posiciona el carnet dentro del marco
   ↓
4. App detecta bordes del documento
   ↓
5. Marco cambia a verde (documento detectado)
   ↓
6. Countdown 3...2...1...
   ↓
7. Captura automática
   ↓
8. Muestra preview y confirma
```

## 🔧 Implementación Técnica

### 1. Detección de Bordes con ML Kit

**Usar Google ML Kit Object Detection:**

```dart
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class DetectorCarnetAutomatico {
  final ObjectDetector _objectDetector;
  bool _documentoDetectado = false;
  DateTime? _tiempoDeteccion;
  
  Future<bool> detectarDocumento(CameraImage image) async {
    final inputImage = _convertirACameraImage(image);
    final objetos = await _objectDetector.processImage(inputImage);
    
    // Buscar objeto rectangular (carnet)
    for (final objeto in objetos) {
      if (_esCarnet(objeto)) {
        if (!_documentoDetectado) {
          _documentoDetectado = true;
          _tiempoDeteccion = DateTime.now();
        }
        
        // Si ha estado estable por 2 segundos, capturar
        if (_tiempoDeteccion != null &&
            DateTime.now().difference(_tiempoDeteccion!) > 
            Duration(seconds: 2)) {
          return true; // Listo para capturar
        }
      }
    }
    
    return false;
  }
  
  bool _esCarnet(DetectedObject objeto) {
    final boundingBox = objeto.boundingBox;
    final aspectRatio = boundingBox.width / boundingBox.height;
    
    // Carnet típico: ratio ~1.6 (85.6mm x 53.98mm)
    return aspectRatio > 1.4 && aspectRatio < 1.8 &&
           boundingBox.width > 200; // Tamaño mínimo
  }
}
```

### 2. Pantalla de Cámara con Detección

**Estructura:**

```dart
class CamaraDeteccionAutomatica extends StatefulWidget {
  final bool esFrente;
  
  @override
  State<CamaraDeteccionAutomatica> createState() => 
      _CamaraDeteccionAutomaticaState();
}

class _CamaraDeteccionAutomaticaState 
    extends State<CamaraDeteccionAutomatica> {
  CameraController? _controller;
  DetectorCarnetAutomatico? _detector;
  bool _detectando = false;
  bool _documentoEncontrado = false;
  int _countdown = 0;
  
  @override
  void initState() {
    super.initState();
    _inicializarCamara();
    _detector = DetectorCarnetAutomatico();
  }
  
  Future<void> _inicializarCamara() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    await _controller!.initialize();
    
    // Iniciar stream de detección
    _controller!.startImageStream(_procesarFrame);
    
    setState(() {});
  }
  
  Future<void> _procesarFrame(CameraImage image) async {
    if (_detectando) return;
    
    _detectando = true;
    
    try {
      final debeCapturar = await _detector!.detectarDocumento(image);
      
      if (debeCapturar && !_documentoEncontrado) {
        _documentoEncontrado = true;
        await _iniciarCountdown();
      }
    } finally {
      _detectando = false;
    }
  }
  
  Future<void> _iniciarCountdown() async {
    for (int i = 3; i > 0; i--) {
      setState(() => _countdown = i);
      await Future.delayed(Duration(seconds: 1));
    }
    
    await _capturarFoto();
  }
  
  Future<void> _capturarFoto() async {
    await _controller!.stopImageStream();
    final foto = await _controller!.takePicture();
    
    if (mounted) {
      Navigator.pop(context, foto.path);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Preview de cámara
          CameraPreview(_controller!),
          
          // Overlay con marco de detección
          _buildOverlay(),
          
          // Indicador de detección
          if (_documentoEncontrado)
            _buildCountdown(),
          
          // Botón manual
          _buildBotonManual(),
          
          // Instrucciones
          _buildInstrucciones(),
        ],
      ),
    );
  }
  
  Widget _buildOverlay() {
    return CustomPaint(
      painter: OverlayDeteccionPainter(
        documentoDetectado: _documentoEncontrado,
      ),
      child: Container(),
    );
  }
  
  Widget _buildCountdown() {
    return Center(
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.8),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$_countdown',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBotonManual() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: FloatingActionButton(
          onPressed: _capturarFoto,
          backgroundColor: Color(0xFF005BAC),
          child: Icon(Icons.camera_alt, size: 32),
        ),
      ),
    );
  }
  
  Widget _buildInstrucciones() {
    return Positioned(
      top: 60,
      left: 20,
      right: 20,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _documentoEncontrado
              ? '✓ Documento detectado. Capturando...'
              : 'Coloca el carnet dentro del marco',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
```

### 3. Overlay Visual con Marco

**CustomPainter para el marco:**

```dart
class OverlayDeteccionPainter extends CustomPainter {
  final bool documentoDetectado;
  
  OverlayDeteccionPainter({required this.documentoDetectado});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Oscurecer todo excepto el área del marco
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5);
    
    // Marco para el carnet (ratio 1.6:1)
    final marcoWidth = size.width * 0.85;
    final marcoHeight = marcoWidth / 1.6;
    final marcoLeft = (size.width - marcoWidth) / 2;
    final marcoTop = (size.height - marcoHeight) / 2;
    
    final marcoRect = Rect.fromLTWH(
      marcoLeft,
      marcoTop,
      marcoWidth,
      marcoHeight,
    );
    
    // Dibujar overlay oscuro con recorte
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        marcoRect,
        Radius.circular(16),
      ))
      ..fillType = PathFillType.evenOdd;
    
    canvas.drawPath(path, paint);
    
    // Dibujar marco
    final marcoPaint = Paint()
      ..color = documentoDetectado 
          ? Color(0xFF4CAF50) // Verde si detectado
          : Color(0xFF005BAC) // Azul si no
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(marcoRect, Radius.circular(16)),
      marcoPaint,
    );
    
    // Esquinas decorativas
    _dibujarEsquinas(canvas, marcoRect, marcoPaint);
  }
  
  void _dibujarEsquinas(Canvas canvas, Rect rect, Paint paint) {
    final cornerLength = 30.0;
    
    // Esquina superior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );
    
    // Esquina superior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );
    
    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );
    
    // Esquina inferior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(OverlayDeteccionPainter oldDelegate) {
    return documentoDetectado != oldDelegate.documentoDetectado;
  }
}
```

## 📊 Características de la Mejora

### Detección Inteligente
- ✅ Detecta bordes rectangulares en tiempo real
- ✅ Valida aspect ratio del carnet (1.4-1.8)
- ✅ Requiere tamaño mínimo para evitar falsos positivos
- ✅ Estabilidad de 2 segundos antes de capturar

### Feedback Visual
- ✅ Marco azul cuando busca documento
- ✅ Marco verde cuando detecta documento
- ✅ Countdown 3-2-1 antes de capturar
- ✅ Instrucciones en pantalla
- ✅ Esquinas decorativas estilo profesional

### Experiencia de Usuario
- ✅ Usuario tiene tiempo para posicionar
- ✅ Feedback claro del estado
- ✅ Captura automática cuando está listo
- ✅ Botón manual como respaldo
- ✅ Animaciones suaves

## 🎨 Diseño Visual

### Estados de la Cámara

**1. Buscando Documento:**
```
┌─────────────────────────┐
│  [Instrucciones]        │
│                         │
│    ┌─────────────┐      │
│    │             │      │ ← Marco azul
│    │   CARNET    │      │
│    │             │      │
│    └─────────────┘      │
│                         │
│        ( 📷 )           │ ← Botón manual
└─────────────────────────┘
```

**2. Documento Detectado:**
```
┌─────────────────────────┐
│  ✓ Documento detectado  │
│                         │
│    ┌─────────────┐      │
│    │             │      │ ← Marco verde
│    │   CARNET    │      │
│    │             │      │
│    └─────────────┘      │
│                         │
│         ( 3 )           │ ← Countdown
└─────────────────────────┘
```

## 📋 Dependencias Necesarias

```yaml
dependencies:
  camera: ^0.10.5+5
  google_mlkit_object_detection: ^0.11.0
  path_provider: ^2.1.1
```

## 🚀 Integración con Código Existente

### Reemplazar en pantalla_subida_identidad.dart

**Antes:**
```dart
final path = await Navigator.of(context).push<String>(
  MaterialPageRoute<String>(
    builder: (context) => const MlKitOcrCameraScreen(isFront: true),
  ),
);
```

**Después:**
```dart
final path = await Navigator.of(context).push<String>(
  MaterialPageRoute<String>(
    builder: (context) => CamaraDeteccionAutomatica(esFrente: true),
  ),
);
```

## ⚙️ Configuración de Detección

### Parámetros Ajustables

```dart
class ConfigDeteccion {
  // Tiempo de estabilidad antes de capturar
  static const Duration tiempoEstabilidad = Duration(seconds: 2);
  
  // Aspect ratio del carnet (85.6mm x 53.98mm = 1.586)
  static const double aspectRatioMin = 1.4;
  static const double aspectRatioMax = 1.8;
  
  // Tamaño mínimo del documento en píxeles
  static const double anchoMinimo = 200;
  
  // Confianza mínima de detección (0.0 - 1.0)
  static const double confianzaMinima = 0.7;
  
  // Duración del countdown
  static const int duracionCountdown = 3;
}
```

## 🎯 Beneficios

### Para el Usuario
- ✅ Más tiempo para posicionar el documento
- ✅ Feedback visual claro
- ✅ Captura automática cuando está listo
- ✅ Menos fotos borrosas o mal encuadradas
- ✅ Experiencia profesional

### Para la App
- ✅ Mejor calidad de imágenes capturadas
- ✅ Menos reintentos necesarios
- ✅ Mayor precisión del OCR
- ✅ Menos errores de validación

## 📝 Notas de Implementación

### Optimización de Rendimiento
- Procesar solo 1 de cada 3 frames (30fps → 10fps)
- Usar ResolutionPreset.medium en lugar de high
- Liberar recursos al salir

### Manejo de Errores
- Timeout de 30 segundos si no detecta
- Opción de captura manual siempre disponible
- Mensaje si la cámara no está disponible

### Accesibilidad
- Instrucciones de voz opcionales
- Vibración al detectar documento
- Botón grande para captura manual

---

**Prioridad**: Alta
**Complejidad**: Media
**Tiempo estimado**: 3-4 horas
**Impacto en UX**: Muy Alto ⭐⭐⭐⭐⭐
