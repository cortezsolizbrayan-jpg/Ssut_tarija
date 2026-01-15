import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static bool _initialized = false;
  static const String _defaultApiUrl =
      'https://dev-repositorio-backend.posgradoupea.edu.bo/api/v1';

  static Future<void> initEnvironment() async {
    if (!_initialized) {
      // En Flutter Web, no intentar cargar .env debido a problemas de codificación
      if (kIsWeb) {
        if (kDebugMode) {
          debugPrint(
            'Ejecutando en Web - usando URL por defecto: $_defaultApiUrl',
          );
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
                    debugPrint(
                      'Timeout cargando .env, usando valores por defecto',
                    );
                  }
                },
              );
          if (kDebugMode) {
            debugPrint('Archivo .env cargado correctamente');
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error cargando .env: $e');
            debugPrint('Usando URL por defecto: $_defaultApiUrl');
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
        debugPrint('Error leyendo variable de entorno: $e');
      }
    }

    /// Si no hay URL de la API, retornar la URL por defecto
    return _defaultApiUrl;
  }
}
