import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;

/// Cliente ligero para Google Cloud Vision (OCR).
/// Usa DOCUMENT_TEXT_DETECTION para mayor precisión.
class CloudVisionOcrService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  static bool get isEnabled {
    final key = dotenv.env['GOOGLE_VISION_API_KEY'];
    return key != null && key.isNotEmpty;
  }

  static Future<String?> extractText(File imageFile) async {
    final apiKey = dotenv.env['GOOGLE_VISION_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    try {
      final preparedBase64 = await _encodeToBase64(imageFile);
      final payload = {
        "requests": [
          {
            "image": {"content": preparedBase64},
            "features": [
              {"type": "DOCUMENT_TEXT_DETECTION"}
            ],
            "imageContext": {
              "languageHints": ["es", "en"]
            }
          }
        ]
      };

      final resp = await _dio.post(
        'https://vision.googleapis.com/v1/images:annotate',
        queryParameters: {"key": apiKey},
        data: payload,
      );

      final responses = resp.data?['responses'] as List<dynamic>?;
      if (responses == null || responses.isEmpty) return null;
      final fullText = responses.first['fullTextAnnotation']?['text'] as String?;
      return fullText?.trim().isNotEmpty == true ? fullText!.trim() : null;
    } catch (e) {
      debugPrint('Cloud Vision OCR error: $e');
      return null;
    }
  }

  static Future<String> _encodeToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return base64Encode(bytes);

    // Redimensionar si es muy grande para reducir latencia/costo
    const maxSide = 1600;
    img.Image resized = decoded;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      resized = img.copyResize(
        decoded,
        width: decoded.width > decoded.height ? maxSide : null,
        height: decoded.height >= decoded.width ? maxSide : null,
      );
    }

    final jpg = img.encodeJpg(resized, quality: 82);
    return base64Encode(jpg);
  }
}
