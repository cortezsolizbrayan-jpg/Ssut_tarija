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
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Verifica si un CI existe en la base de datos
  /// Retorna true si existe, false si no existe
  Future<Map<String, dynamic>> verifyCI(String ci) async {
    try {
      debugPrint('🔍 Verificando CI en BD: $ci');

      // Limpiar el CI (solo números)
      final cleanCI = ci.replaceAll(RegExp(r'[^\d]'), '');

      if (cleanCI.isEmpty || cleanCI.length < 6) {
        return {'success': false, 'exists': false, 'message': 'CI inválido'};
      }

      // Llamar al endpoint de verificación
      // Ajusta el endpoint según tu API
      final response = await dio.get(
        '/usuarios/verificar-ci/$cleanCI',
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
      // Si es 404, el CI no existe (lo cual es bueno para registro)
      if (e.response?.statusCode == 404) {
        debugPrint('✅ CI no existe en BD (disponible para registro)');
        return {
          'success': true,
          'exists': false,
          'message': 'CI disponible para registro',
        };
      }

      // Otros errores
      debugPrint('❌ Error verificando CI: ${e.message}');
      return {
        'success': false,
        'exists': false,
        'message': 'Error al verificar CI. Intenta nuevamente.',
      };
    } catch (e) {
      debugPrint('❌ Error inesperado verificando CI: $e');
      return {
        'success': false,
        'exists': false,
        'message': 'Error al verificar CI. Intenta nuevamente.',
      };
    }
  }
}
