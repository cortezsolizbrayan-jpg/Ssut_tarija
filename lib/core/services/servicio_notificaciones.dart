import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Servicio para gestionar notificaciones locales
/// Optimizado para rendimiento y experiencia de usuario
class ServicioNotificaciones {
  static final ServicioNotificaciones _instance = ServicioNotificaciones._internal();
  factory ServicioNotificaciones() => _instance;
  ServicioNotificaciones._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Inicializar timezone
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('America/La_Paz'));

      // Configuración para Android
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración para iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Inicializar plugin
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;

      if (kDebugMode) {
        print('✅ Servicio de notificaciones inicializado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error inicializando notificaciones: $e');
      }
    }
  }

  /// Callback cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) {
      print('🔔 Notificación tocada: ${response.payload}');
    }
    // Aquí puedes agregar navegación basada en el payload
  }

  /// Solicita permisos de notificación (iOS principalmente)
  Future<bool> requestPermissions() async {
    if (!_initialized) await initialize();

    try {
      final result = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );

      return result ?? true; // Android no requiere permisos explícitos
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error solicitando permisos: $e');
      }
      return false;
    }
  }

  /// Muestra una notificación inmediata
  Future<void> mostrarNotificacion({
    required int id,
    required String titulo,
    required String mensaje,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!_initialized) await initialize();

    try {
      final androidDetails = AndroidNotificationDetails(
        'inscripcion_channel',
        'Inscripciones',
        channelDescription: 'Notificaciones sobre inscripciones y programas',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF005BAC),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        id,
        titulo,
        mensaje,
        details,
        payload: payload,
      );

      if (kDebugMode) {
        print('✅ Notificación mostrada: $titulo');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error mostrando notificación: $e');
      }
    }
  }

  /// Programa una notificación para el futuro
  Future<void> programarNotificacion({
    required int id,
    required String titulo,
    required String mensaje,
    required DateTime fechaHora,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    try {
      final androidDetails = AndroidNotificationDetails(
        'recordatorios_channel',
        'Recordatorios',
        channelDescription: 'Recordatorios de pagos y documentos',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFF005BAC),
        enableVibration: true,
        playSound: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        titulo,
        mensaje,
        tz.TZDateTime.from(fechaHora, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      if (kDebugMode) {
        print('✅ Notificación programada para: $fechaHora');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error programando notificación: $e');
      }
    }
  }

  /// Cancela una notificación específica
  Future<void> cancelarNotificacion(int id) async {
    try {
      await _notificationsPlugin.cancel(id);
      if (kDebugMode) {
        print('✅ Notificación $id cancelada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelando notificación: $e');
      }
    }
  }

  /// Cancela todas las notificaciones
  Future<void> cancelarTodas() async {
    try {
      await _notificationsPlugin.cancelAll();
      if (kDebugMode) {
        print('✅ Todas las notificaciones canceladas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error cancelando notificaciones: $e');
      }
    }
  }

  // ============================================================================
  // NOTIFICACIONES ESPECÍFICAS DE LA APP
  // ============================================================================

  /// Notificación de inscripción exitosa
  Future<void> notificarInscripcionExitosa({
    required String nombrePrograma,
    required String numeroInscripcion,
  }) async {
    await mostrarNotificacion(
      id: 1000,
      titulo: '✅ Inscripción Exitosa',
      mensaje: 'Te has inscrito en $nombrePrograma. Número: $numeroInscripcion',
      payload: 'inscripcion_exitosa',
    );
  }

  /// Recordatorio de subir comprobante de pago
  Future<void> recordatorioSubirComprobante({
    required String nombrePrograma,
    DateTime? fechaRecordatorio,
  }) async {
    final fecha = fechaRecordatorio ?? DateTime.now().add(const Duration(hours: 24));

    await programarNotificacion(
      id: 2000,
      titulo: '📄 Recordatorio: Comprobante de Pago',
      mensaje: 'No olvides subir tu comprobante de pago para $nombrePrograma',
      fechaHora: fecha,
      payload: 'recordatorio_comprobante',
    );
  }

  /// Recordatorio de completar documentos
  Future<void> recordatorioCompletarDocumentos({
    required String tipoDocumento,
    DateTime? fechaRecordatorio,
  }) async {
    final fecha = fechaRecordatorio ?? DateTime.now().add(const Duration(hours: 12));

    await programarNotificacion(
      id: 2001,
      titulo: '📋 Documentos Pendientes',
      mensaje: 'Recuerda completar: $tipoDocumento',
      fechaHora: fecha,
      payload: 'recordatorio_documentos',
    );
  }

  /// Notificación de inscripción aprobada (simulada)
  Future<void> notificarInscripcionAprobada({
    required String nombrePrograma,
  }) async {
    await mostrarNotificacion(
      id: 3000,
      titulo: '🎉 Inscripción Aprobada',
      mensaje: 'Tu inscripción en $nombrePrograma ha sido aprobada',
      payload: 'inscripcion_aprobada',
    );
  }

  /// Notificación de pago recibido (simulada)
  Future<void> notificarPagoRecibido({
    required String nombrePrograma,
    required String monto,
  }) async {
    await mostrarNotificacion(
      id: 3001,
      titulo: '💰 Pago Recibido',
      mensaje: 'Hemos recibido tu pago de $monto para $nombrePrograma',
      payload: 'pago_recibido',
    );
  }

  /// Recordatorio de fecha límite de inscripción
  Future<void> recordatorioFechaLimite({
    required String nombrePrograma,
    required DateTime fechaLimite,
  }) async {
    // Recordatorio 3 días antes
    final fecha3Dias = fechaLimite.subtract(const Duration(days: 3));
    if (fecha3Dias.isAfter(DateTime.now())) {
      await programarNotificacion(
        id: 4000,
        titulo: '⏰ Fecha Límite Próxima',
        mensaje: 'Quedan 3 días para inscribirte en $nombrePrograma',
        fechaHora: fecha3Dias,
        payload: 'fecha_limite_3dias',
      );
    }

    // Recordatorio 1 día antes
    final fecha1Dia = fechaLimite.subtract(const Duration(days: 1));
    if (fecha1Dia.isAfter(DateTime.now())) {
      await programarNotificacion(
        id: 4001,
        titulo: '⚠️ Último Día de Inscripción',
        mensaje: 'Mañana vence la inscripción para $nombrePrograma',
        fechaHora: fecha1Dia,
        payload: 'fecha_limite_1dia',
      );
    }
  }

  /// Notificación de inicio de clases
  Future<void> notificarInicioClases({
    required String nombrePrograma,
    required DateTime fechaInicio,
  }) async {
    // Recordatorio 1 semana antes
    final fecha1Semana = fechaInicio.subtract(const Duration(days: 7));
    if (fecha1Semana.isAfter(DateTime.now())) {
      await programarNotificacion(
        id: 5000,
        titulo: '📚 Inicio de Clases Próximo',
        mensaje: '$nombrePrograma inicia en 1 semana',
        fechaHora: fecha1Semana,
        payload: 'inicio_clases_1semana',
      );
    }

    // Recordatorio 1 día antes
    final fecha1Dia = fechaInicio.subtract(const Duration(days: 1));
    if (fecha1Dia.isAfter(DateTime.now())) {
      await programarNotificacion(
        id: 5001,
        titulo: '🎓 Clases Mañana',
        mensaje: 'Mañana inician las clases de $nombrePrograma',
        fechaHora: fecha1Dia,
        payload: 'inicio_clases_1dia',
      );
    }
  }

  /// Notificación de bienvenida al instalar la app
  Future<void> notificarBienvenida() async {
    await mostrarNotificacion(
      id: 9000,
      titulo: '👋 Bienvenido a Posgrado UPEA',
      mensaje: 'Explora nuestros programas y comienza tu inscripción',
      payload: 'bienvenida',
    );
  }

  /// Notificación de actualización de perfil
  Future<void> notificarPerfilIncompleto() async {
    await mostrarNotificacion(
      id: 9001,
      titulo: '👤 Completa tu Perfil',
      mensaje: 'Completa tu información para poder inscribirte',
      payload: 'perfil_incompleto',
    );
  }
}

/// Enum para prioridades de notificación
enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}
