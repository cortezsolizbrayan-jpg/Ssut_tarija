/// Modelo de datos para información extraída del documento de identidad
class IdentityDocumentData {
  final String ci;
  final String nombres;
  final String apellidos;
  final String fechaNacimiento;
  final String fechaEmision;
  final String fechaExpiracion;
  final String lugarNacimiento;
  final String profesion;
  final String estadoCivil;
  final String domicilio;
  final String grupoSanguineo;
  final String detectedModel;

  const IdentityDocumentData({
    required this.ci,
    required this.nombres,
    required this.apellidos,
    required this.fechaNacimiento,
    required this.fechaEmision,
    required this.fechaExpiracion,
    required this.lugarNacimiento,
    required this.profesion,
    required this.estadoCivil,
    required this.domicilio,
    required this.grupoSanguineo,
    required this.detectedModel,
  });

  factory IdentityDocumentData.empty() {
    return const IdentityDocumentData(
      ci: '',
      nombres: '',
      apellidos: '',
      fechaNacimiento: '',
      fechaEmision: '',
      fechaExpiracion: '',
      lugarNacimiento: '',
      profesion: '',
      estadoCivil: '',
      domicilio: '',
      grupoSanguineo: '',
      detectedModel: 'desconocido',
    );
  }

  IdentityDocumentData copyWith({
    String? ci,
    String? nombres,
    String? apellidos,
    String? fechaNacimiento,
    String? fechaEmision,
    String? fechaExpiracion,
    String? lugarNacimiento,
    String? profesion,
    String? estadoCivil,
    String? domicilio,
    String? grupoSanguineo,
    String? detectedModel,
  }) {
    return IdentityDocumentData(
      ci: ci ?? this.ci,
      nombres: nombres ?? this.nombres,
      apellidos: apellidos ?? this.apellidos,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaExpiracion: fechaExpiracion ?? this.fechaExpiracion,
      lugarNacimiento: lugarNacimiento ?? this.lugarNacimiento,
      profesion: profesion ?? this.profesion,
      estadoCivil: estadoCivil ?? this.estadoCivil,
      domicilio: domicilio ?? this.domicilio,
      grupoSanguineo: grupoSanguineo ?? this.grupoSanguineo,
      detectedModel: detectedModel ?? this.detectedModel,
    );
  }

  bool get hasRequiredData => ci.isNotEmpty && nombres.isNotEmpty;
}

