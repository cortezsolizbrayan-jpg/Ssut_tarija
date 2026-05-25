/// Servicio de usuarios genéricos para el módulo de Recepción.
/// Los usuarios están hardcodeados - no requieren API ni BD externa.
class ServicioUsuariosRecepcion {
  /// Usuarios de atención al cliente con sus credenciales
  static const List<Map<String, String>> _usuarios = [
    {'usuario': 'dayana',   'contrasena': 'upea2024', 'nombre': 'Dayana',   'rol': 'Recepción'},
    {'usuario': 'maria',    'contrasena': 'upea2024', 'nombre': 'María',    'rol': 'Recepción'},
    {'usuario': 'carmen',   'contrasena': 'upea2024', 'nombre': 'Carmen',   'rol': 'Recepción'},
    {'usuario': 'admin',    'contrasena': 'admin123',  'nombre': 'Administrador', 'rol': 'Admin'},
  ];

  /// Verifica credenciales. Retorna el usuario si son correctas, null si no.
  static Map<String, String>? verificarCredenciales(String usuario, String contrasena) {
    final u = usuario.trim().toLowerCase();
    final c = contrasena.trim();
    try {
      return _usuarios.firstWhere(
        (usr) => usr['usuario'] == u && usr['contrasena'] == c,
      );
    } catch (_) {
      return null;
    }
  }
}
