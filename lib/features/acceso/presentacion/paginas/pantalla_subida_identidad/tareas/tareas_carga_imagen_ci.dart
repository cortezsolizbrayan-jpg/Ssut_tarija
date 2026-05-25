import 'dart:io';

import 'package:image/image.dart' as img;

Future<File> normalizeImageTask(Map<String, String> args) async {
  final inputPath = args['inputPath']!;
  final outPath = args['outputPath']!;
  final input = File(inputPath);

  final bytes = await input.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return input;

  img.Image normalized = img.bakeOrientation(decoded);
  // Salida obligatoria en blanco y negro, cuidando legibilidad.
  normalized = img.grayscale(normalized);
  normalized = img.contrast(normalized, contrast: 108);

  const maxDim = 1600;
  final w = normalized.width;
  final h = normalized.height;
  if (w > maxDim || h > maxDim) {
    if (w >= h) {
      normalized = img.copyResize(
        normalized,
        width: maxDim,
        interpolation: img.Interpolation.cubic,
      );
    } else {
      normalized = img.copyResize(
        normalized,
        height: maxDim,
        interpolation: img.Interpolation.cubic,
      );
    }
  }

  final outFile = File(outPath);
  await outFile.writeAsBytes(img.encodeJpg(normalized, quality: 90));
  return outFile;
}

Future<File> cropImageTask(Map<String, dynamic> args) async {
  final inputPath = args['inputPath'] as String;
  final outPath = args['outputPath'] as String;
  final useCenterFrame = args['useCenterFrame'] == true;
  final left = (args['left'] as double?) ?? 0.0;
  final top = (args['top'] as double?) ?? 0.0;
  final right = (args['right'] as double?) ?? 0.0;
  final bottom = (args['bottom'] as double?) ?? 0.0;

  final input = File(inputPath);
  final bytes = await input.readAsBytes();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return input;

  img.Image cropped;
  if (useCenterFrame) {
    // Marco guía fijo con proporción de carnet (aprox. 1.586), centrado.
    final frameWidth = (decoded.width * 0.86).toInt();
    final frameHeight = (frameWidth / 1.586).toInt().clamp(1, decoded.height);
    final frameX = ((decoded.width - frameWidth) / 2).round();
    final frameY = ((decoded.height - frameHeight) / 2).round();
    cropped = img.copyCrop(
      decoded,
      x: frameX.clamp(0, decoded.width - 1),
      y: frameY.clamp(0, decoded.height - 1),
      width: frameWidth.clamp(1, decoded.width),
      height: frameHeight.clamp(1, decoded.height),
    );
  } else {
    final pad = 18.0;
    final l = (left - pad).clamp(0.0, decoded.width.toDouble()).toInt();
    final t = (top - pad).clamp(0.0, decoded.height.toDouble()).toInt();
    final r = (right + pad).clamp(0.0, decoded.width.toDouble()).toInt();
    final b = (bottom + pad).clamp(0.0, decoded.height.toDouble()).toInt();
    final w = r - l;
    final h = b - t;
    if (w < 80 || h < 80) return input;
    cropped = img.copyCrop(decoded, x: l, y: t, width: w, height: h);
  }

  // Mantener orientación natural y nitidez para visualización fiel.
  cropped = img.bakeOrientation(cropped);

  final outFile = File(outPath);
  await outFile.writeAsBytes(img.encodeJpg(cropped, quality: 92));
  return outFile;
}

Future<int?> computeDHashTask(String filePath) async {
  try {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final resized = img.copyResize(
      img.bakeOrientation(decoded),
      width: 9,
      height: 8,
      interpolation: img.Interpolation.average,
    );

    int hash = 0;
    int bitIndex = 0;

    int lum(int x, int y) {
      final p = resized.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      return (0.299 * r + 0.587 * g + 0.114 * b).round();
    }

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final left = lum(x, y);
        final right = lum(x + 1, y);
        if (left > right) {
          hash |= (1 << bitIndex);
        }
        bitIndex++;
      }
    }

    return hash;
  } catch (_) {
    return null;
  }
}

