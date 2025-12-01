import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:refactor_template/features/login/presentation/widgets/widgets.dart';

/// Pantalla de inicio de sesión principal de la aplicación.
class PaginaLogin extends StatelessWidget {
  static const name = 'pagina-login';
  const PaginaLogin({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    const lightBackground = Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header azul
                  _TopHero(width: width),
                  // Tarjeta de autenticación responsiva
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.06,
                      vertical: width * 0.04,
                    ),
                    child: SlideInUp(
                      duration: const Duration(milliseconds: 800),
                      delay: const Duration(milliseconds: 200),
                      child: TarjetaAutenticacionWidget(width: width),
                    ),
                  ),
                  // Sección de biometría y redes sociales
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 600),
                          child: BiometriaWidget(width: width),
                        ),
                        SizedBox(height: width * 0.06),
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 800),
                          child: BotonesSociales(width: width),
                        ),
                        SizedBox(height: width * 0.10),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopHero extends StatelessWidget {
  const _TopHero({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: width * 0.08,
        right: width * 0.08,
        top: width * 0.08,
        bottom: width * 0.18,
      ),
      decoration: const BoxDecoration(
        // Header azul corporativo
        gradient: LinearGradient(
          colors: [Color(0xFF005BAC), Color(0xFF005BAC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(90)),
      ),
      child: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: width * 0.3,
              height: width * 0.3,
              // decoration: BoxDecoration(
              //   // color: Colors.white.withOpacity(0.15),
              //   color: Colors.white.withAlpha(38),
              //   shape: BoxShape.circle,
              // ),
              child: Padding(
                padding: EdgeInsets.all(width * 0.001),
                child: Image.asset(
                  'assets/images/graduation_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.09,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.emoji_people_outlined,
                  color: Colors.white,
                  size: width * 0.09,
                ),
              ],
            ),
          ),
          SizedBox(height: width * 0.02),
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, la educacion es el futuro',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(136),
                fontSize: width * 0.04,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
