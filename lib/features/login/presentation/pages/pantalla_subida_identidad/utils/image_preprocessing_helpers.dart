import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helpers para preprocesamiento de imágenes para OCR
class ImagePreprocessingHelpers {
  /// Preprocesa una imagen para mejorar el OCR
  static Future<File> preprocessForOcr(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageFile;

    // Recortar bordes blancos o ruido externo
    img.Image processed = autoCropBorders(decoded);

    const int minShortSide = 1200;
    const int maxLongSide = 2000;
    int width = processed.width;
    int height = processed.height;
    int shortSide = width < height ? width : height;
    int longSide = width > height ? width : height;

    if (shortSide < minShortSide) {
      final scale = minShortSide / shortSide;
      processed = img.copyResize(
        processed,
        width: (width * scale).round(),
        height: (height * scale).round(),
        interpolation: img.Interpolation.average,
      );
      width = processed.width;
      height = processed.height;
      longSide = width > height ? width : height;
    }

    if (longSide > maxLongSide) {
      final scale = maxLongSide / longSide;
      processed = img.copyResize(
        processed,
        width: (width * scale).round(),
        height: (height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    processed = img.normalize(processed, min: 0, max: 255);
    processed = img.adjustColor(
      processed,
      contrast: 1.1,
      brightness: 1.05,
    );

    return writeOcrImage(processed, suffix: 'ocr');
  }

  /// Preprocesado mejorado con mayor contraste y escala de grises
  static Future<File> preprocessForOcrEnhanced(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return imageFile;

    final cropped = autoCropBorders(decoded);

    var processed = img.grayscale(cropped);
    processed = img.adjustColor(
      processed,
      contrast: 1.35,
      brightness: 1.1,
    );

    return writeOcrImage(processed, suffix: 'ocr_enhanced');
  }

  /// Prepara un archivo para OCR (usa caché si ya está procesado)
  static Future<File> prepareFileForOcr(File original) async {
    if (!original.existsSync()) return original;
    
    if (p.basename(p.dirname(original.path)) == 'ocr_cache') {
      return original;
    }
    
    final processed = await preprocessForOcr(original);
    return processed.existsSync() ? processed : original;
  }

  /// Recorta automáticamente los bordes blancos de una imagen
  static img.Image autoCropBorders(img.Image src) {
    const threshold = 245; // casi blanco
    int minX = src.width, minY = src.height, maxX = 0, maxY = 0;
    bool found = false;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final l = img.getLuminance(src.getPixel(x, y));
        if (l < threshold) {
          found = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (!found) return src;

    const pad = 8;
    final cropX = (minX - pad).clamp(0, src.width - 1);
    final cropY = (minY - pad).clamp(0, src.height - 1);
    final cropW = (maxX - cropX + 1 + pad * 2).clamp(1, src.width - cropX);
    final cropH = (maxY - cropY + 1 + pad * 2).clamp(1, src.height - cropY);

    return img.copyCrop(
      src,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );
  }

  /// Estima la nitidez de una imagen (0.0 a 1.0+)
  static Future<double> estimateSharpness(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return 1.0;

    img.Image sample = decoded;
    final longSide =
        sample.width > sample.height ? sample.width : sample.height;
    if (longSide > 600) {
      final scale = 600 / longSide;
      sample = img.copyResize(
        sample,
        width: (sample.width * scale).round(),
        height: (sample.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    sample = img.grayscale(sample);
    final edges = img.sobel(sample, amount: 1);
    double sum = 0.0;
    int count = 0;
    for (final pixel in edges) {
      sum += pixel.luminance.toDouble();
      count++;
    }

    if (count == 0) return 1.0;
    return (sum / count) / 255.0;
  }

  /// Persiste una imagen en el directorio de caché de OCR
  static Future<File> persistImage(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(appDir.path, 'ocr_cache'));
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final newPath = p.join(
      outDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_${p.basename(file.path)}',
    );
    return file.copy(newPath);
  }

  /// Escribe una imagen procesada al directorio de caché
  static Future<File> writeOcrImage(img.Image image, {required String suffix}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(appDir.path, 'ocr_cache'));
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final newPath = p.join(
      outDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_$suffix.jpg',
    );
    final outBytes = img.encodeJpg(image, quality: 92);
    final outFile = await File(newPath).writeAsBytes(outBytes, flush: true);
    return outFile.existsSync() ? outFile : File(newPath);
  }
}
