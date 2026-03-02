import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static bool _initialized = false;
  static String _defaultApiUrl =
      'https://dev-repositorio-backend.posgradoupea.edu.bo/api/v1';

  static Future<void> initEnvironment() async {
    if (!_initialized) {
      // En Flutter Web, no intentar cargar .env debido a problemas de codificación
      if (kIsWeb) {
        if (kDebugMode) {
          print('Ejecutando en Web - usando URL por defecto: $_defaultApiUrl');
        }
        _initialized = true;
        return;
      }

      // Para otras plataformas, intentar cargar el archivo .env con timeout más corto
      // Inicializar primero para que la app no se bloquee
      _initialized = true;

      // Cargar .env en background sin bloquear
      Future.microtask(() async {
        try {
          await dotenv
              .load(fileName: '.env')
              .timeout(
                const Duration(milliseconds: 1000), // Reducido a 1 segundo
                onTimeout: () {
                  if (kDebugMode) {
                    print('Timeout cargando .env, usando valores por defecto');
                  }
                },
              );
          if (kDebugMode) {
            print('Archivo .env cargado correctamente');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error cargando .env: $e');
            print('Usando URL por defecto: $_defaultApiUrl');
          }
        }
      });
    }
  }

  /// Obtiene la URL de la API
  static String get apiUrlPsg {
    if (!_initialized) {
      throw Exception(
        'Environment no ha sido inicializado. Llama a initEnvironment() primero.',
      );
    }

    // En web, siempre usar el valor por defecto
    if (kIsWeb) {
      return _defaultApiUrl;
    }

    /// Si es web, retornar la URL por defecto
    // Para otras plataformas, intentar obtener del .env
    try {
      final envValue = dotenv.env['THE_API_PSG'];
      if (envValue != null && envValue.isNotEmpty) {
        return envValue;
      }

      /// Si no hay URL de la API, retornar la URL por defecto
    } catch (e) {
      if (kDebugMode) {
        print('Error leyendo variable de entorno: $e');
      }
    }

    /// Si no hay URL de la API, retornar la URL por defecto
    return _defaultApiUrl;
  }

  /// URL base de la API de preinscripción (programas vigentes / oferta).
  /// GET {apiPreinscripcionUrl}/publicaciones/oferta
  /// Por defecto: https://dev-api-preinscripcion.posgradoupea.edu.bo/api/v1
  static String get apiPreinscripcionUrl {
    if (!_initialized) return _defaultApiPreinscripcionUrl;
    if (kIsWeb) return _defaultApiPreinscripcionUrl;
    try {
      final value = dotenv.env['API_PREINSCRIPCION'];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim().replaceAll(RegExp(r'/$'), '');
      }
    } catch (e) {
      if (kDebugMode) print('Error leyendo API_PREINSCRIPCION: $e');
    }
    return _defaultApiPreinscripcionUrl;
  }

  static const String _defaultApiPreinscripcionUrl =
      'https://dev-api-preinscripcion.posgradoupea.edu.bo/api/v1';

  /// Obtiene la licencia de Scanbot desde el .env (o vacío si no existe).
  static String get scanbotLicenseKey {
    if (!_initialized) {
      throw Exception(
        'Environment no ha sido inicializado. Llama a initEnvironment() primero.',
      );
    }

    if (kIsWeb) {
      return '';
    }

    try {
      final value = dotenv.env['SCANBOT_LICENSE_KEY'];
      return value?.trim() ?? '';
    } catch (e) {
      if (kDebugMode) {
        print('Error leyendo SCANBOT_LICENSE_KEY: $e');
      }
    }

    return '';
  }

}
