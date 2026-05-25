import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/image_processing/servicio_remover_fondo.dart';

// ── Parámetros para el Isolate ────────────────────────────────────────────────

class _CropParams {
  final Uint8List bytes;
  final double faceLeft, faceTop, faceWidth, faceHeight;
  final int imageWidth, imageHeight;
  const _CropParams({
    required this.bytes,
    required this.faceLeft,
    required this.faceTop,
    required this.faceWidth,
    required this.faceHeight,
    required this.imageWidth,
    required this.imageHeight,
  });
}

// ── Funciones top-level para compute() ───────────────────────────────────────

/// Procesa el recorte y composición de imagen en un Isolate.
Uint8List _procesarImagenIsolate(_CropParams p) {
  const photoSize = ProfileImageProcessorService.photoSize;
  const plomoR = ProfileImageProcessorService.plomoRed;
  const plomoG = ProfileImageProcessorService.plomoGreen;
  const plomoB = ProfileImageProcessorService.plomoBlue;

  final original = img.decodeImage(p.bytes)!;

  // Calcular padding dinámico según cercanía del rostro
  final faceRatio = p.faceWidth / p.imageWidth;
  double padTop, padBottom, padSides;

  if (faceRatio > 0.5) {
    padTop = 0.6;
    padBottom = 1.8;
    padSides = 1.2;
  } else if (faceRatio > 0.35) {
    padTop = 0.45;
    padBottom = 1.4;
    padSides = 0.9;
  } else {
    padTop = 0.3;
    padBottom = 1.0;
    padSides = 0.7;
  }

  final cropX = (p.faceLeft - p.faceWidth * padSides)
      .clamp(0.0, p.imageWidth.toDouble())
      .toInt();
  final cropY = (p.faceTop - p.faceHeight * padTop)
      .clamp(0.0, p.imageHeight.toDouble())
      .toInt();
  final cropW = (p.faceWidth * (1 + padSides * 2))
      .clamp(1.0, (p.imageWidth - cropX).toDouble())
      .toInt();
  final cropH = (p.faceHeight * (1 + padTop + padBottom))
      .clamp(1.0, (p.imageHeight - cropY).toDouble())
      .toInt();

  final cropRatio = (cropW * cropH) / (p.imageWidth * p.imageHeight);
  img.Image cropped = cropRatio > 0.8
      ? original
      : img.copyCrop(original, x: cropX, y: cropY, width: cropW, height: cropH);

  // Redimensionar manteniendo aspecto
  final ar = cropped.width / cropped.height;
  final nw = ar > 1 ? photoSize : (photoSize * ar).round();
  final nh = ar > 1 ? (photoSize / ar).round() : photoSize;

  final resized = img.copyResize(
    cropped,
    width: nw,
    height: nh,
    interpolation: img.Interpolation.cubic,
  );

  // Componer sobre fondo plomo
  final canvas = img.Image(width: photoSize, height: photoSize);
  img.fill(canvas, color: img.ColorRgb8(plomoR, plomoG, plomoB));
  img.compositeImage(
    canvas,
    resized,
    dstX: (photoSize - nw) ~/ 2,
    dstY: (photoSize - nh) ~/ 2,
  );

  return Uint8List.fromList(img.encodeJpg(canvas, quality: 85));
}

/// Procesa imagen sin rostro detectado (solo centrar en fondo plomo).
Uint8List _procesarSinRostroIsolate(Uint8List bytes) {
  const photoSize = ProfileImageProcessorService.photoSize;
  const plomoR = ProfileImageProcessorService.plomoRed;
  const plomoG = ProfileImageProcessorService.plomoGreen;
  const plomoB = ProfileImageProcessorService.plomoBlue;

  final original = img.decodeImage(bytes)!;
  final ar = original.width / original.height;
  final nw = ar > 1 ? photoSize : (photoSize * ar).round();
  final nh = ar > 1 ? (photoSize / ar).round() : photoSize;

  final resized = img.copyResize(
    original,
    width: nw,
    height: nh,
    interpolation: img.Interpolation.cubic,
  );

  final canvas = img.Image(width: photoSize, height: photoSize);
  img.fill(canvas, color: img.ColorRgb8(plomoR, plomoG, plomoB));
  img.compositeImage(
    canvas,
    resized,
    dstX: (photoSize - nw) ~/ 2,
    dstY: (photoSize - nh) ~/ 2,
  );

  return Uint8List.fromList(img.encodeJpg(canvas, quality: 85));
}

// ─────────────────────────────────────────────────────────────────────────────

/// Servicio para procesar la imagen de perfil del usuario.
///
/// Mejoras v2:
/// - Procesamiento de imagen en Isolate (no bloquea el hilo UI)
/// - Detección facial y remoción de fondo en paralelo cuando es posible
/// - Timeout en detección facial para evitar bloqueos
/// - Fallback robusto en cada paso
class ProfileImageProcessorService {
  // Color plomo (gris) típico de fotos de documentos bolivianos
  static const int plomoRed = 128;
  static const int plomoGreen = 128;
  static const int plomoBlue = 128;

  // Tamaño estándar para fotos 4x4 (en píxeles)
  static const int photoSize = 600;

  // FaceDetector reutilizable — evita recargar el modelo en cada llamada
  static FaceDetector? _faceDetector;

  static FaceDetector _getDetector() {
    _faceDetector ??= FaceDetector(
      options: FaceDetectorOptions(
        enableContours: false, // No necesitamos contornos para recorte
        enableLandmarks: false, // No necesitamos landmarks
        enableClassification: false,
        enableTracking: false,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.fast, // Más rápido que accurate
      ),
    );
    return _faceDetector!;
  }

  /// Libera el detector cuando ya no se necesita (llamar al salir de la pantalla).
  static void liberarDetector() {
    _faceDetector?.close();
    _faceDetector = null;
  }

  /// Procesa la imagen de perfil:
  /// 1. Remoción de fondo (opcional, con ONNX ML)
  /// 2. Detección facial con ML Kit
  /// 3. Recorte + composición sobre fondo plomo (en Isolate)
  ///
  /// Solo procesa si [isFirstPhoto] es true.
  static Future<File?> processProfileImage(
    File imageFile, {
    required bool isFirstPhoto,
    bool removerFondo = true,
  }) async {
    if (!isFirstPhoto) return imageFile;

    try {
      final tempDir = await getTemporaryDirectory();
      File imagenActual = imageFile;

      // ── PASO 1: Remoción de fondo (si está habilitado) ───────────────────
      if (removerFondo) {
        debugPrint('🔄 Removiendo fondo con ONNX ML...');
        final outputPath =
            '${tempDir.path}/profile_nobg_${DateTime.now().millisecondsSinceEpoch}.png';

        final success = await ServicioRemoverFondo.removerFondo(
          imagePath: imageFile.path,
          outputPath: outputPath,
          bgColor: const ui.Color.fromARGB(
            255,
            plomoRed,
            plomoGreen,
            plomoBlue,
          ),
        );

        if (success) {
          imagenActual = File(outputPath);
          debugPrint('✅ Fondo removido');
        } else {
          debugPrint('⚠️ Remoción de fondo falló, usando original');
        }
      }

      // ── PASO 2: Leer bytes y detectar rostro ─────────────────────────────
      final imageBytes = await imagenActual.readAsBytes();

      // Detección facial con timeout de 8s para no bloquear indefinidamente
      List<Face> faces = [];
      try {
        final inputImage = InputImage.fromFile(imagenActual);
        faces = await _getDetector()
            .processImage(inputImage)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                debugPrint(
                  '⏱️ Timeout en detección facial — usando imagen completa',
                );
                return [];
              },
            );
      } catch (e) {
        debugPrint('⚠️ Error en detección facial: $e');
      }

      // ── PASO 3: Procesar imagen en Isolate ───────────────────────────────
      Uint8List processedBytes;

      if (faces.isNotEmpty) {
        final face = faces.first;
        final bb = face.boundingBox;

        // Decodificar solo para obtener dimensiones (rápido)
        final dim = img.decodeImage(imageBytes)!;

        processedBytes = await compute(
          _procesarImagenIsolate,
          _CropParams(
            bytes: imageBytes,
            faceLeft: bb.left,
            faceTop: bb.top,
            faceWidth: bb.width,
            faceHeight: bb.height,
            imageWidth: dim.width,
            imageHeight: dim.height,
          ),
        );
        debugPrint('✅ Imagen procesada con detección facial');
      } else {
        debugPrint('ℹ️ Sin rostro detectado — centrando imagen en fondo plomo');
        processedBytes = await compute(_procesarSinRostroIsolate, imageBytes);
      }

      // ── PASO 4: Guardar resultado ─────────────────────────────────────────
      final outputPath =
          '${tempDir.path}/profile_final_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outputFile = File(outputPath); 
      await outputFile.writeAsBytes(processedBytes);

      debugPrint('✅ Imagen de perfil guardada: $outputPath');
      return outputFile;
    } catch (e) {
      debugPrint('❌ Error procesando imagen de perfil: $e');
      return imageFile; // Fallback: imagen original sin procesar
    }
  }

  /// Verifica si es la primera foto del usuario.
  static Future<bool> isFirstPhoto() async {
    final path = await LocalStorageService.getProfileImagePath();
    return path == null || path.isEmpty;
  }
}
