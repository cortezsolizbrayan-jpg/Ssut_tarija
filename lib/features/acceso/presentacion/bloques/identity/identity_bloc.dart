import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refactor_template/core/services/validation/servicio_procesamiento_ci_optimizado.dart';
import 'package:refactor_template/core/services/otros/cancellation_token.dart';
import 'identity_event.dart';
import 'identity_state.dart';

class IdentityBloc extends Bloc<IdentityEvent, IdentityState> {
  CancellationToken? _currentCancellationToken;
  int _processRunId = 0;

  IdentityBloc() : super(const IdentityState()) {
    on<IdentityFrontImageChanged>(_onFrontImageChanged);
    on<IdentityBackImageChanged>(_onBackImageChanged);
    on<IdentityPdfFileChanged>(_onPdfFileChanged);
    on<IdentityProcessStarted>(_onProcessStarted);
    on<IdentityScanningStatusUpdated>(_onStatusUpdated);
    on<IdentityProcessCancelRequested>(_onProcessCancelRequested);
    on<IdentityReset>(_onReset);
    on<IdentityCaptureStarted>(_onCaptureStarted);
    on<IdentityCaptureFailed>(_onCaptureFailed);
  }

  void _onFrontImageChanged(IdentityFrontImageChanged event, Emitter<IdentityState> emit) {
    emit(state.copyWith(
      frontImage: event.file, 
      status: IdentityStatus.initial
    ));
  }

  void _onBackImageChanged(IdentityBackImageChanged event, Emitter<IdentityState> emit) {
    emit(state.copyWith(
      backImage: event.file, 
      status: IdentityStatus.initial
    ));
  }

  void _onPdfFileChanged(IdentityPdfFileChanged event, Emitter<IdentityState> emit) {
    emit(state.copyWith(
      pdfFile: event.file, 
      isPdfMode: true,
      frontImage: null, // Limpiar fotos si se sube PDF
      backImage: null,
    ));
  }

  void _onStatusUpdated(IdentityScanningStatusUpdated event, Emitter<IdentityState> emit) {
    emit(state.copyWith(scanningMessage: event.message));
  }

  void _onReset(IdentityReset event, Emitter<IdentityState> emit) {
    _currentCancellationToken?.cancel();
    _currentCancellationToken = null;
    emit(const IdentityState());
  }

  void _onCaptureStarted(IdentityCaptureStarted event, Emitter<IdentityState> emit) {
    emit(state.copyWith(
      status: IdentityStatus.loading, 
      scanningMessage: event.isFront ? 'Anverso: Procesando...' : 'Reverso: Procesando...'
    ));
  }

  void _onCaptureFailed(IdentityCaptureFailed event, Emitter<IdentityState> emit) {
    emit(state.copyWith(status: IdentityStatus.initial));
  }

  void _onProcessCancelRequested(
    IdentityProcessCancelRequested event,
    Emitter<IdentityState> emit,
  ) {
    _currentCancellationToken?.cancel();
    _currentCancellationToken = null;
    emit(state.copyWith(
      status: IdentityStatus.initial,
      scanningMessage: '',
      errorMessage: null,
      extractedData: null,
    ));
  }

  @override
  Future<void> close() {
    _currentCancellationToken?.cancel();
    _currentCancellationToken = null;
    return super.close();
  }

  Future<void> _onProcessStarted(IdentityProcessStarted event, Emitter<IdentityState> emit) async {
    if (state.frontImage == null && state.backImage == null && state.pdfFile == null) {
      return;
    }

    emit(state.copyWith(status: IdentityStatus.loading, scanningMessage: 'Iniciando análisis...'));

    try {
      // Cancelar cualquier procesamiento anterior para evitar carreras.
      _currentCancellationToken?.cancel();
      final token = CancellationToken();
      _currentCancellationToken = token;
      final runId = ++_processRunId;

      final result = await ServicioProcesamientoCiOptimizado.procesarImagenesCI(
        frontImage: state.frontImage!,
        backImage: state.backImage!,
        onProgress: (message) {
          // Usar add para enviar un evento desde el callback y actualizar la UI fluidamente
          // Evitar que mensajes antiguos reescriban el estado luego de cancelar.
          if (_currentCancellationToken != null && _currentCancellationToken == token) {
            add(IdentityScanningStatusUpdated(message));
          }
        },
        cancellationToken: token,
      );

      // Si se canceló o se inició otro run, ignorar resultado.
      if (token.isCancelled || runId != _processRunId) {
        return;
      }

      if (result['success']) {
        emit(state.copyWith(
          status: IdentityStatus.success,
          extractedData: result['data'] as Map<String, dynamic>,
        ));
      } else {
        emit(state.copyWith(
          status: IdentityStatus.error,
          errorMessage: result['error'] as String,
        ));
      }
    } on CancellationException catch (_) {
      // Silencioso: cancelado por navegación del usuario.
      emit(state.copyWith(status: IdentityStatus.initial, scanningMessage: ''));
    } catch (e) {
      emit(state.copyWith(
        status: IdentityStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
}

