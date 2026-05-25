import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';

/// Resultado de verificación por CI
/// 
/// Contiene el resultado de validar un Cédula de Identidad (CI) contra el
/// servidor de preinscripción UPEA. Devuelve información del usuario y estado
/// de la autenticación.
class ResultadoAuthCI {
  /// Indica si la verificación fue exitosa
  final bool exito;
  
  /// Nombre completo del usuario (opcional, no siempre se devuelve)
  final String? nombreUsuario;
  
  /// Cédula de Identidad verificada
  final String? ci;
  
  /// Número de celular enmascarado (ej. g******)
  final String? celular;
  
  /// Mensaje descriptivo del resultado
  final String? mensaje;
  
  /// Indica si hubo error de conexión de red
  final bool errorRed;

  const ResultadoAuthCI({
    required this.exito,
    this.nombreUsuario,
    this.ci,
    this.celular,
    this.mensaje,
    this.errorRed = false,
  });
}

/// Servicio para verificar y autenticar usuarios por Cédula de Identidad (CI)
///
/// Este servicio realiza validaciones contra el servidor de preinscripción UPEA
/// para determinar si un CI existe en el sistema. En caso afirmativo, registra
/// una sesión localmente.
///
/// Endpoint: GET /persona/validacion/{ci}
/// Respuesta esperada: { "status": "success", "data": { "ci": "...", "celular": "g*******" } }
class ServicioAutenticacionCI {
  /// Cliente HTTP Dio para realizar peticiones al servidor
  late final Dio _dio;

  /// Constructor que inicializa el cliente HTTP con configuración predeterminada
  ///
  /// Configura:
  /// - URL base del servidor de preinscripción desde variables de entorno
  /// - Timeouts de conexión y recepción de 6 segundos
  /// - Headers Content-Type y Accept como application/json
  ServicioAutenticacionCI() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Environment.apiPreinscripcionUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 6),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// Verifica y autentica un CI contra el servidor de preinscripción
  ///
  /// Parámetros:
  /// - [ci]: Cédula de Identidad a validar (puede contener espacios)
  ///
  /// Retorna un [ResultadoAuthCI] con el resultado de la operación.
  ///
  /// Comportamiento:
  /// 1. Limpia espacios del CI ingresado
  /// 2. Valida que no esté vacío
  /// 3. Realiza petición GET al endpoint /persona/validacion/{ci}
  /// 4. Si exitoso (200, status="success"), guarda sesión localmente
  /// 5. Maneja errores de red (404, timeout) y excepciones generales
  Future<ResultadoAuthCI> verificarYAutenticar(String ci) async {
    // Limpiar espacios en blanco alrededor del CI
    final cleanCI = ci.trim();
    
    // Validación básica: CI no puede estar vacío
    if (cleanCI.isEmpty) {
      return const ResultadoAuthCI(exito: false, mensaje: 'CI vacío');
    }

    try {
      // Log de depuración para trazabilidad
      debugPrint(' Consultando CI: $cleanCI');
      
      // Realizar petición GET al endpoint de validación
      final response = await _dio.get('/persona/validacion/$cleanCI');

      // Extraer campos de la respuesta con valores por defecto seguros
      final status = response.data?['status']?.toString() ?? '';
      final data = response.data?['data'] as Map<String, dynamic>?;

      // Validar respuesta exitosa: HTTP 200, status="success", y data no nula
      if (response.statusCode == 200 && status == 'success' && data != null) {
        // Extraer información del CI y celular desde la respuesta
        final ciServidor = data['ci']?.toString() ?? cleanCI;
        final celular = data['celular']?.toString();

        // Guardar sesión localmente para mantener estado de autenticación
        await LocalStorageService.saveSessionData({
          'authenticated': true,
          'ci': ciServidor,
          'celular': celular ?? '',
          'loginMethod': 'ci_validacion',
          'savedAt': DateTime.now().toIso8601String(),
        });

        // Retornar resultado exitoso con datos del usuario
        return ResultadoAuthCI(
          exito: true,
          ci: ciServidor,
          celular: celular,
          mensaje: 'CI encontrado en el sistema',
        );
      }

      // Respuesta del servidor inválida o CI no registrado
      return const ResultadoAuthCI(exito: false, mensaje: 'CI no registrado');
      
    } on DioException catch (e) {
      // Manejo específico de errores de red (timeout, conexión, HTTP)
      final statusCode = e.response?.statusCode;
      debugPrint('⚠️ Error validando CI ($statusCode): ${e.message}');

      if (statusCode == 404) {
        // CI no existe en el sistema
        return const ResultadoAuthCI(exito: false, mensaje: 'CI no registrado en el sistema');
      }

      // Otro error de red (timeout, servidor caído, etc.)
      return ResultadoAuthCI(exito: false, errorRed: true, mensaje: 'Sin conexión al servidor');
    } catch (e) {
      // Manejo de cualquier otra excepción inesperada
      debugPrint('⚠️ Error inesperado: $e');
      return ResultadoAuthCI(exito: false, errorRed: true, mensaje: 'Error inesperado');
    }
  }
}
