import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

// ── Canales de notificación ───────────────────────────────────────────────────
// Cada canal tiene su propia importancia y sonido en Android 8+

const _chInscripcion = 'inscripcion_channel';
const _chRecordatorio = 'recordatorios_channel';
const _chDocumentos = 'documentos_channel';
const _chPagos = 'pagos_channel';
const _chGeneral = 'general_channel';

// ── IDs de notificación ───────────────────────────────────────────────────────
class _NotifId {
  static const inscripcionExitosa = 1000;
  static const inscripcionAprobada = 1001;
  static const pagoRecibido = 1002;
  static const comprobanteRecordatorio = 2000;
  static const documentosRecordatorio = 2001;
  static const fechaLimite3Dias = 4000;
  static const fechaLimite1Dia = 4001;
  static const inicioClases1Semana = 5000;
  static const inicioClases1Dia = 5001;
  static const bienvenida = 9000;
  static const perfilIncompleto = 9001;
}

/// Servicio de notificaciones locales para Posgrado UPEA.
///
/// Mejoras v2:
/// - Canales diferenciados por tipo (inscripción, pagos, documentos, recordatorios)
/// - Soporte para permisos Android 13+ (POST_NOTIFICATIONS)
/// - Navegación desde notificación via payload
/// - Singleton thread-safe
/// - Manejo robusto de errores con fallback silencioso
class ServicioNotificaciones {
  static final ServicioNotificaciones _instance =
      ServicioNotificaciones._internal();
  factory ServicioNotificaciones() => _instance;
  ServicioNotificaciones._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Callback opcional para navegación desde notificación
  static void Function(String payload)? onNotificationTapped;

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/La_Paz'));

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission:
            false, // Pedimos permisos explícitamente después
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: ios),
        onDidReceiveNotificationResponse: _onTapped,
        onDidReceiveBackgroundNotificationResponse: _onTappedBackground,
      );

      // Crear canales Android 8+
      await _crearCanalesAndroid();

      _initialized = true;
      debugPrint('✅ Notificaciones inicializadas');
    } catch (e) {
      debugPrint('❌ Error inicializando notificaciones: $e');
    }
  }

  Future<void> _crearCanalesAndroid() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (androidPlugin == null) return;

    final canales = [
      const AndroidNotificationChannel(
        _chInscripcion,
        'Inscripciones',
        description: 'Confirmaciones y estado de inscripciones',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _chRecordatorio,
        'Recordatorios',
        description: 'Recordatorios de fechas límite y tareas pendientes',
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _chDocumentos,
        'Documentos',
        description: 'Alertas sobre documentos pendientes o aprobados',
        importance: Importance.defaultImportance,
        playSound: false,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _chPagos,
        'Pagos',
        description: 'Confirmaciones y recordatorios de pago',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      const AndroidNotificationChannel(
        _chGeneral,
        'General',
        description: 'Notificaciones generales de la app',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    ];

    for (final canal in canales) {
      await androidPlugin.createNotificationChannel(canal);
    }
  }

  // ── Permisos ──────────────────────────────────────────────────────────────

  /// Solicita permisos de notificación.
  /// En Android 13+ solicita POST_NOTIFICATIONS.
  /// En iOS solicita alert/badge/sound.
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();
    try {
      // Android 13+
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? true;
      }

      // iOS
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? true;
    } catch (e) {
      debugPrint('Error solicitando permisos: $e');
      return false;
    }
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _onTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      debugPrint('Notificación tocada: $payload');
      onNotificationTapped?.call(payload);
    }
  }

  // Top-level para background
  static void _onTappedBackground(NotificationResponse response) {
    debugPrint('Notificación background: ${response.payload}');
  }

  // ── Helpers internos ──────────────────────────────────────────────────────

  AndroidNotificationDetails _androidDetails(
    String channelId, {
    String? largeIcon,
    bool ongoing = false,
  }) {
    return AndroidNotificationDetails(
      channelId,
      _channelName(channelId),
      importance: channelId == _chInscripcion || channelId == _chPagos
          ? Importance.high
          : Importance.defaultImportance,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFF005BAC),
      enableVibration: true,
      playSound: channelId != _chGeneral,
      ongoing: ongoing,
      styleInformation: const BigTextStyleInformation(''),
    );
  }

  String _channelName(String id) {
    switch (id) {
      case _chInscripcion:
        return 'Inscripciones';
      case _chRecordatorio:
        return 'Recordatorios';
      case _chDocumentos:
        return 'Documentos';
      case _chPagos:
        return 'Pagos';
      default:
        return 'General';
    }
  }

  Future<void> _mostrar({
    required int id,
    required String titulo,
    required String mensaje,
    required String channelId,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    try {
      await _plugin.show(
        id,
        titulo,
        mensaje,
        NotificationDetails(
          android: _androidDetails(channelId),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error mostrando notificación: $e');
    }
  }

  Future<void> _programar({
    required int id,
    required String titulo,
    required String mensaje,
    required DateTime fechaHora,
    required String channelId,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    if (fechaHora.isBefore(DateTime.now())) return; // No programar en el pasado
    try {
      await _plugin.zonedSchedule(
        id,
        titulo,
        mensaje,
        tz.TZDateTime.from(fechaHora, tz.local),
        NotificationDetails(
          android: _androidDetails(channelId),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      debugPrint('❌ Error programando notificación: $e');
    }
  }

  // ── API pública ───────────────────────────────────────────────────────────

  /// Muestra una notificación inmediata genérica.
  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String mensaje,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) => _mostrar(
    id: id,
    titulo: titulo,
    mensaje: mensaje,
    channelId: _chGeneral,
    payload: payload,
  );

  /// Programa una notificación para el futuro.
  Future<void> programarNotificacion({
    required int id,
    required String titulo,
    required String mensaje,
    required DateTime fechaHora,
    String? payload,
  }) => _programar(
    id: id,
    titulo: titulo,
    mensaje: mensaje,
    fechaHora: fechaHora,
    channelId: _chRecordatorio,
    payload: payload,
  );

  /// Cancela una notificación por ID.
  Future<void> cancelarNotificacion(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  /// Cancela todas las notificaciones.
  Future<void> cancelarTodas() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ── Notificaciones específicas ────────────────────────────────────────────

  Future<void> notificarInscripcionExitosa({
    required String nombrePrograma,
    required String numeroInscripcion,
  }) => _mostrar(
    id: _NotifId.inscripcionExitosa,
    titulo: '✅ Inscripción Exitosa',
    mensaje: 'Te inscribiste en $nombrePrograma. Nro: $numeroInscripcion',
    channelId: _chInscripcion,
    payload: 'inscripcion_exitosa',
  );

  Future<void> notificarInscripcionAprobada({required String nombrePrograma}) =>
      _mostrar(
        id: _NotifId.inscripcionAprobada,
        titulo: '🎉 Inscripción Aprobada',
        mensaje: 'Tu inscripción en $nombrePrograma fue aprobada',
        channelId: _chInscripcion,
        payload: 'inscripcion_aprobada',
      );

  Future<void> notificarPagoRecibido({
    required String nombrePrograma,
    required String monto,
  }) => _mostrar(
    id: _NotifId.pagoRecibido,
    titulo: 'Pago Recibido',
    mensaje: 'Recibimos tu pago de $monto para $nombrePrograma',
    channelId: _chPagos,
    payload: 'pago_recibido',
  );

  Future<void> recordatorioSubirComprobante({
    required String nombrePrograma,
    DateTime? fechaRecordatorio,
  }) => _programar(
    id: _NotifId.comprobanteRecordatorio,
    titulo: '📄 Sube tu Comprobante',
    mensaje: 'No olvides subir el comprobante de pago para $nombrePrograma',
    fechaHora:
        fechaRecordatorio ?? DateTime.now().add(const Duration(hours: 24)),
    channelId: _chPagos,
    payload: 'recordatorio_comprobante',
  );

  Future<void> recordatorioCompletarDocumentos({
    required String tipoDocumento,
    DateTime? fechaRecordatorio,
  }) => _programar(
    id: _NotifId.documentosRecordatorio,
    titulo: 'Documentos Pendientes',
    mensaje: 'Recuerda completar: $tipoDocumento',
    fechaHora:
        fechaRecordatorio ?? DateTime.now().add(const Duration(hours: 12)),
    channelId: _chDocumentos,
    payload: 'recordatorio_documentos',
  );

  Future<void> recordatorioFechaLimite({
    required String nombrePrograma,
    required DateTime fechaLimite,
  }) async {
    await _programar(
      id: _NotifId.fechaLimite3Dias,
      titulo: 'Fecha Límite en 3 días',
      mensaje: 'Quedan 3 días para inscribirte en $nombrePrograma',
      fechaHora: fechaLimite.subtract(const Duration(days: 3)),
      channelId: _chRecordatorio,
      payload: 'fecha_limite_3dias',
    );
    await _programar(
      id: _NotifId.fechaLimite1Dia,
      titulo: 'Último Día de Inscripción',
      mensaje: 'Mañana vence la inscripción para $nombrePrograma',
      fechaHora: fechaLimite.subtract(const Duration(days: 1)),
      channelId: _chRecordatorio,
      payload: 'fecha_limite_1dia',
    );
  }

  Future<void> notificarInicioClases({
    required String nombrePrograma,
    required DateTime fechaInicio,
  }) async {
    await _programar(
      id: _NotifId.inicioClases1Semana,
      titulo: 'Clases en 1 semana',
      mensaje: '$nombrePrograma inicia en 7 días',
      fechaHora: fechaInicio.subtract(const Duration(days: 7)),
      channelId: _chRecordatorio,
      payload: 'inicio_clases_1semana',
    );
    await _programar(
      id: _NotifId.inicioClases1Dia,
      titulo: 'Clases Mañana',
      mensaje: 'Mañana inician las clases de $nombrePrograma',
      fechaHora: fechaInicio.subtract(const Duration(days: 1)),
      channelId: _chRecordatorio,
      payload: 'inicio_clases_1dia',
    );
  }

  Future<void> notificarBienvenida() => _mostrar(
    id: _NotifId.bienvenida,
    titulo: 'Bienvenido a Posgrado UPEA',
    mensaje: 'Explora nuestros programas y comienza tu inscripción',
    channelId: _chGeneral,
    payload: 'bienvenida',
  );

  Future<void> notificarPerfilIncompleto() => _mostrar(
    id: _NotifId.perfilIncompleto,
    titulo: 'Completa tu Perfil',
    mensaje: 'Completa tu información para poder inscribirte',
    channelId: _chGeneral,
    payload: 'perfil_incompleto',
  );
}

/// Prioridades de notificación (compatibilidad con código existente).
enum NotificationPriority { low, medium, high, urgent }
