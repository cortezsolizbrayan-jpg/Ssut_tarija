import 'dart:async';

/// Sistema de caché centralizado para la aplicación
/// Maneja caché en memoria con TTL (Time To Live)
class AppCache {
  static final _cache = <String, CacheEntry>{};
  static final _timers = <String, Timer>{};

  /// Obtiene un valor del caché
  /// Retorna null si no existe o está expirado
  static T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (entry.isExpired) {
      invalidate(key);
      return null;
    }

    return entry.value as T;
  }

  /// Guarda un valor en el caché con TTL
  static void set<T>(
    String key,
    T value, {
    Duration ttl = const Duration(minutes: 5),
  }) {
    // Cancelar timer anterior si existe
    _timers[key]?.cancel();

    // Guardar en caché
    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );

    // Programar limpieza automática
    _timers[key] = Timer(ttl, () {
      invalidate(key);
    });
  }

  /// Invalida una entrada específica del caché
  static void invalidate(String key) {
    _cache.remove(key);
    _timers[key]?.cancel();
    _timers.remove(key);
  }

  /// Invalida múltiples entradas que coincidan con un patrón
  static void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      invalidate(key);
    }
  }

  /// Limpia todo el caché
  static void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _cache.clear();
    _timers.clear();
  }

  /// Obtiene el tamaño actual del caché
  static int get size => _cache.length;

  /// Verifica si una key existe en el caché
  static bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (entry.isExpired) {
      invalidate(key);
      return false;
    }
    return true;
  }
}

/// Entrada de caché con valor y tiempo de expiración
class CacheEntry {
  final dynamic value;
  final DateTime expiresAt;

  CacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Keys de caché predefinidas para consistencia
class CacheKeys {
  // Programas
  static const programasVigentes = 'programas_vigentes';
  static const programasDisponibles = 'programas_disponibles';
  static String programaDetalle(String id) => 'programa_$id';

  // Usuario
  static const datosPersonales = 'datos_personales';
  static const documentosPersonales = 'documentos_personales';
  static const curriculum = 'curriculum';
  static const sessionData = 'session_data';

  // Validaciones
  static String validacionRequisitos(String tipo) => 'validacion_$tipo';

  // Imágenes
  static String imagenPerfil(String userId) => 'imagen_perfil_$userId';
  static String imagenPrograma(String programaId) => 'imagen_programa_$programaId';
}
