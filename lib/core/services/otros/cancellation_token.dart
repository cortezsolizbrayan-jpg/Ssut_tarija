import 'dart:async';

/// Token simple para cancelar operaciones asíncronas entre capas (UI -> Bloc -> Servicio).
/// No "mata" el isolate/Future en curso, pero permite:
/// - abortar pasos posteriores
/// - salir temprano en lugares donde haya checks o races
class CancellationToken {
  bool get isCancelled => _completer.isCompleted;

  final Completer<void> _completer = Completer<void>();

  void cancel() {
    if (!_completer.isCompleted) _completer.complete();
  }

  Future<void> get whenCancelled => _completer.future;
}

class CancellationException implements Exception {
  final String message;
  CancellationException([this.message = 'cancelled']);

  @override
  String toString() => 'CancellationException: $message';
}
   
