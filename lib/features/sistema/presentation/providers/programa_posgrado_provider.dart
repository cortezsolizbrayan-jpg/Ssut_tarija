import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/domain/repositories/programa_posgrado_repository.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/programa_posgrado_datasource.dart';
import 'package:refactor_template/features/sistema/infrastructure/datasources/programa_posgrado_datasource_impl.dart';
import 'package:refactor_template/features/sistema/infrastructure/repositories/programa_posgrado_repository_impl.dart';

/// Provider del datasource de programas de posgrado.
final programaPosgradoDatasourceProvider = Provider<ProgramaPosgradoDatasource>(
  (ref) {
    return ProgramaPosgradoDatasourceImpl();
  },
);

/// Provider del repositorio de programas de posgrado.
final programaPosgradoRepositoryProvider = Provider<ProgramaPosgradoRepository>(
  (ref) {
    final datasource = ref.watch(programaPosgradoDatasourceProvider);
    return ProgramaPosgradoRepositoryImpl(datasource);
  },
);

/// Provider para obtener todos los programas.
final programasPosgradoProvider =
    FutureProvider.family<List<ProgramaPosgrado>, Map<String, String?>>((
      ref,
      filters,
    ) {
      final repository = ref.watch(programaPosgradoRepositoryProvider);
      return repository.obtenerProgramas(
        area: filters['area'],
        tipo: filters['tipo'],
      );
    });

/// Provider para obtener un programa por ID.
final programaPorIdProvider = FutureProvider.family<ProgramaPosgrado?, String>((
  ref,
  id,
) {
  final repository = ref.watch(programaPosgradoRepositoryProvider);
  return repository.obtenerProgramaPorId(id);
});

/// Provider para obtener programas por área.
final programasPorAreaProvider =
    FutureProvider.family<List<ProgramaPosgrado>, String>((ref, area) {
      final repository = ref.watch(programaPosgradoRepositoryProvider);
      return repository.obtenerProgramasPorArea(area);
    });
