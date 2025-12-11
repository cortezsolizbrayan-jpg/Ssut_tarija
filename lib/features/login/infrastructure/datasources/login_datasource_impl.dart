import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/dio_error_handler.dart';
import 'package:refactor_template/features/login/domain/entities/login.dart';
import 'package:refactor_template/features/login/infrastructure/datasources/login_datasource.dart';
import 'package:refactor_template/features/login/infrastructure/models/login_model.dart';

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
