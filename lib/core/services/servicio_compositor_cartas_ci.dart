import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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
    Uint8List? signatureBytes,
  }) async {
    try {
      final fontData = await rootBundle.load('assets/Fonts/Inter-Regular.ttf');
      final font = pw.Font.ttf(fontData.buffer.asByteData());
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr =
          "La Paz, ${now.day} de ${_getMonthName(now.month)} de ${now.year}";

      final String body = """$dateStr

Señor:
Dr. Richard Jorge Torrez Juaniquina Ph. D.
DIRECTOR DE POSGRADO - UPEA
Presente.-

Ref.: SOLICITUD DE PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL

Distinguido Magister:
Me es grato hacerle llegar un saludo cordial y fraterno a nombre mío, deseándole mis mejores deseos de éxitos en las labores que desempeña.
El motivo de la presente es para solicitar a su autoridad una PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL, para la inscripción al PROGRAMA: “Diplomado en: $career” MODALIDAD: Virtual; siendo que mi persona debe realizar solicitud en la Universidad de origen de estudios, por ese motivo es que le mando mi solicitud de prórroga. Por ese motivo es que le mando mi solicitud, esperando el visto bueno de su autoridad me despido.
Atentamente,
""";

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  body,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                pw.SizedBox(height: 40),
                if (signatureBytes != null) ...[
                  pw.Center(
                    child: pw.Container(
                      width: 180,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                      ),
                      child: pw.Image(
                        pw.MemoryImage(signatureBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ] else
                  pw.SizedBox(height: 52),
                pw.Text(
                  "………………………………………………………………",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  "NOMBRE: $fullName",
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.Text(
                  "C.I. $ci",
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.Text(
                  "c/Dirección de Posgrado – UPEA",
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.Text(
                  "c/Archivo persona.",
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${dir.path}${Platform.pathSeparator}participant_documents');
      if (!await outDir.exists()) await outDir.create(recursive: true);

      final fileName = 'prorroga_generada_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outFile = File('${outDir.path}${Platform.pathSeparator}$fileName');
      await outFile.writeAsBytes(await pdf.save());
      return outFile;
    } catch (e) {
      return null;
    }
  }

  static Future<File?> generateInscripcionLetter({
    required String fullName,
    required String ci,
    String? career = "Educación Superior",
    Uint8List? signatureBytes,
  }) async {
    try {
      final fontData = await rootBundle.load('assets/Fonts/Inter-Regular.ttf');
      final font = pw.Font.ttf(fontData.buffer.asByteData());
      final pdf = pw.Document();

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
• Cumplir con todas las actividades académicas hasta culminar las clases del posgrado en la Universidad Pública de El Alto.
• Realizar los pagos de colegiatura y matrícula, y presentar mis comprobantes de depósito en un máximo de 48 horas después de realizar el depósito.
• Completar mis documentos en un máximo de 8 meses después de concluir el último módulo del Diplomado.
Adjunto los requisitos exigidos por la Unidad de Posgrado.
Sin más que decir, me despido con las consideraciones más distinguidas.
Atentamente,
""";

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  body,
                  style: pw.TextStyle(font: font, fontSize: 12, height: 1.5),
                ),
                pw.SizedBox(height: 40),
                if (signatureBytes != null) ...[
                  pw.Center(
                    child: pw.Container(
                      width: 180,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
                      ),
                      child: pw.Image(
                        pw.MemoryImage(signatureBytes),
                        fit: pw.BoxFit.contain,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 12),
                ] else
                  pw.SizedBox(height: 52),
                pw.Text(
                  "………………………………………………………………",
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(font: font, fontSize: 12),
                ),
                pw.SizedBox(height: 6),
                pw.Text(fullName, style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text("C.I. $ci", style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text("c/Dirección de Posgrado – UPEA",
                    style: pw.TextStyle(font: font, fontSize: 12)),
                pw.Text("c/Archivo persona",
                    style: pw.TextStyle(font: font, fontSize: 12)),
              ],
            );
          },
        ),
      );

      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory('${dir.path}${Platform.pathSeparator}participant_documents');
      if (!await outDir.exists()) await outDir.create(recursive: true);

      final fileName = 'inscripcion_generada_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final outFile = File('${outDir.path}${Platform.pathSeparator}$fileName');
      await outFile.writeAsBytes(await pdf.save());
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

}
