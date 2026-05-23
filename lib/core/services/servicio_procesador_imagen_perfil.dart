import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:refactor_template/core/services/image_processing/servicio_remover_fondo.dart';
import 'package:path_provider/path_provider.dart';
import 'storage/servicio_almacenamiento_local.dart';

/// Servicio para procesar la imagen de perfil del usuario.
/// Incluye rostro + hombros + traje (más cuerpo), con fondo plomo (gris) estilo 4x4.
class ProfileImageProcessorService {
  // Color plomo (gris) típico de fotos de documentos bolivianos
  static const int plomoRed = 128;
  static const int plomoGreen = 128;
  static const int plomoBlue = 128;

  // Tamaño estándar para fotos 4x4 (en píxeles)
  static const int photoSize = 600;

  /// Procesa la imagen: rostro + hombros + traje, sobre fondo plomo.
  /// Solo se aplica si es la primera foto del usuario.
  /// Ahora incluye remoción automática de fondo con ONNX ML.
  static Future<File?> processProfileImage(
    File imageFile, {
    required bool isFirstPhoto,
    bool removerFondo =
        true, // Nuevo parámetro para controlar remoción de fondo
  }) async {
    if (!isFirstPhoto) {
      return imageFile;
    }

    try {
      // PASO 1: Remover fondo automáticamente con ONNX ML si está habilitado
      File imagenProcesada = imageFile;

      if (removerFondo) {
        debugPrint('🔄 Removiendo fondo de foto de perfil con ONNX ML...');

        final tempDir = await getTemporaryDirectory();
        final outputPath =
            '${tempDir.path}/profile_no_bg_${DateTime.now().millisecondsSinceEpoch}.png';

        // Usar color plomo institucional (gris medio) para el fondo
        final success = await ServicioRemoverFondo.removerFondo(
          imagePath: imageFile.path,
          outputPath: outputPath,
          bgColor: const ui.Color.fromARGB(
            255,
            plomoRed,
            plomoGreen,
            plomoBlue,
          ), // Plomo institucional
        );

        if (success) {
          imagenProcesada = File(outputPath);
          debugPrint(
            '✅ Fondo removido automáticamente con ONNX ML (fondo plomo institucional)',
          );
        } else {
          debugPrint('⚠️ No se pudo remover fondo, usando imagen original');
        }
      }

      // PASO 2: Continuar con el procesamiento normal (detección facial y recorte)
      final imageBytes = await imagenProcesada.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('Error: No se pudo decodificar la imagen');
        return imageFile;
      }

      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: true,
          enableLandmarks: true,
          enableClassification: true,
          enableTracking: false,
          minFaceSize: 0.15,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      final inputImage = InputImage.fromFile(imageFile);
      final faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      img.Image processedImage;

      if (faces.isNotEmpty) {
        final face = faces.first;
        final boundingBox = face.boundingBox;

        // Calcular qué tan cerca está la persona (ratio del rostro vs imagen)
        final faceRatio = boundingBox.width / originalImage.width;

        // Ajustar padding dinámicamente según cercanía
        // Si faceRatio > 0.5 = muy cerca, necesita más padding
        // Si faceRatio < 0.3 = lejos, puede usar menos padding
        double paddingTop, paddingBottom, paddingSides;

        if (faceRatio > 0.5) {
          // Persona MUY CERCA - Máximo padding para no cortar nada
          paddingTop = 0.6; // Mucho espacio arriba
          paddingBottom = 1.8; // Mucho espacio abajo para brazos
          paddingSides = 1.2; // Mucho espacio a los lados
          debugPrint(
            ' Persona muy cerca (ratio: ${faceRatio.toStringAsFixed(2)}) - Usando padding máximo',
          );
        } else if (faceRatio > 0.35) {
          // Persona CERCA - Padding generoso
          paddingTop = 0.45;
          paddingBottom = 1.4;
          paddingSides = 0.9;
          debugPrint(
            ' Persona cerca (ratio: ${faceRatio.toStringAsFixed(2)}) - Usando padding generoso',
          );
        } else {
          // Persona LEJOS - Padding estándar
          paddingTop = 0.3;
          paddingBottom = 1.0;
          paddingSides = 0.7;
          debugPrint(
            ' Persona a distancia normal (ratio: ${faceRatio.toStringAsFixed(2)}) - Usando padding estándar',
          );
        }

        // Calcular área de recorte con padding dinámico
        final cropX = (boundingBox.left - boundingBox.width * paddingSides)
            .clamp(0.0, originalImage.width.toDouble())
            .toInt();
        final cropY = (boundingBox.top - boundingBox.height * paddingTop)
            .clamp(0.0, originalImage.height.toDouble())
            .toInt();
        final cropWidth = ((boundingBox.width * (1 + paddingSides * 2)).clamp(
          1.0,
          (originalImage.width - cropX).toDouble(),
        )).toInt();
        final cropHeight =
            ((boundingBox.height * (1 + paddingTop + paddingBottom)).clamp(
              1.0,
              (originalImage.height - cropY).toDouble(),
            )).toInt();

        // Si el recorte es muy grande (persona muy cerca), usar toda la imagen
        final cropRatio =
            (cropWidth * cropHeight) /
            (originalImage.width * originalImage.height);
        if (cropRatio > 0.8) {
          debugPrint(
            ' Recorte muy grande (${(cropRatio * 100).toStringAsFixed(1)}%) - Usando imagen completa',
          );
          processedImage = originalImage;
        } else {
          processedImage = img.copyCrop(
            originalImage,
            x: cropX,
            y: cropY,
            width: cropWidth,
            height: cropHeight,
          );
          debugPrint(
            ' Recorte aplicado: ${cropWidth}x${cropHeight} (${(cropRatio * 100).toStringAsFixed(1)}% de la imagen)',
          );
        }

        final aspectRatio = processedImage.width / processedImage.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          newWidth = photoSize;
          newHeight = (photoSize / aspectRatio).round();
        } else {
          newHeight = photoSize;
          newWidth = (photoSize * aspectRatio).round();
        }

        processedImage = img.copyResize(
          processedImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Canvas plomo y pegar la imagen completa (rostro + traje) sin recorte elíptico
        final squareImage = img.Image(width: photoSize, height: photoSize);
        final plomoColor = img.ColorRgb8(plomoRed, plomoGreen, plomoBlue);
        img.fill(squareImage, color: plomoColor);

        final offsetX = (photoSize - newWidth) ~/ 2;
        final offsetY = (photoSize - newHeight) ~/ 2;

        // Composición rectangular: se ve la persona completa (y su traje) sobre fondo plomo
        img.compositeImage(
          squareImage,
          processedImage,
          dstX: offsetX,
          dstY: offsetY,
        );

        debugPrint(
          ' Imagen procesada: ${newWidth}x${newHeight} centrada en canvas ${photoSize}x${photoSize}',
        );

        processedImage = squareImage;
      } else {
        // Si no se detecta rostro, usar la imagen completa pero centrada en fondo plomo
        final aspectRatio = originalImage.width / originalImage.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          newWidth = photoSize;
          newHeight = (photoSize / aspectRatio).round();
        } else {
          newHeight = photoSize;
          newWidth = (photoSize * aspectRatio).round();
        }

        final resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Crear imagen cuadrada con fondo plomo
        final squareImage = img.Image(width: photoSize, height: photoSize);
        final plomoColor = img.ColorRgb8(plomoRed, plomoGreen, plomoBlue);
        img.fill(squareImage, color: plomoColor);

        final offsetX = (photoSize - newWidth) ~/ 2;
        final offsetY = (photoSize - newHeight) ~/ 2;

        img.compositeImage(
          squareImage,
          resizedImage,
          dstX: offsetX,
          dstY: offsetY,
        );

        processedImage = squareImage;
        processedImage = _applySoftMask(processedImage);
      }

      // Guardar la imagen procesada
      final processedBytes = Uint8List.fromList(
        img.encodeJpg(processedImage, quality: 85),
      );
      final processedFile = File('${imageFile.path}_processed.jpg');
      await processedFile.writeAsBytes(processedBytes);

      return processedFile;
    } catch (e) {
      debugPrint('Error procesando imagen de perfil: $e');
      // Si hay error, retornar la imagen original
      return imageFile;
    }
  }

  /// Aplica una máscara suave (en rama sin rostro).
  static img.Image _applySoftMask(img.Image image) {
    return image;
  }

  /// Verifica si es la primera foto del usuario
  static Future<bool> isFirstPhoto() async {
    // Verificar si ya existe una foto guardada
    final existingImagePath = await LocalStorageService.getProfileImagePath();
    return existingImagePath == null || existingImagePath.isEmpty;
  }
}
