import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clase simple para manejar el contador de notificaciones
class NotificacionesState {
  int count;

  NotificacionesState(this.count);
}

/// Provider global para el contador de notificaciones no leídas
final notificacionesProvider = Provider<NotificacionesState>((ref) {
  return NotificacionesState(2); // Inicialmente hay 2 notificaciones
});
