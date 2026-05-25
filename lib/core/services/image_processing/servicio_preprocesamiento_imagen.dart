import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Servicio de preprocesamiento de imágenes para mejorar OCR
/// Aplica filtros y optimizaciones antes de pasar al OCR
class ServicioPreprocesamientoImagen {

  /// Procesa imagen antes de pasar al OCR
  /// Retorna ruta de imagen optimizada
  static Future<String?> procesarParaOCR(File imagenOriginal) async {
    try {
      debugPrint('🖼️ Iniciando preprocesamiento de imagen...');

      final bytes = await imagenOriginal.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        debugPrint('❌ No se pudo decodificar la imagen');
        return imagenOriginal.path;
      }

      img.Image procesada = decoded;

      // 1. Redimensionar si es demasiado grande (óptimo: 2000-2500px)
      if (procesada.width > 2500 || procesada.height > 2500) {
        final scale = 2500 / (procesada.width > procesada.height 
            ? procesada.width 
            : procesada.height);
        procesada = img.copyResize(
          procesada,
          width: (procesada.width * scale).round(),
          height: (procesada.height * scale).round(),
          interpolation: img.Interpolation.cubic,
        );
        debugPrint('📐 Redimensionada a ${procesada.width}x${procesada.height}');
      }

      // 2. Mejorar nitidez con filtro de enfoque simple
      // Aplicar múltiples pasadas de ajuste de contraste local
      for (int i = 0; i < 2; i++) {
        procesada = img.adjustColor(
          procesada,
          contrast: 1.05,
        );
      }
      debugPrint('✨ Nitidez mejorada');

      // 3. Ajustar contraste para mejor separación texto/fondo
      procesada = img.adjustColor(
        procesada,
        contrast: 1.15, // Aumentar contraste ligeramente
        brightness: 1.05, // Ligero aumento de brillo
        saturation: 0.95, // Reducir saturación (texto es B/N)
      );
      debugPrint('🎨 Contraste y brillo ajustados');

      // 4. Aplicar ecualización de histograma para mejor distribución de tonos
      procesada = _equalizeHistogram(procesada);
      debugPrint('📊 Histograma ecualizado');

      // 5. Convertir a JPEG con calidad óptima para OCR
      final procesadaBytes = img.encodeJpg(
        procesada,
        quality: 95, // Alta calidad para OCR
      );

      // Guardar en cache
      final tempDir = Directory.systemTemp;
      final outputPath = '${tempDir.path}/ocr_preprocessed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(procesadaBytes);

      debugPrint('✅ Imagen preprocesada guardada: $outputPath');
      return outputPath;

    } catch (e) {
      debugPrint('⚠️ Error en preprocesamiento: $e');
      // Retornar imagen original si falla el preprocesamiento
      return imagenOriginal.path;
    }
  }

  /// Ecualiza histograma para mejorar distribución de tonos
  static img.Image _equalizeHistogram(img.Image image) {
    try {
      // Convertir a escala de grises para ecualización
      final gray = img.grayscale(image);
      
      // Calcular histograma
      final histogram = List.filled(256, 0);
      for (int y = 0; y < gray.height; y++) {
        for (int x = 0; x < gray.width; x++) {
          final pixel = gray.getPixel(x, y);
          final luminance = pixel.r.toInt(); // Ya está en escala de grises
          histogram[luminance]++;
        }
      }

      // Calcular CDF (Cumulative Distribution Function)
      final cdf = List.filled(256, 0);
      cdf[0] = histogram[0];
      for (int i = 1; i < 256; i++) {
        cdf[i] = cdf[i - 1] + histogram[i];
      }

      // Normalizar CDF
      final totalPixels = image.width * image.height;
      final cdfMin = cdf.where((v) => v > 0).reduce((a, b) => a < b ? a : b);
      final lookupTable = List.filled(256, 0);
      
      for (int i = 0; i < 256; i++) {
        lookupTable[i] = (((cdf[i] - cdfMin) / (totalPixels - cdfMin)) * 255).round().clamp(0, 255);
      }

      // Aplicar ecualización a imagen original
      final result = img.Image(width: image.width, height: image.height);
      
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b).toInt();
          final newLuminance = lookupTable[luminance];
          
          // Aplicar nuevo valor manteniendo color original
          final factor = newLuminance / (luminance > 0 ? luminance : 1);
          result.setPixel(x, y, img.ColorRgb8(
            (pixel.r.toDouble() * factor).round().clamp(0, 255).toInt(),
            (pixel.g.toDouble() * factor).round().clamp(0, 255).toInt(),
            (pixel.b.toDouble() * factor).round().clamp(0, 255).toInt(),
          ));
        }
      }

      return result;
    } catch (e) {
      debugPrint('⚠️ Error en ecualización: $e');
      return image;
    }
  }

  /// Convierte imagen a escala de grises optimizada para OCR
  static Future<Uint8List?> convertirAGris(File imagen) async {
    try {
      final bytes = await imagen.readAsBytes();
      final decoded = img.decodeImage(bytes);
      
      if (decoded == null) return null;

      final gray = img.grayscale(decoded);
      return img.encodeJpg(gray, quality: 90);
    } catch (e) {
      debugPrint('⚠️ Error convirtiendo a gris: $e');
      return null;
    }
  }

  /// Aplica umbral adaptativo para mejor separación texto/fondo
  static Future<Uint8List?> aplicarUmbral(File imagen, {int threshold = 128}) async {
    try {
      final bytes = await imagen.readAsBytes();
      final decoded = img.decodeImage(bytes);
      
      if (decoded == null) return null;

      final gray = img.grayscale(decoded);
      final binary = img.Image(width: gray.width, height: gray.height);

      for (int y = 0; y < gray.height; y++) {
        for (int x = 0; x < gray.width; x++) {
          final pixel = gray.getPixel(x, y);
          final value = pixel.r > threshold ? 255 : 0;
          binary.setPixel(x, y, img.ColorRgb8(value, value, value));
        }
      }

      return img.encodePng(binary);
    } catch (e) {
      debugPrint('⚠️ Error aplicando umbral: $e');
      return null;
    }
  }

  /// Verifica calidad de imagen y sugiere mejoras
  static Map<String, dynamic> evaluarCalidad(File imagen) {
    try {
      final bytes = imagen.readAsBytesSync();
      final decoded = img.decodeImage(bytes);
      
      if (decoded == null) {
        return {'calidad': 0, 'mensaje': 'No se pudo decodificar'};
      }

      // Calcular brillo promedio
      double brilloTotal = 0;
      int pixelCount = 0;
      
      for (int y = 0; y < decoded.height; y++) {
        for (int x = 0; x < decoded.width; x++) {
          final pixel = decoded.getPixel(x, y);
          final luminance = img.getLuminanceRgb(pixel.r, pixel.g, pixel.b);
          brilloTotal += luminance;
          pixelCount++;
        }
      }

      final brilloPromedio = brilloTotal / pixelCount;
      final relacionAspect = decoded.width / decoded.height;

      // Evaluar calidad
      int score = 100;
      List<String> sugerencias = [];

      // Brillo muy bajo (oscura)
      if (brilloPromedio < 80) {
        score -= 20;
        sugerencias.add('Imagen muy oscura, mejorar iluminación');
      }
      
      // Brillo muy alto (sobreexpuesta)
      if (brilloPromedio > 200) {
        score -= 15;
        sugerencias.add('Imagen sobreexpuesta, reducir brillo');
      }

      // Resolución muy baja
      if (decoded.width < 1000 || decoded.height < 1000) {
        score -= 25;
        sugerencias.add('Resolución baja, usar cámara de mayor resolución');
      }

      // Relación de aspecto no esperada para carnet (debería ser ~1.6)
      if (relacionAspect < 1.2 || relacionAspect > 2.0) {
        score -= 10;
        sugerencias.add('Proporción inusual, verificar encuadre del carnet');
      }

      return {
        'calidad': score.clamp(0, 100),
        'brillo': brilloPromedio.round(),
        'resolucion': '${decoded.width}x${decoded.height}',
        'relacionAspect': relacionAspect.toStringAsFixed(2),
        'sugerencias': sugerencias,
      };
    } catch (e) {
      return {'calidad': 0, 'mensaje': 'Error evaluando: $e'};
    }
  }
}
