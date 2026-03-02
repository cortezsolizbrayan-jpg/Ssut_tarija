import 'package:flutter/foundation.dart';

import 'package:refactor_template/core/services/servicio_ocr_blinkid.dart';

/// Callbacks que la pantalla debe implementar para el escáner BlinkID.
typedef BlinkIdScanCallbacks = ({
  bool Function() isMounted,
  Future<bool> Function() showScanTipsDialog,
  void Function(bool) setProcessing,
  void Function(double) setProgress,
  void Function(String) logStep,
  Future<bool> Function({
    required String extractedCI,
    required String extractedNombres,
    required String extractedApellidos,
    required String extractedFechaNacimiento,
    required String extractedFechaEmision,
    required String extractedFechaExpiracion,
    required String extractedLugarNacimiento,
    required String extractedProfesion,
    required String extractedEstadoCivil,
    required String extractedDomicilio,
    required String extractedGrupoSanguineo,
    required String detectedModel,
  }) finalizeOcrResult,
  void Function(String title, String message) showErrorDialog,
  void Function(String title, String message) showInfoDialog,
  void Function(String title, String message) showSuccessDialog,
});

/// Módulo de escaneo con BlinkID (UX nativo).
/// Orquesta: tips → scanWithUi → finalize con datos extraídos.
Future<bool> runBlinkIdScanner(BlinkIdScanCallbacks callbacks) async {
  if (!BlinkIdOcrService.isEnabled) {
    if (callbacks.isMounted()) {
      callbacks.showErrorDialog(
        'Escáner no disponible',
        'Las licencias de BlinkID no están configuradas. Verifica el archivo .env o usa otra opción de escaneo.',
      );
    }
    return false;
  }

  final confirmed = await callbacks.showScanTipsDialog();
  if (!confirmed) return false;

  callbacks.setProcessing(true);
  callbacks.setProgress(0.05);
  callbacks.logStep('Iniciando BlinkID UX');

  try {
    callbacks.setProgress(0.2);
    final blinkidData = await BlinkIdOcrService.scanWithUi();

    if (blinkidData == null) {
      if (callbacks.isMounted()) {
        callbacks.showInfoDialog(
          'Escaneo cancelado',
          'El escaneo fue cancelado o no se pudieron extraer datos del documento. Puedes intentar nuevamente o usar otra opción.',
        );
      }
      return false;
    }

    callbacks.setProgress(0.6);
    callbacks.logStep('Datos extraídos con BlinkID, finalizando...');

    final finalized = await callbacks.finalizeOcrResult(
      extractedCI: blinkidData['ci'] ?? '',
      extractedNombres: blinkidData['nombres'] ?? '',
      extractedApellidos: blinkidData['apellidos'] ?? '',
      extractedFechaNacimiento: blinkidData['fechaNacimiento'] ?? '',
      extractedFechaEmision: blinkidData['fechaEmision'] ?? '',
      extractedFechaExpiracion: blinkidData['fechaExpiracion'] ?? '',
      extractedLugarNacimiento: blinkidData['lugarNacimiento'] ?? '',
      extractedProfesion: blinkidData['profesion'] ?? '',
      extractedEstadoCivil: blinkidData['estadoCivil'] ?? '',
      extractedDomicilio: blinkidData['domicilio'] ?? '',
      extractedGrupoSanguineo: blinkidData['grupoSanguineo'] ?? '',
      detectedModel: 'blinkid',
    );

    if (finalized && callbacks.isMounted()) {
      callbacks.showSuccessDialog('¡Escaneo exitoso!', 'Los datos se extrajeron correctamente.');
    }

    return finalized;
  } catch (e) {
    debugPrint('Error BlinkID UX: $e');
    if (callbacks.isMounted()) {
      callbacks.showErrorDialog(
        'Error de escaneo',
        'Ocurrió un error durante el escaneo: ${e.toString()}. Intenta con otra opción.',
      );
    }
    return false;
  } finally {
    if (callbacks.isMounted()) {
      callbacks.setProcessing(false);
    }
    callbacks.logStep('BlinkID UX finalizado');
  }
}
