// SERVICIO DESHABILITADO: BlinkID SDK removido para reducir tamaño de la app
// Si necesitas reactivarlo, descomenta blinkid_flutter en pubspec.yaml

import 'dart:io';
import 'package:flutter/foundation.dart';

class BlinkIdOcrService {
  // Siempre deshabilitado
  static bool get isEnabled => false;

  static Future<Map<String, String>?> scanImages({
    required File frontFile,
    File? backFile,
  }) async {
    if (kDebugMode) {
      print('⚠️ BlinkID está deshabilitado. Usa ML Kit OCR en su lugar.');
    }
    return null;
  }

  static Future<Map<String, String>?> scanWithUi() async {
    if (kDebugMode) {
      print('⚠️ BlinkID está deshabilitado. Usa ML Kit OCR en su lugar.');
    }
    return null;
  }
}
