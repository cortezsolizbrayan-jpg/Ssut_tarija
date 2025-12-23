import 'dart:math';

import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/features/sistema/screens/perfil/perfil_screen.dart';
import 'package:rive/rive.dart';

import 'components/menu_btn.dart';
import 'components/side_bar.dart';

/// Pantalla principal del sistema (luego de iniciar sesión).
///
/// Contiene el menú lateral, la barra inferior y el contenido central.
class PantallaPrincipal extends StatefulWidget {
  static const name = '/sistema/pantalla_principal';
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal>
    with SingleTickerProviderStateMixin {
  bool isSideBarOpen = false;

  late SMIBool isMenuOpenInput;

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  @override
  void initState() {
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350), // Más suave
        )..addListener(() {
          setState(() {});
        });
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic, // Curva más suave
      ),
    );
    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic, // Curva más suave
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor2,
      body: Stack(
        children: [
          AnimatedPositioned(
            key: const ValueKey('sideBar'),
            width: 288,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: isSideBarOpen ? 0 : -288,
            top: 0,
            child: const SideBar(),
          ),
          Transform(
            key: const ValueKey('mainScreen'),
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(
                1 * animation.value - 30 * (animation.value) * pi / 180,
              ),
            child: Transform.translate(
              offset: Offset(animation.value * 265, 0),
              child: Transform.scale(
                scale: scalAnimation.value,
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  child: PerfilScreen(),
                ),
              ),
            ),
          ),
          AnimatedPositioned(
            key: const ValueKey('menuBtn'),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOutCubic,
            left: isSideBarOpen ? 220 : 0,
            top: MediaQuery.of(context).padding.top + 16,
            child: MenuBtn(
              press: () {
                try {
                  isMenuOpenInput.value = !isMenuOpenInput.value;

                  if (_animationController.value == 0) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }

                  setState(() {
                    isSideBarOpen = !isSideBarOpen;
                  });
                } catch (e) {
                  print("Error al abrir menú: $e");
                  // Fallback por si falla Rive
                  if (_animationController.value == 0) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                  setState(() {
                    isSideBarOpen = !isSideBarOpen;
                  });
                }
              },
              riveOnInit: (artboard) {
                final controller = StateMachineController.fromArtboard(
                  artboard,
                  "State Machine",
                );

                if (controller != null) {
                  artboard.addController(controller);
                  isMenuOpenInput =
                      controller.findInput<bool>("isOpen") as SMIBool;
                  isMenuOpenInput.value = true;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
