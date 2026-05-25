import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:refactor_template/core/services/otros/servicio_notificaciones.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';

/// 🔔 PANTALLA DE CONFIGURACIÓN DE NOTIFICACIONES - V0.4.4
/// 
/// Pantalla especializada para gestionar todas las preferencias de notificaciones
/// del usuario en el sistema UPEA. Permite activar/desactivar diferentes tipos
/// de notificaciones y probar el funcionamiento del sistema.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Control maestro de todas las notificaciones
/// ✅ Configuración granular por tipo de notificación
/// ✅ Persistencia de preferencias con SharedPreferences
/// ✅ Notificación de prueba para verificar funcionamiento
/// ✅ Interfaz responsive con colores UPEA
/// ✅ Estados deshabilitados cuando notificaciones están off
/// ✅ Feedback visual inmediato de cambios
/// 
/// TIPOS DE NOTIFICACIONES SOPORTADAS:
/// - Inscripción exitosa: Confirmación de inscripción completada
/// - Recordatorio de comprobante: Alertas para subir comprobantes de pago
/// - Documentos pendientes: Recordatorios de documentos faltantes
/// - Fechas límite: Alertas de fechas límite de inscripción
/// - Inicio de clases: Recordatorios de inicio de clases
/// - Actualizaciones de perfil: Recordatorios para completar perfil
/// 
/// FUNCIONALIDADES AVANZADAS:
/// - Switch maestro que controla todas las notificaciones
/// - Cancelación automática de notificaciones programadas
/// - Notificación de prueba con payload personalizado
/// - Estados visuales para opciones deshabilitadas
/// - Información contextual sobre la importancia de notificaciones
/// 
/// INTEGRACIÓN:
/// - SharedPreferences para persistencia de configuración
/// - ServicioNotificaciones para gestión de notificaciones
/// - ResponsiveUtils para diseño adaptativo
/// - Colores y tipografía del sistema UPEA
class ConfiguracionNotificacionesPantalla extends StatefulWidget {
  static const String name = 'configuracion-notificaciones';

  const ConfiguracionNotificacionesPantalla({super.key});

  @override
  State<ConfiguracionNotificacionesPantalla> createState() =>
      _ConfiguracionNotificacionesPantallaState();
}

class _ConfiguracionNotificacionesPantallaState
    extends State<ConfiguracionNotificacionesPantalla> {
  
  // 🔔 PREFERENCIAS DE NOTIFICACIONES
  /// Control maestro de todas las notificaciones del sistema
  bool _notificacionesActivas = true;
  
  /// Notificación cuando la inscripción es exitosa
  bool _inscripcionExitosa = true;
  
  /// Recordatorios para subir comprobantes de pago
  bool _recordatorioComprobante = true;
  
  /// Alertas de documentos pendientes por subir
  bool _recordatorioDocumentos = true;
  
  /// Notificaciones de fechas límite importantes
  bool _fechasLimite = true;
  
  /// Recordatorios de inicio de clases
  bool _inicioClases = true;
  
  /// Alertas para completar información del perfil
  bool _actualizacionesPerfil = true;

  // ⏳ ESTADO DE CARGA
  /// Indica si la pantalla está cargando las preferencias iniciales
  bool _loading = true;

  /// 🚀 INICIALIZACIÓN DEL Widget
  /// 
  /// Configura el estado inicial y carga las preferencias guardadas.
  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  /// 📂 CARGAR PREFERENCIAS DESDE ALMACENAMIENTO LOCAL
  /// 
  /// Recupera todas las preferencias de notificaciones guardadas en SharedPreferences.
  /// Si no existen preferencias previas, usa valores por defecto (todas activadas).
  /// 
  /// PROCESO:
  /// 1. Obtiene instancia de SharedPreferences
  /// 2. Lee cada preferencia con valor por defecto true
  /// 3. Actualiza el estado de la UI con los valores cargados
  /// 4. Desactiva el indicador de carga
  /// 5. Maneja errores silenciosamente
  /// 
  /// CLAVES DE PREFERENCIAS:
  /// - 'notif_activas': Control maestro de notificaciones
  /// - 'notif_inscripcion': Notificaciones de inscripción exitosa
  /// - 'notif_comprobante': Recordatorios de comprobantes
  /// - 'notif_documentos': Alertas de documentos pendientes
  /// - 'notif_fechas': Notificaciones de fechas límite
  /// - 'notif_clases': Recordatorios de inicio de clases
  /// - 'notif_perfil': Actualizaciones de perfil
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

  /// 💾 GUARDAR PREFERENCIA INDIVIDUAL
  /// 
  /// Guarda una preferencia específica en SharedPreferences de forma asíncrona.
  /// Maneja errores silenciosamente para no interrumpir la experiencia del usuario.
  /// 
  /// @param key - Clave de la preferencia a guardar
  /// @param value - Valor booleano de la preferencia
  /// @return Future<void> - Operación asíncrona de guardado
  Future<void> _guardarPreferencia(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      // Error silencioso
    }
  }

  /// 🧪 PROBAR NOTIFICACIÓN
  /// 
  /// Envía una notificación de prueba para verificar que el sistema funciona correctamente.
  /// Útil para que el usuario confirme que las notificaciones están configuradas
  /// y funcionando en su dispositivo.
  /// 
  /// CARACTERÍSTICAS DE LA NOTIFICACIÓN DE PRUEBA:
  /// - ID único (99999) para evitar conflictos
  /// - Título con emoji para llamar la atención
  /// - Mensaje descriptivo del propósito
  /// - Payload 'test' para identificación
  /// 
  /// FEEDBACK AL USUARIO:
  /// - SnackBar verde de confirmación
  /// - Duración de 2 segundos
  /// - Solo se muestra si el Widget está montado
  /// 
  /// @return Future<void> - Operación asíncrona de envío
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

  /// 🎨 CONSTRUCCIÓN DE LA INTERFAZ PRINCIPAL
  /// 
  /// Construye la interfaz completa de configuración de notificaciones.
  /// Utiliza diseño responsive y colores del sistema UPEA.
  /// 
  /// ESTRUCTURA DE LA UI:
  /// 1. Scaffold con color de fondo institucional (#EEF1F8)
  /// 2. AppBar con título y colores UPEA
  /// 3. Indicador de carga mientras se cargan preferencias
  /// 4. ScrollView con contenido principal:
  ///    - Tarjeta principal con switch maestro
  ///    - Sección de tipos de notificaciones
  ///    - Botón de prueba de notificaciones
  ///    - Información adicional sobre importancia
  /// 
  /// CARACTERÍSTICAS RESPONSIVE:
  /// - Espaciado adaptativo con ResponsiveUtils
  /// - Fuentes escalables según tamaño de pantalla
  /// - Padding y márgenes proporcionales
  /// - Widgets que se adaptan a diferentes dispositivos
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Notificaciones',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: ResponsiveUtils.subtitleFontSize(context),
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
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta principal
                  Container(
                    padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(ResponsiveUtils.cardBorderRadius(context)),
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
                              padding: EdgeInsets.all(ResponsiveUtils.cardSpacing(context)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF005BAC).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(ResponsiveUtils.buttonBorderRadius(context)),
                              ),
                              child: Icon(
                                Icons.notifications_active,
                                color: const Color(0xFF005BAC),
                                size: ResponsiveUtils.mediumIconSize(context),
                              ),
                            ),
                            SizedBox(width: ResponsiveUtils.cardSpacing(context)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mantente Informado',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: ResponsiveUtils.subtitleFontSize(context),
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF333333),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
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

  /// 🎛️ CONSTRUIR ELEMENTO SWITCH
  /// 
  /// Crea un elemento de configuración con switch para activar/desactivar
  /// un tipo específico de notificación. Incluye icono, título, descripción y switch.
  /// 
  /// CARACTERÍSTICAS:
  /// - Icono temático en contenedor redondeado
  /// - Título y subtítulo descriptivos
  /// - Switch con colores UPEA
  /// - Estados deshabilitados cuando corresponde
  /// - Colores diferenciados para switch principal vs secundarios
  /// 
  /// ESTADOS VISUALES:
  /// - Habilitado: Colores normales, switch funcional
  /// - Deshabilitado: Colores grises, switch no funcional
  /// - Principal: Colores azules UPEA para destacar
  /// - Secundario: Colores grises para elementos dependientes
  /// 
  /// @param icon - Icono de Material Design para el tipo de notificación
  /// @param title - Título descriptivo del tipo de notificación
  /// @param subtitle - Descripción detallada de cuándo se envía
  /// @param value - Estado actual del switch (activado/desactivado)
  /// @param onChanged - Callback para manejar cambios, null para deshabilitar
  /// @param isMain - Si es el switch principal (control maestro)
  /// @return Widget con el elemento switch completo
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


