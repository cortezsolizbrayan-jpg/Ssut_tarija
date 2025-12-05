import 'package:dio/dio.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/dio_error_handler.dart';
import 'package:refactor_template/features/login/domain/entities/login.dart';
import 'package:refactor_template/features/login/infrastructure/datasources/login_datasource.dart';
import 'package:refactor_template/features/login/infrastructure/models/login_model.dart';

class LoginDatasourceImpl implements LoginDatasource {
  final dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrlPsg,
      // headers: {
      // 'Authorization': 'Bearer ${Environment.token}',
      // 'Content-Type': 'multipart/form-data',
      // },
    ),
  );

  @override
  Future<Login> login({
    required String nombreUsuario,
    required String claveUsuario,
  }) async {
    try {
      final response = await dio.post(
        '/auth/login',
        data: {'nombre_usuario': nombreUsuario, 'clave_usuario': claveUsuario},
        // options: Options(responseType: ResponseType.json),
      );
      return LoginModel.fromJson(response.data);
    } on DioException catch (e) {
      throw DioErrorHandler.handle(e);
    } catch (e) {
      throw Exception('Error en el datasource al iniciar sesión: $e');
    }
  }
}
