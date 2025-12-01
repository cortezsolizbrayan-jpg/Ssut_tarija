import 'package:refactor_template/features/login/domain/entities/login.dart';
import 'package:refactor_template/features/login/infrastructure/datasources/login_datasource_impl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_provider.g.dart';

@riverpod
class AsyncLoginNotifier extends _$AsyncLoginNotifier {
  @override
  FutureOr<Login> build(String nombreUsuario, String claveUsuario) async {
    final LoginDatasourceImpl LoginImpl = LoginDatasourceImpl();
    return await LoginImpl.login(nombreUsuario, claveUsuario);
  }
}
