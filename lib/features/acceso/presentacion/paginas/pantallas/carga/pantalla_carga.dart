import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/services/otros/servicio_actualizacion.dart';
import 'package:refactor_template/core/services/otros/servicio_biometrico.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';

class SplashPantalla extends StatefulWidget {
  static const name = 'splash';
  const SplashPantalla({super.key});

  @override
  State<SplashPantalla> createState() => _SplashPantallaState();
}

class _SplashPantallaState extends State<SplashPantalla>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  late AnimationController _particleController;
  late AnimationController _shakeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  late Animation<Offset> _shakeAnimation;
  late AnimationController _implosionController;
  late Animation<double> _implosionAnimation;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _implosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _implosionAnimation = CurvedAnimation(
      parent: _implosionController,
      curve: Curves.easeInQuint,
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));
    _textSlideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _shakeAnimation =
        Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(0.010, 0.006),
        ).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
        );

    _initializeParticles();
    _startAnimations();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < 60; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 2.5 + 0.5,
          speed: random.nextDouble() * 0.02 + 0.008,
          opacity: random.nextDouble() * 0.6 + 0.2,
          initialAngle: random.nextDouble() * math.pi * 2,
          orbitRadius: random.nextDouble() * 18.0,
          flickerRate: random.nextDouble() * 6.0 + 1.0,
        ),
      );
    }
  }

  Future<void> _startAnimations() async {
    // Verificar seguridad primero (rápido, con timeout)
    final biometricService = BiometricService();
    bool hasSecurityConfigured = false;
    try {
      hasSecurityConfigured = await biometricService
          .hasSecurityConfigured()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
    } catch (_) {}

    if (!mounted) return;

    // Verificar si hay un registro en progreso para retomar
    String? registroProgreso;
    try {
      registroProgreso = await LocalStorageService.getRegistroProgreso();
    } catch (_) {}

    final double speedFactor = hasSecurityConfigured ? 0.35 : 0.7;

    // Verificar actualizaciones en background sin bloquear la animación
    ServicioActualizacion()
        .verificarYActualizarAutomaticamente(context, isCritical: false)
        .catchError((_) {});

    // 1. Fade del fondo
    await Future.delayed(Duration(milliseconds: (120 * speedFactor).round()));
    if (!mounted) return;
    _fadeController.forward();

    // 2. Implosión de partículas
    await Future.delayed(Duration(milliseconds: (280 * speedFactor).round()));
    if (!mounted) return;
    await _implosionController.forward();

    // 3. Shake + logo
    _triggerShake();
    _logoController.forward();

    // 4. Texto
    await Future.delayed(Duration(milliseconds: (400 * speedFactor).round()));
    if (!mounted) return;
    _textController.forward();

    // 5. Permanencia reducida
    final int holdMs = hasSecurityConfigured ? 500 : 1200;
    await Future.delayed(Duration(milliseconds: holdMs));

    if (!mounted) return;

    if (hasSecurityConfigured) {
      context.go('/autenticacion-rapida');
    } else if (registroProgreso != null) {
      // Retomar el registro desde donde quedó
      context.go(registroProgreso);
    } else {
      context.go('/start-screen');
    }
  }

  Future<void> _triggerShake() async {
    HapticFeedback.heavyImpact();
    await _shakeController.forward();
    await _shakeController.reverse();
  }

  @override
  void dispose() {
    _implosionController.dispose();
    _logoController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    _particleController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, hijo) {
          return Transform.translate(
            offset: _shakeAnimation.value * 25.0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    DesignTokens.darkBackground,
                    DesignTokens.primaryBlue.withOpacity(0.9),
                    DesignTokens.primaryBlueLight.withOpacity(0.8),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Partículas de fondo
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _particleController,
                        _implosionController,
                        _logoController,
                      ]),
                      builder: (context, hijo) {
                        double particleScale;
                        if (_implosionController.value < 1.0) {
                          particleScale =
                              6.0 * (1.0 - _implosionAnimation.value);
                        } else {
                          particleScale =
                              0.15 *
                              Curves.easeOutExpo.transform(
                                _logoController.value,
                              );
                        }
                        return CustomPaint(
                          painter: ParticlePainter(
                            particles: _particles,
                            progress: _particleController.value,
                            scaleFactor: particleScale,
                          ),
                        );
                      },
                    ),
                  ),

                  // Texto institucional
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 230),
                          AnimatedBuilder(
                            animation: _textController,
                            builder: (context, hijo) {
                              return Transform.translate(
                                offset: Offset(0, _textSlideAnimation.value),
                                child: Opacity(
                                  opacity: _textFadeAnimation.value,
                                  child: Column(
                                    children: [
                                      const Text(
                                        'POSGRADO UPEA',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                          letterSpacing: 2.5,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black54,
                                              blurRadius: 12,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'DEMOCRATIZANDO LA EDUCACIÓN SUPERIOR',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withOpacity(0.9),
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              backgroundColor: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Logo institucional
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: Transform.translate(
                          offset: const Offset(0, -100),
                          child: AnimatedBuilder(
                            animation: _logoController,
                            builder: (context, hijo) {
                              final logoOpacity = _logoController.value.clamp(
                                0.0,
                                1.0,
                              );
                              final logoScale = 0.82 + (logoOpacity * 0.18);
                              return Transform.scale(
                                scale: logoScale,
                                child: Opacity(
                                  opacity: logoOpacity,
                                  child: Container(
                                    width: 160,
                                    height: 160,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(
                                            logoOpacity * 0.35,
                                          ),
                                          blurRadius: 25,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      'assets/images/logoposgrado.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class Particle {
  double x, y;
  final double size, speed, opacity, initialAngle, orbitRadius, flickerRate;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.initialAngle,
    required this.orbitRadius,
    required this.flickerRate,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;
  final double scaleFactor;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  ParticlePainter({
    required this.particles,
    required this.progress,
    required this.scaleFactor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.4);
    final double prog6 = progress * 6;
    final double prog40 = progress * 40;

    for (var particle in particles) {
      final double currentY = (particle.y + progress * particle.speed) % 1.0;
      final double angle = particle.initialAngle + prog6;
      final double orbitX = math.cos(angle) * particle.orbitRadius;
      final double orbitY = math.sin(angle) * particle.orbitRadius;

      final Offset normalPos = Offset(
        particle.x * size.width + orbitX,
        currentY * size.height + orbitY,
      );
      final Offset pos = center + (normalPos - center) * scaleFactor;

      final double flickerVal = math.sin(prog40 * particle.flickerRate).abs();
      final double opacity = (particle.opacity * flickerVal).clamp(0.0, 1.0);

      if (opacity < 0.02) continue;

      _paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(pos, particle.size, _paint);

      if (particle.size > 1.8) {
        _paint.color = Colors.white.withOpacity(opacity * 0.25);
        canvas.drawCircle(pos, particle.size * 2.2, _paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter old) =>
      old.progress != progress || old.scaleFactor != scaleFactor;
}
