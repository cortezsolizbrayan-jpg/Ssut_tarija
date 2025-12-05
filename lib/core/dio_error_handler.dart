import 'package:dio/dio.dart';

class DioErrorHandler {
  static Exception handle(DioException e) {
    // Si hay respuesta del servidor
    if (e.response != null) {
      final status = e.response!.statusCode;
      final data = e.response!.data;

      final serverMessage = data is Map && data['message'] != null
          ? data['message']
          : "Error desconocido del servidor";

      switch (status) {
        case 400:
          return Exception(serverMessage);

        case 401:
          return Exception(serverMessage);

        case 403:
          return Exception(serverMessage);

        case 404:
          return Exception("Recurso no encontrado");

        case 500:
          return Exception("Error interno del servidor");

        default:
          return Exception("Error $status: $serverMessage");
      }
    }
    return Exception("No hay conexión con el servidor");
  }
}
