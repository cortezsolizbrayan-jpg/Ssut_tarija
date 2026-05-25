import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refactor_template/core/services/otros/servicio_actualizacion.dart';

/// Provider que expone el servicio de actualización
final servicioActualizacionProvider = Provider<ServicioActualizacion>((ref) {
  return ServicioActualizacion();
});

/// Provider para saber si hay una actualización disponible
final actualizacionDisponibleProvider = FutureProvider<bool>((ref) async {
  final servicio = ref.watch(servicioActualizacionProvider);
  return await servicio.verificarActualizacion();
});

/// Provider para la información de la actualización
final infoActualizacionProvider = FutureProvider<ActualizacionInfo?>((
  ref,
) async {
  final servicio = ref.watch(servicioActualizacionProvider);
  final hayActualizacion = await servicio.verificarActualizacion();

  if (!hayActualizacion) return null;

  return ActualizacionInfo(
    disponible: true,
    versionActual: servicio.currentVersion ?? 'Desconocida',
    versionNueva: servicio.latestVersion ?? 'Desconocida',
    esCritica: false, // Puedes definir tu propia lógica aquí
  );
});

/// Modelo de datos para la información de actualización
class ActualizacionInfo {
  final bool disponible;
  final String versionActual;
  final String versionNueva;
  final bool esCritica;

  ActualizacionInfo({
    required this.disponible,
    required this.versionActual,
    required this.versionNueva,
    required this.esCritica,
  });
}

