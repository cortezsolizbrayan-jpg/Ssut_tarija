import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/screens/mapa/pantalla_mapa.dart';

import '../../../../../config/menu/menu.dart';
import '../../../../../core/utils/rive_utils.dart';
import 'info_card.dart';
import 'side_menu.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key, this.refreshTrigger, this.onClose});

  final ValueNotifier<int>? refreshTrigger;
  final VoidCallback? onClose;

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;
  String _userName = 'Usuario';
  String _userBio = '';
  VoidCallback? _refreshListener;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _refreshListener = () => _loadUserInfo();
    widget.refreshTrigger?.addListener(_refreshListener!);
  }

  @override
  void dispose() {
    if (widget.refreshTrigger != null && _refreshListener != null) {
      widget.refreshTrigger!.removeListener(_refreshListener!);
    }
    super.dispose();
  }

  /// Refresca nombre y CI desde datos personales (p. ej. al abrir el menú).
  Future<void> _loadUserInfo() async {
    final personal = await LocalStorageService.getPersonalData();
    if (!mounted) return;

    String str(dynamic v) => (v?.toString() ?? '').trim();
    final nombre = str(personal?['nombre']);
    final apPaterno = str(personal?['apPaterno']);
    final apMaterno = str(personal?['apMaterno']);

    final nombreCompleto = [
      if (nombre.isNotEmpty) nombre,
      if (apPaterno.isNotEmpty) apPaterno,
      if (apMaterno.isNotEmpty) apMaterno,
    ].join(' ').trim();

    final ci = str(personal?['numeroCI']);
    final complemento = str(personal?['complemento']);
    final expedidoEn = str(personal?['expedidoEn']);

    final ciLine = [
      if (ci.isNotEmpty) 'CI: $ci',
      if (complemento.isNotEmpty) complemento,
      if (expedidoEn.isNotEmpty) expedidoEn,
    ].join(' ').trim();

    setState(() {
      _userName = nombreCompleto.isNotEmpty ? nombreCompleto : 'Usuario';
      _userBio = ciLine.isNotEmpty ? ciLine : _userBio;
    });
  }

  void _navigateToRoute(String menuTitle) {
    switch (menuTitle) {
      case 'Inicio':
        context.go('/sistema/pantalla_principal');
        break;
      case 'Principal Posgraduante':
        context.go('/sistema/pantalla_principal');
        break;
      case 'Mis Datos Personales':
        context.go('/mis-datos-personales');
        break;
      case 'Mis Documentos Personales':
        context.go('/mis-documentos-personales');
        break;
      case 'Mis Programas':
        context.go('/diplomados');
        break;
      case 'Programas Vigentes':
        context.go('/programas-vigentes');
        break;
      case 'Curriculum':
        context.go('/mi-curriculum');
        break;
      case 'Mapa de Ubicaciones':
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const MapaPantalla()));
        break;
      case 'Cambiar Contraseña':
        // TODO: Navegar a cambiar contraseña
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función en desarrollo'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'Historia':
        // TODO: Navegar a historia
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función en desarrollo'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'Notificationes':
        context.go('/configuracion-notificaciones');
        break;
      case 'Secciones Abiertas':
        // TODO: Navegar a secciones abiertas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Función en desarrollo'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
      case 'Cerrar Sesión':
        _showLogoutDialog(context);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 290,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF005BAC), // Azul institucional
              Color(0xFF004A8F), // Azul más oscuro
              Color(0xFF003870), // Azul aún más oscuro
            ],
          ),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(4, 0),
            ),
          ],
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con info del usuario
              InfoCard(name: _userName, bio: _userBio),

              // Divider decorativo
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Menú principal
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: sidebarMenus
                      .map(
                        (menu) => SideMenu(
                          menu: menu,
                          selectedMenu: selectedSideMenu,
                          press: () {
                            HapticFeedback.selectionClick();
                            RiveUtils.chnageSMIBoolState(menu.rive.status!);
                            setState(() {
                              selectedSideMenu = menu;
                            });
                            _navigateToRoute(menu.title);
                            widget.onClose
                                ?.call(); // Cerrar menú automáticamente
                          },
                          riveOnInit: (artboard) {
                            menu.rive.status = RiveUtils.getRiveInput(
                              artboard,
                              stateMachineName: menu.rive.stateMachineName,
                            );
                          },
                        ),
                      )
                      .toList(),
                ),
              ),

              // Botón de cerrar sesión al final
              Padding(
                padding: const EdgeInsets.all(16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showLogoutDialog(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white.withOpacity(0.9),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cerrar Sesión',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await LocalStorageService.clearSessionAndPin();
              if (context.mounted) context.go('/start-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

