import 'package:refactor_template/features/login/domain/entities/login.dart';

abstract class LoginDatasource {
  Future<Login> login({
    required String nombreUsuario,
    required String claveUsuario,
  });
}
