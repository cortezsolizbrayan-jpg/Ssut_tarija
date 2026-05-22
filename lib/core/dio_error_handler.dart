import 'package:dio/dio.dart';
import 'package:refactor_template/features/acceso/dominio/errors/login_exceptions.dart';

class DioErrorHandler {
  static Exception handle(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return LoginException(
          'Tiempo de espera agotado. Verifica tu conexión a internet.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return LoginException('Usuario o contraseña incorrectos.');
        } else if (statusCode == 404) {
          return LoginException(
            'Servicio no encontrado. Contacta al administrador.',
          );
        } else if (statusCode == 500) {
          return LoginException('Error del servidor. Intenta más tarde.');
        } else {
          return LoginException(
            'Error del servidor (${statusCode ?? 'desconocido'}). Intenta más tarde.',
          );
        }

      case DioExceptionType.cancel:
        return LoginException('Solicitud cancelada.');

      case DioExceptionType.connectionError:
        return LoginException(
          'Error de conexión. Verifica tu conexión a internet.',
        );

      case DioExceptionType.badCertificate:
        return LoginException(
          'Error de certificado. Contacta al administrador.',
        );

      case DioExceptionType.unknown:
        return LoginException(
          'Error desconocido: ${error.message ?? 'Sin mensaje'}',
        );
    }
  }
}
