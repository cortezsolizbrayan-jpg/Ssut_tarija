class Login {
  String status;
  Data data;
  String message;

  Login({required this.status, required this.data, required this.message});
}

class Data {
  String token;
  int expiresIn;
  String nombreUsuario;
  List<String> grupos;

  Data({
    required this.token,
    required this.expiresIn,
    required this.nombreUsuario,
    required this.grupos,
  });
}
