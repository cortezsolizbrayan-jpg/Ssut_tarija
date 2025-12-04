import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';

/// Fuente de datos para obtener programas de posgrado.
abstract class ProgramaPosgradoDatasource {
  /// Obtiene programas desde el sitio web de Posgrado UAP.
  Future<List<ProgramaPosgrado>> obtenerProgramasDesdeWeb({
    String? area,
    String? tipo,
  });

  /// Obtiene programas desde una API (si está disponible).
  Future<List<ProgramaPosgrado>> obtenerProgramasDesdeApi({
    String? area,
    String? tipo,
  });
}
