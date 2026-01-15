import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ServicioCompositorCartasCi {
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
    String? career = "Educación Superior",
  }) async {
    try {
      final int pageW = 1275;
      final int pageH = 1650;

      final page = img.Image(width: pageW, height: pageH);
      img.fill(page, color: img.ColorRgb8(255, 255, 255));

      final font = img.arial24;
      
      final now = DateTime.now();
      final dateStr = "La Paz, ${now.day} de ${_getMonthName(now.month)} de ${now.year}";

      final String body = """$dateStr

Señor:
Dr. Richard Jorge Torrez Juaniquina Ph. D.
DIRECTOR DE POSGRADO - UPEA
Presente.-

Ref.: SOLICITUD DE PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TITULO EN PROVISIÓN NACIONAL

Distinguido Magister:
Me es grato hacerle llegar un saludo cordial y fraterno a nombre mío, deseándole mis mejores deseos de éxitos en las labores que desempeña.
El motivo de la presente es para solicitar a su autoridad una PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL, para la inscripción al PROGRAMA: “Diplomado en: $career” MODALIDAD: Virtual; siendo que mi persona debe realizar solicitud en la Universidad de origen de estudios, por ese motivo es que le mando mi solicitud de prórroga. Por ese motivo es que le mando mi solicitud, esperando el visto bueno de su autoridad me despido.
Atentamente,


………………………………………………………………
NOMBRE: $fullName
C.I. $ci
c/Dirección de Posgrado – UPEA
c/Archivo persona.""";

      _drawMultiLineText(page, body, font, 100, 150, 1075);

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

  static Future<File?> generateInscripcionLetter({
    required String fullName,
    required String ci,
    String? career = "Educación Superior",
  }) async {
    try {
      final int pageW = 1275;
      final int pageH = 1650;

      final page = img.Image(width: pageW, height: pageH);
      img.fill(page, color: img.ColorRgb8(255, 255, 255));

      final font = img.arial24;
      
      final now = DateTime.now();
      final dateStr = "La Paz, ${now.day} de ${_getMonthName(now.month)} de ${now.year}";

      final String body = """$dateStr

Señor:
Dr. Richard Jorge Torrez Juaniquina Ph. D.
DIRECTOR DE POSGRADO - UPEA
Presente.-

REF.: SOLICITUD DE INSCRIPCIÓN Y COMPROMISO
Distinguido Director:
Me es grato hacerle llegar un saludo cordial y fraterno a nombre mío, deseándole mis mejores deseos de éxitos en las labores que desempeña.
El motivo de la presente es para solicitar a su autoridad la INSCRIPCIÓN AL PROGRAMA: “Diplomado en: $career” MODALIDAD Virtual, así mismo, me comprometo:
 Cumplir con todas las actividades académicas hasta culminar las clases del posgrado en la Universidad Pública de El Alto. 
 Realizar los pagos de colegiatura y matrícula, y presentar mis comprobantes de depósito en un máximo de 48 horas después de realizar el depósito.
 Completar mis documentos en un máximo de 8 meses después de concluir el último módulo del Diplomado.
Adjunto los requisitos exigidos por la Unidad de Posgrado.
Sin más que decir, me despido con las consideraciones más distinguidas.
Atentamente,


………………………………………………………………
$fullName
C.I. $ci
c/Dirección de Posgrado – UPEA
c/Archivo persona""";

      _drawMultiLineText(page, body, font, 100, 150, 1075);

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${dir.path}${Platform.pathSeparator}participant_documents');
      if (!await outDir.exists()) await outDir.create(recursive: true);

      final fileName = 'inscripcion_generada_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File('${outDir.path}${Platform.pathSeparator}$fileName');
      await outFile.writeAsBytes(img.encodeJpg(page, quality: 85));
      return outFile;
    } catch (e) {
      return null;
    }
  }

  static String _getMonthName(int month) {
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    if (month < 1 || month > 12) return 'mes';
    return months[month - 1];
  }

  static int _drawMultiLineText(
    img.Image image,
    String text,
    img.BitmapFont font,
    int x,
    int y,
    int maxWidth, {
    int lineHeight = 30,
  }) {
    final lines = text.split('\n');
    int currentY = y;
    
    // Average char width estimate for arial24
    const double avgCharWidth = 12.0; 

    for (final line in lines) {
       if (line.isEmpty) {
         currentY += lineHeight;
         continue;
       }
       
       final words = line.split(' ');
       String buffer = '';
       
       for (final word in words) {
          if ((buffer.length + word.length + 1) * avgCharWidth <= maxWidth) {
             buffer += (buffer.isEmpty ? '' : ' ') + word;
          } else {
             img.drawString(image, buffer, font: font, x: x, y: currentY, color: img.ColorRgb8(0, 0, 0));
             currentY += lineHeight;
             buffer = word;
          }
       }
       if (buffer.isNotEmpty) {
          img.drawString(image, buffer, font: font, x: x, y: currentY, color: img.ColorRgb8(0, 0, 0));
          currentY += lineHeight;
       }
    }
    return currentY;
  }
}
