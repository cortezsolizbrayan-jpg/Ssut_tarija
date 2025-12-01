import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pantalla de splash inicial.
///
/// Muestra el ícono del sombrero moviéndose de arriba a abajo.
/// Cuando está abajo se forma un círculo celeste y, al subir,
/// el círculo se va desvaneciendo lentamente.
/// Al finalizar la animación, navega a la pantalla de login.
class SplashScreen extends StatefulWidget {
  static const name = 'splash-page';

  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _positionAnim; // 0 = arriba, 1 = abajo
  late final Animation<double> _circleScale; // tamaño círculo
  late final Animation<double> _circleOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Movimiento vertical del icono (sube y baja)
    _positionAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    );

    // Círculo aparece cuando el icono está abajo
    _circleScale = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutBack),
    );

    _circleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _controller.forward();

    // Cuando termina la animación, ir a la pantalla de login
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go('/login');
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
    final size = MediaQuery.of(context).size;
    final maxMove = size.height * 0.18; // cuánto se desplaza el icono

    return Scaffold(
      backgroundColor: const Color(0xFF2858A1),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            // De -maxMove (arriba) a +maxMove (abajo)
            final dy = -maxMove + _positionAnim.value * (2 * maxMove);

            return Stack(
              alignment: Alignment.center,
              children: [
                // Círculo celeste que aparece cuando el icono está abajo
                Opacity(
                  opacity: _circleOpacity.value,
                  child: Transform.scale(
                    scale: 0.4 + _circleScale.value * 0.8,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B2FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                // Icono del sombrero que se mueve arriba/abajo
                Transform.translate(
                  offset: Offset(0, dy),
                  child: Image.asset(
                    'assets/images/graduation_icon.png',
                    width: 56,
                    height: 56,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
