import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de splash simple con icono animado.
class SplashScreen extends StatefulWidget {
  static const name = 'splash-page';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Animación mínima y rápida
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Muy rápido
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    // Navegar inmediatamente - no esperar animación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasNavigated) {
        // Iniciar animación en background (no bloquea)
        _controller.forward();
        // Navegar después de un delay mínimo (200ms) - reducido aún más
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted && !_hasNavigated) {
            _navigateToLogin();
          }
        });
      }
    });

    // Timeout de seguridad muy corto: 800ms máximo
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && !_hasNavigated) {
        _navigateToLogin();
      }
    });
  }

  void _navigateToLogin() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Navegar de forma asíncrona sin bloquear
    Future.microtask(() {
      if (!mounted) return;

      try {
        // Usar unisolate para no bloquear el hilo principal
        context.go('/login');
      } catch (e) {
        // Si hay error, intentar con un delay mínimo
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) {
            try {
              context.go('/login');
            } catch (_) {
              // Último recurso
              if (mounted) {
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    try {
                      context.go('/login');
                    } catch (_) {}
                  }
                });
              }
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget ultra simplificado para máximo rendimiento
    return Scaffold(
      backgroundColor: const Color(0xFF1A3A5C),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 100, color: Colors.white),
                    SizedBox(height: 20),
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
