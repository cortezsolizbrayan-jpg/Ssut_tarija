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
  /// 
  /// [cropRect] es el área de recorte normalizada (0.0 a 1.0) del cuadrado verde de escaneo
  static Future<String?> generatePdf({
    required File frontFile,
    required File backFile,
    File? profilePhoto,
    Rect? frontCropRect, // Área de recorte del anverso (normalizada 0-1)
    Rect? backCropRect,  // Área de recorte del reverso (normalizada 0-1)
  }) async {
    try {
      final frontImage = img.decodeImage(await frontFile.readAsBytes());
      final backImage = img.decodeImage(await backFile.readAsBytes());
      if (frontImage == null || backImage == null) return null;

      // Procesar imágenes: recortar según cuadrado verde, rotar a vertical, B/N mejorado
      final processedFront = _processIdCard(frontImage, frontCropRect);
      final processedBack = _processIdCard(backImage, backCropRect);

      // Configuración para A4 vertical
      const pdfWidth = 595.28; // A4 points (ancho)
      const pdfHeight = 841.89; // A4 points (alto)
      const margin = 40.0;
      final availableWidth = pdfWidth - (margin * 2);
      final availableHeight = (pdfHeight - (margin * 3)) / 2; // Espacio para cada imagen

      // Redimensionar manteniendo aspect ratio
      final resizedFront = _resizeForPdf(processedFront, availableWidth, availableHeight);
      final resizedBack = _resizeForPdf(processedBack, availableWidth, availableHeight);

      // Procesar foto de perfil si existe
      pw.MemoryImage? profile;
      if (profilePhoto != null && profilePhoto.existsSync()) {
        final pp = img.decodeImage(await profilePhoto.readAsBytes());
        if (pp != null) {
          final ppGray = _enhanceContrast(img.grayscale(pp));
          final ppResized = img.copyResize(
            ppGray,
            width: 180,
            height: 180,
            interpolation: img.Interpolation.cubic,
          );
          profile = pw.MemoryImage(img.encodeJpg(ppResized, quality: 95));
        }
      }

      final pdf = pw.Document();
      final front = pw.MemoryImage(img.encodeJpg(resizedFront, quality: 92));
      final back = pw.MemoryImage(img.encodeJpg(resizedBack, quality: 92));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(margin),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildPdfHeader(profile),
                pw.SizedBox(height: 20),
                
                // Anverso (vertical)
                pw.Expanded(
                  child: _buildCardSection('ANVERSO', front),
                ),
                
                pw.SizedBox(height: 20),
                
                // Reverso (vertical)
                pw.Expanded(
                  child: _buildCardSection('REVERSO', back),
                ),
                
                pw.SizedBox(height: 12),
                
                // Footer
                _buildPdfFooter(),
              ],
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

  /// Procesa la imagen del carnet: recorta, rota a vertical, convierte a B/N mejorado
  static img.Image _processIdCard(img.Image source, Rect? cropRect) {
    img.Image processed = source;
    
    // 1. Aplicar orientación EXIF
    processed = img.bakeOrientation(processed);
    
    // 2. Recortar según el cuadrado verde de escaneo (si se proporciona)
    if (cropRect != null) {
      final x = (cropRect.left * processed.width).toInt().clamp(0, processed.width - 1);
      final y = (cropRect.top * processed.height).toInt().clamp(0, processed.height - 1);
      final w = (cropRect.width * processed.width).toInt().clamp(1, processed.width - x);
      final h = (cropRect.height * processed.height).toInt().clamp(1, processed.height - y);
      
      processed = img.copyCrop(processed, x: x, y: y, width: w, height: h);
    }
    
    // 3. Rotar a vertical si está horizontal
    if (processed.width > processed.height) {
      processed = img.copyRotate(processed, angle: 90);
    }
    
    // 4. Convertir a escala de grises
    processed = img.grayscale(processed);
    
    // 5. Mejorar contraste para evitar brillos
    processed = _enhanceContrast(processed);
    
    // 6. Recortar bordes blancos automáticamente
    processed = _autoCropWhitespace(processed);
    
    return processed;
  }

  /// Mejora el contraste y reduce brillos en imágenes B/N
  static img.Image _enhanceContrast(img.Image input) {
    // Ajustar contraste y brillo de forma muy suave para evitar imágenes negras
    var enhanced = img.adjustColor(
      input,
      contrast: 1.15,      // Contraste muy suave
      brightness: 1.05,    // Brillo mínimo
    );
    
    // Aplicar normalización MUY suave para evitar pérdida de información
    // Rango más amplio para preservar detalles
    enhanced = img.normalize(enhanced, min: 10, max: 245);
    
    return enhanced;
  }

  /// Redimensiona la imagen para caber en el PDF manteniendo aspect ratio
  static img.Image _resizeForPdf(img.Image source, double maxWidth, double maxHeight) {
    final aspectRatio = source.width / source.height;
    int targetWidth = source.width;
    int targetHeight = source.height;
    
    // Calcular dimensiones manteniendo aspect ratio
    if (source.width > maxWidth) {
      targetWidth = maxWidth.toInt();
      targetHeight = (targetWidth / aspectRatio).toInt();
    }
    
    if (targetHeight > maxHeight) {
      targetHeight = maxHeight.toInt();
      targetWidth = (targetHeight * aspectRatio).toInt();
    }
    
    return img.copyResize(
      source,
      width: targetWidth,
      height: targetHeight,
      interpolation: img.Interpolation.cubic,
    );
  }

  /// Recorta automáticamente los bordes blancos/grises
  static img.Image _autoCropWhitespace(img.Image src) {
    const int threshold = 230; // Umbral para detectar fondo blanco
    int minX = src.width;
    int minY = src.height;
    int maxX = 0;
    int maxY = 0;
    bool foundContent = false;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final l = img.getLuminance(p);
        if (l < threshold) {
          foundContent = true;
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (!foundContent || maxX <= minX || maxY <= minY) return src;

    // Añadir padding pequeño
    const pad = 5;
    minX = (minX - pad).clamp(0, src.width - 1);
    minY = (minY - pad).clamp(0, src.height - 1);
    maxX = (maxX + pad).clamp(0, src.width - 1);
    maxY = (maxY + pad).clamp(0, src.height - 1);

    final w = (maxX - minX + 1).clamp(1, src.width);
    final h = (maxY - minY + 1).clamp(1, src.height);

    return img.copyCrop(src, x: minX, y: minY, width: w, height: h);
  }

  /// Construye el header del PDF
  static pw.Widget _buildPdfHeader(pw.MemoryImage? profile) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F8F9FB'),
        border: pw.Border.all(color: PdfColor.fromHex('#005BAC'), width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: profile != null
          ? pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  width: 60,
                  height: 60,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColor.fromHex('#005BAC'),
                      width: 2,
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.ClipRRect(
                    horizontalRadius: 4,
                    verticalRadius: 4,
                    child: pw.Image(profile, fit: pw.BoxFit.cover),
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FOTOCOPIA DE CÉDULA DE IDENTIDAD',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#005BAC'),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Documento oficial para trámites académicos',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColor.fromHex('#666666'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : pw.Center(
              child: pw.Text(
                'FOTOCOPIA DE CÉDULA DE IDENTIDAD',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#005BAC'),
                ),
              ),
            ),
    );
  }

  /// Construye una sección del carnet (anverso o reverso)
  static pw.Widget _buildCardSection(String label, pw.MemoryImage image) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColor.fromHex('#E0E4ED'), width: 1.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#005BAC'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Expanded(
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(
                  color: PdfColor.fromHex('#CCCCCC'),
                  width: 1,
                ),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 4,
                verticalRadius: 4,
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye el footer del PDF
  static pw.Widget _buildPdfFooter() {
    final now = DateTime.now();
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColor.fromHex('#E0E4ED'),
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Posgrado UPEA',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#005BAC'),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'Generado: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#999999'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Clase auxiliar para representar un rectángulo de recorte
class Rect {
  final double left;
  final double top;
  final double width;
  final double height;

  const Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
