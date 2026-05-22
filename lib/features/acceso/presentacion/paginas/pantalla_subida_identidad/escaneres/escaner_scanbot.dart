// SERVICIO DESHABILITADO: Scanbot SDK removido para reducir tamaño de la app
// Si necesitas reactivarlo, descomenta scanbot_sdk en pubspec.yaml

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Callbacks que la pantalla debe implementar para el escáner Scanbot (DESHABILITADO).
typedef ScanbotScanCallbacks = ({
  File? Function() getFrontImage,
  bool Function() isMounted,
  bool isWeb,
  void Function(bool) setScanbotProcessing,
  void Function(String title, String message) showErrorDialog,
  void Function(String title, String message) showInfoDialog,
  void Function(File front, File back) onBothImagesReady,
});

/// Módulo de escaneo con Scanbot (DESHABILITADO).
Future<void> runScanbotScanner(ScanbotScanCallbacks callbacks) async {
  if (kDebugMode) {
    print('⚠️ Scanbot está deshabilitado. Usa ML Kit OCR en su lugar.');
  }
  
  callbacks.setScanbotProcessing(false);
  
  if (callbacks.isMounted()) {
    callbacks.showInfoDialog(
      'Función deshabilitada',
      'Scanbot SDK fue removido para reducir el tamaño de la app. Usa "ML Kit OCR" o "Cámara/Galería" en su lugar.',
    );
  }
}

