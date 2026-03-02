import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/domain/repositories/programa_posgrado_repository.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/programa_posgrado_datasource.dart';

/// Implementación del repositorio de programas de posgrado.
class ProgramaPosgradoRepositoryImpl implements ProgramaPosgradoRepository {
  final ProgramaPosgradoDatasource datasource;

  ProgramaPosgradoRepositoryImpl(this.datasource);

  @override
  Future<List<ProgramaPosgrado>> obtenerProgramas({
    String? area,
    String? tipo,
  }) async {
    try {
      return await datasource.obtenerProgramasDesdeApi(area: area, tipo: tipo);
    } catch (_) {
      try {
        return await datasource.obtenerProgramasDesdeWeb(area: area, tipo: tipo);
      } catch (e) {
        rethrow;
      }
    }
  }

  @override
  Future<ProgramaPosgrado?> obtenerProgramaPorId(String id) async {
    final programas = await obtenerProgramas();
    try {
      return programas.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<ProgramaPosgrado>> obtenerProgramasPorArea(String area) async {
    return await obtenerProgramas(area: area);
  }
}
