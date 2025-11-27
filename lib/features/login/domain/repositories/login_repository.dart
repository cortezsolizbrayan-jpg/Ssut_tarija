import 'package:refactor_template/features/login/domain/entities/login.dart';

abstract class LoginRepository {
  Future<Login> login(String nombreUsuario, String claveUsuario);
}
