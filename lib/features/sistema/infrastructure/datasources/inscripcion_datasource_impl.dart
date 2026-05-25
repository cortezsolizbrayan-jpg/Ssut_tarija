import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/inscripcion_datasource.dart';
import 'package:http_parser/http_parser.dart';

/// Implementación del datasource de inscripción
class InscripcionDatasourceImpl implements InscripcionDatasource {
  final Dio dio;

  InscripcionDatasourceImpl({Dio? dio})
      : dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: Environment.apiPreinscripcionUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: {
                  'Accept': '*/*',
                },
              ),
            );

  @override
  Future<Map<String, dynamic>> enviarInscripcion({
    required int idPersona,
    required int idPrograma,
    required Map<String, dynamic> personaExterna,
    required Map<String, dynamic> facturacion,
    File? respaldoCiAnverso,
    File? respaldoCiReverso,
  }) async {
    try {
      // Crear FormData para multipart/form-data
      final formData = FormData();

      // Agregar campos simples
      formData.fields.add(MapEntry('idPersona', idPersona.toString()));
      formData.fields.add(MapEntry('idPrograma', idPrograma.toString()));

      // Agregar personaExterna como campos individuales
      personaExterna.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry('personaExterna[$key]', value.toString()));
        }
      });

      // Agregar facturacion como campos individuales
      facturacion.forEach((key, value) {
        if (value != null) {
          formData.fields.add(MapEntry('facturacion[$key]', value.toString()));
        }
      });

      // Agregar archivos si existen
      if (respaldoCiAnverso != null && await respaldoCiAnverso.exists()) {
        final fileName = respaldoCiAnverso.path.split('/').last;
        formData.files.add(
          MapEntry(
            'respaldoCi[anverso]',
            await MultipartFile.fromFile(
              respaldoCiAnverso.path,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      if (respaldoCiReverso != null && await respaldoCiReverso.exists()) {
        final fileName = respaldoCiReverso.path.split('/').last;
        formData.files.add(
          MapEntry(
            'respaldoCi[reverso]',
            await MultipartFile.fromFile(
              respaldoCiReverso.path,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ),
        );
      }

      if (kDebugMode) {
        print('📤 Enviando inscripción a: ${Environment.apiPreinscripcionUrl}/inscripcion');
        print('📋 Datos: idPersona=$idPersona, idPrograma=$idPrograma');
      }

      // Enviar request
      final response = await dio.post(
        '/inscripcion',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      if (kDebugMode) {
        print('✅ Inscripción enviada exitosamente');
        print('📥 Respuesta: ${response.data}');
      }

      return {
        'success': true,
        'data': response.data,
        'statusCode': response.statusCode,
      };
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ Error DioException en inscripción:');
        print('   Tipo: ${e.type}');
        print('   Mensaje: ${e.message}');
        print('   Response: ${e.response?.data}');
      }

      String errorMessage = 'Error al enviar inscripción';
      
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;
        
        if (statusCode == 400) {
          errorMessage = 'Datos inválidos: ${data['message'] ?? 'Verifica la información'}';
        } else if (statusCode == 404) {
          errorMessage = 'Endpoint no encontrado';
        } else if (statusCode == 500) {
          errorMessage = 'Error en el servidor';
        } else {
          errorMessage = data['message'] ?? 'Error desconocido';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Tiempo de conexión agotado';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tiempo de respuesta agotado';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Error de conexión. Verifica tu internet';
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inesperado en inscripción: $e');
      }
      throw Exception('Error inesperado al enviar inscripción: $e');
    }
  }
}
