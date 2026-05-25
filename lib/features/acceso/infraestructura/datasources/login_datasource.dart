import 'package:refactor_template/features/acceso/dominio/entities/login.dart';

abstract class LoginDatasource {
  Future<Login> login({
    required String nombreUsuario,
    required String claveUsuario,
  });
}

