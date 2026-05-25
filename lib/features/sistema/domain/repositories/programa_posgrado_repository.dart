import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';

/// Repositorio para obtener programas de posgrado.
abstract class ProgramaPosgradoRepository {
  /// Obtiene todos los programas de posgrado del sitio web.
  Future<List<ProgramaPosgrado>> obtenerProgramas({String? area, String? tipo});

  /// Obtiene un programa específico por ID.
  Future<ProgramaPosgrado?> obtenerProgramaPorId(String id);

  /// Obtiene programas por área (ej: ÁREA DE EDUCACIÓN).
  Future<List<ProgramaPosgrado>> obtenerProgramasPorArea(String area);
}
