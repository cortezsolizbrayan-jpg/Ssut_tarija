import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/inscripcion_datasource_impl.dart';

/// Servicio para gestionar el proceso completo de inscripción.
/// Optimizado: carga de datos en paralelo con Future.wait.
class ServicioInscripcion {
  final InscripcionDatasourceImpl _datasource = InscripcionDatasourceImpl();

  /// Envía la inscripción completa al servidor.
  /// Carga todos los datos en paralelo para reducir el tiempo de espera.
  Future<Map<String, dynamic>> enviarInscripcionCompleta({
    required int idPrograma,
  }) async {
    try {
      // ── Cargar todos los datos en PARALELO ────────────────────────────────
      final results = await Future.wait([
        LocalStorageService.getPersonalData(),
        LocalStorageService.getSessionData(),
        LocalStorageService.getFacturacionData(),
        LocalStorageService.getParticipantDocumentsData(),
      ]);

      final personalData = results[0] as Map<String, dynamic>?;
      final sessionData = results[1] as Map<String, dynamic>?;
      final facturacionData = results[2] as Map<String, dynamic>?;
      final participantDocs = results[3] as Map<String, dynamic>?;

      if (personalData == null || personalData.isEmpty) {
        throw Exception('No hay datos personales guardados');
      }

      // ── ID de persona ─────────────────────────────────────────────────────
      final idPersona =
          sessionData?['idPersona'] as int? ??
          personalData['idPersona'] as int? ??
          0;

      if (idPersona == 0) {
        throw Exception('ID de persona no encontrado');
      }

      // ── Persona externa ───────────────────────────────────────────────────
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

      // ── Facturación ───────────────────────────────────────────────────────
      final nombreCompleto =
          '${personalData['nombre']} ${personalData['apPaterno']} ${personalData['apMaterno']}'
              .trim();

      final facturacion = {
        'idTributario': facturacionData?['nit']?.toString() ?? '1',
        'tipoTributario': facturacionData?['tipoTributario']?.toString() ?? '1',
        'tipoDocumento': facturacionData?['tipoDocumento']?.toString() ?? '5',
        'pais': facturacionData?['pais']?.toString() ?? '22',
        'nroDocumento':
            facturacionData?['nroDocumento']?.toString() ?? '8372500',
        'complemento': facturacionData?['complemento']?.toString() ?? '',
        'razonSocial':
            facturacionData?['razonSocial']?.toString() ?? nombreCompleto,
        'celular':
            facturacionData?['celular']?.toString() ??
            personalData['celular']?.toString() ??
            '',
        'correo':
            facturacionData?['correo']?.toString() ??
            personalData['correo']?.toString() ??
            '',
      };

      // ── Archivos CI (verificar existencia en paralelo) ────────────────────
      final ciAnversoPath = participantDocs?['ci_front_path'] as String?;
      final ciReversoPath = participantDocs?['ci_back_path'] as String?;

      final fileChecks = await Future.wait([
        _resolveFile(ciAnversoPath),
        _resolveFile(ciReversoPath),
      ]);

      final ciAnverso = fileChecks[0];
      final ciReverso = fileChecks[1];

      // ── Validar datos mínimos ─────────────────────────────────────────────
      _validarDatosRequeridos(personaExterna, facturacion);

      if (kDebugMode) {
        debugPrint(
          '📋 Inscripción: idPersona=$idPersona, idPrograma=$idPrograma',
        );
        debugPrint(
          '   CI: ${personaExterna['ci']} | ${personaExterna['nombre']} ${personaExterna['paterno']}',
        );
        debugPrint(
          '   CI Anverso: ${ciAnverso != null ? '✅' : '❌'} | Reverso: ${ciReverso != null ? '✅' : '❌'}',
        );
      }

      // ── Enviar ────────────────────────────────────────────────────────────
      final resultado = await _datasource.enviarInscripcion(
        idPersona: idPersona,
        idPrograma: idPrograma,
        personaExterna: personaExterna,
        facturacion: facturacion,
        respaldoCiAnverso: ciAnverso,
        respaldoCiReverso: ciReverso,
      );

      if (kDebugMode) debugPrint('✅ Inscripción enviada exitosamente');
      return resultado;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error en enviarInscripcionCompleta: $e');
      rethrow;
    }
  }

  /// Resuelve un path a File solo si existe, null en caso contrario.
  Future<File?> _resolveFile(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    return await file.exists() ? file : null;
  }

  /// Valida que los datos requeridos estén presentes.
  void _validarDatosRequeridos(
    Map<String, dynamic> personaExterna,
    Map<String, dynamic> facturacion,
  ) {
    final errores = <String>[];

    void check(Map<String, dynamic> map, String key, String label) {
      if (map[key]?.toString().trim().isEmpty ?? true) errores.add(label);
    }

    check(personaExterna, 'ci', 'Número de CI');
    check(personaExterna, 'nombre', 'Nombre');
    check(personaExterna, 'paterno', 'Apellido paterno');
    check(personaExterna, 'celular', 'Celular');
    check(personaExterna, 'correo', 'Correo electrónico');
    check(facturacion, 'razonSocial', 'Razón social');
    check(facturacion, 'nroDocumento', 'Número de documento de facturación');

    if (errores.isNotEmpty) {
      throw Exception(
        'Faltan datos requeridos: ${errores.join(', ')}. '
        'Por favor completa tu perfil antes de inscribirte.',
      );
    }
  }

  /// Formatea una fecha al formato YYYY-MM-DD esperado por el servidor.
  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '';
    try {
      if (fecha is DateTime) {
        return '${fecha.year}-${_pad(fecha.month)}-${_pad(fecha.day)}';
      }
      if (fecha is String) {
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(fecha)) return fecha;
        final parsed = DateTime.tryParse(fecha);
        if (parsed != null) {
          return '${parsed.year}-${_pad(parsed.month)}-${_pad(parsed.day)}';
        }
      }
    } catch (_) {}
    return '';
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// Verifica si el usuario tiene todos los datos necesarios para inscribirse.
  Future<bool> tieneDatosCompletos() async {
    try {
      final personalData = await LocalStorageService.getPersonalData();
      if (personalData == null || personalData.isEmpty) return false;

      const camposRequeridos = [
        'numeroCI',
        'nombre',
        'apPaterno',
        'celular',
        'correo',
      ];
      return camposRequeridos.every(
        (campo) => personalData[campo]?.toString().trim().isNotEmpty ?? false,
      );
    } catch (_) {
      return false;
    }
  }

  /// Obtiene un resumen de los datos que se enviarán.
  Future<Map<String, dynamic>> obtenerResumenInscripcion({
    required int idPrograma,
  }) async {
    try {
      final results = await Future.wait([
        LocalStorageService.getPersonalData(),
        LocalStorageService.getFacturacionData(),
        LocalStorageService.getParticipantDocumentsData(),
      ]);

      final personalData = results[0] as Map<String, dynamic>?;
      final facturacionData = results[1] as Map<String, dynamic>?;
      final participantDocs = results[2] as Map<String, dynamic>?;

      return {
        'nombreCompleto':
            '${personalData?['nombre']} ${personalData?['apPaterno']} ${personalData?['apMaterno']}'
                .trim(),
        'ci': personalData?['numeroCI']?.toString() ?? '',
        'correo': personalData?['correo']?.toString() ?? '',
        'celular': personalData?['celular']?.toString() ?? '',
        'razonSocial': facturacionData?['razonSocial']?.toString() ?? '',
        'nit': facturacionData?['nit']?.toString() ?? '',
        'tieneCiAnverso': participantDocs?['ci_front_path'] != null,
        'tieneCiReverso': participantDocs?['ci_back_path'] != null,
        'idPrograma': idPrograma,
      };
    } catch (_) {
      return {};
    }
  }
}
