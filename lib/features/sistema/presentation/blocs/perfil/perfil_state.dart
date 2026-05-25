import 'package:equatable/equatable.dart';

enum PerfilStatus { initial, loading, loaded, error }

class PerfilState extends Equatable {
  final PerfilStatus status;
  final String? nombreUsuario;
  final String? errorMessage;

  const PerfilState({
    this.status = PerfilStatus.initial,
    this.nombreUsuario,
    this.errorMessage,
  });

  PerfilState copyWith({
    PerfilStatus? status,
    String? nombreUsuario,
    String? errorMessage,
  }) {
    return PerfilState(
      status: status ?? this.status,
      nombreUsuario: nombreUsuario ?? this.nombreUsuario,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, nombreUsuario, errorMessage];
}
