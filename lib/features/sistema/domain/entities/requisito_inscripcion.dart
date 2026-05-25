/// Entidad que representa un requisito para inscripción a un programa de posgrado
class RequisitoInscripcion {
  final String id;
  final String descripcion;
  final bool esObligatorio;
  final TipoRequisito tipo;
  final String? campoDocumento; // Campo en el sistema que valida este requisito

  const RequisitoInscripcion({
    required this.id,
    required this.descripcion,
    required this.esObligatorio,
    required this.tipo,
    this.campoDocumento,
  });

  /// Crea una copia del requisito con campos modificados
  RequisitoInscripcion copyWith({
    String? id,
    String? descripcion,
    bool? esObligatorio,
    TipoRequisito? tipo,
    String? campoDocumento,
  }) {
    return RequisitoInscripcion(
      id: id ?? this.id,
      descripcion: descripcion ?? this.descripcion,
      esObligatorio: esObligatorio ?? this.esObligatorio,
      tipo: tipo ?? this.tipo,
      campoDocumento: campoDocumento ?? this.campoDocumento,
    );
  }
}

/// Tipos de requisitos para inscripción
enum TipoRequisito {
  /// Documentos de identidad (CI)
  documentoIdentidad,
  
  /// Títulos académicos
  tituloAcademico,
  
  /// Fotografías
  fotografia,
  
  /// Formularios
  formulario,
  
  /// Pagos y comprobantes
  pago,
  
  /// Cartas y documentos escritos
  carta,
  
  /// Hoja de vida
  hojaVida,
  
  /// Otros documentos
  otro,
}

/// Estado de cumplimiento de un requisito
enum EstadoRequisito {
  /// Requisito completado
  completado,
  
  /// Requisito pendiente
  pendiente,
  
  /// Requisito con prórroga solicitada
  conProrroga,
  
  /// No aplica (requisito opcional no completado)
  noAplica,
}

/// Resultado de validación de un requisito
class ResultadoValidacionRequisito {
  final RequisitoInscripcion requisito;
  final EstadoRequisito estado;
  final String? mensaje;
  final DateTime? fechaValidacion;

  const ResultadoValidacionRequisito({
    required this.requisito,
    required this.estado,
    this.mensaje,
    this.fechaValidacion,
  });

  bool get estaCumplido => 
      estado == EstadoRequisito.completado || 
      estado == EstadoRequisito.conProrroga ||
      estado == EstadoRequisito.noAplica;
}

/// Resultado completo de validación de requisitos para inscripción
class ResultadoValidacionInscripcion {
  final List<ResultadoValidacionRequisito> resultados;
  final DateTime fechaValidacion;

  const ResultadoValidacionInscripcion({
    required this.resultados,
    required this.fechaValidacion,
  });

  /// Verifica si todos los requisitos obligatorios están cumplidos
  bool get todosLosRequisitosObligatoriosCumplidos {
    return resultados
        .where((r) => r.requisito.esObligatorio)
        .every((r) => r.estaCumplido);
  }

  /// Obtiene la lista de requisitos pendientes
  List<ResultadoValidacionRequisito> get requisitosPendientes {
    return resultados
        .where((r) => r.estado == EstadoRequisito.pendiente)
        .toList();
  }

  /// Obtiene la lista de requisitos obligatorios pendientes
  List<ResultadoValidacionRequisito> get requisitosObligatoriosPendientes {
    return resultados
        .where((r) => 
            r.requisito.esObligatorio && 
            r.estado == EstadoRequisito.pendiente)
        .toList();
  }

  /// Calcula el porcentaje de completitud
  double get porcentajeCompletitud {
    if (resultados.isEmpty) return 0.0;
    
    final cumplidos = resultados.where((r) => r.estaCumplido).length;
    return (cumplidos / resultados.length) * 100;
  }

  /// Calcula el porcentaje de completitud solo de requisitos obligatorios
  double get porcentajeCompletitudObligatorios {
    final obligatorios = resultados
        .where((r) => r.requisito.esObligatorio)
        .toList();
    
    if (obligatorios.isEmpty) return 100.0;
    
    final cumplidos = obligatorios.where((r) => r.estaCumplido).length;
    return (cumplidos / obligatorios.length) * 100;
  }
}
