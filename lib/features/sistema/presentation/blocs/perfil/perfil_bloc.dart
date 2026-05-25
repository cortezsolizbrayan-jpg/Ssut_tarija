import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'perfil_event.dart';
import 'perfil_state.dart';

class PerfilBloc extends Bloc<PerfilEvent, PerfilState> {
  PerfilBloc() : super(const PerfilState()) {
    on<LoadPerfilData>(_onLoadPerfilData);
  }

  Future<void> _onLoadPerfilData(LoadPerfilData event, Emitter<PerfilState> emit) async {
    emit(state.copyWith(status: PerfilStatus.loading));
    try {
      final personal = await LocalStorageService.getPersonalData();
      final session  = await LocalStorageService.getSessionData();

      String str(dynamic v) => (v?.toString() ?? '').trim();
      
      final nombre    = str(personal?['nombre']);
      final apPaterno = str(personal?['apPaterno']);
      final apMaterno = str(personal?['apMaterno']);
      
      final completo  = [
        if (nombre.isNotEmpty)    nombre,
        if (apPaterno.isNotEmpty) apPaterno,
        if (apMaterno.isNotEmpty) apMaterno,
      ].join(' ').trim();
      
      final sessionNombre = str(session?['nombreUsuario']);
      final nombreFinal = completo.isNotEmpty
          ? completo
          : (sessionNombre.isNotEmpty ? sessionNombre : 'Usuario');

      emit(state.copyWith(
        status: PerfilStatus.loaded, 
        nombreUsuario: nombreFinal
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PerfilStatus.error, 
        errorMessage: e.toString()
      ));
    }
  }
}

