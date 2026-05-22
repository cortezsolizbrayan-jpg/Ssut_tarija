import 'package:refactor_template/features/acceso/dominio/entities/login.dart';

abstract class LoginRepository {
  Future<Login> login({
    required String nombreUsuario,
    required String claveUsuario,
  });
}

