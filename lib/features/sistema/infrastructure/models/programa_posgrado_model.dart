import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';

/// Modelo que extiende la entidad ProgramaPosgrado para manejar datos del sitio web.
class ProgramaPosgradoModel extends ProgramaPosgrado {
  ProgramaPosgradoModel({
    required super.id,
    required super.titulo,
    required super.tipo,
    required super.modalidad,
    required super.duracion,
    required super.cargaHoraria,
    required super.creditos,
    required super.estado,
    super.descuento,
    required super.area,
    super.descripcion,
    super.universidad,
    super.fechaInicio,
    super.urlFichaTecnica,
    super.responsable,
    super.inscripcionHasta,
    super.imagenPortada,
    super.celularSoporte,
  });

  /// Crea un modelo desde un mapa JSON (útil para APIs genéricas).
  factory ProgramaPosgradoModel.fromJson(Map<String, dynamic> json) {
    return ProgramaPosgradoModel(
      id: json['id']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      modalidad: json['modalidad']?.toString() ?? '',
      duracion: json['duracion']?.toString() ?? '',
      cargaHoraria: json['cargaHoraria']?.toString() ?? '',
      creditos: _parseInt(json['creditos'], 0),
      estado: json['estado']?.toString() ?? '',
      descuento: json['descuento'] != null
          ? double.tryParse(json['descuento'].toString())
          : null,
      area: json['area']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      universidad: json['universidad']?.toString(),
      fechaInicio: json['fechaInicio']?.toString(),
      urlFichaTecnica: json['urlFichaTecnica']?.toString(),
      responsable: json['responsable']?.toString(),
      inscripcionHasta: json['inscripcionHasta']?.toString(),
      imagenPortada: json['imagenPortada']?.toString(),
      celularSoporte: json['celularSoporte']?.toString(),
    );
  }

  /// Crea un modelo desde la API de oferta (publicaciones/oferta).
  /// Campos: id, grado, nombre, modalidad, fechafininscripcion, responsableInterno, portada, estado, etc.
  factory ProgramaPosgradoModel.fromOfertaApi(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final nombre = json['nombre']?.toString() ?? '';
    final grado = json['grado']?.toString() ?? '';
    final modalidad = json['modalidad']?.toString() ?? '';
    final estado = json['estado']?.toString() ?? 'PUBLICADO';
    final duracion = json['duracion']?.toString();
    final cargahoraria = json['cargahoraria']?.toString();
    // Imagen: probar varios campos que la API puede enviar
    final portada = json['portada']?.toString() ??
        json['imagen']?.toString() ??
        json['imagenPortada']?.toString() ??
        json['cover']?.toString() ??
        json['foto']?.toString() ??
        json['url_imagen']?.toString();

    String? inscripcionHasta;
    final fechafin = json['fechafininscripcion']?.toString();
    if (fechafin != null && fechafin.isNotEmpty) {
      inscripcionHasta = _formatOfertaDate(fechafin);
    }

    String? responsable;
    final resp = json['responsableInterno'];
    if (resp is Map<String, dynamic>) {
      final n = (resp['nombre']?.toString() ?? '').trim();
      final p = (resp['paterno']?.toString() ?? '').trim();
      final m = (resp['materno']?.toString() ?? '').trim();
      final c = (resp['celular']?.toString() ?? '').trim();
      final parts = [n, p, m].where((e) => e.isNotEmpty);
      responsable = parts.join(' ');
      if (c.isNotEmpty) {
        responsable = '$responsable · $c';
      }
    }

    return ProgramaPosgradoModel(
      id: id,
      titulo: nombre,
      tipo: grado.toUpperCase().replaceAll('Í', 'I'),
      modalidad: modalidad.isNotEmpty ? modalidad : '—',
      duracion: duracion?.trim().isNotEmpty == true ? duracion! : '—',
      cargaHoraria: cargahoraria?.trim().isNotEmpty == true ? cargahoraria! : '—',
      creditos: 0,
      estado: estado,
      area: grado.isNotEmpty ? grado : '—',
      urlFichaTecnica: portada?.trim().isNotEmpty == true ? portada : null,
      responsable: responsable,
      inscripcionHasta: inscripcionHasta,
      imagenPortada: portada?.trim().isNotEmpty == true ? portada : null,
      celularSoporte: json['responsableInterno']?['celular']?.toString(),
    );
  }

  static String _formatOfertaDate(String isoDate) {
    try {
      final d = DateTime.tryParse(isoDate);
      if (d == null) return isoDate;
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  static int _parseInt(dynamic v, int def) {
    if (v == null) return def;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? def;
  }

  /// Crea un modelo desde datos extraídos del HTML del sitio web.
  factory ProgramaPosgradoModel.fromHtml({
    required String id,
    required String titulo,
    String tipo = 'DIPLOMADO',
    String modalidad = '100% Virtual',
    String duracion = '6 meses',
    String cargaHoraria = '800 Hrs. Académicas',
    int creditos = 20,
    String estado = 'INSCRIPCIONES ABIERTAS',
    double? descuento,
    String area = 'ÁREA DE EDUCACIÓN',
    String? descripcion,
    String? universidad,
    String? fechaInicio,
    String? urlFichaTecnica,
    String? responsable,
    String? inscripcionHasta,
  }) {
    return ProgramaPosgradoModel(
      id: id,
      titulo: titulo,
      tipo: tipo,
      modalidad: modalidad,
      duracion: duracion,
      cargaHoraria: cargaHoraria,
      creditos: creditos,
      estado: estado,
      descuento: descuento,
      area: area,
      descripcion: descripcion,
      universidad: universidad ?? 'Universidad Amazónica de Pando',
      fechaInicio: fechaInicio,
      urlFichaTecnica: urlFichaTecnica,
      responsable: responsable,
      inscripcionHasta: inscripcionHasta,
      imagenPortada: urlFichaTecnica,
      celularSoporte: null,
    );
  }

  /// Convierte el modelo a un mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'tipo': tipo,
      'modalidad': modalidad,
      'duracion': duracion,
      'cargaHoraria': cargaHoraria,
      'creditos': creditos,
      'estado': estado,
      'descuento': descuento,
      'area': area,
      'descripcion': descripcion,
      'universidad': universidad,
      'fechaInicio': fechaInicio,
      'urlFichaTecnica': urlFichaTecnica,
      'responsable': responsable,
      'inscripcionHasta': inscripcionHasta,
      'imagenPortada': imagenPortada,
      'celularSoporte': celularSoporte,
    };
  }
}
