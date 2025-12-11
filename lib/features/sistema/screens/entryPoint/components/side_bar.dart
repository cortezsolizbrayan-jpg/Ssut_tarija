import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  void _navigateToRoute(String menuTitle) {
    switch (menuTitle) {
      case 'Inicio':
        context.go('/perfil');
        break;
      case 'Mis Programas':
        context.go('/diplomados');
        break;
      case 'Curriculum':
        context.go('/mi-curriculum');
        break;
      case 'Mis Datos Personales':
        context.go('/mis-datos-personales');
        break;
      case 'Cambiar Contraseña':
        // TODO: Navegar a pantalla de cambiar contraseña
        break;
      case 'Historia':
        // TODO: Navegar a pantalla de historia
        break;
      case 'Notificationes':
        context.go('/notificaciones');
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
              const InfoCard(
                name: "Guadalupe Flores Mamani",
                bio: "CI:9225528 LP",
              ),
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
