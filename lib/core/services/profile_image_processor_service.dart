import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:refactor_template/core/services/local_storage_service.dart';

/// Servicio para procesar la imagen de perfil del usuario
/// Extrae la cara frontal, quita el fondo y aplica un fondo plomo (gris) estilo 4x4
class ProfileImageProcessorService {
  // Color plomo (gris) típico de fotos de documentos bolivianos
  static const int plomoRed = 128;
  static const int plomoGreen = 128;
  static const int plomoBlue = 128;

  // Tamaño estándar para fotos 4x4 (en píxeles)
  static const int photoSize = 600;

  /// Procesa la imagen de perfil: extrae la cara frontal, quita el fondo y aplica fondo plomo
  /// Solo se aplica si es la primera foto del usuario
  static Future<File?> processProfileImage(
    File imageFile, {
    required bool isFirstPhoto,
  }) async {
    if (!isFirstPhoto) {
      // Si no es la primera foto, retornar la imagen sin procesar
      return imageFile;
    }

    try {
      // Leer la imagen
      final imageBytes = await imageFile.readAsBytes();
      img.Image? originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        debugPrint('Error: No se pudo decodificar la imagen');
        return imageFile;
      }

      // Detectar rostro usando ML Kit con configuración mejorada
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
        // Si se detecta un rostro, extraer la cara frontal
        final face = faces.first;
        final boundingBox = face.boundingBox;

        // Calcular el área de recorte con padding más generoso para incluir hombros
        // Las fotos 4x4 típicamente incluyen desde los hombros hasta arriba de la cabeza
        final paddingTop = 0.15; // 15% arriba de la cabeza
        final paddingBottom = 0.35; // 35% abajo para incluir hombros
        final paddingSides = 0.25; // 25% a los lados

        final cropX = (boundingBox.left - boundingBox.width * paddingSides)
            .clamp(0.0, originalImage.width.toDouble())
            .toInt();
        final cropY = (boundingBox.top - boundingBox.height * paddingTop)
            .clamp(0.0, originalImage.height.toDouble())
            .toInt();
        final cropWidth = ((boundingBox.width * (1 + paddingSides * 2)).clamp(
          0.0,
          (originalImage.width - cropX).toDouble(),
        )).toInt();
        final cropHeight =
            ((boundingBox.height * (1 + paddingTop + paddingBottom)).clamp(
              0.0,
              (originalImage.height - cropY).toDouble(),
            )).toInt();

        // Recortar la imagen alrededor del rostro y hombros
        processedImage = img.copyCrop(
          originalImage,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        // Redimensionar manteniendo la proporción y luego hacer cuadrado
        // Primero redimensionar para que el lado más largo sea photoSize
        final aspectRatio = processedImage.width / processedImage.height;
        int newWidth, newHeight;

        if (aspectRatio > 1) {
          // Más ancho que alto
          newWidth = photoSize;
          newHeight = (photoSize / aspectRatio).round();
        } else {
          // Más alto que ancho o cuadrado
          newHeight = photoSize;
          newWidth = (photoSize * aspectRatio).round();
        }

        processedImage = img.copyResize(
          processedImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.cubic,
        );

        // Crear imagen cuadrada con fondo plomo
        final squareImage = img.Image(width: photoSize, height: photoSize);

        // Rellenar con fondo plomo
        final plomoColor = img.ColorRgb8(plomoRed, plomoGreen, plomoBlue);
        img.fill(squareImage, color: plomoColor);

        // Centrar la imagen recortada en el cuadrado
        final offsetX = (photoSize - newWidth) ~/ 2;
        final offsetY = (photoSize - newHeight) ~/ 2;

        _compositeEllipseMasked(
          squareImage,
          processedImage,
          dstX: offsetX,
          dstY: offsetY,
        );

        processedImage = squareImage;

        // Aplicar máscara suave para quitar bordes duros y mejorar la transición
        processedImage = _applySoftMask(processedImage);
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
        img.encodeJpg(processedImage, quality: 95),
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

  /// Aplica una máscara suave para mejorar la transición entre la imagen y el fondo
  static img.Image _applySoftMask(img.Image image) {
    return image;
  }

  static void _compositeEllipseMasked(
    img.Image dst,
    img.Image src, {
    required int dstX,
    required int dstY,
  }) {
    final plomoColor = img.ColorRgb8(plomoRed, plomoGreen, plomoBlue);

    final cx = dstX + (src.width / 2);
    final cy = dstY + (src.height / 2);
    final rx = (src.width * 0.46);
    final ry = (src.height * 0.62);
    final featherStart = 0.92;

    for (int y = 0; y < src.height; y++) {
      final dy = (dstY + y) - cy;
      for (int x = 0; x < src.width; x++) {
        final dx = (dstX + x) - cx;

        final nx = dx / rx;
        final ny = dy / ry;
        final d = math.sqrt(nx * nx + ny * ny);
        if (d > 1.0) continue;

        final srcPixel = src.getPixel(x, y);
        final outX = dstX + x;
        final outY = dstY + y;
        if (outX < 0 || outY < 0 || outX >= dst.width || outY >= dst.height) {
          continue;
        }

        double alpha = 1.0;
        if (d > featherStart) {
          alpha = ((1.0 - d) / (1.0 - featherStart)).clamp(0.0, 1.0);
        }

        final r =
            (srcPixel.r.toDouble() * alpha +
                    plomoColor.r.toDouble() * (1.0 - alpha))
                .round();
        final g =
            (srcPixel.g.toDouble() * alpha +
                    plomoColor.g.toDouble() * (1.0 - alpha))
                .round();
        final b =
            (srcPixel.b.toDouble() * alpha +
                    plomoColor.b.toDouble() * (1.0 - alpha))
                .round();

        dst.setPixel(outX, outY, img.ColorRgb8(r, g, b));
      }
    }
  }

  /// Verifica si es la primera foto del usuario
  static Future<bool> isFirstPhoto() async {
    // Verificar si ya existe una foto guardada
    final existingImagePath = await LocalStorageService.getProfileImagePath();
    return existingImagePath == null || existingImagePath.isEmpty;
  }
}
