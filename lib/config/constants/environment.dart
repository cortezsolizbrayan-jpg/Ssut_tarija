class Environment {
  // Valores por defecto - puedes cambiarlos directamente aquí
  static const String apiUrlPsg =
      'No hay comunicación con el servicio rest de Posgrado (UPEA)';
  static const String token = 'No se estableció el token';

  // Método de inicialización simplificado - ya no necesita ser async
  static void initEnvironment() {
    // Ya no cargamos ningún archivo .env
    // Los valores están definidos directamente arriba
  }
}
