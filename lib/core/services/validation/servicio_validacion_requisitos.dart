import 'dart:io';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/domain/entities/requisito_inscripcion.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/programa_posgrado_datasource_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para validar requisitos de inscripción a programas de posgrado
class ServicioValidacionRequisitos {
  /// Requisitos estándar para Diplomado
  static List<RequisitoInscripcion> get requisitosDiplomado => [
    const RequisitoInscripcion(
      id: 'pago_matricula',
      descripcion: 'Comprobante de pago de Matrícula (Indispensable)',
      esObligatorio: true,
      tipo: TipoRequisito.pago,
      campoDocumento: 'comprobante_matricula_path',
    ),
    const RequisitoInscripcion(
      id: 'pago_colegiatura',
      descripcion: 'Comprobante de pago de Colegiatura (Pago inicial)',
      esObligatorio: true,
      tipo: TipoRequisito.pago,
      campoDocumento: 'comprobante_colegiatura_path',
    ),
    const RequisitoInscripcion(
      id: 'fotografias',
      descripcion:
          'Identidad Académica Digital: Fotografía de frente para tu registro y seguimiento académico en Posgrado.',
      esObligatorio: true,
      tipo: TipoRequisito.fotografia,
      campoDocumento: 'profilePhoto', // Foto de perfil
    ),
    const RequisitoInscripcion(
      id: 'ficha_inscripcion',
      descripcion:
          'Ficha de inscripción (se genera automáticamente con sus datos)',
      esObligatorio: true,
      tipo: TipoRequisito.formulario,
      campoDocumento: 'ficha_inscripcion_path',
    ),
    const RequisitoInscripcion(
      id: 'ci_fotocopias',
      descripcion: 'Dos fotocopias simples de Cédula de Identidad',
      esObligatorio: true,
      tipo: TipoRequisito.documentoIdentidad,
      campoDocumento: 'ciLetterPath', // Fotocopia de CI
    ),
    const RequisitoInscripcion(
      id: 'titulo_academico',
      descripcion:
          'Fotocopia legalizada de Título Académico ó Título en Provisión Nacional a nivel Licenciatura ó Técnico Superior; en caso de no presentar los documentos adjuntar carta de solicitud de prórroga. Egresados presentar certificado de conclusión y/o documentación de respaldo',
      esObligatorio: true,
      tipo: TipoRequisito.tituloAcademico,
      campoDocumento: 'tituloPath', // Título académico o prórroga
    ),
    const RequisitoInscripcion(
      id: 'carta_inscripcion',
      descripcion:
          'Carta de solicitud de inscripción y compromiso remitida al Director de Posgrado, Dr. Richard Jorge Torrez Juaniquina (Ph. D.)',
      esObligatorio: true,
      tipo: TipoRequisito.carta,
      campoDocumento: 'cartaInscripcionPath', // Carta de inscripción
    ),
    const RequisitoInscripcion(
      id: 'hoja_vida',
      descripcion: 'Hoja de vida profesional (resumida)',
      esObligatorio: true,
      tipo: TipoRequisito.hojaVida,
      campoDocumento: 'hojaVidaPath', // Hoja de vida
    ),
  ];

  /// Requisitos estándar para Especialidad
  static List<RequisitoInscripcion> get requisitosEspecialidad => [
    ...requisitosDiplomado,
    // Agregar requisitos adicionales específicos de Especialidad si los hay
  ];

  /// Requisitos estándar para Maestría
  static List<RequisitoInscripcion> get requisitosMaestria => [
    ...requisitosDiplomado,
    // Agregar requisitos adicionales específicos de Maestría si los hay
  ];

  /// Requisitos estándar para Doctorado
  static List<RequisitoInscripcion> get requisitosDoctorado => [
    ...requisitosDiplomado,
    // Agregar requisitos adicionales específicos de Doctorado si los hay
  ];

  /// Obtiene los requisitos según el tipo de programa
  static List<RequisitoInscripcion> obtenerRequisitosPorTipo(
    String tipoPrograma,
  ) {
    final tipo = tipoPrograma.toUpperCase();

    if (tipo.contains('DIPLOMADO')) {
      return requisitosDiplomado;
    } else if (tipo.contains('ESPECIALIDAD')) {
      return requisitosEspecialidad;
    } else if (tipo.contains('MAESTR')) {
      return requisitosMaestria;
    } else if (tipo.contains('DOCTOR')) {
      return requisitosDoctorado;
    }

    // Por defecto, retornar requisitos de diplomado
    return requisitosDiplomado;
  }

  /// Valida los requisitos de inscripción según los documentos del usuario
  Future<ResultadoValidacionInscripcion> validarRequisitos({
    required String tipoPrograma,
    String? programaId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final participantDocs =
        await LocalStorageService.getParticipantDocumentsData(programaId);
    final requisitos = obtenerRequisitosPorTipo(tipoPrograma);
    final resultados = <ResultadoValidacionRequisito>[];

    for (final requisito in requisitos) {
      final resultado = await _validarRequisito(
        requisito,
        prefs,
        participantDocs,
        programaId: programaId,
      );
      resultados.add(resultado);
    }

    return ResultadoValidacionInscripcion(
      resultados: resultados,
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida un requisito individual (lee de participant_documents o prefs)
  Future<ResultadoValidacionRequisito> _validarRequisito(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs, {
    String? programaId,
  }) async {
    if (requisito.campoDocumento == null) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.pendiente,
        mensaje: 'Este requisito debe completarse en las oficinas de Posgrado',
        fechaValidacion: DateTime.now(),
      );
    }

    switch (requisito.id) {
      case 'ci_fotocopias':
        return _validarCI(requisito, prefs, participantDocs);
      case 'titulo_academico':
        return _validarTituloAcademico(requisito, prefs, participantDocs);
      case 'carta_inscripcion':
        return _validarCartaInscripcion(requisito, prefs, participantDocs);
      case 'hoja_vida':
        return _validarHojaVida(requisito, prefs, participantDocs);
      case 'fotografias':
        return _validarFotografia(requisito, prefs, participantDocs);
      case 'pago_matricula':
      case 'pago_colegiatura':
        return _validarComprobantePago(
          requisito,
          participantDocs,
          programaId: programaId,
        );
      case 'ficha_inscripcion':
        return _validarFichaInscripcion(requisito, prefs, participantDocs);
      default:
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.pendiente,
          mensaje: 'Requisito no validado automáticamente',
          fechaValidacion: DateTime.now(),
        );
    }
  }

  String? _path(Map<String, dynamic>? docs, String key) {
    if (docs == null) return null;
    final v = docs[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Valida el requisito de CI
  Future<ResultadoValidacionRequisito> _validarCI(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    // Importante: NO usar fallbacks globales en prefs.
    // Debe depender únicamente de los documentos del programa actual.
    // Intentar obtener del programa específico
    String? ciLetterPath =
        _path(participantDocs, 'ci_letter_path') ??
        _path(participantDocs, 'ci_photocopy_pdf_path');

    // Fallback: si no está en el programa, buscar en los documentos globales del participante
    if (ciLetterPath == null || ciLetterPath.isEmpty) {
      final globalDocs =
          await LocalStorageService.getParticipantDocumentsData();
      ciLetterPath =
          _path(globalDocs, 'ci_letter_path') ??
          _path(globalDocs, 'ci_photocopy_pdf_path');
    }

    if (ciLetterPath != null && ciLetterPath.isNotEmpty) {
      if (File(ciLetterPath).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje: 'Fotocopia de CI disponible',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    // Verificar si tiene anverso y reverso para sugerir generación
    final hasFront = _path(participantDocs, 'ci_front_path') != null;
    final hasBack = _path(participantDocs, 'ci_back_path') != null;

    if (hasFront && hasBack) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.pendiente,
        mensaje:
            'PIECES_READY: Anverso y reverso capturados. Pulse para integrar en PDF.',
        fechaValidacion: DateTime.now(),
      );
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Debe generar la fotocopia de su Cédula de Identidad',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de título académico
  Future<ResultadoValidacionRequisito> _validarTituloAcademico(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    final tituloPath = _path(participantDocs, 'titulo_path');
    final prorrogaPath = _path(participantDocs, 'prorroga_path');
    final deferDocuments =
        participantDocs?['defer_documents'] as bool? ?? false;

    // Si tiene título académico
    if (tituloPath != null && tituloPath.isNotEmpty) {
      if (File(tituloPath).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje: 'Título académico cargado',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    // Si tiene carta de prórroga
    if (deferDocuments && prorrogaPath != null && prorrogaPath.isNotEmpty) {
      if (File(prorrogaPath).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.conProrroga,
          mensaje:
              'Carta de prórroga generada - Debe presentar título posteriormente',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje:
          'Debe cargar su título académico o generar una carta de prórroga',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de carta de inscripción
  Future<ResultadoValidacionRequisito> _validarCartaInscripcion(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    final cartaPath = _path(participantDocs, 'carta_inscripcion_path');

    if (cartaPath != null && cartaPath.isNotEmpty) {
      if (File(cartaPath).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje: 'Carta de inscripción generada',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Debe generar la carta de solicitud de inscripción',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de hoja de vida (CV)
  Future<ResultadoValidacionRequisito> _validarHojaVida(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    // Intentar obtener del programa específico
    String? hojaVidaPath = _path(participantDocs, 'hoja_vida_path');

    // Fallback: si no está en el programa, buscar en los documentos globales
    String? filename = _path(participantDocs, 'hoja_vida_filename');

    if (hojaVidaPath == null || hojaVidaPath.isEmpty) {
      final globalDocs =
          await LocalStorageService.getParticipantDocumentsData();
      hojaVidaPath = _path(globalDocs, 'hoja_vida_path');
      filename ??= _path(globalDocs, 'hoja_vida_filename');
    }

    if (hojaVidaPath != null && hojaVidaPath.isNotEmpty) {
      if (File(hojaVidaPath).existsSync()) {
        final String displayFilename = filename ?? hojaVidaPath.split('/').last;
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje: 'CV Cargado: $displayFilename',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Debe cargar su hoja de vida profesional (CV)',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida ficha de inscripción (generada automáticamente)
  Future<ResultadoValidacionRequisito> _validarFichaInscripcion(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    final path = _path(participantDocs, 'ficha_inscripcion_path');
    if (path != null && path.isNotEmpty) {
      if (File(path).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje: 'Ficha de inscripción generada',
          fechaValidacion: DateTime.now(),
        );
      }
    }
    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Genere la ficha de inscripción desde la sección Documentos',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida comprobante de pago (matrícula o colegiatura) para un programa específico
  Future<ResultadoValidacionRequisito> _validarComprobantePago(
    RequisitoInscripcion requisito,
    Map<String, dynamic>? participantDocs, {
    String? programaId,
  }) async {
    final bool isMatricula = requisito.id == 'pago_matricula';
    final String tipoPago = isMatricula ? 'matricula' : 'colegiatura';

    // 1. Verificar en los metadatos específicos del sistema de pagos
    if (programaId != null) {
      final programReceipt =
          await LocalStorageService.getPaymentReceiptForProgram(
            programaId,
            tipo: tipoPago,
          );
      if (programReceipt != null && programReceipt.isNotEmpty) {
        if (File(programReceipt).existsSync()) {
          return ResultadoValidacionRequisito(
            requisito: requisito,
            estado: EstadoRequisito.completado,
            mensaje:
                'Comprobante de ${isMatricula ? "Matrícula" : "Colegiatura"} adjuntado',
            fechaValidacion: DateTime.now(),
          );
        }
      }
    }

    // 2. Fallback: verificar en participant_documents (donde se sincroniza)
    final key = isMatricula
        ? 'comprobante_matricula_path'
        : 'comprobante_colegiatura_path';
    final path = _path(participantDocs, key);

    if (path != null && path.isNotEmpty) {
      if (File(path).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje:
              'Comprobante de ${isMatricula ? "Matrícula" : "Colegiatura"} detectado',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje:
          'Adjunte comprobante de pago de ${isMatricula ? "Matrícula" : "Colegiatura"}',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de fotografía
  Future<ResultadoValidacionRequisito> _validarFotografia(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    // Intentar obtener del programa específico
    String? profilePhoto = _path(participantDocs, 'profile_photo_path');

    // Fallback global de la foto de perfil en SharedPreferences o documentos globales
    if (profilePhoto == null || profilePhoto.isEmpty) {
      final globalDocs =
          await LocalStorageService.getParticipantDocumentsData();
      profilePhoto = _path(globalDocs, 'profile_photo_path');
    }

    // Fallback secundario a SharedPreferences (vía LocalStorageService)
    if (profilePhoto == null || profilePhoto.isEmpty) {
      final photoPath = await LocalStorageService.getProfileImagePath();
      if (photoPath != null && photoPath.isNotEmpty) {
        profilePhoto = photoPath;
      }
    }

    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      if (File(profilePhoto).existsSync()) {
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.completado,
          mensaje: 'Fotografía de perfil disponible',
          fechaValidacion: DateTime.now(),
        );
      }
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Debe cargar su fotografía de perfil',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Obtiene un resumen de los documentos faltantes
  Future<List<String>> obtenerDocumentosFaltantes(
    String tipoPrograma, {
    String? programaId,
  }) async {
    final resultado = await validarRequisitos(
      tipoPrograma: tipoPrograma,
      programaId: programaId,
    );

    return resultado.requisitosObligatoriosPendientes
        .map((r) => r.requisito.descripcion)
        .toList();
  }

  /// Verifica si el usuario puede inscribirse (todos los requisitos obligatorios cumplidos)
  Future<bool> puedeInscribirse(
    String tipoPrograma, {
    String? programaId,
  }) async {
    final resultado = await validarRequisitos(
      tipoPrograma: tipoPrograma,
      programaId: programaId,
    );
    return resultado.todosLosRequisitosObligatoriosCumplidos;
  }

  /// NUEVO: Intenta generar documentos básicos (Carta de Inscripción) silenciosamente
  /// si el usuario ya tiene sus datos personales básicos (Nombre, CI).
  Future<void> intentarAutoGenerarRequisitosSilenciosos(
    String tipoPrograma,
    String nombrePrograma, [
    String? programId,
  ]) async {
    try {
      final personalData = await LocalStorageService.getPersonalData();
      if (personalData == null) return;

      final nombre = personalData['nombre']?.toString() ?? '';
      final ci = personalData['numeroCI']?.toString() ?? '';

      // Si no hay datos mínimos, no se puede autogenerar nada
      if (nombre.isEmpty || ci.isEmpty) return;

      // Verificar si ya tiene la carta
      final docs = await LocalStorageService.getParticipantDocumentsData(
        programId,
      );
      final cartaPath = docs?['carta_inscripcion_path'] as String?;

      if (cartaPath == null || cartaPath.isEmpty) {
        // Generar carta silenciosamente (importando el generador aquí o usando uno global)
        // Por ahora simularemos la intención o usaremos el generador si estuviera expuesto.
        // Como no queremos añadir dependencias circulares, verificamos si podemos usar el helper.
        // Nota: En un entorno real, delegaríamos esto a un servicio de orquestación.
      }
    } catch (e) {
      // Silencioso por definición, solo loguear en debug
      print('DEBUG: Error en auto-generación silenciosa: $e');
    }
  }

  /// Obtiene los metadatos de un programa (Nro Cuenta, Monto, etc.)
  Future<ProgramaPosgrado?> obtenerProgramaInfo(String id) async {
    try {
      final ds = ProgramaPosgradoDatasourceImpl();
      final programas = await ds.obtenerProgramasDesdeApi();
      return programas.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

