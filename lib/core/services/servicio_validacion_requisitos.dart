import 'package:shared_preferences/shared_preferences.dart';
import 'package:refactor_template/features/sistema/domain/entities/requisito_inscripcion.dart';

/// Servicio para validar requisitos de inscripción a programas de posgrado
class ServicioValidacionRequisitos {
  /// Requisitos estándar para Diplomado
  static List<RequisitoInscripcion> get requisitosDiplomado => [
        const RequisitoInscripcion(
          id: 'pago_matricula',
          descripcion:
              'Boletas originales de depósito bancario de matrícula y cuota inicial, más 4 fotocopias de cada uno (pagos separados)',
          esObligatorio: true,
          tipo: TipoRequisito.pago,
          campoDocumento: null, // Se maneja fuera del sistema de documentos
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
          id: 'formularios',
          descripcion:
              'Hoja de Inscripción y Formulario de Matriculación debidamente llenados (Recabar de oficinas de Posgrado UPEA)',
          esObligatorio: true,
          tipo: TipoRequisito.formulario,
          campoDocumento: null, // Se maneja en oficinas
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
    final requisitos = obtenerRequisitosPorTipo(tipoPrograma);
    final resultados = <ResultadoValidacionRequisito>[];

    for (final requisito in requisitos) {
      final resultado = await _validarRequisito(requisito, prefs);
      resultados.add(resultado);
    }

    return ResultadoValidacionInscripcion(
      resultados: resultados,
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida un requisito individual
  Future<ResultadoValidacionRequisito> _validarRequisito(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
  ) async {
    // Si no tiene campo de documento asociado, se considera pendiente
    // (debe completarse manualmente fuera del sistema)
    if (requisito.campoDocumento == null) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.pendiente,
        mensaje: 'Este requisito debe completarse en las oficinas de Posgrado',
        fechaValidacion: DateTime.now(),
      );
    }

    // Validar según el tipo de requisito
    switch (requisito.id) {
      case 'ci_fotocopias':
        return _validarCI(requisito, prefs);
      
      case 'titulo_academico':
        return _validarTituloAcademico(requisito, prefs);
      
      case 'carta_inscripcion':
        return _validarCartaInscripcion(requisito, prefs);
      
      case 'hoja_vida':
        return _validarHojaVida(requisito, prefs);
      
      case 'fotografias':
        return _validarFotografia(requisito, prefs);
      
      default:
        return ResultadoValidacionRequisito(
          requisito: requisito,
          estado: EstadoRequisito.pendiente,
          mensaje: 'Requisito no validado automáticamente',
          fechaValidacion: DateTime.now(),
        );
    }
  }

  /// Valida el requisito de CI
  Future<ResultadoValidacionRequisito> _validarCI(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
  ) async {
    final ciLetterPath = prefs.getString('ciLetterPath');
    
    if (ciLetterPath != null && ciLetterPath.isNotEmpty) {
      return ResultadoValidacionRequisito(
        requisito: requisito,
        estado: EstadoRequisito.completado,
        mensaje: 'Fotocopia de CI disponible',
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
  ) async {
    final tituloPath = prefs.getString('tituloPath');
    final prorrogaPath = prefs.getString('prorrogaPath');
    final deferDocuments = prefs.getBool('deferDocuments') ?? false;

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
  ) async {
    final cartaPath = prefs.getString('cartaInscripcionPath');
    
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

  /// Valida el requisito de hoja de vida
  Future<ResultadoValidacionRequisito> _validarHojaVida(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
  ) async {
    final hojaVidaPath = prefs.getString('hojaVidaPath');
    
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
      mensaje: 'Debe cargar su hoja de vida profesional',
      fechaValidacion: DateTime.now(),
    );
  }

  /// Valida el requisito de fotografía
  Future<ResultadoValidacionRequisito> _validarFotografia(
    RequisitoInscripcion requisito,
    SharedPreferences prefs,
  ) async {
    final profilePhoto = prefs.getString('profilePhoto');
    
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
