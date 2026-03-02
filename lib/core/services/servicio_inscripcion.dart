import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/inscripcion_datasource_impl.dart';

/// Servicio para gestionar el proceso completo de inscripción
class ServicioInscripcion {
  final InscripcionDatasourceImpl _datasource = InscripcionDatasourceImpl();

  /// Envía la inscripción completa al servidor
  /// Recopila todos los datos del usuario desde LocalStorage y los envía
  Future<Map<String, dynamic>> enviarInscripcionCompleta({
    required int idPrograma,
  }) async {
    try {
      // 1. Obtener datos personales
      final personalData = await LocalStorageService.getPersonalData();
      if (personalData == null || personalData.isEmpty) {
        throw Exception('No hay datos personales guardados');
      }

      // 2. Obtener datos de sesión (para idPersona)
      final sessionData = await LocalStorageService.getSessionData();
      final idPersona = sessionData?['idPersona'] as int? ?? 
                        personalData['idPersona'] as int? ?? 
                        0;

      if (idPersona == 0) {
        throw Exception('ID de persona no encontrado');
      }

      // 3. Construir objeto personaExterna
      final personaExterna = {
        'ci': personalData['numeroCI']?.toString() ?? '',
        'expedido': personalData['expedidoEn']?.toString() ?? 'LP',
        'nombre': personalData['nombre']?.toString() ?? '',
        'paterno': personalData['apPaterno']?.toString() ?? '',
        'materno': personalData['apMaterno']?.toString() ?? '',
        'genero': personalData['genero']?.toString() ?? 'M',
        'fechaNacimiento': _formatearFecha(personalData['fechaNacimiento']),
        'celular': personalData['celular']?.toString() ?? '',
        'correo': personalData['correo']?.toString() ?? '',
        'direccion': personalData['direccion']?.toString() ?? '',
        'ciudad': personalData['ciudad']?.toString() ?? 'LA PAZ - EL ALTO',
      };

      // 4. Obtener datos de facturación
      final facturacionData = await LocalStorageService.getFacturacionData();
      
      // 5. Construir objeto facturacion
      final facturacion = {
        'idTributario': facturacionData?['nit']?.toString() ?? '1',
        'tipoTributario': facturacionData?['tipoTributario']?.toString() ?? '1',
        'tipoDocumento': facturacionData?['tipoDocumento']?.toString() ?? '5',
        'pais': facturacionData?['pais']?.toString() ?? '22',
        'nroDocumento': facturacionData?['nroDocumento']?.toString() ?? '8372500',
        'complemento': facturacionData?['complemento']?.toString() ?? '',
        'razonSocial': facturacionData?['razonSocial']?.toString() ?? 
                       '${personalData['nombre']} ${personalData['apPaterno']} ${personalData['apMaterno']}'.trim(),
        'celular': facturacionData?['celular']?.toString() ?? 
                   personalData['celular']?.toString() ?? '',
        'correo': facturacionData?['correo']?.toString() ?? 
                  personalData['correo']?.toString() ?? '',
      };

      // 6. Obtener archivos de CI
      final participantDocs = await LocalStorageService.getParticipantDocumentsData();
      File? ciAnverso;
      File? ciReverso;

      final ciAnversoPath = participantDocs?['ci_front_path'] as String?;
      final ciReversoPath = participantDocs?['ci_back_path'] as String?;

      if (ciAnversoPath != null && ciAnversoPath.isNotEmpty) {
        ciAnverso = File(ciAnversoPath);
        if (!await ciAnverso.exists()) {
          ciAnverso = null;
        }
      }

      if (ciReversoPath != null && ciReversoPath.isNotEmpty) {
        ciReverso = File(ciReversoPath);
        if (!await ciReverso.exists()) {
          ciReverso = null;
        }
      }

      // 7. Validar datos mínimos requeridos
      _validarDatosRequeridos(personaExterna, facturacion);

      if (kDebugMode) {
        print('📋 Preparando inscripción:');
        print('   idPersona: $idPersona');
        print('   idPrograma: $idPrograma');
        print('   CI: ${personaExterna['ci']}');
        print('   Nombre: ${personaExterna['nombre']} ${personaExterna['paterno']}');
        print('   Correo: ${personaExterna['correo']}');
        print('   Facturación: ${facturacion['razonSocial']}');
        print('   CI Anverso: ${ciAnverso != null ? 'Sí' : 'No'}');
        print('   CI Reverso: ${ciReverso != null ? 'Sí' : 'No'}');
      }

      // 8. Enviar inscripción
      final resultado = await _datasource.enviarInscripcion(
        idPersona: idPersona,
        idPrograma: idPrograma,
        personaExterna: personaExterna,
        facturacion: facturacion,
        respaldoCiAnverso: ciAnverso,
        respaldoCiReverso: ciReverso,
      );

      if (kDebugMode) {
        print('✅ Inscripción enviada exitosamente');
      }

      return resultado;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en enviarInscripcionCompleta: $e');
      }
      rethrow;
    }
  }

  /// Valida que los datos requeridos estén presentes
  void _validarDatosRequeridos(
    Map<String, dynamic> personaExterna,
    Map<String, dynamic> facturacion,
  ) {
    final errores = <String>[];

    // Validar personaExterna
    if (personaExterna['ci']?.toString().isEmpty ?? true) {
      errores.add('Número de CI');
    }
    if (personaExterna['nombre']?.toString().isEmpty ?? true) {
      errores.add('Nombre');
    }
    if (personaExterna['paterno']?.toString().isEmpty ?? true) {
      errores.add('Apellido paterno');
    }
    if (personaExterna['celular']?.toString().isEmpty ?? true) {
      errores.add('Celular');
    }
    if (personaExterna['correo']?.toString().isEmpty ?? true) {
      errores.add('Correo electrónico');
    }

    // Validar facturacion
    if (facturacion['razonSocial']?.toString().isEmpty ?? true) {
      errores.add('Razón social');
    }
    if (facturacion['nroDocumento']?.toString().isEmpty ?? true) {
      errores.add('Número de documento de facturación');
    }

    if (errores.isNotEmpty) {
      throw Exception(
        'Faltan datos requeridos: ${errores.join(', ')}. '
        'Por favor completa tu perfil antes de inscribirte.',
      );
    }
  }

  /// Formatea una fecha al formato esperado por el servidor (YYYY-MM-DD)
  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '';
    
    try {
      if (fecha is DateTime) {
        return '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';
      }
      
      if (fecha is String) {
        // Si ya está en formato correcto, retornar
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) {
          return fecha;
        }
        
        // Intentar parsear y reformatear
        final parsedDate = DateTime.tryParse(fecha);
        if (parsedDate != null) {
          return '${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}';
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error formateando fecha: $e');
      }
    }
    
    return '';
  }

  /// Verifica si el usuario tiene todos los datos necesarios para inscribirse
  Future<bool> tieneDatosCompletos() async {
    try {
      final personalData = await LocalStorageService.getPersonalData();
      if (personalData == null || personalData.isEmpty) {
        return false;
      }

      // Verificar campos esenciales
      final camposRequeridos = [
        'numeroCI',
        'nombre',
        'apPaterno',
        'celular',
        'correo',
      ];

      for (final campo in camposRequeridos) {
        final valor = personalData[campo];
        if (valor == null || valor.toString().trim().isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error verificando datos completos: $e');
      }
      return false;
    }
  }

  /// Obtiene un resumen de los datos que se enviarán
  Future<Map<String, dynamic>> obtenerResumenInscripcion({
    required int idPrograma,
  }) async {
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final facturacionData = await LocalStorageService.getFacturacionData();
      final participantDocs = await LocalStorageService.getParticipantDocumentsData();

      return {
        'nombreCompleto': '${personalData?['nombre']} ${personalData?['apPaterno']} ${personalData?['apMaterno']}'.trim(),
        'ci': personalData?['numeroCI']?.toString() ?? '',
        'correo': personalData?['correo']?.toString() ?? '',
        'celular': personalData?['celular']?.toString() ?? '',
        'razonSocial': facturacionData?['razonSocial']?.toString() ?? '',
        'nit': facturacionData?['nit']?.toString() ?? '',
        'tieneCiAnverso': participantDocs?['ci_front_path'] != null,
        'tieneCiReverso': participantDocs?['ci_back_path'] != null,
        'idPrograma': idPrograma,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error obteniendo resumen: $e');
      }
      return {};
    }
  }
}
