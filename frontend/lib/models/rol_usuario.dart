enum UserRole {
  administradorSistema,
  administradorDocumentos,
  contador,
  gerente,
  auditor;

  String get displayName {
    switch (this) {
      case UserRole.administradorSistema:
        return 'Administrador de Sistema';
      case UserRole.administradorDocumentos:
        return 'Administrador de Documentos';
      case UserRole.contador:
        return 'Contador';
      case UserRole.gerente:
        return 'Gerente';
      case UserRole.auditor:
        return 'Auditor';
    }
  }

  String get codigo {
    switch (this) {
      case UserRole.administradorSistema:
        return 'AdministradorSistema';
      case UserRole.administradorDocumentos:
        return 'AdministradorDocumentos';
      case UserRole.contador:
        return 'Contador';
      case UserRole.gerente:
        return 'Gerente';
      case UserRole.auditor:
        return 'Auditor';
    }
  }

  /// Mismas pantallas y permisos base que Contador.
  bool get mismasFuncionesQueContador =>
      this == UserRole.contador || this == UserRole.auditor;

  /// Solo ve sus propios préstamos en movimientos.
  bool get veSoloPropiosMovimientos =>
      this == UserRole.contador ||
      this == UserRole.gerente ||
      this == UserRole.auditor;
}
