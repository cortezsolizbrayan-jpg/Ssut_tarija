import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/config/constants/environment.dart';

/// Servicio para verificar si un CI existe en la base de datos
class CIVerificationService {
  late final Dio dio;

  CIVerificationService() {
    dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiUrlPsg,
        connectTimeout: const Duration(seconds: 3),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }
///verificaimos si un ci existen en la dicho bd 
  /// Verifica si un CI existe en la base de datos
  /// Retorna true si existe, false si no existe
  Future<Map<String, dynamic>> verifyCI(String ci) async {
    try {
      debugPrint('🔍 Verificando CI en BD: $ci');

      // Usar el CI completo (incluyendo letras, guiones o complementos)
      final cleanCI = ci.trim();

      if (cleanCI.isEmpty || cleanCI.length < 2) {
        return {
          'success': false, 
          'exists': false, 
          'message': 'Ingresa un CI válido'
        };
      }

      // Llamar al endpoint de verificación codificando caracteres especiales
      final encodedCI = Uri.encodeComponent(cleanCI);
      final response = await dio.get(
        '/usuarios/verificar-ci/$encodedCI',
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Si la respuesta es 200, el CI existe
      // Si es 404, no existe
      if (response.statusCode == 200) {
        final data = response.data;
        final exists = data['existe'] ?? false;

        debugPrint('✅ CI verificado. Existe: $exists');

        return {
          'success': true,
          'exists': exists,
          'message': exists
              ? 'El CI ya está registrado en el sistema'
              : 'CI disponible para registro',
        };
      } else {
        return {
          'success': true,
          'exists': false,
          'message': 'CI disponible para registro',
        };
      }
    } on DioException catch (e) {
      // TRATAMIENTO NO-BLOQUEANTE: 
      // Si el servidor falla (500), no se encuentra (404) o hay timeout,
      // permitimos continuar para no bloquear al usuario nuevo.
      debugPrint('⚠️ Error técnico verificando CI (${e.response?.statusCode}): ${e.message}');
      
      return {
        'success': true,
        'exists': false,
        'message': 'CI disponible para verificación manual',
        'technicalError': true
      };
    } catch (e) {
      debugPrint('⚠️ Error inesperado: $e');
      return {
        'success': true,
        'exists': false,
        'message': 'CI disponible para verificación manual',
      };
    }
  }
}

