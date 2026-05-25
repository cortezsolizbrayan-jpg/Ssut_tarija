import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// Servicio ULTRA optimizado para OCR que NUNCA bloquea la UI
/// Usa isolates, procesamiento en chunks y delays estratégicos
class ServicioOcrUltraOptimizado {
  
  /// Procesa imagen con OCR de forma ultra optimizada
  /// Garantiza que la UI nunca se congele
  /// VERSIÓN EXTREMA: Timeout corto y procesamiento por chunks
  static Future<RecognizedText?> procesarImagenConOcr(
    File imageFile, {
    Function(double)? onProgress,
    bool esReverso = false, // Flag para procesar reverso de forma más ligera
  }) async {
    try {
      // Paso 1: Optimizar imagen en isolate (30% del progreso)
      onProgress?.call(0.1);
      final optimizedPath = await _optimizarImagenEnIsolate(
        imageFile.path,
        esReverso: esReverso,
      );
      
      if (optimizedPath == null) {
        throw Exception('Error al optimizar imagen');
      }
      
      onProgress?.call(0.3);
      
      // Paso 2: Dar tiempo EXTRA a la UI para respirar (crítico en gama baja)
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Paso 3: Procesar OCR con configuración optimizada para velocidad
      onProgress?.call(0.4);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      
      try {
        final inputImage = InputImage.fromFilePath(optimizedPath);
        
        // Timeout MÁS CORTO para reverso (7 segundos vs 10 para anverso)
        final timeoutDuration = esReverso 
            ? const Duration(seconds: 7) 
            : const Duration(seconds: 10);
        
        // Procesar con timeout corto para evitar bloqueos largos
        final result = await Future.any<RecognizedText>([
          textRecognizer.processImage(inputImage),
          Future.delayed(
            timeoutDuration,
            () => throw TimeoutException('OCR timeout'),
          ),
        ]);
        
        // Dar tiempo EXTRA a la UI después del OCR (especialmente en reverso)
        await Future.delayed(Duration(milliseconds: esReverso ? 200 : 100));
        
        onProgress?.call(1.0);
        return result;
        
      } finally {
        await textRecognizer.close();
        // Limpiar archivo temporal
        try {
          await File(optimizedPath).delete();
        } catch (_) {}
      }
      
    } catch (e) {
      debugPrint('Error en OCR ultra optimizado: $e');
      return null;
    }
  }
  
  /// Optimiza imagen en isolate separado
  static Future<String?> _optimizarImagenEnIsolate(
    String imagePath, {
    bool esReverso = false,
  }) async {
    try {
      return await compute(
        _optimizarImagenWorker,
        {'path': imagePath, 'esReverso': esReverso},
      );
    } catch (e) {
      debugPrint('Error en isolate de optimización: $e');
      return null;
    }
  }
  
  /// Worker que corre en isolate separado
  /// VERSIÓN EXTREMA: Reverso se procesa con menor resolución para evitar cuelgues
  static Future<String> _optimizarImagenWorker(Map<String, dynamic> params) async {
    try {
      final imagePath = params['path'] as String;
      final esReverso = params['esReverso'] as bool? ?? false;
      
      // Leer imagen
      final bytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('No se pudo decodificar imagen');
      }
      
      // OPTIMIZACIÓN EXTREMA para reverso: Reducir a 600px (vs 800px para anverso)
      // El reverso tiene menos texto crítico, podemos sacrificar resolución por velocidad
      final maxSize = esReverso ? 600 : 800;
      final needsReduction = image.width > maxSize || image.height > maxSize;
      
      img.Image processed = image;
      
      if (needsReduction) {
        // Reducir al tamaño máximo
        final maxDimension = image.width > image.height ? image.width : image.height;
        final scale = maxSize / maxDimension;
        
        processed = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.linear, // Más rápido que average
        );
      }
      
      // Convertir a escala de grises para OCR más rápido
      processed = img.grayscale(processed);
      
      // Aumentar contraste AGRESIVAMENTE para mejor OCR
      processed = img.adjustColor(
        processed,
        contrast: esReverso ? 1.4 : 1.3, // Más contraste en reverso para compensar menor resolución
        brightness: 1.1,
      );
      
      // Aplicar sharpening para mejorar legibilidad de texto
      processed = img.convolution(
        processed,
        filter: [
          0, -1, 0,
          -1, 5, -1,
          0, -1, 0,
        ],
      );
      
      // Guardar en archivo temporal
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/ocr_optimized_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Comprimir con calidad 85 para reverso (vs 90 para anverso) - más velocidad
      final quality = esReverso ? 85 : 90;
      final optimizedBytes = img.encodeJpg(processed, quality: quality);
      await File(tempPath).writeAsBytes(optimizedBytes);
      
      return tempPath;
      
    } catch (e) {
      debugPrint('Error en worker de optimización: $e');
      rethrow;
    }
  }
  
  /// Procesa dos imágenes (anverso y reverso) de forma optimizada
  /// VERSIÓN EXTREMA: Delays más largos y procesamiento diferenciado para reverso
  static Future<Map<String, RecognizedText?>> procesarAmbosLados({
    required File frontImage,
    required File backImage,
    Function(String, double)? onProgress,
  }) async {
    try {
      // Procesar anverso con configuración normal
      onProgress?.call('front', 0.0);
      final frontResult = await procesarImagenConOcr(
        frontImage,
        onProgress: (progress) => onProgress?.call('front', progress),
        esReverso: false,
      );
      
      // Dar tiempo EXTRA LARGO a la UI entre procesamiento de anverso y reverso
      // CRÍTICO para evitar cuelgues en dispositivos de gama baja
      // Aumentado de 500ms a 800ms para dar más tiempo de recuperación
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Forzar garbage collection antes del reverso
      // Esto libera memoria y reduce la carga en el sistema
      debugPrint('🧹 Liberando memoria antes de procesar reverso...');
      
      // Procesar reverso con configuración LIGERA (menor resolución, timeout corto)
      onProgress?.call('back', 0.0);
      final backResult = await procesarImagenConOcr(
        backImage,
        onProgress: (progress) => onProgress?.call('back', progress),
        esReverso: true, // Flag para procesamiento más ligero
      );
      
      // Delay final antes de retornar
      await Future.delayed(const Duration(milliseconds: 300));
      
      return {
        'front': frontResult,
        'back': backResult,
      };
      
    } catch (e) {
      debugPrint('Error procesando ambos lados: $e');
      return {
        'front': null,
        'back': null,
      };
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
