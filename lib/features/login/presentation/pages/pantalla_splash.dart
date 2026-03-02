import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/servicio_biometrico.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void _navigateToLogin() async {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Decidir a dónde navegar según si tiene seguridad configurada
    try {
      final biometricService = BiometricService();
      final hasSecurityConfigured = await biometricService.hasSecurityConfigured();
      
      // 🔍 DEBUG: Logs para verificar el estado
      debugPrint('🔐 === VERIFICACIÓN DE SEGURIDAD ===');
      debugPrint('🔐 hasSecurityConfigured: $hasSecurityConfigured');
      
      // Verificar detalles adicionales
      final prefs = await SharedPreferences.getInstance();
      final pinConfigured = prefs.getBool('pin_configured') ?? false;
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      final savedPin = prefs.getString('saved_pin');
      
      debugPrint('🔐 PIN configurado: $pinConfigured');
      debugPrint('🔐 Biometría habilitada: $biometricEnabled');
      debugPrint('🔐 PIN guardado existe: ${savedPin != null}');
      debugPrint('🔐 ================================');
      
      if (!mounted) return;
      
      if (hasSecurityConfigured) {
        // Si ya tiene PIN/huella configurados, ir directo a autenticación rápida
        debugPrint('✅ Navegando a pantalla de PIN');
        context.go('/autenticacion-rapida');
      } else {
        // Si no tiene seguridad configurada, ir a la pantalla de bienvenida
        debugPrint('ℹ️ Navegando a pantalla de bienvenida');
        context.go('/start-screen');
      }
    } catch (e) {
      debugPrint('❌ Error verificando seguridad: $e');
      // Si hay error, ir a la pantalla de bienvenida por defecto
      if (mounted) {
        context.go('/start-screen');
      }
    }
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
