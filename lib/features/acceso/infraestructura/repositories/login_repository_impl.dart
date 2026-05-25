import 'package:refactor_template/features/acceso/dominio/entities/login.dart';
import 'package:refactor_template/features/acceso/dominio/repositories/login_repository.dart';
import 'package:refactor_template/features/acceso/infraestructura/datasources/login_datasource.dart';

class LoginRepositoryImpl implements LoginRepository {
  final LoginDatasource datasource;

  LoginRepositoryImpl(this.datasource);

  @override
  Future<Login> login({
    required String nombreUsuario,
    required String claveUsuario,
  }) {
    return datasource.login(
      nombreUsuario: nombreUsuario,
      claveUsuario: claveUsuario,
    );
  }
}

