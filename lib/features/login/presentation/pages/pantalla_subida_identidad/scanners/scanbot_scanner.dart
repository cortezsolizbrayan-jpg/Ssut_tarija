import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:scanbot_sdk/scanbot_sdk_ui_v2.dart' as scanbot_ui hide ImageSource;

/// Callbacks para el escáner Scanbot (captura de páginas → archivos).
typedef ScanbotScanCallbacks = ({
  bool Function() isMounted,
  bool isWeb,
  void Function(bool) setScanbotProcessing,
  void Function(String title, String message) showErrorDialog,
  void Function(String title, String message) showInfoDialog,
  void Function(String title, String message) showSuccessDialog,
  void Function(File? front, File? back) onImagesPicked,
});

/// Convierte una página de Scanbot en File (URI → path).
File? fileFromScanbotPage(dynamic page) {
  final uriString = page?.documentImageURI ??
      page?.originalImageURI ??
      page?.documentImagePreviewURI;
  if (uriString == null || (uriString is String && uriString.isEmpty)) return null;
  final uri = Uri.parse(uriString.toString());
  final path = uri.scheme == 'file' ? uri.toFilePath() : uriString.toString();
  return File(path);
}

/// Módulo de escaneo con Scanbot (captura de documento → front/back files).
/// No hace OCR; solo captura imágenes y las entrega a la pantalla.
Future<void> runScanbotScanner(ScanbotScanCallbacks callbacks) async {
  if (callbacks.isWeb) {
    if (callbacks.isMounted()) {
      callbacks.showInfoDialog(
        'No disponible en Web',
        'Scanbot no está disponible en la versión web. Usa otra opción de escaneo.',
      );
    }
    return;
  }

  callbacks.setScanbotProcessing(true);

  try {
    // Solo 2 fotos: anverso y reverso del carnet.
    final configuration = scanbot_ui.DocumentScanningFlow(
      outputSettings: scanbot_ui.DocumentScannerOutputSettings(
        pagesScanLimit: 2,
      ),
    );
    final result = await scanbot_ui.ScanbotSdkUiV2.startDocumentScanner(configuration);

    if (!callbacks.isMounted()) return;

    if (result.status != scanbot_ui.OperationStatus.OK || result.data == null) {
      callbacks.showInfoDialog(
        'Escaneo cancelado',
        'El escaneo fue cancelado o no se obtuvieron resultados. Si suele fallar, puede ser por licencia de Scanbot: usa Cámara, Galería o Regula.',
      );
      return;
    }

    final pages = result.data!.pages;
    if (pages.isEmpty) {
      callbacks.showInfoDialog(
        'Sin páginas detectadas',
        'Scanbot no detectó páginas en el documento. Intenta nuevamente con mejor iluminación.',
      );
      return;
    }

    final frontFile = fileFromScanbotPage(pages.first);
    final backFile = pages.length > 1 ? fileFromScanbotPage(pages[1]) : null;

    if (frontFile == null) {
      callbacks.showErrorDialog(
        'Error de procesamiento',
        'No se pudo procesar la imagen principal de Scanbot.',
      );
      return;
    }

    callbacks.onImagesPicked(frontFile, backFile);

    final message = backFile == null
        ? 'Anverso capturado. Falta capturar el reverso.'
        : 'Ambos lados del documento capturados correctamente.';

    // Habilitar el botón ya para poder volver a escanear.
    callbacks.setScanbotProcessing(false);
    // Mostrar el diálogo cuando Flutter vuelva a tener control (evita "bote" al inicio).
    Future.delayed(const Duration(milliseconds: 400), () {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (callbacks.isMounted()) {
          callbacks.showSuccessDialog('¡Escaneo exitoso!', message);
        }
      });
    });
  } catch (e) {
    if (callbacks.isMounted()) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('license') || msg.contains('not valid') || msg.contains('licence')) {
        callbacks.showErrorDialog(
          'Licencia de Scanbot no válida',
          'La licencia de Scanbot no está configurada o ha expirado. Usa Cámara, Galería o Regula para escanear tu carnet.',
        );
      } else {
        callbacks.showErrorDialog(
          'Error en Scanbot',
          'Ocurrió un error durante el escaneo. Usa Cámara o Galería si el problema continúa.',
        );
      }
    }
  } finally {
    // Solo volver a habilitar si no se hizo ya en el flujo exitoso.
    if (callbacks.isMounted()) {
      callbacks.setScanbotProcessing(false);
    }
  }
}
