import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/otros/servicio_inscripcion.dart';
import 'package:refactor_template/core/services/validation/servicio_validacion_requisitos.dart';
import 'package:refactor_template/core/services/otros/servicio_notificaciones.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/screens/inscripcion/pantalla_validacion_requisitos.dart';

/// Helper para validar requisitos antes de permitir inscripción
class HelperValidacionInscripcion {
  /// Valida los requisitos y muestra la pantalla correspondiente
  ///
  /// Si todos los requisitos están completos, ejecuta la inscripción
  /// Si faltan requisitos, muestra la pantalla de validación
  ///
  /// Retorna true si se puede continuar con la inscripción
  static Future<bool> validarYContinuar({
    required BuildContext context,
    required String tipoPrograma,
    required String nombrePrograma,
    required String idPrograma,
    String modalidad = 'Virtual',
    VoidCallback? onRequisitosCompletos,
  }) async {
    final servicio = ServicioValidacionRequisitos();

    // Guardar el nombre y tipo del programa en datos personales para que
    // la generación de carta use el programa correcto.
    try {
      final personalData = await LocalStorageService.getPersonalData() ?? {};
      personalData['nombreProgramaCarta'] = nombrePrograma;
      personalData['tipoProgramaCarta'] = tipoPrograma;
      personalData['modalidadProgramaCarta'] = modalidad;
      await LocalStorageService.savePersonalData(personalData);
    } catch (_) {
      // No bloquear el flujo si falla el guardado
    }

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
        ),
      ),
    );

    try {
      // Validar requisitos
      final puedeInscribirse = await servicio.puedeInscribirse(tipoPrograma);

      // Cerrar indicador de carga con seguridad
      if (context.mounted) {
        await Future.microtask(() {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }

      if (puedeInscribirse) {
        // Todos los requisitos están completos - proceder con inscripción
        if (context.mounted) {
          await _ejecutarInscripcion(
            context: context,
            idPrograma: idPrograma,
            nombrePrograma: nombrePrograma,
          );
        }
        onRequisitosCompletos?.call();
        return true;
      } else {
        // Faltan requisitos - mostrar pantalla de validación
        if (context.mounted) {
          final resultado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => PantallaValidacionRequisitos(
                tipoPrograma: tipoPrograma,
                nombrePrograma: nombrePrograma,
                modalidad: modalidad,
                idPrograma: idPrograma,
                onRequisitosCompletos: onRequisitosCompletos,
              ),
            ),
          );

          return resultado ?? false;
        }
        return false;
      }
    } catch (e) {
      // Cerrar indicador de carga con seguridad
      if (context.mounted) {
        await Future.microtask(() {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        // Mostrar error
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al validar requisitos: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return false;
    }
  }

  /// Muestra un diálogo con los documentos faltantes
  static Future<void> mostrarDocumentosFaltantes({
    required BuildContext context,
    required String tipoPrograma,
    required String idPrograma,
    String modalidad = 'Virtual',
  }) async {
    final servicio = ServicioValidacionRequisitos();

    try {
      final documentosFaltantes = await servicio.obtenerDocumentosFaltantes(
        tipoPrograma,
      );

      if (!context.mounted) return;

      if (documentosFaltantes.isEmpty) {
        // Todos los documentos están completos
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Requisitos Completos',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: const Text(
              'Todos los requisitos obligatorios están completos. Puede continuar con la inscripción.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Entendido',
                  style: TextStyle(color: Color(0xFF00D9FF)),
                ),
              ),
            ],
          ),
        );
      } else {
        // Mostrar documentos faltantes
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1D1E33),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Documentos Faltantes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Debe completar los siguientes requisitos:',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...documentosFaltantes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final documento = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D9FF).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF00D9FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              documento,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Navegar a pantalla de validación
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PantallaValidacionRequisitos(
                        tipoPrograma: tipoPrograma,
                        nombrePrograma: 'Programa de Posgrado',
                        idPrograma: idPrograma,
                        modalidad: modalidad,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                ),
                child: const Text(
                  'Completar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  /// Obtiene un widget badge que muestra el estado de requisitos
  static Widget buildBadgeEstado({
    required int completados,
    required int total,
  }) {
    final todosCompletos = completados == total;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: todosCompletos
            ? Colors.green.withOpacity(0.2)
            : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: todosCompletos ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            todosCompletos ? Icons.check_circle : Icons.warning,
            color: todosCompletos ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$completados/$total Requisitos',
            style: TextStyle(
              color: todosCompletos ? Colors.green : Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Ejecuta la inscripción y navega a la pantalla de confirmación
  static Future<void> _ejecutarInscripcion({
    required BuildContext context,
    required String idPrograma,
    required String nombrePrograma,
  }) async {
    // Mostrar loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF005BAC)),
                ),
                SizedBox(height: 16),
                Text(
                  'Enviando inscripción...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Por favor espera',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final servicioInscripcion = ServicioInscripcion();

      // Convertir ID de String a int
      final idProgramaInt = int.tryParse(idPrograma) ?? 0;

      if (idProgramaInt == 0) {
        throw Exception('ID de programa inválido');
      }

      // Enviar inscripción
      final resultado = await servicioInscripcion.enviarInscripcionCompleta(
        idPrograma: idProgramaInt,
      );

      // Cerrar loader
      if (context.mounted) {
        await Future.microtask(() {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }

      // Extraer datos del resultado
      final numeroInscripcion =
          resultado['id']?.toString() ??
          resultado['inscripcionId']?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final mensaje =
          resultado['mensaje']?.toString() ?? resultado['message']?.toString();

      // 🔔 ENVIAR NOTIFICACIONES
      final servicioNotificaciones = ServicioNotificaciones();

      // Notificación inmediata de éxito
      await servicioNotificaciones.notificarInscripcionExitosa(
        nombrePrograma: nombrePrograma,
        numeroInscripcion: numeroInscripcion,
      );

      // Recordatorio para subir comprobante (24 horas después)
      await servicioNotificaciones.recordatorioSubirComprobante(
        nombrePrograma: nombrePrograma,
      );

      // Navegar a pantalla de confirmación
      if (context.mounted) {
        context.push(
          '/confirmacion-inscripcion',
          extra: {
            'nombrePrograma': nombrePrograma,
            'numeroInscripcion': numeroInscripcion,
            'mensaje': mensaje,
          },
        );
      }
    } catch (e) {
      // Cerrar loader con seguridad
      if (context.mounted) {
        await Future.microtask(() {
          if (context.mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        // Mostrar error
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 28),
                  SizedBox(width: 12),
                  Text('Error en Inscripción'),
                ],
              ),
              content: Text(
                e.toString().replaceFirst('Exception: ', ''),
                style: const TextStyle(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.push('/mis-datos-personales');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BAC),
                  ),
                  child: const Text('Completar Datos'),
                ),
              ],
            ),
          );
        }
      }
    }
  }
}
