import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/domain/entities/requisito_inscripcion.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para validar requisitos de inscripción a programas de posgrado
class ServicioValidacionRequisitos {
  /// Requisitos estándar para Diplomado
  static List<RequisitoInscripcion> get requisitosDiplomado => [
        const RequisitoInscripcion(
          id: 'pago_matricula',
          descripcion:
              'Comprobante de pago de matrícula o de colegiatura (adjuntar al menos uno)',
          esObligatorio: true,
          tipo: TipoRequisito.pago,
          campoDocumento: 'comprobantePago',
        ),
        const RequisitoInscripcion(
          id: 'fotografias',
          descripcion:
              'Cuatro fotografías 4x4 fondo AZUL y Cuatro fotografías 2.5x2.5 con fondo PLOMO, foto estudio en papel mate para Diplomas (traje formal)',
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
  static List<RequisitoInscripcion> obtenerRequisitosPorTipo(String tipoPrograma) {
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
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final participantDocs = await LocalStorageService.getParticipantDocumentsData();
    final requisitos = obtenerRequisitosPorTipo(tipoPrograma);
    final resultados = <ResultadoValidacionRequisito>[];

    for (final requisito in requisitos) {
      final resultado = await _validarRequisito(requisito, prefs, participantDocs);
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
    Map<String, dynamic>? participantDocs,
  ) async {
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
        return _validarComprobantePago(requisito, participantDocs);
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
    final ciLetterPath = _path(participantDocs, 'ci_letter_path') ?? 
                         _path(participantDocs, 'ci_photocopy_pdf_path') ??
                         prefs.getString('ciLetterPath');
    
    if (ciLetterPath != null && ciLetterPath.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Fotocopia de CI disponible',
        fechaValidacion: DateTime.now(),
      );
    }

    // Verificar si tiene anverso y reverso para sugerir generación
    final hasFront = (_path(participantDocs, 'ci_front_path') ?? prefs.getString('ci_front_path')) != null;
    final hasBack = (_path(participantDocs, 'ci_back_path') ?? prefs.getString('ci_back_path')) != null;

    if (hasFront && hasBack) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.pendiente,
        mensaje: 'PIECES_READY: Anverso y reverso capturados. Pulse para integrar en PDF.',
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
    final tituloPath = _path(participantDocs, 'titulo_path') ?? prefs.getString('tituloPath') ?? prefs.getString('titulo_path');
    final prorrogaPath = _path(participantDocs, 'prorroga_path') ?? prefs.getString('prorrogaPath') ?? prefs.getString('prorroga_path');
    final deferDocuments = participantDocs?['defer_documents'] as bool? ?? prefs.getBool('deferDocuments') ?? false;

    // Si tiene título académico
    if (tituloPath != null && tituloPath.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Título académico cargado',
        fechaValidacion: DateTime.now(),
      );
    }

    // Si tiene carta de prórroga
    if (deferDocuments && prorrogaPath != null && prorrogaPath.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.conProrroga,
        mensaje: 'Carta de prórroga generada - Debe presentar título posteriormente',
        fechaValidacion: DateTime.now(),
      );
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Debe cargar su título académico o generar una carta de prórroga',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de carta de inscripción
  Future<ResultadoValidacionRequisito> _validarCartaInscripcion(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    final cartaPath = _path(participantDocs, 'carta_inscripcion_path') ?? prefs.getString('cartaInscripcionPath') ?? prefs.getString('carta_inscripcion_path');
    
    if (cartaPath != null && cartaPath.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Carta de inscripción generada',
        fechaValidacion: DateTime.now(),
      );
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
    final hojaVidaPath = _path(participantDocs, 'hoja_vida_path') ?? prefs.getString('hojaVidaPath') ?? prefs.getString('hoja_vida_path');
    
    if (hojaVidaPath != null && hojaVidaPath.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Hoja de vida cargada',
        fechaValidacion: DateTime.now(),
      );
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
    final path = _path(participantDocs, 'ficha_inscripcion_path') ?? prefs.getString('fichaInscripcionPath') ?? prefs.getString('ficha_inscripcion_path');
    if (path != null && path.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Ficha de inscripción generada',
        fechaValidacion: DateTime.now(),
      );
    }
    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Genere la ficha de inscripción desde la sección Documentos',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida comprobante de pago (matrícula o colegiatura)
  Future<ResultadoValidacionRequisito> _validarComprobantePago(
    RequisitoInscripcion requisito,
    Map<String, dynamic>? participantDocs,
  ) async {
    final matricula = _path(participantDocs, 'comprobante_matricula_path');
    final colegiatura = _path(participantDocs, 'comprobante_colegiatura_path');
    if ((matricula != null && matricula.isNotEmpty) ||
        (colegiatura != null && colegiatura.isNotEmpty)) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Comprobante de pago adjuntado',
        fechaValidacion: DateTime.now(),
      );
    }
    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Adjunte comprobante de pago (matrícula o colegiatura)',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de fotografía
  Future<ResultadoValidacionRequisito> _validarFotografia(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
    Map<String, dynamic>? participantDocs,
  ) async {
    final profilePhoto = _path(participantDocs, 'profile_photo_path') ?? 
                        prefs.getString('profilePhoto') ?? 
                        prefs.getString('profile_image_path');
    
    if (profilePhoto != null && profilePhoto.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Fotografía de perfil disponible',
        fechaValidacion: DateTime.now(),
      );
    }

    return ResultadoValidacionRequisito(
      requisito: requisito,
      estado: EstadoRequisito.pendiente,
      mensaje: 'Debe cargar su fotografía de perfil',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Obtiene un resumen de los documentos faltantes
  Future<List<String>> obtenerDocumentosFaltantes(String tipoPrograma) async {
    final resultado = await validarRequisitos(tipoPrograma: tipoPrograma);
    
    return resultado.requisitosObligatoriosPendientes
        .map((r) => r.requisito.descripcion)
        .toList();
  }

  /// Verifica si el usuario puede inscribirse (todos los requisitos obligatorios cumplidos)
  Future<bool> puedeInscribirse(String tipoPrograma) async {
    final resultado = await validarRequisitos(tipoPrograma: tipoPrograma);
    return resultado.todosLosRequisitosObligatoriosCumplidos;
  }
}
