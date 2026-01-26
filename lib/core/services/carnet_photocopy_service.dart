import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CarnetPhotocopyService {
  /// Genera un PDF A4 en B/N con anverso sobre reverso (vertical).
  /// Devuelve la ruta del PDF generado.
  static Future<String?> generatePdf({
    required File frontFile,
    required File backFile,
    File? profilePhoto, // foto 4x4 procesada, opcional
  }) async {
    try {
      final frontImage = img.decodeImage(await frontFile.readAsBytes());
      final backImage = img.decodeImage(await backFile.readAsBytes());
      if (frontImage == null || backImage == null) return null;

      // Convertir a escala de grises, enderezar y recortar fondo sobrante
      final grayFront = _autoCrop(
        _normalize(
          img.grayscale(_ensureLandscape(frontImage)),
        ),
      );
      final grayBack = _autoCrop(
        _normalize(
          img.grayscale(_ensureLandscape(backImage)),
        ),
      );

      // Ajustar ancho para A4 (vertical)
      const pdfWidth = 595.28; // A4 points
      const margin = 24.0;
      final availableWidth = (pdfWidth - (margin * 2) - 8);
      const maxDisplayHeight = 280; // limitar para que quepan anverso y reverso en una sola hoja

      img.Image resizedFront = grayFront;
      if (grayFront.width > availableWidth) {
        resizedFront = img.copyResize(
          grayFront,
          width: availableWidth.toInt(),
          interpolation: img.Interpolation.linear,
        );
      }
      if (resizedFront.height > maxDisplayHeight) {
        resizedFront = img.copyResize(
          resizedFront,
          height: maxDisplayHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      img.Image resizedBack = grayBack;
      if (grayBack.width > availableWidth) {
        resizedBack = img.copyResize(
          grayBack,
          width: availableWidth.toInt(),
          interpolation: img.Interpolation.linear,
        );
      }
      if (resizedBack.height > maxDisplayHeight) {
        resizedBack = img.copyResize(
          resizedBack,
          height: maxDisplayHeight,
          interpolation: img.Interpolation.linear,
        );
      }

      pw.MemoryImage? profile;
      if (profilePhoto != null && profilePhoto.existsSync()) {
        final pp = img.decodeImage(await profilePhoto.readAsBytes());
        if (pp != null) {
          final ppGray = _normalize(img.grayscale(pp));
          final ppResized = img.copyResize(ppGray, width: 200, height: 200, interpolation: img.Interpolation.cubic);
          profile = pw.MemoryImage(img.encodeJpg(ppResized, quality: 90));
        }
      }

      final pdf = pw.Document();
      final front = pw.MemoryImage(img.encodeJpg(resizedFront, quality: 85));
      final back = pw.MemoryImage(img.encodeJpg(resizedBack, quality: 85));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(margin),
          build: (context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColor.fromHex('#444444'), width: 0.5),
              ),
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      height: 24,
                      alignment: pw.Alignment.centerLeft,
                      child: profile != null
                          ? pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: 64,
                                  height: 64,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColor.fromHex('#999999'), width: 0.5),
                                  ),
                                  child: pw.Image(profile, fit: pw.BoxFit.cover),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text('Fotocopia C.I.', style: pw.TextStyle(fontSize: 12)),
                              ],
                            )
                          : pw.Text('Fotocopia C.I.', style: pw.TextStyle(fontSize: 12)),
                    ),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromHex('#999999'), width: 0.5),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Anverso', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#555555'))),
                          pw.SizedBox(height: 6),
                          pw.Center(
                            child: pw.Image(
                              front,
                              width: availableWidth,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColor.fromHex('#999999'), width: 0.5),
                      ),
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Reverso', style: pw.TextStyle(fontSize: 11, color: PdfColor.fromHex('#555555'))),
                          pw.SizedBox(height: 6),
                          pw.Center(
                            child: pw.Image(
                              back,
                              width: availableWidth,
                              fit: pw.BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      final docDir = await getApplicationDocumentsDirectory();
      final outDir = Directory(p.join(docDir.path, 'participant_documents'));
      if (!outDir.existsSync()) outDir.createSync(recursive: true);
      final outPath = p.join(
        outDir.path,
        'ci_photocopy_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      final outFile = File(outPath);
      await outFile.writeAsBytes(await pdf.save(), flush: true);
      return outFile.path;
    } catch (e) {
      debugPrint('Error generando PDF de fotocopia: $e');
      return null;
    }
  }

  static img.Image _normalize(img.Image input) {
    var out = img.adjustColor(
      input,
      contrast: 1.25,
      brightness: 1.08,
    );
    out = img.copyResize(
      out,
      width: input.width,
      height: input.height,
      interpolation: img.Interpolation.linear,
    );
    return out;
  }

  static img.Image _ensureLandscape(img.Image src) {
    // Asegurar orientación correcta según EXIF y rotar a horizontal si viene vertical.
    final baked = img.bakeOrientation(src);
    if (baked.height > baked.width) {
      // Rotar 90° a la derecha (clockwise) para mantener texto arriba.
      return img.copyRotate(baked, angle: -90);
    }
    return baked;
  }

  /// Recorta el fondo blanco/gris dejando solo la tarjeta.
  static img.Image _autoCrop(img.Image src) {
    // Ajustar a fondo claro: detecta píxeles que no son casi blancos.
    const int threshold = 220; // más agresivo para recortar fondos grisáceos
    int minX = src.width;
    int minY = src.height;
    int maxX = 0;
    int maxY = 0;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final l = img.getLuminance(p);
        if (l < threshold) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    // Si no encuentra nada, retorna original
    if (maxX <= minX || maxY <= minY) return src;

    // Añadir un pequeño padding
    const pad = 2;
    minX = (minX - pad).clamp(0, src.width - 1);
    minY = (minY - pad).clamp(0, src.height - 1);
    maxX = (maxX + pad).clamp(0, src.width - 1);
    maxY = (maxY + pad).clamp(0, src.height - 1);

    final w = (maxX - minX + 1).clamp(1, src.width);
    final h = (maxY - minY + 1).clamp(1, src.height);

    return img.copyCrop(src, x: minX, y: minY, width: w, height: h);
  }
}
