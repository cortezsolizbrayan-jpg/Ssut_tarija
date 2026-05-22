import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

// ── Funciones top-level para compute() ───────────────────────────────────────
// Deben estar fuera de la clase para poder ejecutarse en un Isolate.

/// Aplica threshold adaptativo en un Isolate — no bloquea el hilo UI.
Uint8List _thresholdAdaptativoIsolate(List<dynamic> args) {
  final bytes = args[0] as Uint8List;
  final offset = args[1] as int;
  final imagen = img.decodeImage(bytes)!;
  final result = img.Image.from(imagen);
  const ventana = 15;
  final half = ventana ~/ 2;

  for (int y = 0; y < imagen.height; y++) {
    for (int x = 0; x < imagen.width; x++) {
      int suma = 0, contador = 0;
      for (int dy = -half; dy <= half; dy++) {
        for (int dx = -half; dx <= half; dx++) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < imagen.width && ny >= 0 && ny < imagen.height) {
            suma += imagen.getPixel(nx, ny).r.toInt();
            contador++;
          }
        }
      }
      final promedio = suma ~/ contador;
      final valor = imagen.getPixel(x, y).r.toInt();
      if (valor > promedio + offset) {
        result.setPixelRgba(x, y, 255, 255, 255, 255);
      } else {
        result.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  }
  return Uint8List.fromList(img.encodeJpg(result, quality: 95));
}

/// Aplica threshold binario en un Isolate.
Uint8List _thresholdBinarioIsolate(Uint8List bytes) {
  final imagen = img.decodeImage(bytes)!;
  final result = img.Image.from(imagen);
  const umbral = 128;
  for (int y = 0; y < imagen.height; y++) {
    for (int x = 0; x < imagen.width; x++) {
      final v = imagen.getPixel(x, y).r.toInt();
      if (v > umbral) {
        result.setPixelRgba(x, y, 255, 255, 255, 255);
      } else {
        result.setPixelRgba(x, y, 0, 0, 0, 255);
      }
    }
  }
  return Uint8List.fromList(img.encodeJpg(result, quality: 95));
}

// ─────────────────────────────────────────────────────────────────────────────

/// Servicio OCR nativo optimizado usando flutter_native_ocr.
///
/// - iOS: Apple Vision Framework (nativo, alta precisión)
/// - Android: Google ML Kit Text Recognition v2
/// - Procesamiento on-device (sin internet)
/// - Preprocesamiento en Isolate — no bloquea el hilo UI
/// - Optimizado para Carnet de Identidad boliviano
class ServicioOcrOptimizado {
  static final ServicioOcrOptimizado _instance =
      ServicioOcrOptimizado._internal();
  factory ServicioOcrOptimizado() => _instance;
  ServicioOcrOptimizado._internal();

  final FlutterNativeOcr _flutterNativeOcr = FlutterNativeOcr();
  bool _isInitialized = false;

  static const double _umbralCalidadMinima = 0.3;
  static const int _maxReintentos = 3;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    debugPrint('✅ ServicioOcrOptimizado inicializado');
  }

  /// Extrae datos del CI boliviano con preprocesamiento adaptativo.
  Future<Map<String, String>> extraerDatosCI(
    File imagenFile, {
    int reintentos = _maxReintentos,
  }) async {
    if (!_isInitialized) await initialize();

    if (!await imagenFile.exists() || await imagenFile.length() == 0) {
      debugPrint('❌ Archivo inválido: ${imagenFile.path}');
      return {};
    }

    String? ultimoTexto;

    for (int intento = 0; intento < reintentos; intento++) {
      try {
        debugPrint('🔄 OCR intento ${intento + 1}/$reintentos');

        // Preprocesar en Isolate — no bloquea el hilo UI
        final imagenOptimizada = await _preprocesarEnIsolate(
          imagenFile,
          estrategia: intento,
        );

        final texto = await _flutterNativeOcr.recognizeText(
          imagenOptimizada.path,
        );

        try {
          await imagenOptimizada.delete();
        } catch (_) {}

        if (texto.isEmpty) {
          debugPrint('⚠️ Sin texto (intento ${intento + 1})');
          continue;
        }

        debugPrint('✅ Texto OCR: ${texto.length} chars');

        final calidad = _evaluarCalidad(texto);
        debugPrint('📊 Calidad: ${(calidad * 100).toStringAsFixed(1)}%');

        if (calidad < _umbralCalidadMinima && intento < reintentos - 1) {
          ultimoTexto = texto;
          continue;
        }

        final datos = _extraerDatosConRegex(texto);
        if (!_validarDatos(datos) && intento < reintentos - 1) {
          ultimoTexto = texto;
          continue;
        }

        debugPrint('✅ Extracción completada: ${datos.length} campos');
        return datos;
      } catch (e) {
        debugPrint('❌ Error OCR intento ${intento + 1}: $e');
        if (intento == reintentos - 1)
          return _extraerUltimoRecurso(ultimoTexto);
      }
    }

    return _extraerUltimoRecurso(ultimoTexto);
  }

  /// Preprocesa la imagen en un Isolate según la estrategia del intento.
  Future<File> _preprocesarEnIsolate(
    File imagenFile, {
    required int estrategia,
  }) async {
    try {
      var bytes = await imagenFile.readAsBytes();
      var imagen = img.decodeImage(bytes);
      if (imagen == null) return imagenFile;

      // 1. Redimensionar si es muy grande
      if (imagen.width > 1920) {
        final ratio = 1920 / imagen.width;
        imagen = img.copyResize(
          imagen,
          width: 1920,
          height: (imagen.height * ratio).round(),
        );
      }

      // 2. Escala de grises
      imagen = img.grayscale(imagen);

      // 3. Ajuste de contraste/brillo (rápido, en hilo principal)
      final contrastes = [1.3, 1.6, 2.0];
      final brillos = [1.1, 1.15, 1.2];
      imagen = img.adjustColor(
        imagen,
        contrast: contrastes[estrategia.clamp(0, 2)],
        brightness: brillos[estrategia.clamp(0, 2)],
      );

      bytes = Uint8List.fromList(img.encodeJpg(imagen, quality: 95));

      // 4. Threshold en Isolate (operación O(n²) — no bloquea UI)
      Uint8List thresholdBytes;
      if (estrategia == 2) {
        thresholdBytes = await compute(_thresholdBinarioIsolate, bytes);
      } else {
        final offset = estrategia == 0 ? -10 : -15;
        thresholdBytes = await compute(_thresholdAdaptativoIsolate, [
          bytes,
          offset,
        ]);
      }

      // 5. Sharpening (rápido, en hilo principal)
      var imagenFinal = img.decodeImage(thresholdBytes)!;
      final kernels = [
        [0, -1, 0, -1, 9, -1, 0, -1, 0], // suave
        [0, -1, 0, -1, 10, -1, 0, -1, 0], // fuerte
        [-1, -1, -1, -1, 13, -1, -1, -1, -1], // muy fuerte
      ];
      imagenFinal = img.convolution(
        imagenFinal,
        filter: kernels[estrategia.clamp(0, 2)],
        div: [5, 6, 5][estrategia.clamp(0, 2)],
      );

      // Solo aplicar blur en estrategia 0 y 1
      if (estrategia < 2)
        imagenFinal = img.gaussianBlur(imagenFinal, radius: 1);

      // Guardar en directorio temporal correcto (compatible con Android)
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/ocr_pre_${estrategia}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);
      await file.writeAsBytes(img.encodeJpg(imagenFinal, quality: 98));
      return file;
    } catch (e) {
      debugPrint('❌ Error preprocesamiento: $e');
      return imagenFile;
    }
  }

  double _evaluarCalidad(String texto) {
    if (texto.isEmpty) return 0.0;
    final lineas = texto.split(RegExp(r'[\n\r]+'));
    int validos = 0, total = texto.length, longTotal = 0, lineasValidas = 0;

    for (final linea in lineas) {
      final l = linea.trim();
      if (l.isEmpty) continue;
      longTotal += l.length;
      lineasValidas++;
      for (final c in l.runes) {
        if ((c >= 65 && c <= 90) ||
            (c >= 97 && c <= 122) ||
            (c >= 48 && c <= 57) ||
            (c >= 192 && c <= 255) ||
            c == 32 ||
            c == 46 ||
            c == 44 ||
            c == 47 ||
            c == 45 ||
            c == 58) {
          validos++;
        }
      }
    }

    if (lineasValidas == 0) return 0.0;
    final promLong = longTotal / lineasValidas;
    return ((validos / total) * 0.5 +
            (promLong / 20).clamp(0.0, 0.3) +
            (lineasValidas / lineas.length) * 0.2)
        .clamp(0.0, 1.0);
  }

  bool _validarDatos(Map<String, String> datos) {
    if (datos.isEmpty) return false;
    final ci = datos['numeroDocumento'];
    if (ci == null || ci.length < 7 || ci.length > 8) return false;
    if (!RegExp(r'^\d+$').hasMatch(ci)) return false;
    return true;
  }

  Map<String, String> _extraerUltimoRecurso(String? texto) {
    if (texto == null || texto.isEmpty) return {};
    return _extraerDatosConRegex(texto);
  }

  Map<String, String> _extraerDatosConRegex(String texto) {
    final datos = <String, String>{};
    final t = texto
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // CI: 7-8 dígitos
    final mCI = RegExp(r'\b(\d{7,8})\b').firstMatch(t);
    if (mCI != null) datos['numeroDocumento'] = mCI.group(1)!;

    // Nombres
    final mNom = RegExp(
      r'(?:NOMBRES?|NAME)[:\s]*([A-ZÁÉÍÓÚÑ\s]{2,50})',
      caseSensitive: false,
    ).firstMatch(t);
    if (mNom != null) datos['nombres'] = mNom.group(1)!.trim();

    // Apellidos
    final mApe = RegExp(
      r'(?:APELLIDOS?|SURNAME)[:\s]*([A-ZÁÉÍÓÚÑ\s]{2,50})',
      caseSensitive: false,
    ).firstMatch(t);
    if (mApe != null) datos['apellidos'] = mApe.group(1)!.trim();

    // Fecha nacimiento
    final mFec = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b').firstMatch(t);
    if (mFec != null) {
      datos['fechaNacimiento'] =
          '${mFec.group(1)!.padLeft(2, '0')}/${mFec.group(2)!.padLeft(2, '0')}/${mFec.group(3)!}';
    }

    // Departamento de expedición
    const deptos = [
      'LA PAZ',
      'COCHABAMBA',
      'SANTA CRUZ',
      'ORURO',
      'POTOSÍ',
      'POTOSI',
      'CHUQUISACA',
      'TARIJA',
      'BENI',
      'PANDO',
    ];
    final tUp = t.toUpperCase();
    for (final d in deptos) {
      if (tUp.contains(d)) {
        datos['expedido'] = d;
        break;
      }
    }

    debugPrint('📊 Campos extraídos: ${datos.length}');
    return datos;
  }

  Future<void> dispose() async {
    _isInitialized = false;
  }
}
