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
  });

  /// Crea un modelo desde un mapa JSON (útil para APIs).
  factory ProgramaPosgradoModel.fromJson(Map<String, dynamic> json) {
    return ProgramaPosgradoModel(
      id: json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      tipo: json['tipo'] ?? '',
      modalidad: json['modalidad'] ?? '',
      duracion: json['duracion'] ?? '',
      cargaHoraria: json['cargaHoraria'] ?? '',
      creditos: json['creditos'] ?? 0,
      estado: json['estado'] ?? '',
      descuento: json['descuento'] != null
          ? double.tryParse(json['descuento'].toString())
          : null,
      area: json['area'] ?? '',
      descripcion: json['descripcion'],
      universidad: json['universidad'],
      fechaInicio: json['fechaInicio'],
      urlFichaTecnica: json['urlFichaTecnica'],
    );
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
    };
  }
}
