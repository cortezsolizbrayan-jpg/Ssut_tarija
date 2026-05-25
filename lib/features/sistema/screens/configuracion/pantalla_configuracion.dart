import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';

class ConfiguracionPantalla extends ConsumerStatefulWidget {
  static const name = 'configuracion';
  const ConfiguracionPantalla({super.key});

  @override
  ConsumerState<ConfiguracionPantalla> createState() =>
      _ConfiguracionPantallaState();
}

class _ConfiguracionPantallaState extends ConsumerState<ConfiguracionPantalla> {
  bool notificationsEnabled = true;
  final bool _checkingUpdate = false;
  String? _currentVersion;

  Future<void> _mostrarEnviarSugerenciaSheet(BuildContext context) async {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    Future<void> sendSuggestion() async {
      final subject = subjectController.text.trim();
      final message = messageController.text.trim();

      if (subject.isEmpty || message.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa el asunto y el mensaje.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final session = await LocalStorageService.getSessionData();
      final nombreUsuario =
          (session?['nombreUsuario'] as String?)?.trim() ?? '';
      final ci = (session?['ci'] as String?)?.trim() ?? '';

      final body =
          '''
Sugerencia de usuario
Nombre: ${nombreUsuario.isEmpty ? 'N/D' : nombreUsuario}
CI: ${ci.isEmpty ? 'N/D' : ci}

Mensaje:
$message
''';

      final uri = Uri(
        scheme: 'mailto',
        path: 'posgrado@upea.edu.bo',
        queryParameters: <String, String>{
          'subject': 'Sugerencia App Posgrado: $subject',
          'body': body,
        },
      );

      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        await Clipboard.setData(
          ClipboardData(text: 'Asunto: $subject\n\n$body'),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir correo. Sugerencia copiada.'),
              backgroundColor: Color(0xFF005BAC),
            ),
          );
        }
      }
    }

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
        final hPad = ResponsiveUtils.horizontalPadding(ctx);
        final titleSize = ResponsiveUtils.subtitleFontSize(ctx);
        final bodySize = ResponsiveUtils.bodyFontSize(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.feedback_outlined,
                      color: Color(0xFF005BAC),
                    ),
                    SizedBox(width: ResponsiveUtils.scale(ctx, 10)),
                    Expanded(
                      child: Text(
                        'Enviar sugerencia',
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: subjectController,
                  textInputAction: TextInputAction.next,
                  style: TextStyle(fontSize: bodySize),
                  decoration: InputDecoration(
                    labelText: 'Asunto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  style: TextStyle(fontSize: bodySize),
                  decoration: InputDecoration(
                    labelText: 'Mensaje',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A5F),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await sendSuggestion();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005BAC),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text(
                          'Enviar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _mostrarDialogoDesactivarCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Desactivar Cuenta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Â¿Deseas desactivar temporalmente tu cuenta?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Al desactivar tu cuenta:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildInfoItem('No podrÃ¡s iniciar sesiÃ³n', Icons.lock_outline),
            _buildInfoItem('Tus datos se conservan', Icons.save_outlined),
            _buildInfoItem('Puedes reactivarla cuando quieras', Icons.refresh),
            _buildInfoItem(
              'No se elimina ningÃºn dato',
              Icons.check_circle_outline,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta es una opciÃ³n reversible. Puedes reactivar tu cuenta contactando a posgrado@upea.edu.bo',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4CAF50)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmarDesactivacionCuenta(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF005BAC), size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _confirmarDesactivacionCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar DesactivaciÃ³n'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tu cuenta serÃ¡ desactivada inmediatamente.',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              'Para reactivarla, envÃ­a un correo a:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'posgrado@upea.edu.bo',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF005BAC),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // Simular desactivaciÃ³n
              await Future.delayed(const Duration(seconds: 2));

              if (context.mounted) {
                Navigator.pop(context); // Cerrar loading

                // Mostrar pantalla de cuenta desactivada
                _mostrarPantallaCuentaDesactivada(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar DesactivaciÃ³n'),
          ),
        ],
      ),
    );
  }

  void _mostrarPantallaCuentaDesactivada(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de pausa
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pause_circle_filled,
                    size: 50,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // TÃ­tulo
                const Text(
                  'Cuenta Desactivada',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensaje
                const Text(
                  'Tu cuenta ha sido desactivada temporalmente.',
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tus datos estÃ¡n seguros y puedes reactivarla cuando quieras.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Para reactivar tu cuenta',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'EnvÃ­a un correo a:\nposgrado@upea.edu.bo\n\n'
                        'Asunto: Reactivar Cuenta\n'
                        'Incluye tu nombre y CI',
                        style: TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BotÃ³n para volver al inicio
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Cerrar diÃ¡logo

                      // Limpiar datos de sesiÃ³n y PIN
                      await LocalStorageService.clearSessionAndPin();

                      if (context.mounted) {
                        context.go('/start-screen');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005BAC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Volver al Inicio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _mostrarDialogoEliminarCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Eliminar Cuenta'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Â¿EstÃ¡s seguro de que deseas eliminar tu cuenta?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta acciÃ³n es permanente e irreversible. Se eliminarÃ¡n:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildDeleteItem('InformaciÃ³n personal'),
            _buildDeleteItem('Documentos subidos'),
            _buildDeleteItem('Historial de inscripciones'),
            _buildDeleteItem('Historial de pagos'),
            _buildDeleteItem('Configuraciones'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF005BAC), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Los registros acadÃ©micos oficiales se conservan segÃºn normativa universitaria.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF005BAC)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmarEliminacionCuenta(context);
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.close, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmarEliminacionCuenta(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ConfirmaciÃ³n Final'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu solicitud de eliminaciÃ³n serÃ¡ procesada en un plazo de 30 dÃ­as.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'RecibirÃ¡s un correo de confirmaciÃ³n con instrucciones adicionales.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.email_outlined, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TambiÃ©n puedes solicitar la eliminaciÃ³n por correo a: posgrado@upea.edu.bo',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              // Mostrar loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) =>
                    const Center(child: CircularProgressIndicator()),
              );

              // Simular envÃ­o de solicitud
              await Future.delayed(const Duration(seconds: 2));

              if (context.mounted) {
                Navigator.pop(context); // Cerrar loading

                // Mostrar pantalla de cuenta eliminada
                _mostrarPantallaCuentaEliminada(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar EliminaciÃ³n'),
          ),
        ],
      ),
    );
  }

  void _mostrarPantallaCuentaEliminada(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de Ã©xito
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    size: 50,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // TÃ­tulo
                const Text(
                  'Cuenta Eliminada',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAC),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensaje
                const Text(
                  'Tu solicitud de eliminaciÃ³n ha sido registrada exitosamente.',
                  style: TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'RecibirÃ¡s un correo de confirmaciÃ³n en las prÃ³ximas 24 horas.',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Proceso de eliminaciÃ³n',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'â€¢ VerificaciÃ³n de identidad: 24-48 horas\n'
                        'â€¢ EliminaciÃ³n de datos: hasta 30 dÃ­as\n'
                        'â€¢ NotificaciÃ³n final por correo',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // BotÃ³n para volver al inicio
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Cerrar diÃ¡logo

                      // Limpiar datos de sesiÃ³n y PIN
                      await LocalStorageService.clearSessionAndPin();

                      // Volver a la pantalla de bienvenida/login
                      if (context.mounted) {
                        context.go('/start-screen');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005BAC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Volver al Inicio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BAC), // Azul Institucional
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'ConfiguraciÃ³n',
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.subtitleFontSize(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        children: [
          _buildSectionTitle('Cuenta'),
          _buildSettingItem(
            context,
            icon: Icons.person,
            title: 'Mis Datos Personales',
            subtitle: 'Editar informaciÃ³n personal',
            onTap: () {
              context.push('/mis-datos-personales');
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.lock,
            title: 'Cambiar ContraseÃ±a',
            subtitle: 'Actualizar tu contraseÃ±a de acceso',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FunciÃ³n en desarrollo')),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.pause_circle_outline,
            title: 'Desactivar Cuenta',
            subtitle: 'Desactivar temporalmente tu cuenta',
            onTap: () => _mostrarDialogoDesactivarCuenta(context),
          ),
          _buildSettingItem(
            context,
            icon: Icons.delete_forever,
            title: 'Eliminar Cuenta',
            subtitle: 'Eliminar permanentemente tu cuenta y datos',
            onTap: () => _mostrarDialogoEliminarCuenta(context),
            isDestructive: true,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Notificaciones'),
          _buildSwitchItem(
            context,
            icon: Icons.notifications,
            title: 'Notificaciones Push',
            subtitle: 'Recibir notificaciones en tiempo real',
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Ayuda y Soporte'),
          _buildSettingItem(
            context,
            icon: Icons.feedback_outlined,
            title: 'Enviar sugerencia',
            subtitle: 'AyÃºdanos a mejorar la app con tu opiniÃ³n',
            onTap: () => _mostrarEnviarSugerenciaSheet(context),
          ),
          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: 'Centro de Ayuda',
            subtitle: 'Preguntas frecuentes y soporte',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('FunciÃ³n en desarrollo')),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'Acerca de',
            subtitle: 'InformaciÃ³n de la aplicaciÃ³n',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Acerca de'),
                  content: const Text(
                    'Posgrado UPEA\nVersiÃ³n 1.0.0\n\nSistema de gestiÃ³n de programas de posgrado.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('SesiÃ³n'),
          _buildSettingItem(
            context,
            icon: Icons.logout,
            title: 'Cerrar SesiÃ³n',
            subtitle: 'Salir de tu cuenta',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar SesiÃ³n'),
                  content: const Text(
                    'Â¿EstÃ¡s seguro de que deseas cerrar sesiÃ³n?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await LocalStorageService.clearSessionAndPin();
                        if (context.mounted) {
                          context.go('/start-screen');
                        }
                      },
                      child: const Text(
                        'Cerrar SesiÃ³n',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.cardSpacing(context),
        top: ResponsiveUtils.cardSpacing(context) * 0.67,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveUtils.bodyFontSize(context) * 1.14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF005BAC), // Azul Institucional
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.only(bottom: ResponsiveUtils.scale(context, 8)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: ResponsiveUtils.scale(context, 40),
          height: ResponsiveUtils.scale(context, 40),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.shade50
                : const Color(0xFF005BAC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF005BAC),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.subtitleFontSize(context) - 2,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : const Color(0xFF1E3A5F),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveUtils.bodyFontSize(context) - 1,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      margin: EdgeInsets.only(bottom: ResponsiveUtils.scale(context, 8)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: ResponsiveUtils.scale(context, 40),
          height: ResponsiveUtils.scale(context, 40),
          decoration: BoxDecoration(
            color: value
                ? const Color(0xFF005BAC).withOpacity(0.2)
                : const Color(0xFF005BAC).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF005BAC), size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: ResponsiveUtils.subtitleFontSize(context) - 2,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E3A5F),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: ResponsiveUtils.bodyFontSize(context) - 1,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF005BAC),
          activeTrackColor: const Color(0xFF005BAC).withOpacity(0.5),
        ),
      ),
    );
  }
}



