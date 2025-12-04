/// Entidad que representa un programa de posgrado de la UAP.
class ProgramaPosgrado {
  final String id;
  final String titulo;
  final String tipo; // DIPLOMADO, MAESTRÍA, DOCTORADO, etc.
  final String modalidad; // 100% Virtual, Presencial, Semipresencial
  final String duracion; // 6 meses, 9 meses, etc.
  final String cargaHoraria; // 800 Hrs. Académicas
  final int creditos;
  final String estado; // INSCRIPCIONES ABIERTAS, PREINSCRIPCIONES, etc.
  final double? descuento; // 20% de descuento
  final String area; // ÁREA DE EDUCACIÓN, etc.
  final String? descripcion;
  final String? universidad;
  final String? fechaInicio;
  final String? urlFichaTecnica;

  ProgramaPosgrado({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.modalidad,
    required this.duracion,
    required this.cargaHoraria,
    required this.creditos,
    required this.estado,
    this.descuento,
    required this.area,
    this.descripcion,
    this.universidad,
    this.fechaInicio,
    this.urlFichaTecnica,
  });
}
