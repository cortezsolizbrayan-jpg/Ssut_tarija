import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/otros/servicio_biometrico.dart';

/// Pantalla de splash simple con logo animado.
/// Navega a /start-screen o /autenticacion-rapida según el estado de seguridad.
class SplashPantalla extends StatefulWidget {
  static const name = 'splash-page';
  const SplashPantalla({super.key});

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasNavigated) {
        _controller.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_hasNavigated) _navigateToNext();
        });
      }
    });

    // Timeout de seguridad: si algo falla, navega igual
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_hasNavigated) _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    try {
      final biometricService = BiometricService();
      final hasSecurityConfigured = await biometricService
          .hasSecurityConfigured()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);

      if (!mounted) return;

      if (hasSecurityConfigured) {
        context.go('/autenticacion-rapida');
      } else {
        context.go('/start-screen');
      }
    } catch (e) {
      debugPrint('Error en splash: $e');
      if (mounted) context.go('/start-screen');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logoposgrado.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF005BAC),
                      ),
                      strokeWidth: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
