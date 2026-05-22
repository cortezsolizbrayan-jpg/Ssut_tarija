import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/otros/cancellation_token.dart';

// ── Función top-level para compute() ─────────────────────────────────────────
Uint8List _optimizarImagenIsolate(List<dynamic> args) {
  final bytes = args[0] as Uint8List;
  final maxSize = args[1] as int;

  final image = img.decodeImage(bytes);
  if (image == null || image.width <= 0 || image.height <= 0) return bytes;

  img.Image processed = image;
  if (image.width > maxSize || image.height > maxSize) {
    final scale =
        maxSize / (image.width > image.height ? image.width : image.height);
    final nw = (image.width * scale).round();
    final nh = (image.height * scale).round();
    if (nw > 0 && nh > 0) {
      processed = img.copyResize(image, width: nw, height: nh);
    }
  }

  return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
}

// ─────────────────────────────────────────────────────────────────────────────
/// Usa memoria RAM agresivamente para máxima velocidad.
class ServicioOcrTurboRam {
  // Caché en RAM para imágenes procesadas (evita reprocesar)
  static final Map<String, Uint8List> _cacheImagenesOptimizadas = {};
  static final Map<String, RecognizedText> _cacheResultadosOcr = {};

  // Límite de caché (10 imágenes máximo para no saturar RAM)
  static const int _maxCacheSize = 10;

  // TextRecognizer persistente para evitar recargar modelos TFLite en cada llamada
  static TextRecognizer? _recognizer;
  static TextRecognizer _getRecognizer() {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _recognizer!;
  }

  /// Pre-inicializa el recognizer para cargar modelos TFLite en background.
  static void inicializarRecognizer() {
    _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    debugPrint('🔧 TextRecognizer pre-inicializado');
  }

  /// Libera el recognizer (llamar al cerrar la pantalla de escaneo).
  static void liberarRecognizer() {
    _recognizer?.close();
    _recognizer = null;
    debugPrint('🔧 TextRecognizer liberado');
  }

  /// Limpia el caché de RAM.
  static void limpiarCache() {
    _cacheImagenesOptimizadas.clear();
    _cacheResultadosOcr.clear();
    debugPrint('🧹 Caché de OCR limpiado');
  }

  /// Pre-carga y optimiza una imagen en background antes de que el usuario
  /// confirme el escaneo. Llamar justo después de capturar la foto.
  static Future<void> precargarImagen(
    String imagePath, {
    required bool esReverso,
  }) async {
    try {
      final cacheKey = esReverso ? 'scan_latest_back' : 'scan_latest_front';

      if (_cacheImagenesOptimizadas.containsKey(cacheKey)) {
        return;
      }

      final optimizedBytes = await _optimizarImagenTurbo(
        imagePath,
        esReverso: esReverso,
      );

      if (optimizedBytes != null &&
          _cacheImagenesOptimizadas.length < _maxCacheSize) {
        _cacheImagenesOptimizadas[cacheKey] = optimizedBytes;
        debugPrint('💾 Pre-carga: Imagen guardada en caché RAM');
      }
    } catch (e) {
      debugPrint('Error en pre-carga: $e');
    }
  }

  /// Procesa imagen con OCR TURBO usando RAM agresivamente.
  /// VERSIÓN TURBO: Caché en RAM + procesamiento paralelo.
  static Future<RecognizedText?> procesarImagenTurbo(
    File imageFile, {
    Function(double)? onProgress,
    bool esReverso = false,
    bool usarCache = true,
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      // Clave estática por lado (solo se escanea una identidad a la vez)
      final cacheKey = esReverso ? 'scan_latest_back' : 'scan_latest_front';

      // 1. Verificar caché de resultados OCR (súper rápido)
      if (usarCache && _cacheResultadosOcr.containsKey(cacheKey)) {
        debugPrint('⚡ OCR desde caché RAM: $cacheKey');
        onProgress?.call(1.0);
        return _cacheResultadosOcr[cacheKey];
      }

      onProgress?.call(0.1);
      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      // 2. Optimizar imagen (verificar caché de imagen optimizada)
      Uint8List? optimizedBytes;

      if (usarCache && _cacheImagenesOptimizadas.containsKey(cacheKey)) {
        debugPrint('⚡ Imagen optimizada desde caché RAM');
        optimizedBytes = _cacheImagenesOptimizadas[cacheKey]!;
      } else {
        optimizedBytes = await _optimizarImagenTurbo(
          imageFile.path,
          esReverso: esReverso,
        );

        if (optimizedBytes == null) {
          throw Exception('Error al optimizar imagen');
        }

        if (_cacheImagenesOptimizadas.length < _maxCacheSize) {
          _cacheImagenesOptimizadas[cacheKey] = optimizedBytes;
          debugPrint('💾 Imagen guardada en caché RAM');
        }
      }

      onProgress?.call(0.3);
      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      // 3. Guardar temporalmente en disco (ML Kit requiere archivo)
      final tempPath = await _guardarEnTemporal(optimizedBytes);

      onProgress?.call(0.4);
      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      // 4. Procesar OCR - ceder el event loop para no bloquear UI
      final textRecognizer = _getRecognizer();

      try {
        final inputImage = InputImage.fromFilePath(tempPath);

        await Future<void>.delayed(Duration.zero);

        final timeoutDuration = esReverso
            ? const Duration(seconds: 10)
            : const Duration(seconds: 12);

        final result = await Future.any<RecognizedText>([
          textRecognizer.processImage(inputImage),
          Future<RecognizedText>.delayed(
            timeoutDuration,
            () => throw TimeoutException('OCR timeout'),
          ),
          if (cancellationToken != null)
            cancellationToken.whenCancelled.then<RecognizedText>(
              (_) => throw CancellationException(),
            ),
        ]);

        if (usarCache && _cacheResultadosOcr.length < _maxCacheSize) {
          _cacheResultadosOcr[cacheKey] = result;
          debugPrint('💾 Resultado OCR guardado en caché RAM');
        }

        onProgress?.call(1.0);
        return result;
      } finally {
        // NO cerrar el recognizer — es persistente
        try {
          await File(tempPath).delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Error en OCR Turbo: $e');
      if (e is CancellationException) rethrow;
      return null;
    }
  }

  /// Optimiza imagen en un Isolate — no bloquea el hilo UI.
  static Future<Uint8List?> _optimizarImagenTurbo(
    String imagePath, {
    bool esReverso = false,
  }) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      // Mover el procesamiento pesado al Isolate
      return await compute(_optimizarImagenIsolate, [bytes, 1200]);
    } catch (e) {
      debugPrint('❌ Error en optimización: $e');
      try {
        return await File(imagePath).readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }

  /// Guarda bytes en archivo temporal para ML Kit.
  /// Usa getTemporaryDirectory() — compatible con Android e iOS.
  static Future<String> _guardarEnTemporal(Uint8List bytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/ocr_turbo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(tempPath).writeAsBytes(bytes);
    return tempPath;
  }

  /// Procesa ambos lados SECUENCIALMENTE para no bloquear el hilo principal.
  static Future<Map<String, RecognizedText?>> procesarAmbosLadosTurbo({
    required File frontImage,
    required File backImage,
    Function(String, double)? onProgress,
    bool usarCache = true,
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      debugPrint('🚀 Iniciando OCR secuencial anverso/reverso...');

      onProgress?.call('front', 0.0);
      final frontResult = await procesarImagenTurbo(
        frontImage,
        onProgress: (progress) => onProgress?.call('front', progress),
        esReverso: false,
        usarCache: usarCache,
        cancellationToken: cancellationToken,
      );

      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      // Ceder el hilo principal entre los dos OCR
      await Future<void>.delayed(const Duration(milliseconds: 50));

      onProgress?.call('back', 0.0);
      final backResult = await procesarImagenTurbo(
        backImage,
        onProgress: (progress) => onProgress?.call('back', progress),
        esReverso: true,
        usarCache: usarCache,
        cancellationToken: cancellationToken,
      );

      return {'front': frontResult, 'back': backResult};
    } catch (e) {
      debugPrint('Error procesando ambos lados turbo: $e');
      if (e is CancellationException) rethrow;
      return {'front': null, 'back': null};
    }
  }

  /// Obtiene estadísticas del caché para debugging.
  static Map<String, dynamic> obtenerEstadisticasCache() {
    return {
      'imagenes_en_cache': _cacheImagenesOptimizadas.length,
      'resultados_en_cache': _cacheResultadosOcr.length,
      'memoria_imagenes_mb': _calcularTamanoCache(_cacheImagenesOptimizadas),
      'max_cache_size': _maxCacheSize,
    };
  }

  static double _calcularTamanoCache(Map<String, Uint8List> cache) {
    int totalBytes = 0;
    for (final bytes in cache.values) {
      totalBytes += bytes.length;
    }
    return totalBytes / (1024 * 1024);
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
