/// Entidad que representa una persona a nombre de quien se factura
class PersonaFacturacion {
  final String id; // UUID único
  final String nombre;
  final String apellido;
  final String tipoDocumento; // CI, NIT, PASAPORTE
  final String numeroDocumento;
  final String email;
  final String telefono;
  final bool esEmpresa;
  final String? nitEmpresa; // Solo si esEmpresa es true
  final String? razonSocial; // Solo si esEmpresa es true
  final DateTime fechaCreacion;
  final DateTime? fechaActualizacion;
  final bool esActivo;

  const PersonaFacturacion({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.tipoDocumento,
    required this.numeroDocumento,
    required this.email,
    required this.telefono,
    this.esEmpresa = false,
    this.nitEmpresa,
    this.razonSocial,
    required this.fechaCreacion,
    this.fechaActualizacion,
    this.esActivo = true,
  });

  /// Obtiene el nombre completo
  String get nombreCompleto => '$nombre $apellido';

  /// Obtiene el nombre para facturación (empresa o persona)
  String get nombreFacturacion => esEmpresa ? (razonSocial ?? nombreCompleto) : nombreCompleto;

  /// Obtiene el documento para facturación
  String get documentoFacturacion => esEmpresa ? (nitEmpresa ?? numeroDocumento) : numeroDocumento;

  /// Crea una copia con campos modificados
  PersonaFacturacion copyWith({
    String? id,
    String? nombre,
    String? apellido,
    String? tipoDocumento,
    String? numeroDocumento,
    String? email,
    String? telefono,
    bool? esEmpresa,
    String? nitEmpresa,
    String? razonSocial,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    bool? esActivo,
  }) {
    return PersonaFacturacion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      numeroDocumento: numeroDocumento ?? this.numeroDocumento,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      esEmpresa: esEmpresa ?? this.esEmpresa,
      nitEmpresa: nitEmpresa ?? this.nitEmpresa,
      razonSocial: razonSocial ?? this.razonSocial,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      esActivo: esActivo ?? this.esActivo,
    );
  }

  /// Convierte a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'tipoDocumento': tipoDocumento,
      'numeroDocumento': numeroDocumento,
      'email': email,
      'telefono': telefono,
      'esEmpresa': esEmpresa,
      'nitEmpresa': nitEmpresa,
      'razonSocial': razonSocial,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'esActivo': esActivo,
    };
  }

  /// Crea desde Map
  factory PersonaFacturacion.fromMap(Map<String, dynamic> map) {
    return PersonaFacturacion(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      apellido: map['apellido'] as String,
      tipoDocumento: map['tipoDocumento'] as String,
      numeroDocumento: map['numeroDocumento'] as String,
      email: map['email'] as String,
      telefono: map['telefono'] as String,
      esEmpresa: map['esEmpresa'] as bool? ?? false,
      nitEmpresa: map['nitEmpresa'] as String?,
      razonSocial: map['razonSocial'] as String?,
      fechaCreacion: DateTime.parse(map['fechaCreacion'] as String),
      fechaActualizacion: map['fechaActualizacion'] != null
          ? DateTime.parse(map['fechaActualizacion'] as String)
          : null,
      esActivo: map['esActivo'] as bool? ?? true,
    );
  }
}

