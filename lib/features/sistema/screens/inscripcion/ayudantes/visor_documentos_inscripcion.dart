import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Utilidad para previsualizar documentos del flujo de inscripción.
///
/// - HTML: se muestra en WebView con zoom (como carta).
/// - PDF: se muestra integrado con PdfPreview (paquete printing).
/// - Imágenes: visor simple con zoom.
class VisorDocumentosInscripcion {
  static const Color _headerBlue = Color(0xFF005BAC);

  static Future<void> previsualizar({
    required BuildContext context,
    required String titulo,
    required String path,
    required void Function(String mensaje) onError,
  }) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        onError('El archivo no existe físicamente en el dispositivo.');
        return;
      }

      final lower = path.toLowerCase();
      if (lower.endsWith('.html') || lower.endsWith('.htm')) {
        await _showHtml(context: context, titulo: titulo, htmlPath: path, onError: onError);
        return;
      }

      if (lower.endsWith('.pdf')) {
        await _showPdf(context: context, titulo: titulo, pdfPath: path, onError: onError);
        return;
      }

      if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png')) {
        await _showImage(context: context, titulo: titulo, imagePath: path, onError: onError);
        return;
      }

      await OpenFilex.open(path);
    } catch (e) {
      onError('No se pudo abrir el documento: $e');
    }
  }

  static Future<void> _showHtml({
    required BuildContext context,
    required String titulo,
    required String htmlPath,
    required void Function(String mensaje) onError,
  }) async {
    final file = File(htmlPath);
    if (!await file.exists()) {
      onError('El archivo generado ya no existe en el dispositivo.');
      return;
    }
    final html = await file.readAsString();

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) {
          final viewportRegex = RegExp(
            r'''<meta\s+name=["\']viewport["\']\s+content=["\'][^"\']*["\']\s*/?>''',
            caseSensitive: false,
          );
          final htmlConViewport = html.contains(viewportRegex)
              ? html.replaceFirst(
                  viewportRegex,
                  '<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">',
                )
              : html.replaceFirst(
                  '<head>',
                  '<head><meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">',
                );

          final controller = WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(Colors.transparent)
            ..loadHtmlString(htmlConViewport, baseUrl: null);

          return Scaffold(
            appBar: AppBar(
              backgroundColor: _headerBlue,
              title: Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
            body: Container(
              color: const Color(0xFFE5E5E5),
              child: SafeArea(
                child: WebViewWidget(controller: controller),
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> _showImage({
    required BuildContext context,
    required String titulo,
    required String imagePath,
    required void Function(String mensaje) onError,
  }) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      onError('La imagen ya no existe en el dispositivo.');
      return;
    }
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            backgroundColor: _headerBlue,
            title: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(file),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _showPdf({
    required BuildContext context,
    required String titulo,
    required String pdfPath,
    required void Function(String mensaje) onError,
  }) async {
    final file = File(pdfPath);
    if (!await file.exists()) {
      onError('El PDF ya no existe en el dispositivo.');
      return;
    }

    final bytes = await file.readAsBytes();

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            backgroundColor: _headerBlue,
            title: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PdfPreview(
            build: (format) => bytes,
            useActions: false, 
            canChangePageFormat: false,
            canChangeOrientation: false,
            allowSharing: true,
            allowPrinting: true,
            maxPageWidth: 700,
            initialPageFormat: PdfPageFormat.a4,
            loadingWidget: const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }
}

