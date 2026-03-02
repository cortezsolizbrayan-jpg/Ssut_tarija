import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/core/widgets/offline_banner.dart';
import 'package:refactor_template/features/sistema/screens/perfil/perfil_screen.dart';
import 'package:rive/rive.dart'
    hide LinearGradient, Image, Animation, PaintingStyle;

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
  
  // Animación de entrada estilo Windows 11
  late AnimationController _entryController;
  late Animation<double> _blurAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
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
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Animación de entrada estilo Windows 11
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    
    _blurAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    // Iniciar animación de entrada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.lightImpact();
      _entryController.forward().then((_) {
        if (mounted) {
          setState(() => _showContent = true);
        }
      });
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
        backgroundColor: backgroundColor2,
        body: AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            return Stack(
              children: [
                // Contenido principal con blur y fade
                ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: _blurAnimation.value,
                    sigmaY: _blurAnimation.value,
                  ),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child!,
                    ),
                  ),
                ),
              ],
            );
          },
          // OnboardingOverlay removido - ya no se muestra la pantalla flotante de bienvenida
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
      ),
    );
  }
}
