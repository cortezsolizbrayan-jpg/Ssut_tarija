import 'dart:io';

/// Datasource abstracto para inscripción
abstract class InscripcionDatasource {
  /// Envía la inscripción al servidor
  Future<Map<String, dynamic>> enviarInscripcion({
    required int idPersona,
    required int idPrograma,
    required Map<String, dynamic> personaExterna,
    required Map<String, dynamic> facturacion,
    File? respaldoCiAnverso,
    File? respaldoCiReverso,
  });
}
