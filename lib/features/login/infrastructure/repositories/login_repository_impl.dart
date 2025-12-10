import 'package:refactor_template/features/login/domain/entities/login.dart';
import 'package:refactor_template/features/login/domain/repositories/login_repository.dart';
import 'package:refactor_template/features/login/infrastructure/datasources/login_datasource.dart';

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
