import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class CiLetterComposerService {
  static Future<File?> composeLetterFromCiImages({
    required File front,
    required File back,
  }) async {
    try {
      final frontBytes = await front.readAsBytes();
      final backBytes = await back.readAsBytes();

      final frontDecoded = img.decodeImage(frontBytes);
      final backDecoded = img.decodeImage(backBytes);

      if (frontDecoded == null || backDecoded == null) return null;

      final frontImg = img.bakeOrientation(frontDecoded);
      final backImg = img.bakeOrientation(backDecoded);

      const int dpi = 200;
      final int pageW = (8.5 * dpi).round();
      final int pageH = (11 * dpi).round();

      final int margin = (pageW * 0.06).round();
      final int gap = (pageH * 0.035).round();

      final page = img.Image(width: pageW, height: pageH);
      img.fill(page, color: img.ColorRgb8(255, 255, 255));

      final availableW = pageW - (margin * 2);
      final availableH = pageH - (margin * 2) - gap;
      final halfH = (availableH / 2).floor();

      final frontFit = _resizeToFit(frontImg, availableW, halfH);
      final backFit = _resizeToFit(backImg, availableW, halfH);

      final border = (pageW * 0.02).round();
      final frontBox = _addWhiteBorder(frontFit, border: border);
      final backBox = _addWhiteBorder(backFit, border: border);

      final frontX = margin + ((availableW - frontBox.width) / 2).floor();
      final frontY = margin + ((halfH - frontBox.height) / 2).floor();

      final backX = margin + ((availableW - backBox.width) / 2).floor();
      final backY =
          margin + halfH + gap + ((halfH - backBox.height) / 2).floor();

      img.compositeImage(page, frontBox, dstX: frontX, dstY: frontY);
      img.compositeImage(page, backBox, dstX: backX, dstY: backY);

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory(
        '${dir.path}${Platform.pathSeparator}participant_documents',
      );
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }

      final fileName =
          'ci_hoja_carta_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}.jpg';
      final outFile = File('${outDir.path}${Platform.pathSeparator}$fileName');
      await outFile.writeAsBytes(img.encodeJpg(page, quality: 92));
      return outFile;
    } catch (_) {
      return null;
    }
  }

  static img.Image _resizeToFit(img.Image src, int maxW, int maxH) {
    final w = src.width;
    final h = src.height;
    if (w <= 0 || h <= 0) return src;

    final scale = math.min(maxW / w, maxH / h);
    final newW = math.max(1, (w * scale).round());
    final newH = math.max(1, (h * scale).round());

    return img.copyResize(
      src,
      width: newW,
      height: newH,
      interpolation: img.Interpolation.cubic,
    );
  }

  static img.Image _addWhiteBorder(img.Image src, {required int border}) {
    if (border <= 0) return src;

    final out = img.Image(
      width: src.width + border * 2,
      height: src.height + border * 2,
    );
    img.fill(out, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(out, src, dstX: border, dstY: border);
    return out;
  }

  static Future<File?> generateProrrogaLetter({
    required String fullName,
    required String ci,
  }) async {
    try {
      // Letter size at ~150 DPI for faster generation, readable enough
      final int pageW = 1275;
      final int pageH = 1650;
      
      final page = img.Image(width: pageW, height: pageH);
      img.fill(page, color: img.ColorRgb8(255, 255, 255));

      final font = img.arial24; 
      
      int y = 200;
      int x = 100;
      
      void drawLine(String text) {
        img.drawString(page, text, font: font, x: x, y: y, color: img.ColorRgb8(0, 0, 0));
        y += 50;
      }

      drawLine("CARTA DE SOLICITUD DE PRORROGA");
      y += 40;
      drawLine("Fecha: ${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}");
      y += 60;
      drawLine("Yo, $fullName".toUpperCase());
      drawLine("Con C.I.: $ci");
      y += 50;
      drawLine("Por la presente, solicito formalmente una prorroga");
      drawLine("para la presentacion de mi Titulo en Provision Nacional,");
      drawLine("comprometiendome a entregarlo a la brevedad posible.");
      y += 150;
      drawLine("___________________________________");
      drawLine("Firma Digital: $fullName");
      drawLine("C.I.: $ci");

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${dir.path}${Platform.pathSeparator}participant_documents');
      if (!await outDir.exists()) await outDir.create(recursive: true);

      final fileName = 'prorroga_generada_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File('${outDir.path}${Platform.pathSeparator}$fileName');
      await outFile.writeAsBytes(img.encodeJpg(page, quality: 85));
      return outFile;
    } catch (e) {
      return null;
    }
  }
}
