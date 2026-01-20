import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cliente simple a Gemini para estructurar el texto del OCR.
/// Envía el texto plano del anverso/reverso y devuelve un JSON con campos clave.
class GeminiStructuredOcrService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  static bool get isEnabled {
    final key = dotenv.env['GOOGLE_GEMINI_API_KEY'];
    return key != null && key.isNotEmpty;
  }

  static String _model() {
    final fromEnv = dotenv.env['GEMINI_MODEL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    // Default a modelo estable y accesible con API key de Google AI Studio
    return 'gemini-1.5-flash-latest';
  }

  /// Retorna un mapa con campos: ci, nombres, apellidos, fechaNacimiento, fechaEmision, fechaExpiracion.
  static Future<Map<String, String>?> structureOcr({
    required String frontText,
    String? backText,
  }) async {
    final apiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;
    final model = _model();

    final prompt = '''
Eres un sistema de extracción de datos de Cédulas de Identidad de Bolivia.
Devuelve únicamente JSON válido (sin texto extra) con las claves:
{
  "ci": "...",                  // número de documento (7-12 dígitos) tomado de "NO.", "Nº", "NRO"; nunca uses "SECCIÓN" o "SERIE"
  "nombres": "...",             // nombres en MAYÚSCULAS sin acentos ni palabras como "FOTOGRAFÍA", "IMPRESIÓN", "PERTENECE"
  "apellidos": "...",           // apellidos en MAYÚSCULAS
  "fechaNacimiento": "dd/mm/yyyy",
  "fechaEmision": "dd/mm/yyyy",
  "fechaExpiracion": "dd/mm/yyyy"
}
Reglas:
- Prioriza el texto del anverso para CI; ignora números de sección/serie.
- Para nombres/apellidos, si ves una línea con 2-4 palabras en mayúsculas (ej: "RICHARD ERICK HUAÑAPACO CHURA"), úsala completa.
- Si faltan campos, déjalos como cadena vacía.
- Normaliza meses en español (enero..diciembre) a dd/mm/yyyy.
- No incluyas nada fuera del JSON.

Texto anverso:
$frontText

Texto reverso:
${backText ?? ''}
''';

    try {
      final resp = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        queryParameters: {'key': apiKey},
        data: {
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        },
        options: Options(
          // Si el modelo o la ruta no existen, no explotar: devolver null
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Si no es 2xx, salimos sin romper el flujo
      final status = resp.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        debugPrint('Gemini OCR structuring error: status $status, model=$model, body: ${resp.data}');
        return null;
      }

      final candidates = resp.data?['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) return null;
      final text = candidates.first['content']?['parts']?[0]?['text'] as String?;
      if (text == null) return null;

      final jsonString = _extractJsonString(text);
      if (jsonString == null) return null;

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return null;

      return decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    } catch (e) {
      debugPrint('Gemini OCR structuring error: $e');
      return null;
    }
  }

  static String? _extractJsonString(String raw) {
    final fence = RegExp(r'\{[\s\S]*\}');
    final match = fence.firstMatch(raw);
    if (match != null) return match.group(0);
    if (raw.trim().startsWith('{') && raw.trim().endsWith('}')) {
      return raw.trim();
    }
    return null;
  }
}
