import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_background_remover/image_background_remover.dart';

/// Servicio para remover el fondo de imágenes automáticamente usando ONNX ML
/// Funciona completamente offline sin APIs externas
class ServicioRemoverFondo {
  static bool _isInitialized = false;

  /// Inicializa el modelo ONNX (llamar una vez al inicio de la app)
  static Future<void> inicializar() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 Inicializando modelo ONNX para remoción de fondo...');
      await BackgroundRemover.instance.initializeOrt();
      _isInitialized = true;
      debugPrint('✅ Modelo ONNX inicializado correctamente');
    } catch (e) {
      debugPrint('❌ Error inicializando modelo ONNX: $e');
      rethrow;
    }
  }

  /// Libera recursos del modelo ONNX (llamar al cerrar la app)
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      await BackgroundRemover.instance.dispose();
      _isInitialized = false;
      debugPrint('✅ Recursos ONNX liberados');
    } catch (e) {
      debugPrint('⚠️ Error liberando recursos ONNX: $e');
    }
  }

  /// Remueve el fondo de una imagen y aplica fondo gris claro institucional
  ///
  /// [imagePath] - Ruta de la imagen original
  /// [outputPath] - Ruta donde guardar la imagen procesada
  /// [bgColor] - Color de fondo a aplicar (por defecto gris claro #E0E0E0)
  /// [threshold] - Umbral de confianza (0.0-1.0). Valores más bajos = más conservador
  ///
  /// Returns: true si fue exitoso, false si falló
  static Future<bool> removerFondo({
    required String imagePath,
    required String outputPath,
    ui.Color bgColor = const ui.Color(0xFFE0E0E0), // Gris claro institucional
    double threshold =
        0.20, // Umbral optimizado para un recorte más limpio de hombros
  }) async {
    try {
      // Asegurar que el modelo está inicializado
      if (!_isInitialized) {
        await inicializar();
      }

      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('❌ Imagen no existe: $imagePath');
        return false;
      }

      debugPrint('🔄 Removiendo fondo con ONNX ML (threshold: $threshold)...');

      // Leer imagen
      final imageBytes = await imageFile.readAsBytes();

      // Remover fondo usando ONNX con umbral más conservador
      final ui.Image
      transparentImage = await BackgroundRemover.instance.removeBg(
        imageBytes,
        threshold:
            threshold, // Umbral más bajo = preserva más detalles (cabello, ropa)
        smoothMask: true, // Suavizar bordes para transiciones naturales
        enhanceEdges: true, // Mejorar detección de bordes finos (cabello)
      );

      // Convertir ui.Image a bytes
      final byteData = await transparentImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        debugPrint('❌ Error convirtiendo imagen');
        return false;
      }

      final transparentBytes = byteData.buffer.asUint8List();

      // Post-procesamiento: refinar bordes para preservar detalles finos
      final refinedBytes = await _refinarBordes(transparentBytes);

      // Aplicar fondo de color usando el método del paquete
      final withBackgroundBytes = await BackgroundRemover.instance
          .addBackground(image: refinedBytes, bgColor: bgColor);

      // Guardar imagen procesada
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(withBackgroundBytes);

      debugPrint('✅ Fondo removido y aplicado exitosamente: $outputPath');
      return true;
    } catch (e) {
      debugPrint('❌ Error removiendo fondo: $e');
      return false;
    }
  }

  /// Refina los bordes de la imagen para preservar detalles finos como cabello
  static Future<Uint8List> _refinarBordes(Uint8List imageBytes) async {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;

      // Aplicar filtro de nitidez en lugar de desenfoque total
      // Esto ayuda a que los bordes del recorte se vean más definidos
      final refined = img.adjustColor(image, saturation: 1.05, contrast: 1.02);
      
      // Solo un desenfoque mínimo para antialiasing de bordes si el paquete no lo hizo perfecto
      final smoothed = img.gaussianBlur(refined, radius: 1);

      return Uint8List.fromList(img.encodePng(smoothed));
    } catch (e) {
      debugPrint('⚠️ Error refinando bordes, usando imagen original: $e');
      return imageBytes;
    }
  }

  /// Procesa foto de perfil completa: remueve fondo, aplica gris claro, y optimiza
  ///
  /// [imageBytes] - Bytes de la imagen original
  /// [targetSize] - Tamaño objetivo en píxeles (cuadrado)
  /// [bgColor] - Color de fondo a aplicar
  /// [threshold] - Umbral de confianza (0.0-1.0). Valores más bajos = más conservador
  ///
  /// Returns: Bytes de la imagen procesada o null si falla
  static Future<Uint8List?> procesarFotoPerfil({
    required Uint8List imageBytes,
    int targetSize = 800, // Aumentado de 600 a 800 para mejor calidad
    ui.Color bgColor = const ui.Color(0xFFE0E0E0),
    double threshold =
        0.20, // Umbral optimizado para preservación de detalles y recorte limpio
  }) async {
    try {
      // Asegurar que el modelo está inicializado
      if (!_isInitialized) {
        await inicializar();
      }

      debugPrint(
        '🔄 Procesando foto de perfil con ONNX ML (threshold: $threshold)...',
      );

      // Remover fondo con umbral conservador
      final ui.Image transparentImage = await BackgroundRemover.instance
          .removeBg(
            imageBytes,
            threshold:
                threshold, // Umbral más bajo para preservar cabello y ropa
            smoothMask: true, // Suavizar bordes
            enhanceEdges: true, // Mejorar detección de bordes finos
          );

      // Convertir a bytes PNG
      final byteData = await transparentImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      final transparentBytes = byteData.buffer.asUint8List();

      // Post-procesamiento: refinar bordes
      final refinedBytes = await _refinarBordes(transparentBytes);

      // Aplicar fondo de color
      final withBackgroundBytes = await BackgroundRemover.instance
          .addBackground(image: refinedBytes, bgColor: bgColor);

      // Redimensionar y optimizar con mejor calidad
      final image = img.decodeImage(withBackgroundBytes);
      if (image == null) return withBackgroundBytes;

      final resized = img.copyResize(
        image,
        width: targetSize,
        height: targetSize,
        interpolation: img.Interpolation.cubic, // Mejor interpolación
      );

      // Comprimir como JPEG con calidad 90% (aumentado de 85%)
      final optimized = img.encodeJpg(resized, quality: 90);

      debugPrint(
        '✅ Foto de perfil procesada exitosamente (${optimized.length} bytes)',
      );
      return Uint8List.fromList(optimized);
    } catch (e) {
      debugPrint('❌ Error procesando foto de perfil: $e');
      return null;
    }
  }

  /// Aplica fondo gris claro directamente a bytes de imagen
  /// Útil para procesar en memoria sin guardar archivo
  ///
  /// [imageBytes] - Bytes de la imagen original
  /// [bgColor] - Color de fondo a aplicar
  /// [threshold] - Umbral de confianza (0.0-1.0). Valores más bajos = más conservador
  ///
  /// Returns: Bytes de la imagen con fondo o null si falla
  static Future<Uint8List?> aplicarFondoGrisABytes(
    Uint8List imageBytes, {
    ui.Color bgColor = const ui.Color(0xFFE0E0E0),
    double threshold = 0.15, // Aún más conservador para preservar detalles
  }) async {
    try {
      // Asegurar que el modelo está inicializado
      if (!_isInitialized) {
        await inicializar();
      }

      // Remover fondo con umbral conservador
      final ui.Image transparentImage = await BackgroundRemover.instance
          .removeBg(
            imageBytes,
            threshold:
                threshold, // Umbral más bajo para preservar cabello y ropa
            smoothMask: true, // Suavizar bordes
            enhanceEdges: true, // Mejorar detección de bordes finos
          );

      // Convertir a bytes
      final byteData = await transparentImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      final transparentBytes = byteData.buffer.asUint8List();

      // Post-procesamiento: refinar bordes
      final refinedBytes = await _refinarBordes(transparentBytes);

      // Aplicar fondo
      return await BackgroundRemover.instance.addBackground(
        image: refinedBytes,
        bgColor: bgColor,
      );
    } catch (e) {
      debugPrint('❌ Error aplicando fondo: $e');
      return null;
    }
  }

  /// Verifica si el modelo ONNX está inicializado
  static bool get estaInicializado => _isInitialized;
}
