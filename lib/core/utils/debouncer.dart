import 'dart:async';
import 'package:flutter/foundation.dart';

/// Utilidad para hacer debounce de funciones
/// Útil para búsquedas, validaciones, etc.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 300)});

  /// Ejecuta la acción después del delay
  /// Cancela ejecuciones anteriores pendientes
  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  /// Ejecuta la acción inmediatamente y cancela pendientes
  void immediate(VoidCallback action) {
    _timer?.cancel();
    action();
  }

  /// Cancela cualquier ejecución pendiente
  void cancel() {
    _timer?.cancel();
  }

  /// Libera recursos
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Verifica si hay una ejecución pendiente
  bool get isPending => _timer?.isActive ?? false;
}

/// Utilidad para hacer throttle de funciones
/// Limita la frecuencia de ejecución
class Throttler {
  final Duration duration;
  DateTime? _lastExecutionTime;
  Timer? _timer;

  Throttler({this.duration = const Duration(milliseconds: 300)});

  /// Ejecuta la acción si ha pasado suficiente tiempo
  void call(VoidCallback action) {
    final now = DateTime.now();

    if (_lastExecutionTime == null ||
        now.difference(_lastExecutionTime!) >= duration) {
      _lastExecutionTime = now;
      action();
    } else {
      // Programar para ejecutar después del período de throttle
      _timer?.cancel();
      final remaining = duration - now.difference(_lastExecutionTime!);
      _timer = Timer(remaining, () {
        _lastExecutionTime = DateTime.now();
        action();
      });
    }
  }

  /// Cancela cualquier ejecución pendiente
  void cancel() {
    _timer?.cancel();
  }

  /// Libera recursos
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _lastExecutionTime = null;
  }
}
