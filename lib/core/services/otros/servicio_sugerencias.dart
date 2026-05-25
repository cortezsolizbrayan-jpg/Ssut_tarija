import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:refactor_template/config/constants/environment.dart';

/// Servicio para enviar sugerencias a un webhook configurable.
/// El webhook debe estar preparado para recibir un POST JSON con los datos
/// y encargarse de notificar al administrador (ej: enviando SMS, email, etc.).
class ServicioSugerencias {
  static final ServicioSugerencias _instance = ServicioSugerencias._internal();
  factory ServicioSugerencias() => _instance;

  final Dio _dio;

  ServicioSugerencias._internal()
    : _dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  /// Envía una sugerencia al webhook configurado.
  ///
  /// Retorna `true` si el envío fue exitoso (código 2xx), `false` en caso contrario.
  Future<bool> enviarSugerencia({
    required String categoria,
    required String comentario,
    String? usuario,
  }) async {
    final webhookUrl = Environment.suggestionWebhookUrl;
    if (webhookUrl.isEmpty) {
      if (kDebugMode) {
        print(
          '⚠️ SUGGESTION_WEBHOOK_URL no configurada. Sugerencia no enviada.',
        );
      }
      return false;
    }

    try {
      final payload = <String, dynamic>{
        'categoria': categoria,
        'comentario': comentario,
        'fecha_envio': DateTime.now().toIso8601String(),
        'origen': 'app_posgrado_movil',
        if (usuario != null && usuario.isNotEmpty) 'usuario': usuario,
      };

      final response = await _dio.post(webhookUrl, data: payload);

      final statusCode = response.statusCode;
      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        if (kDebugMode) {
          print('✅ Sugerencia enviada correctamente. Status: $statusCode');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Webhook respondió con status: $statusCode');
        }
        return false;
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error de red al enviar sugerencia: ${e.message}');
        if (e.response != null) {
          print(
            'Respuesta error: ${e.response?.statusCode} - ${e.response?.data}',
          );
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inesperado al enviar sugerencia: $e');
      }
      return false;
    }
  }
}

