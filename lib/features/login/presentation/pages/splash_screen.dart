import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/services/servicio_biometrico.dart';
import 'package:refactor_template/features/login/presentation/pages/pantalla_autenticacion_rapida.dart';

class SplashScreen extends StatefulWidget {
  static const name = 'splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _fadeController;
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;
  
  final List<Particle> _particles = [];
  final int _particleCount = 40;

  @override
  void initState() {
    super.initState();
    
    // Controlador para las partículas (desarmar y armar)
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Controlador para el fade general
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    // Controlador para el texto
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _textSlideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    
    _initializeParticles();
    _startAnimations();
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(Particle(
        startX: random.nextDouble() * 2 - 1, // -1 a 1
        startY: random.nextDouble() * 2 - 1,
        endX: (i % 8 - 3.5) * 0.15, // Posición en grid
        endY: (i ~/ 8 - 2.5) * 0.15,
        size: random.nextDouble() * 8 + 4,
        delay: random.nextDouble() * 0.3,
      ));
    }
  }

  Future<void> _startAnimations() async {
    // Fade in inicial
    _fadeController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Animar partículas (desarmar → armar)
    _particleController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Mostrar texto
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Decidir a dónde navegar según si tiene seguridad configurada
    if (mounted) {
      final biometricService = BiometricService();
      final hasSecurityConfigured = await biometricService.hasSecurityConfigured();
      
      if (hasSecurityConfigured) {
        // Si ya tiene PIN/huella configurados, ir directo a autenticación rápida
        context.go('/autenticacion-rapida');
      } else {
        // Si no tiene seguridad configurada, ir a la pantalla de bienvenida
        context.go('/start-screen');
      }
    }
  }

  @override
  void dispose() {
    _particleController.dispose();
    _fadeController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DesignTokens.primaryBlue,
              DesignTokens.primaryBlue.withOpacity(0.9),
              DesignTokens.primaryBlueLight.withOpacity(0.85),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo animado con partículas
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Partículas animadas
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(200, 200),
                            painter: ParticlePainter(
                              particles: _particles,
                              progress: _particleController.value,
                            ),
                          );
                        },
                      ),
                      // Logo que aparece gradualmente
                      AnimatedBuilder(
                        animation: _particleController,
                        builder: (context, child) {
                          final logoOpacity = _particleController.value > 0.5
                              ? ((_particleController.value - 0.5) * 2).clamp(0.0, 1.0)
                              : 0.0;
                          return Opacity(
                            opacity: logoOpacity,
                            child: Container(
                              width: 140,
                              height: 140,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 30,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logoposgrado.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Texto animado
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlideAnimation.value),
                      child: Opacity(
                        opacity: _textFadeAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              'Posgrado UPEA',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: DesignTokens.primaryFont,
                                letterSpacing: 1.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Excelencia Académica',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.95),
                                fontFamily: DesignTokens.primaryFont,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Particle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double delay;

  Particle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.delay,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      // Calcular progreso individual con delay
      final particleProgress = ((progress - particle.delay) / (1 - particle.delay)).clamp(0.0, 1.0);
      
      // Curva de animación suave
      final easedProgress = Curves.easeInOutCubic.transform(particleProgress);

      // Interpolar posición
      final x = _lerp(particle.startX * size.width * 0.8, particle.endX * size.width, easedProgress);
      final y = _lerp(particle.startY * size.height * 0.8, particle.endY * size.height, easedProgress);

      // Calcular opacidad (aparece gradualmente)
      final opacity = easedProgress.clamp(0.0, 1.0);

      // Dibujar partícula
      paint.color = Colors.white.withOpacity(opacity * 0.9);
      canvas.drawCircle(
        Offset(center.dx + x, center.dy + y),
        particle.size * (0.5 + easedProgress * 0.5), // Crece mientras se mueve
        paint,
      );

      // Agregar brillo
      if (easedProgress > 0.7) {
        paint.color = Colors.white.withOpacity((easedProgress - 0.7) * 0.5);
        canvas.drawCircle(
          Offset(center.dx + x, center.dy + y),
          particle.size * 1.5,
          paint,
        );
      }
    }
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
