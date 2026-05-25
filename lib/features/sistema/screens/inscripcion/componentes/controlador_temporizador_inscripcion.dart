import 'dart:async';

import 'package:flutter/material.dart';

/// Controla el conteo regresivo (5 min) para completar la inscripción.
///
/// - Es **in-app only**: persiste mientras la app siga viva.
/// - Se indexa por `idPrograma` para que cada inscripción sea independiente.
class ControladorTemporizadorInscripcion {
  final String idPrograma;
  final int segundosIniciales;
  final VoidCallback onTiempoAgotado;

  Timer? _timer;
  int _segundosRestantes;

  static final Map<String, int> _cacheSegundosPorPrograma = <String, int>{};

  /// Stream global que emite el idPrograma cuando su tiempo expira.
  /// Cualquier pantalla puede escucharlo para reaccionar al vencimiento.
  static final StreamController<String> _tiempoAgotadoStream =
      StreamController<String>.broadcast();

  static Stream<String> get onTiempoAgotadoGlobal =>
      _tiempoAgotadoStream.stream;

  ControladorTemporizadorInscripcion({
    required this.idPrograma,
    required this.onTiempoAgotado,
    this.segundosIniciales = 300,
  }) : _segundosRestantes =
            _cacheSegundosPorPrograma[idPrograma] ?? segundosIniciales;

  int get segundosRestantes => _segundosRestantes;

  void iniciar({required VoidCallback onTick}) {
    detener();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes <= 0) {
        detener();
        _cacheSegundosPorPrograma.remove(idPrograma);
        // Emitir evento global para que TODAS las pantallas activas reaccionen
        _tiempoAgotadoStream.add(idPrograma);
        onTiempoAgotado();
        return;
      }
      _segundosRestantes--;
      _cacheSegundosPorPrograma[idPrograma] = _segundosRestantes;
      onTick();
    });
  }

  void detener() {
    _timer?.cancel();
    _timer = null;
  }

  void resetear() {
    _segundosRestantes = segundosIniciales;
    _cacheSegundosPorPrograma[idPrograma] = _segundosRestantes;
  }

  void limpiarCachePrograma() {
    _cacheSegundosPorPrograma.remove(idPrograma);
  }

  void dispose() {
    detener();
  }
}


