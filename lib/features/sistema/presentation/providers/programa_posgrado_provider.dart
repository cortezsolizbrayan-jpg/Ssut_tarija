import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refactor_template/core/cache/app_cache.dart';
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

/// Provider para obtener todos los programas (con filtros opcionales).
final programasPosgradoProvider =
    FutureProvider.autoDispose.family<List<ProgramaPosgrado>, Map<String, String?>>((
  ref,
  filters,
) {
  final repository = ref.watch(programaPosgradoRepositoryProvider);
  return repository.obtenerProgramas(
    area: filters['area'],
    tipo: filters['tipo'],
  );
});

/// Provider estable solo para la pantalla de programas vigentes.
/// Sin family: un solo Future, no se recrea en cada rebuild y la UI deja de quedarse en loading.
/// Implementa caché para reducir llamadas a la API.
final programasVigentesProvider =
    FutureProvider.autoDispose<List<ProgramaPosgrado>>((ref) async {
  // Intentar obtener del caché primero
  final cached = AppCache.get<List<ProgramaPosgrado>>(
    CacheKeys.programasVigentes,
  );
  
  if (cached != null) {
    return cached;
  }
  
  // Si no hay caché, obtener de la API
  final repository = ref.watch(programaPosgradoRepositoryProvider);
  final programas = await repository.obtenerProgramas();
  
  // Guardar en caché por 5 minutos
  AppCache.set(
    CacheKeys.programasVigentes,
    programas,
    ttl: const Duration(minutes: 5),
  );
  
  return programas;
});

/// Provider para obtener un programa por ID.
final programaPorIdProvider =
    FutureProvider.autoDispose.family<ProgramaPosgrado?, String>((
  ref,
  id,
) {
  final repository = ref.watch(programaPosgradoRepositoryProvider);
  return repository.obtenerProgramaPorId(id);
});

/// Provider para obtener programas por área.
final programasPorAreaProvider =
    FutureProvider.autoDispose.family<List<ProgramaPosgrado>, String>((ref, area) {
      final repository = ref.watch(programaPosgradoRepositoryProvider);
      return repository.obtenerProgramasPorArea(area);
    });
