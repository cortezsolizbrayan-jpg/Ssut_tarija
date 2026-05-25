import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/widgets/offline_banner.dart';
import 'package:refactor_template/features/sistema/screens/inicio/pantalla_inicio_optimizada.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/barra_navegacion_inferior_personalizada.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;

import 'components/menu_btn.dart';
import 'components/side_bar.dart';

/// Pantalla principal del sistema (luego de iniciar sesión).
///
/// Contiene el menú lateral, la barra inferior y el contenido central.
/// Incluye animación de entrada estilo Windows 11.
class PantallaPrincipal extends StatefulWidget {
  static const name = '/sistema/pantalla_principal';
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal>
    with TickerProviderStateMixin {
  bool isSideBarOpen = false;
  final ValueNotifier<int> _sidebarRefreshTrigger = ValueNotifier<int>(0);

  late SMIBool isMenuOpenInput;

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  // Animación de entrada
  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        context.go('/diplomados');
        break;
      case 1:
        context.go('/programas-vigentes');
        break;
      case 2:
        context.go('/sistema/pantalla_principal');
        break;
      case 3:
        context.go('/mi-curriculum');
        break;
      case 4:
        context.go('/mis-documentos-personales');
        break;
    }
  }

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    // NO usar addListener con setState — usar AnimatedBuilder en el build

    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    // Animación de entrada
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Reducido de 1400ms
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar animación de entrada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _entryController.dispose();
    _sidebarRefreshTrigger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            // Usar solo Opacity + Scale — sin ImageFilter.blur (muy costoso en GPU)
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: child!,
              ),
            );
          },
          child: Stack(
            children: [
              AnimatedPositioned(
                key: const ValueKey('sideBar'),
                width: 288,
                height: MediaQuery.of(context).size.height,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
                left: isSideBarOpen ? 0 : -288,
                top: 0,
                child: SideBar(refreshTrigger: _sidebarRefreshTrigger),
              ),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) => Transform(
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
                      child: child,
                    ),
                  ),
                ),
                child: const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                  child: InicioPantalla(),
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
                    HapticFeedback.mediumImpact();
                    try {
                      final willOpen = !isSideBarOpen;
                      isMenuOpenInput.value = !isMenuOpenInput.value;

                      if (_animationController.value == 0) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }

                      setState(() {
                        isSideBarOpen = !isSideBarOpen;
                      });
                      if (willOpen) _sidebarRefreshTrigger.value++;
                    } catch (e) {
                      debugPrint("Error al abrir menú: $e");
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
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: OfflineBanner(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: 2,
          onShellTap: _onNavTap,
        ),
      ),
    );
  }
}
