import 'package:flutter/services.dart';

class PaddleOcrService {
  static const MethodChannel _channel = MethodChannel('paddle_ocr');

  static Future<Map<String, dynamic>> runOcr(String imagePath) async {
    final result = await _channel.invokeMethod('runOcr', {'path': imagePath});
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    return <String, dynamic>{'ok': false, 'error': 'invalid_response'};
  }
}
