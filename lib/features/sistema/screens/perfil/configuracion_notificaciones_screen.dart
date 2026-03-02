import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refactor_template/core/services/servicio_notificaciones.dart';

/// Pantalla para configurar preferencias de notificaciones
class ConfiguracionNotificacionesScreen extends StatefulWidget {
  static const String name = 'configuracion-notificaciones';

  const ConfiguracionNotificacionesScreen({super.key});

  @override
  State<ConfiguracionNotificacionesScreen> createState() =>
      _ConfiguracionNotificacionesScreenState();
}

class _ConfiguracionNotificacionesScreenState
    extends State<ConfiguracionNotificacionesScreen> {
  // Preferencias de notificaciones
  bool _notificacionesActivas = true;
  bool _inscripcionExitosa = true;
  bool _recordatorioComprobante = true;
  bool _recordatorioDocumentos = true;
  bool _fechasLimite = true;
  bool _inicioClases = true;
  bool _actualizacionesPerfil = true;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  Future<void> _cargarPreferencias() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificacionesActivas = prefs.getBool('notif_activas') ?? true;
        _inscripcionExitosa = prefs.getBool('notif_inscripcion') ?? true;
        _recordatorioComprobante = prefs.getBool('notif_comprobante') ?? true;
        _recordatorioDocumentos = prefs.getBool('notif_documentos') ?? true;
        _fechasLimite = prefs.getBool('notif_fechas') ?? true;
        _inicioClases = prefs.getBool('notif_clases') ?? true;
        _actualizacionesPerfil = prefs.getBool('notif_perfil') ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _guardarPreferencia(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Error silencioso
    }
  }

  Future<void> _probarNotificacion() async {
    final servicio = ServicioNotificaciones();
    await servicio.mostrarNotificacion(
      id: 99999,
      titulo: '🔔 Notificación de Prueba',
      mensaje: 'Las notificaciones están funcionando correctamente',
      payload: 'test',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación de prueba enviada'),
          backgroundColor: Color(0xFF4CAF50),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFF005BAC),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta principal
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005BAC).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: Color(0xFF005BAC),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mantente Informado',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF333333),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Recibe actualizaciones importantes',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF666666),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 12),

                        // Switch principal
                        _buildSwitchTile(
                          icon: Icons.notifications,
                          title: 'Notificaciones',
                          subtitle: 'Activar o desactivar todas las notificaciones',
                          value: _notificacionesActivas,
                          onChanged: (value) async {
                            setState(() => _notificacionesActivas = value);
                            await _guardarPreferencia('notif_activas', value);
                            
                            if (!value) {
                              // Cancelar todas las notificaciones programadas
                              final servicio = ServicioNotificaciones();
                              await servicio.cancelarTodas();
                            }
                          },
                          isMain: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sección de tipos de notificaciones
                  const Text(
                    'Tipos de Notificaciones',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          icon: Icons.check_circle_outline,
                          title: 'Inscripción Exitosa',
                          subtitle: 'Confirma cuando tu inscripción sea exitosa',
                          value: _inscripcionExitosa && _notificacionesActivas,
                          onChanged: _notificacionesActivas
                              ? (value) async {
                                  setState(() => _inscripcionExitosa = value);
                                  await _guardarPreferencia('notif_inscripcion', value);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.receipt_long,
                          title: 'Recordatorio de Comprobante',
                          subtitle: 'Te recordamos subir tu comprobante de pago',
                          value: _recordatorioComprobante && _notificacionesActivas,
                          onChanged: _notificacionesActivas
                              ? (value) async {
                                  setState(() => _recordatorioComprobante = value);
                                  await _guardarPreferencia('notif_comprobante', value);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.folder_open,
                          title: 'Documentos Pendientes',
                          subtitle: 'Recordatorios de documentos faltantes',
                          value: _recordatorioDocumentos && _notificacionesActivas,
                          onChanged: _notificacionesActivas
                              ? (value) async {
                                  setState(() => _recordatorioDocumentos = value);
                                  await _guardarPreferencia('notif_documentos', value);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.event,
                          title: 'Fechas Límite',
                          subtitle: 'Alertas de fechas límite de inscripción',
                          value: _fechasLimite && _notificacionesActivas,
                          onChanged: _notificacionesActivas
                              ? (value) async {
                                  setState(() => _fechasLimite = value);
                                  await _guardarPreferencia('notif_fechas', value);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.school,
                          title: 'Inicio de Clases',
                          subtitle: 'Recordatorios de inicio de clases',
                          value: _inicioClases && _notificacionesActivas,
                          onChanged: _notificacionesActivas
                              ? (value) async {
                                  setState(() => _inicioClases = value);
                                  await _guardarPreferencia('notif_clases', value);
                                }
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildSwitchTile(
                          icon: Icons.person,
                          title: 'Actualizaciones de Perfil',
                          subtitle: 'Recordatorios para completar tu perfil',
                          value: _actualizacionesPerfil && _notificacionesActivas,
                          onChanged: _notificacionesActivas
                              ? (value) async {
                                  setState(() => _actualizacionesPerfil = value);
                                  await _guardarPreferencia('notif_perfil', value);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Botón de prueba
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _notificacionesActivas ? _probarNotificacion : null,
                      icon: const Icon(Icons.notifications_active, size: 20),
                      label: const Text(
                        'Enviar Notificación de Prueba',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF005BAC),
                        side: const BorderSide(
                          color: Color(0xFF005BAC),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información adicional
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005BAC).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF005BAC).withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF005BAC),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Las notificaciones te ayudan a estar al día con tu proceso de inscripción y no perder fechas importantes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool isMain = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMain
                  ? const Color(0xFF005BAC).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: isMain ? const Color(0xFF005BAC) : Colors.grey[700],
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: onChanged == null
                        ? Colors.grey[400]
                        : const Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: onChanged == null
                        ? Colors.grey[300]
                        : const Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF005BAC),
          ),
        ],
      ),
    );
  }
}
