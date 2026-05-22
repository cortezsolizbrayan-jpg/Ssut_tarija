import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/core/widgets/offline_banner.dart';
import 'package:refactor_template/features/sistema/screens/contenedor/menu_lateral_scope.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/side_bar.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/barra_navegacion_inferior_personalizada.dart';

/// Shell principal que centraliza el Sidebar, el Menú y la animación 3D.
/// El botón de menú ahora se inyecta en el AppBar de cada pantalla
/// a través de [MenuLateralScope] y [BotonMenuLateral].
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  bool isSideBarOpen = false;
  final ValueNotifier<int> _sidebarRefreshTrigger = ValueNotifier<int>(0);

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 350),
        )..addListener(() {
          setState(() {});
        });

    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );

    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.992, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

//aqui se produce el controlador de la animacion

  @override
  void dispose() {
    _animationController.dispose();
    _entryController.dispose();
    _sidebarRefreshTrigger.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (isSideBarOpen) _closeSideBar();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _toggleMenu() {
    HapticFeedback.mediumImpact();
    final willOpen = !isSideBarOpen;
    if (_animationController.value == 0) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    setState(() {
      isSideBarOpen = willOpen;
    });
    if (willOpen) _sidebarRefreshTrigger.value++;
  }

  void _closeSideBar() {
    setState(() {
      isSideBarOpen = false;
      _animationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 288.0,
      tablet: 320.0,
      largeTablet: 340.0,
      desktop: 360.0,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          if (isSideBarOpen) {
            _closeSideBar();
            return;
          }
          //aqui se produce el inicio de la variable con la fecha de inicio 
          final now = DateTime.now();
          if (_lastBackPressTime == null ||
              now.difference(_lastBackPressTime!) >
                  const Duration(seconds: 2)) {
            _lastBackPressTime = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Presione de nuevo para salir'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }
          SystemNavigator.pop();
        },
        //AQUI SE ARMA EL SCAFFOOL CON TODOS LOS ELEMENTOS VISUALES 
        child: Scaffold(
          extendBody: true,
          resizeToAvoidBottomInset: false,
          backgroundColor: backgroundColor2,
          body: AnimatedBuilder(
            animation: _entryController,
            builder: (context, hijo) {
              return Stack(
                children: [
                  Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: hijo!,
                    ),
                  ),
                ],
              );
            },

          //AQUI SE ARMA EL MENU LATERAL 
            child: MenuLateralScope(
              onToggleMenu: _toggleMenu,
              isOpen: isSideBarOpen,
              child: Stack(
                children: [
                  // 1. Sidebar
                  AnimatedPositioned(
                    key: const ValueKey('sideBar'),
                    width: sidebarWidth,
                    height: MediaQuery.of(context).size.height,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOutCubic,
                    left: isSideBarOpen ? 0 : -sidebarWidth,
                    top: 0,
                    child: SideBar(
                      refreshTrigger: _sidebarRefreshTrigger,
                      onClose: _closeSideBar,
                    ),
                  ),

                  // 2. Contenido del shell con animación 3D
                  Transform(
                    key: const ValueKey('mainPantallaStack'),
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(
                        1 * animation.value - 30 * (animation.value) * pi / 180,
                      ),
                    child: Transform.translate(
                      offset: Offset(animation.value * (sidebarWidth - 23), 0),
                      child: Transform.scale(
                        scale: scalAnimation.value,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isSideBarOpen ? 24 : 0,
                          ),
                          child: widget.navigationShell,
                        ),
                      ),
                    ),
                  ),

                  // 3. Banner Offline
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: OfflineBanner(),
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: widget.navigationShell.currentIndex,
            onShellTap: _onNavTap,
          ),
        ),
      ),
    );
  }
}
