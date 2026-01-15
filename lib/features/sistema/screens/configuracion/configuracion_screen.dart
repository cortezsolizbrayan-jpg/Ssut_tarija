import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';

class ConfiguracionScreen extends StatefulWidget {
  static const name = 'configuracion';
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool notificationsEnabled = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(width * 0.05),
        children: [
          _buildSectionTitle('Cuenta'),
          _buildSettingItem(
            context,
            icon: Icons.person,
            title: 'Mis Datos Personales',
            subtitle: 'Editar información personal',
            onTap: () {
              context.push('/mis-datos-personales');
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.lock,
            title: 'Cambiar Contraseña',
            subtitle: 'Actualizar tu contraseña de acceso',
            onTap: () {
              // TODO: Implementar cambio de contraseña
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función en desarrollo')),
              );
            },
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
          _buildSectionTitle('Apariencia'),
          _buildSwitchItem(
            context,
            icon: Icons.dark_mode,
            title: 'Modo Oscuro',
            subtitle: 'Activar tema oscuro',
            value: darkMode,
            onChanged: (value) {
              setState(() {
                darkMode = value;
              });
            },
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Ayuda y Soporte'),
          _buildSettingItem(
            context,
            icon: Icons.help_outline,
            title: 'Centro de Ayuda',
            subtitle: 'Preguntas frecuentes y soporte',
            onTap: () {
              // TODO: Implementar centro de ayuda
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función en desarrollo')),
              );
            },
          ),
          _buildSettingItem(
            context,
            icon: Icons.info_outline,
            title: 'Acerca de',
            subtitle: 'Información de la aplicación',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Acerca de'),
                  content: const Text(
                    'Posgrado UPEA\nVersión 1.0.0\n\nSistema de gestión de programas de posgrado.',
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
          _buildSectionTitle('Sesión'),
          _buildSettingItem(
            context,
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Salir de tu cuenta',
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text(
                    '¿Estás seguro de que deseas cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await LocalStorageService.clearSessionData();
                        if (context.mounted) {
                          context.go('/login');
                        }
                      },
                      child: const Text(
                        'Cerrar Sesión',
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
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A3A5C),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.shade50
                : const Color(0xFF1A3A5C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : const Color(0xFF1A3A5C),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : const Color(0xFF1A3A5C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A5C).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1A3A5C), size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3A5C),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF1A3A5C),
        ),
      ),
    );
  }
}
