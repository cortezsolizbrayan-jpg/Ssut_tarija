import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resultado de la validación facial con Gemini
class ResultadoValidacionFacial {
  final bool esDeFrente;
  final bool fondoPlomo;
  final bool esNitida;
  final bool soloUnaPersona;
  final String mensaje;
  final bool esValida;

  ResultadoValidacionFacial({
    required this.esDeFrente,
    required this.fondoPlomo,
    required this.esNitida,
    required this.soloUnaPersona,
    required this.mensaje,
  }) : esValida = esDeFrente && fondoPlomo && esNitida && soloUnaPersona;

  factory ResultadoValidacionFacial.fromJson(Map<String, dynamic> json) {
    return ResultadoValidacionFacial(
      esDeFrente: json['esDeFrente'] == true || json['esDeFrente'] == 'true',
      fondoPlomo: json['fondoPlomo'] == true || json['fondoPlomo'] == 'true',
      esNitida: json['esNitida'] == true || json['esNitida'] == 'true',
      soloUnaPersona: json['soloUnaPersona'] == true || json['soloUnaPersona'] == 'true',
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }

  String obtenerMensajeDetallado() {
    if (esValida) {
      return '✓ Foto válida: Rostro de frente, fondo plomo, imagen nítida.';
    }

    final problemas = <String>[];
    if (!esDeFrente) problemas.add('El rostro debe estar de frente (ambos ojos visibles)');
    if (!fondoPlomo) problemas.add('El fondo debe ser gris/plomo uniforme');
    if (!esNitida) problemas.add('La imagen debe ser nítida y bien iluminada');
    if (!soloUnaPersona) problemas.add('Solo debe aparecer una persona en la foto');

    return problemas.join('\n• ');
  }
}

/// Servicio para validar fotos faciales usando Gemini AI
class ServicioValidacionFacialGemini {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
    ),
  );

  static bool get isEnabled {
    final key = dotenv.env['GOOGLE_GEMINI_API_KEY'];
    return key != null && key.isNotEmpty;
  }

  static String _model() {
    final fromEnv = dotenv.env['GEMINI_MODEL'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'gemini-1.5-flash';
  }

  /// Valida una foto facial usando Gemini Vision
  static Future<ResultadoValidacionFacial?> validarFotoFacial(File imagenFile) async {
    final apiKey = dotenv.env['GOOGLE_GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('❌ API Key de Gemini no configurada');
      return null;
    }

    try {
      // Leer imagen y convertir a base64
      final bytes = await imagenFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Determinar el tipo MIME
      final extension = imagenFile.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'jpg' || extension == 'jpeg') mimeType = 'image/jpeg';

      final prompt = '''Analiza esta foto de rostro para validación de documento oficial y responde ÚNICAMENTE con un JSON válido, sin explicaciones ni markdown.

Formato exacto de respuesta:
{"esDeFrente":true,"fondoPlomo":true,"esNitida":true,"soloUnaPersona":true,"mensaje":""}

Criterios de validación:
1. esDeFrente: El rostro debe estar mirando directamente a la cámara. Ambos ojos deben ser claramente visibles, la nariz debe estar centrada, y la cara no debe estar girada hacia los lados (perfil) ni inclinada. La persona debe estar mirando al frente.

2. fondoPlomo: El fondo debe ser de color gris/plomo uniforme, sin patrones, texturas, objetos o personas adicionales. Debe ser un fondo liso y neutro, similar al usado en fotos de documentos oficiales.

3. esNitida: La imagen debe estar enfocada, sin desenfoque. Los rasgos faciales (ojos, nariz, boca) deben ser claramente distinguibles. La iluminación debe ser adecuada (ni muy oscura ni sobreexpuesta).

4. soloUnaPersona: Solo debe aparecer UNA persona en la foto. No debe haber otras personas, ni siquiera parcialmente visibles en el fondo o los bordes.

5. mensaje: Si algún criterio NO se cumple, describe brevemente el problema principal (máximo 50 palabras). Si todos se cumplen, deja el mensaje vacío.

IMPORTANTE: Responde SOLO con el JSON, sin ```json ni explicaciones adicionales.''';

      final candidatesModels = <String>[
        _model(),
        'gemini-1.5-flash',
        'gemini-1.5-flash-002',
        'gemini-1.5-pro',
      ];

      for (final model in candidatesModels) {
        debugPrint('→ Validando foto facial con Gemini (model: $model)');
        
        try {
          final resp = await _dio.post(
            'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
            queryParameters: {'key': apiKey},
            data: {
              "contents": [
                {
                  "parts": [
                    {"text": prompt},
                    {
                      "inline_data": {
                        "mime_type": mimeType,
                        "data": base64Image,
                      }
                    }
                  ]
                }
              ],
              "generationConfig": {
                "temperature": 0.1,
                "topK": 1,
                "topP": 1,
                "maxOutputTokens": 256,
              }
            },
            options: Options(
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          final status = resp.statusCode ?? 0;
          if (status < 200 || status >= 300) {
            debugPrint('❌ Error en validación facial: status $status, model=$model');
            if (status == 404) continue; // Probar siguiente modelo
            return null;
          }

          final candidates = resp.data?['candidates'] as List<dynamic>?;
          if (candidates == null || candidates.isEmpty) {
            debugPrint('⚠️ Sin candidatos en respuesta de Gemini');
            continue;
          }

          final text = candidates.first['content']?['parts']?[0]?['text'] as String?;
          if (text == null || text.isEmpty) {
            debugPrint('⚠️ Texto vacío en respuesta de Gemini');
            continue;
          }

          debugPrint('✔ Respuesta de Gemini recibida (model: $model)');
          debugPrint('Texto: $text');

          // Extraer JSON de la respuesta
          final jsonString = _extractJsonString(text);
          if (jsonString == null) {
            debugPrint('⚠️ No se pudo extraer JSON de la respuesta');
            continue;
          }

          final decoded = jsonDecode(jsonString);
          if (decoded is! Map<String, dynamic>) {
            debugPrint('⚠️ JSON no es un mapa válido');
            continue;
          }

          final resultado = ResultadoValidacionFacial.fromJson(decoded);
          debugPrint('✅ Validación facial completada: ${resultado.esValida ? "VÁLIDA" : "INVÁLIDA"}');
          debugPrint('   - De frente: ${resultado.esDeFrente}');
          debugPrint('   - Fondo plomo: ${resultado.fondoPlomo}');
          debugPrint('   - Nítida: ${resultado.esNitida}');
          debugPrint('   - Solo una persona: ${resultado.soloUnaPersona}');
          if (resultado.mensaje.isNotEmpty) {
            debugPrint('   - Mensaje: ${resultado.mensaje}');
          }

          return resultado;
        } catch (e) {
          debugPrint('❌ Error al validar con modelo $model: $e');
          continue;
        }
      }

      debugPrint('❌ Todos los modelos fallaron en la validación facial');
      return null;
    } catch (e) {
      debugPrint('❌ Error general en validación facial: $e');
      return null;
    }
  }

  static String? _extractJsonString(String raw) {
    // Remover markdown si existe
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // Buscar JSON con regex
    final fence = RegExp(r'\{[\s\S]*\}');
    final match = fence.firstMatch(cleaned);
    if (match != null) return match.group(0);

    // Si ya es JSON válido
    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      return cleaned;
    }

    return null;
  }
}
