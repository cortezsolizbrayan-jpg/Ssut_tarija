import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';

import '../../../../../config/menu/menu.dart';
import '../../../../../core/utils/rive_utils.dart';
import 'info_card.dart';
import 'side_menu.dart';

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Menu selectedSideMenu = sidebarMenus.first;
  String _userName = 'Usuario';
  String _userBio = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final personal = await LocalStorageService.getPersonalData();
    if (!mounted) return;

    final nombre = (personal?['nombre'] as String?)?.trim();
    final apPaterno = (personal?['apPaterno'] as String?)?.trim();
    final apMaterno = (personal?['apMaterno'] as String?)?.trim();

    final nombreCompleto = [
      if (nombre != null && nombre.isNotEmpty) nombre,
      if (apPaterno != null && apPaterno.isNotEmpty) apPaterno,
      if (apMaterno != null && apMaterno.isNotEmpty) apMaterno,
    ].join(' ').trim();

    final ci = (personal?['numeroCI'] as String?)?.trim();
    final complemento = (personal?['complemento'] as String?)?.trim();
    final expedidoEn = (personal?['expedidoEn'] as String?)?.trim();

    final ciLine = [
      if (ci != null && ci.isNotEmpty) 'CI:$ci',
      if (complemento != null && complemento.isNotEmpty) complemento,
      if (expedidoEn != null && expedidoEn.isNotEmpty) expedidoEn,
    ].join(' ').trim();

    setState(() {
      _userName = nombreCompleto.isNotEmpty ? nombreCompleto : 'Usuario';
      _userBio = ciLine;
    });
  }

  void _navigateToRoute(String menuTitle) {
    switch (menuTitle) {
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
        // TODO: Navegar a programas vigentes
        break;
      case 'Curriculum':
        context.go('/mi-curriculum');
        break;
      case 'Cambiar Contraseña':
        // TODO: Navegar a cambiar contraseña
        break;
      case 'Secciones Abiertas':
        // TODO: Navegar a secciones abiertas
        break;
      case 'Cerrar Sesión':
        context.go('/login');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        width: 288,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF17203A),
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
        child: DefaultTextStyle(
          style: const TextStyle(color: Colors.white),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoCard(name: _userName, bio: _userBio),
              const SizedBox(height: 16),
              // Padding(
              //   padding: const EdgeInsets.only(left: 24, top: 32, bottom: 16),
              //   child: Text(
              //     "Browse".toUpperCase(),
              //     style: Theme.of(
              //       context,
              //     ).textTheme.titleMedium!.copyWith(color: Colors.white70),
              //   ),
              // ),
              ...sidebarMenus.map(
                (menu) => SideMenu(
                  menu: menu,
                  selectedMenu: selectedSideMenu,
                  press: () {
                    RiveUtils.chnageSMIBoolState(menu.rive.status!);
                    setState(() {
                      selectedSideMenu = menu;
                    });
                    _navigateToRoute(menu.title);
                  },
                  riveOnInit: (artboard) {
                    menu.rive.status = RiveUtils.getRiveInput(
                      artboard,
                      stateMachineName: menu.rive.stateMachineName,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 40, bottom: 16),
                child: Text(
                  "History".toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white70),
                ),
              ),
              ...sidebarMenus2.map(
                (menu) => SideMenu(
                  menu: menu,
                  selectedMenu: selectedSideMenu,
                  press: () {
                    RiveUtils.chnageSMIBoolState(menu.rive.status!);
                    setState(() {
                      selectedSideMenu = menu;
                    });
                    _navigateToRoute(menu.title);
                  },
                  riveOnInit: (artboard) {
                    menu.rive.status = RiveUtils.getRiveInput(
                      artboard,
                      stateMachineName: menu.rive.stateMachineName,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
