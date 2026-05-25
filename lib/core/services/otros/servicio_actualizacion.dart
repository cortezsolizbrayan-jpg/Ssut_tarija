import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Colores y radios del aviso de actualización (alineados con marca UPEA).
abstract final class _ActualizacionUi {
  static const Color primary = Color(0xFF005BAC);
  static const Color primaryDark = Color(0xFF003F7A);
  static const Color surface = Color(0xFFF5F7FC);
  static const Color onSurface = Color(0xFF1A2744);
  static const Color muted = Color(0xFF5C6B8A);
  static const Color critical = Color(0xFFE53935);
  static const Color criticalBg = Color(0xFFFFEBEE);
  static const double radius = 24;
}

class ServicioActualizacion {
  static final ServicioActualizacion _instancia =
      ServicioActualizacion._internal();
  factory ServicioActualizacion() => _instancia;
  ServicioActualizacion._internal();

  AppUpdateInfo? _infoActualizacion;
  bool _verificando = false;
  bool _actualizacionDisponible = false;
  String? _versionActual;
  String? _ultimaVersion;
  bool _yaReportadoNoPoseido = false;

  bool _esExcepcionAppNoPoseida(Object e) {
    if (e is! PlatformException) return false;
    final raw = '${e.code} ${e.message} ${e.details}'.toUpperCase();
    return raw.contains('ERROR_APP_NOT_OWNED') ||
        raw.contains('INSTALL ERROR(-10)');
  }

  /// Verifica si hay una actualización disponible
  Future<bool> verificarActualizacion() async {
    if (_verificando) return _actualizacionDisponible;
    if (!Platform.isAndroid) return false;

    _verificando = true;

    try {
      // Obtener info de la app actual
      final packageInfo = await PackageInfo.fromPlatform();
      _versionActual = packageInfo.version;

      // Verificar actualización en Play Store con timeout para evitar bloqueos (ANR)
      _infoActualizacion = await InAppUpdate.checkForUpdate().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Timeout verificando actualización (5s)');
          throw TimeoutException('Play Store no respondió a tiempo');
        },
      );

      _actualizacionDisponible =
          _infoActualizacion?.updateAvailability ==
          UpdateAvailability.updateAvailable;

      if (_actualizacionDisponible) {
        _ultimaVersion = _infoActualizacion?.availableVersionCode.toString();
        debugPrint(
          'Actualización disponible: $_versionActual -> $_ultimaVersion',
        );
      }

      return _actualizacionDisponible;
    } catch (e) {
      // Caso común en APK debug/sideload o error de estado de dispositivo (-6)
      if (_esExcepcionAppNoPoseida(e) || e.toString().contains('-6')) {
        if (!_yaReportadoNoPoseido) {
          _yaReportadoNoPoseido = true;
          debugPrint(
            'Actualización automática deshabilitada o no permitida por el dispositivo (Error -6 / Not Owned).',
          );
        }
        return false;
      }
      debugPrint('Error silencioso verificando actualización: $e');
      return false;
    } finally {
      _verificando = false;
    }
  }

  /// Inicia la actualización flexible (permite seguir usando la app)
  Future<bool> iniciarActualizacionFlexible() async {
    if (_infoActualizacion == null || !_actualizacionDisponible) return false;

    try {
      await InAppUpdate.startFlexibleUpdate();
      return true;
    } catch (e) {
      debugPrint('Error iniciando actualización flexible: $e');
      return false;
    }
  }

  /// Completa la actualización flexible (requiere reinicio)
  Future<bool> completarActualizacionFlexible() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (e) {
      debugPrint('Error completando actualización: $e');
      return false;
    }
  }

  /// Inicia actualización inmediata (bloquea la app hasta completar)
  Future<bool> iniciarActualizacionInmediata() async {
    if (_infoActualizacion == null || !_actualizacionDisponible) return false;

    try {
      await InAppUpdate.performImmediateUpdate();
      return true;
    } catch (e) {
      debugPrint('Error iniciando actualización inmediata: $e');
      return false;
    }
  }

  /// Verifica si la actualización flexible está lista para completar
  Future<bool> get actualizacionFlexibleListaParaCompletar {
    return _verificarSiActualizacionDescargada();
  }

  Future<bool> _verificarSiActualizacionDescargada() async {
    final info = await InAppUpdate.checkForUpdate();
    return info.installStatus == InstallStatus.downloaded;
  }

  /// Cancelar actualización en progreso
  Future<void> cancelarActualizacion() async {
    // El plugin no expone cancelación explícita de update en versiones recientes.
    debugPrint('Cancelación de actualización no soportada por in_app_update');
  }

  // Getters (mantenidos en inglés para compatibilidad con código existente)
  bool get isUpdateAvailable => _actualizacionDisponible;
  bool get isChecking => _verificando;
  String? get currentVersion => _versionActual;
  String? get latestVersion => _ultimaVersion;
  AppUpdateInfo? get updateInfo => _infoActualizacion;

  /// Método completo: verifica y actualiza automáticamente si es crítico
  Future<void> verificarYActualizarAutomaticamente(
    BuildContext contexto, {
    bool isCritical = false,
    bool autoStart = true,
  }) async {
    final hayActualizacion = await verificarActualizacion();

    if (!hayActualizacion) return;
    if (!contexto.mounted) return;

    final info = _infoActualizacion;
    if (info == null) return;

    // Intento más automático posible (Play Core igual mostrará UI del sistema).
    if (autoStart) {
      if (isCritical && info.immediateUpdateAllowed) {
        final ok = await iniciarActualizacionInmediata();
        if (!contexto.mounted) return;
        if (ok) return;
      }

      // Si no es crítica, intentar flexible en background y completar.
      if (!isCritical && info.flexibleUpdateAllowed) {
        final iniciado = await iniciarActualizacionFlexible();
        if (!contexto.mounted) return;
        if (iniciado && contexto.mounted) {
          await _monitorearProgresoActualizacion(contexto);
          return;
        }
      }
    }

    // Fallback a UI propia (cuando no se permite immediate/flexible o falla).
    if (isCritical) {
      await _mostrarDialogoActualizacionCritica(contexto);
    } else {
      await mostrarDialogoActualizacionNormal(contexto);
    }
  }

  /// Muestra diálogo de actualización normal (no crítico)
  Future<void> mostrarDialogoActualizacionNormal(BuildContext contexto) async {
    if (!_actualizacionDisponible) return;

    final actualizar = await showDialog<bool>(
      context: contexto,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_ActualizacionUi.radius),
              boxShadow: [
                BoxShadow(
                  color: _ActualizacionUi.primary.withValues(alpha: 0.18),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_ActualizacionUi.radius),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _ActualizacionUi.primary,
                          _ActualizacionUi.primaryDark,
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Nueva versión',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Mejoras y correcciones te esperan',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_ultimaVersion != null &&
                            _ultimaVersion!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _ActualizacionUi.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: _ActualizacionUi.primary.withValues(
                                  alpha: 0.12,
                                ),
                              ),
                            ),
                            child: Text(
                              'Build disponible: $_ultimaVersion',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _ActualizacionUi.primary,
                              ),
                            ),
                          ),
                        if (_versionActual != null &&
                            _versionActual!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Versión instalada: $_versionActual',
                            style: const TextStyle(
                              fontSize: 13,
                              color: _ActualizacionUi.muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        const Text(
                          'Puedes actualizar en segundo plano. Cuando termine la descarga, reinicia la app para aplicar los cambios.',
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.45,
                            color: _ActualizacionUi.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ActualizacionUi.onSurface,
                              side: BorderSide(
                                color: _ActualizacionUi.primary.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Más tarde'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () async {
                              Navigator.of(ctx).pop(true);
                              await iniciarActualizacionFlexible();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: _ActualizacionUi.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Actualizar ahora'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (actualizar == true && contexto.mounted) {
      await _monitorearProgresoActualizacion(contexto);
    }
  }

  Future<void> _mostrarDialogoActualizacionCritica(
    BuildContext contexto,
  ) async {
    if (!contexto.mounted) return;

    await showDialog(
      context: contexto,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(_ActualizacionUi.radius),
                boxShadow: [
                  BoxShadow(
                    color: _ActualizacionUi.critical.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_ActualizacionUi.radius),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      color: _ActualizacionUi.criticalBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _ActualizacionUi.critical.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.shield_moon_rounded,
                                  color: _ActualizacionUi.critical,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Text(
                                  'Actualización obligatoria',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _ActualizacionUi.onSurface,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Esta versión incluye mejoras importantes de seguridad y estabilidad. Debes actualizar para continuar.',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: _ActualizacionUi.onSurface.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FilaVersion(
                            etiqueta: 'Instalada',
                            valor: _versionActual ?? '—',
                          ),
                          const SizedBox(height: 10),
                          _FilaVersion(
                            etiqueta: 'Requerida',
                            valor: _ultimaVersion ?? '—',
                            resaltar: true,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: FilledButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          await iniciarActualizacionInmediata();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _ActualizacionUi.critical,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Actualizar ahora',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _monitorearProgresoActualizacion(BuildContext contexto) async {
    if (!contexto.mounted) return;

    final progreso = ValueNotifier<double>(0.05);
    final textoEstado = ValueNotifier<String>('Preparando actualización...');

    // Mostrar indicador de progreso
    if (contexto.mounted) {
      showDialog(
        context: contexto,
        barrierDismissible: false,
        builder: (context) => _DialogoProgresoActualizacion(
          progreso: progreso,
          textoEstado: textoEstado,
        ),
      );
    }

    // Monitorear estado hasta que quede descargada (lista para completar)
    bool lista = false;
    for (var i = 0; i < 60; i++) {
      // ~60s máximo
      try {
        final info = await InAppUpdate.checkForUpdate();
        final estado = info.installStatus;
        final mapeado = _mapearEstadoInstalacionAUi(estado);
        progreso.value = mapeado.$1;
        textoEstado.value = mapeado.$2;
        lista = estado == InstallStatus.downloaded;
      } catch (_) {
        textoEstado.value = 'Verificando descarga...';
      }
      if (lista) break;
      await Future.delayed(const Duration(seconds: 1));
    }

    if (contexto.mounted) {
      Navigator.of(contexto).pop(); // Cerrar diálogo de progreso
    }

    progreso.dispose();
    textoEstado.dispose();

    if (lista && contexto.mounted) {
      await completarActualizacionFlexible();
      if (contexto.mounted) {
        _mostrarDialogoReinicioRequerido(contexto);
      }
    }
  }

  static (double, String) _mapearEstadoInstalacionAUi(InstallStatus estado) {
    switch (estado) {
      case InstallStatus.pending:
        return (0.15, 'Esperando inicio de descarga...');
      case InstallStatus.downloading:
        return (0.45, 'Descargando actualización...');
      case InstallStatus.downloaded:
        return (0.9, 'Descarga completa. Preparando instalación...');
      case InstallStatus.installing:
        return (0.95, 'Instalando actualización...');
      case InstallStatus.installed:
        return (1.0, 'Actualización instalada.');
      case InstallStatus.failed:
        return (0.2, 'Falló la descarga. Reintentando...');
      case InstallStatus.canceled:
        return (0.2, 'Actualización cancelada.');
      case InstallStatus.unknown:
        return (0.1, 'Verificando actualización...');
    }
  }

  void _mostrarDialogoReinicioRequerido(BuildContext contexto) {
    showDialog(
      context: contexto,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_ActualizacionUi.radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF2E7D32),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Listo para aplicar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ActualizacionUi.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'La actualización se descargó correctamente. Reinicia la app para usar la nueva versión.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: _ActualizacionUi.muted,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        exit(0);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Reiniciar ahora',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilaVersion extends StatelessWidget {
  const _FilaVersion({
    required this.etiqueta,
    required this.valor,
    this.resaltar = false,
  });

  final String etiqueta;
  final String valor;
  final bool resaltar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: resaltar
            ? _ActualizacionUi.primary.withValues(alpha: 0.08)
            : _ActualizacionUi.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: resaltar
              ? _ActualizacionUi.primary.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Text(
            etiqueta,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _ActualizacionUi.muted,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: resaltar
                    ? _ActualizacionUi.primary
                    : _ActualizacionUi.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget diálogo de progreso de actualización
class _DialogoProgresoActualizacion extends StatefulWidget {
  const _DialogoProgresoActualizacion({
    required this.progreso,
    required this.textoEstado,
  });

  final ValueNotifier<double> progreso;
  final ValueNotifier<String> textoEstado;

  @override
  State<_DialogoProgresoActualizacion> createState() =>
      _DialogoProgresoActualizacionState();
}

class _DialogoProgresoActualizacionState
    extends State<_DialogoProgresoActualizacion> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_ActualizacionUi.radius),
            boxShadow: [
              BoxShadow(
                color: _ActualizacionUi.primary.withValues(alpha: 0.15),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: widget.progreso,
                  builder: (context, value, _) => SizedBox(
                    height: 56,
                    width: 56,
                    child: CircularProgressIndicator(
                      value: value < 0.05 ? null : value.clamp(0.0, 1.0),
                      strokeWidth: 3,
                      color: _ActualizacionUi.primary,
                      backgroundColor: _ActualizacionUi.primary.withValues(
                        alpha: 0.12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                ValueListenableBuilder<String>(
                  valueListenable: widget.textoEstado,
                  builder: (context, value, _) => Text(
                    value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _ActualizacionUi.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mantén la app abierta un momento. Esto puede tardar según tu conexión.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: _ActualizacionUi.muted,
                  ),
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ValueListenableBuilder<double>(
                    valueListenable: widget.progreso,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: _ActualizacionUi.primary.withValues(
                        alpha: 0.1,
                      ),
                      color: _ActualizacionUi.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

