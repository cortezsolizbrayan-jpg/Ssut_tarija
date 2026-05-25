import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/dio_error_handler.dart';
import 'package:refactor_template/core/services/storage/servicio_base_datos_local.dart';
import 'package:refactor_template/features/acceso/dominio/entities/login.dart';
import 'package:refactor_template/features/acceso/infraestructura/datasources/login_datasource.dart';
import 'package:refactor_template/features/acceso/infraestructura/models/login_model.dart';

class LoginDatasourceImpl implements LoginDatasource {
  late final Dio dio;

  LoginDatasourceImpl() {
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

    // Interceptor para debug en web
    if (kDebugMode && kIsWeb) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, error: true),
      );
    }
  }

  @override
  Future<Login> login({
    required String nombreUsuario,
    required String claveUsuario,
  }) async {
    // ESTRATEGIA 1: Intentar autenticar con BD local primero
    try {
      final localUser = await LocalDatabaseService.authenticateUser(
        nombreUsuario,
        claveUsuario,
      );
      
      if (localUser != null) {
        if (kDebugMode) {
          print('✅ Login exitoso con BD local para CI: $nombreUsuario');
        }
        
        // Convertir usuario local al formato Login
        return LoginModel.fromJson({
          'success': true,
          'message': 'Login exitoso (BD Local)',
          'token': 'local_token_${nombreUsuario}_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'ci': localUser['ci'],
            'nombres': localUser['nombres'],
            'apellidos': localUser['apellidos'],
            'email': localUser['email'] ?? '',
            'telefono': localUser['telefono'] ?? '',
          },
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error en autenticación local: $e');
      }
      // Continuar con API si falla la BD local
    }

    // ESTRATEGIA 2: Si no está en BD local, intentar con el API
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'nombre_usuario': nombreUsuario, 'clave_usuario': claveUsuario},
        options: Options(
          responseType: ResponseType.json,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      return LoginModel.fromJson(response.data);
    } on DioException catch (e) {
      if (kDebugMode) {
        print('=== Error DioException ===');
        print('Type: ${e.type}');
        print('Message: ${e.message}');
        print('Error: ${e.error}');
        print('Response: ${e.response?.data}');
        print('Status: ${e.response?.statusCode}');
        print('Request Path: ${e.requestOptions.path}');
        print('Request Base URL: ${e.requestOptions.baseUrl}');
        if (kIsWeb) {
          print(' Ejecutando en WEB - Puede ser un problema de CORS');
          print(' Solución: Ejecuta Chrome con --disable-web-security');
        }
        print('========================');
      }
      throw DioErrorHandler.handle(e);
    } catch (e) {
      if (kDebugMode) {
        print('Error inesperado en login: $e');
      }
      throw Exception('Error en el datasource al iniciar sesión: $e');
    }
  }
}

