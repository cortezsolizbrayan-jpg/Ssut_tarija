import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Modelo ────────────────────────────────────────────────────────────────────

enum TipoNotificacion { inscripcion, pago, documento, recordatorio, general }

class AppNotificacion {
  final String id;
  final String titulo;
  final String mensaje;
  final DateTime fecha;
  final bool leida;
  final TipoNotificacion tipo;
  final String? payload;

  const AppNotificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    this.leida = false,
    this.tipo = TipoNotificacion.general,
    this.payload,
  });

  AppNotificacion copyWith({bool? leida}) => AppNotificacion(
    id: id,
    titulo: titulo,
    mensaje: mensaje,
    fecha: fecha,
    leida: leida ?? this.leida,
    tipo: tipo,
    payload: payload,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'mensaje': mensaje,
    'fecha': fecha.toIso8601String(),
    'leida': leida,
    'tipo': tipo.index,
    'payload': payload,
  };

  factory AppNotificacion.fromJson(Map<String, dynamic> j) => AppNotificacion(
    id: j['id'] as String,
    titulo: j['titulo'] as String,
    mensaje: j['mensaje'] as String,
    fecha: DateTime.parse(j['fecha'] as String),
    leida: j['leida'] as bool? ?? false,
    tipo: TipoNotificacion.values[j['tipo'] as int? ?? 4],
    payload: j['payload'] as String?,
  );
}

// ── Estado ────────────────────────────────────────────────────────────────────

class NotificacionesState {
  final List<AppNotificacion> items;
  final bool cargando;

  const NotificacionesState({this.items = const [], this.cargando = false});

  int get noLeidas => items.where((n) => !n.leida).length;
  // Alias para compatibilidad
  int get count => noLeidas;

  NotificacionesState copyWith({
    List<AppNotificacion>? items,
    bool? cargando,
  }) => NotificacionesState(
    items: items ?? this.items,
    cargando: cargando ?? this.cargando,
  );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class NotificacionesNotifier extends Notifier<NotificacionesState> {
  static const _key = 'app_notificaciones_v2';

  @override
  NotificacionesState build() {
    _cargar();
    return const NotificacionesState(cargando: true);
  }

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      List<AppNotificacion> items = [];
      if (raw != null) {
        final list = jsonDecode(raw) as List;
        items = list
            .map((e) => AppNotificacion.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      if (items.isEmpty) items = _ejemplos();
      state = NotificacionesState(items: items);
    } catch (e) {
      debugPrint('Error cargando notificaciones: $e');
      state = NotificacionesState(items: _ejemplos());
    }
  }

  Future<void> _guardar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(state.items.map((n) => n.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> agregar(AppNotificacion notif) async {
    state = state.copyWith(items: [notif, ...state.items]);
    await _guardar();
  }

  Future<void> marcarLeida(String id) async {
    state = state.copyWith(
      items: state.items
          .map((n) => n.id == id ? n.copyWith(leida: true) : n)
          .toList(),
    );
    await _guardar();
  }

  Future<void> marcarTodasLeidas() async {
    state = state.copyWith(
      items: state.items.map((n) => n.copyWith(leida: true)).toList(),
    );
    await _guardar();
  }

  Future<void> eliminar(String id) async {
    state = state.copyWith(
      items: state.items.where((n) => n.id != id).toList(),
    );
    await _guardar();
  }

  Future<void> limpiarLeidas() async {
    state = state.copyWith(items: state.items.where((n) => !n.leida).toList());
    await _guardar();
  }

  // Compatibilidad con código antiguo
  void clear() => marcarTodasLeidas();
  void increment() => agregar(
    AppNotificacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: 'Nueva notificación',
      mensaje: '',
      fecha: DateTime.now(),
    ),
  );

  List<AppNotificacion> _ejemplos() => [
    AppNotificacion(
      id: '1',
      titulo: 'Bienvenido a Posgrado UPEA',
      mensaje: 'Explora nuestros programas y comienza tu inscripción.',
      fecha: DateTime.now().subtract(const Duration(minutes: 5)),
      tipo: TipoNotificacion.general,
      payload: 'bienvenida',
    ),
    AppNotificacion(
      id: '2',
      titulo: 'Completa tu perfil',
      mensaje:
          'Agrega tu CI y datos personales para inscribirte en un programa.',
      fecha: DateTime.now().subtract(const Duration(hours: 2)),
      tipo: TipoNotificacion.documento,
      payload: 'perfil_incompleto',
    ),
    AppNotificacion(
      id: '3',
      titulo: 'Programas disponibles',
      mensaje: 'Hay nuevos programas de posgrado disponibles para inscripción.',
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      leida: true,
      tipo: TipoNotificacion.inscripcion,
      payload: 'programas_vigentes',
    ),
  ];
}

// ── Providers ─────────────────────────────────────────────────────────────────

final notificacionesProvider =
    NotifierProvider<NotificacionesNotifier, NotificacionesState>(
      NotificacionesNotifier.new,
    );

/// Conteo de no leídas — para el badge del icono.
final notificacionesCountProvider = Provider<int>(
  (ref) => ref.watch(notificacionesProvider).noLeidas,
);
