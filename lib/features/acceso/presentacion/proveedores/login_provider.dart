import 'package:refactor_template/features/acceso/dominio/entities/login.dart';
import 'package:refactor_template/features/acceso/infraestructura/datasources/login_datasource_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_provider.g.dart';

@riverpod
class AsyncLoginNotifier extends _$AsyncLoginNotifier {
  @override
  FutureOr<Login> build(String nombreUsuario, String claveUsuario) async {
    final LoginDatasourceImpl loginImpl = LoginDatasourceImpl();
    return await loginImpl.login(
      nombreUsuario: nombreUsuario,
      claveUsuario: claveUsuario,
    );
  }
}

