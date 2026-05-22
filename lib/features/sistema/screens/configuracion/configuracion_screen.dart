import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:refactor_template/config/providers/theme_mode_provider.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  static const name = 'configuracion';
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  // ── Colores institucionales ────────────────────────────────────────────────
  static const _primaryBlue = Color(0xFF005BAC);
  static const _darkBg = Color(0xFF0F172A);
  static const _darkCard = Color(0xFF1E293B);
  static const _lightBg = Color(0xFFEEF1F8);

  // ── Estado ─────────────────────────────────────────────────────────────────
  bool _notificationsEnabled = true;
  String _nombreUsuario = '';
  String _ciUsuario = '';
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final personal = await LocalStorageService.getPersonalData();
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      final nombre = personal?['nombre']?.toString() ?? '';
      final apPaterno = personal?['apPaterno']?.toString() ?? '';
      _nombreUsuario = [
        nombre,
        apPaterno,
      ].where((s) => s.isNotEmpty).join(' ').trim();
      if (_nombreUsuario.isEmpty) _nombreUsuario = 'Usuario';
      _ciUsuario = personal?['numeroCI']?.toString() ?? '';
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final darkMode = themeMode == ThemeMode.dark;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? _darkBg : _lightBg,
      body: CustomScrollView(
        slivers: [
          // ── AppBar expandible con avatar ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: isDark ? _darkCard : _primaryBlue,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
              ),
              onPressed: () => context.pop(),
            ),
            title: const Text(
              'Configuración',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [_primaryBlue, const Color(0xFF003F7A)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Row(
                      children: [
                        // Avatar
                        ProfileAvatarWidget(
                          radius: 32,
                          showShadow: true,
                          onTap: () => context.push('/mis-datos-personales'),
                        ),
                        const SizedBox(width: 16),
                        // Nombre y CI
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _nombreUsuario,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_ciUsuario.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'CI: $_ciUsuario',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFC900),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'POSGRADUANTE ACTIVO',
                                  style: TextStyle(
                                    color: Color(0xFF0D1730),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botón editar perfil
                        IconButton(
                          onPressed: () =>
                              context.push('/mis-datos-personales'),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 18,
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

          // ── Contenido ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Cuenta
                _SectionHeader(title: 'Cuenta', isDark: isDark),
                _SettingCard(
                  isDark: isDark,
                  children: [
                    _SettingTile(
                      icon: Icons.person_outline_rounded,
                      title: 'Mis Datos Personales',
                      subtitle: 'Editar información personal',
                      isDark: isDark,
                      onTap: () => context.push('/mis-datos-personales'),
                    ),
                    _Divider(isDark: isDark),
                    _SettingTile(
                      icon: Icons.folder_outlined,
                      title: 'Mis Documentos',
                      subtitle: 'Gestionar archivos y documentos',
                      isDark: isDark,
                      onTap: () => context.push('/mis-documentos-personales'),
                    ),
                    _Divider(isDark: isDark),
                    _SettingTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'Cambiar Contraseña',
                      subtitle: 'Actualizar tu contraseña de acceso',
                      isDark: isDark,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función en desarrollo'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                    _Divider(isDark: isDark),
                    _SettingTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'Seguridad Biométrica',
                      subtitle: 'PIN y huella digital',
                      isDark: isDark,
                      onTap: () => context.push('/biometric-setup'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Notificaciones
                _SectionHeader(title: 'Notificaciones', isDark: isDark),
                _SettingCard(
                  isDark: isDark,
                  children: [
                    _SwitchTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notificaciones Push',
                      subtitle: 'Recibir alertas en tiempo real',
                      value: _notificationsEnabled,
                      isDark: isDark,
                      onChanged: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                    _Divider(isDark: isDark),
                    _SettingTile(
                      icon: Icons.tune_rounded,
                      title: 'Preferencias',
                      subtitle: 'Personalizar qué notificaciones recibir',
                      isDark: isDark,
                      onTap: () =>
                          context.push('/configuracion-notificaciones'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Apariencia
                _SectionHeader(title: 'Apariencia', isDark: isDark),
                _SettingCard(
                  isDark: isDark,
                  children: [
                    _SwitchTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Modo Oscuro',
                      subtitle: 'Activar tema oscuro',
                      value: darkMode,
                      isDark: isDark,
                      onChanged: (v) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(v ? ThemeMode.dark : ThemeMode.light);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Ayuda
                _SectionHeader(title: 'Ayuda y Soporte', isDark: isDark),
                _SettingCard(
                  isDark: isDark,
                  children: [
                    _SettingTile(
                      icon: Icons.help_outline_rounded,
                      title: 'Centro de Ayuda',
                      subtitle: 'Preguntas frecuentes y soporte',
                      isDark: isDark,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Función en desarrollo'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      ),
                    ),
                    _Divider(isDark: isDark),
                    _SettingTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Acerca de',
                      subtitle: 'Posgrado UPEA · v$_appVersion',
                      isDark: isDark,
                      onTap: () => _mostrarAcercaDe(context),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Sesión
                _SectionHeader(title: 'Sesión', isDark: isDark),
                _SettingCard(
                  isDark: isDark,
                  children: [
                    _SettingTile(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar Sesión',
                      subtitle: 'Salir de tu cuenta',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () => _confirmarCerrarSesion(context),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Versión al pie
                Center(
                  child: Text(
                    'Posgrado UPEA · v$_appVersion',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Diálogos ───────────────────────────────────────────────────────────────

  void _mostrarAcercaDe(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: _primaryBlue,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Posgrado UPEA',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versión: $_appVersion'),
            const SizedBox(height: 8),
            const Text(
              'Sistema de gestión de programas de posgrado de la Universidad Pública de El Alto.',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.clearSessionAndPin();
              if (context.mounted) context.go('/start-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
        ),
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.grey.withOpacity(0.12),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDark;
  final bool isDestructive;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isDark,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isDestructive
        ? Colors.red
        : (isDark ? Colors.white70 : const Color(0xFF005BAC));
    final iconBg = isDestructive
        ? Colors.red.withOpacity(0.1)
        : (isDark
              ? Colors.white.withOpacity(0.08)
              : const Color(0xFF005BAC).withOpacity(0.08));
    final titleColor = isDestructive
        ? Colors.red
        : (isDark ? Colors.white : const Color(0xFF1A3A5C));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isDestructive)
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final bool isDark;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF005BAC);
    final iconColor = value
        ? activeColor
        : (isDark ? Colors.white70 : activeColor);
    final iconBg = value
        ? activeColor.withOpacity(0.12)
        : (isDark
              ? Colors.white.withOpacity(0.08)
              : activeColor.withOpacity(0.08));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1A3A5C),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.35),
            inactiveThumbColor: isDark
                ? Colors.grey.shade400
                : Colors.grey.shade300,
            inactiveTrackColor: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}
