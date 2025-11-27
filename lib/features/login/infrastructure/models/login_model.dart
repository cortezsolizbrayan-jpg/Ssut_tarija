import 'package:refactor_template/features/login/domain/entities/login.dart';

class LoginModel extends Login {
  LoginModel({
    required super.status,
    required super.data,
    required super.message,
  });

  factory LoginModel.fromJson(Map<String, dynamic> json) => LoginModel(
    status: json['status'],
    data: Data(
      token: json['data']['token'],
      expiresIn: json['data']['expiresIn'],
      nombreUsuario: json['data']['nombre_usuario'],
      grupos: List<String>.from(json['data']['grupos']),
    ),
    message: json['message'],
  );
}
