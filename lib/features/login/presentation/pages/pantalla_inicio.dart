import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StartScreen extends StatelessWidget {
  static const name = 'start-screen';

  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Color base dado por el usuario
    const Color primaryColor = Color(0xFF305BA4);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor,
              Color(0xFF1A3B70), // Un tono más oscuro para el degradado
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),
            // Imagen del edificio
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: FadeInDown(
                duration: const Duration(milliseconds: 1000),
                from: 50,
                child: Image.asset(
                  'assets/images/edificio.png', // Asegúrate de que esta ruta sea correcta
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const Spacer(),
            // Título o texto de bienvenida (Opcional, pero se ve vacío sin él)
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 800),
              child: Column(
                children: const [
                  Text(
                    'Bienvenido',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sistema de Postgrado',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Botones
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              child: FadeInUp(
                delay: const Duration(milliseconds: 600),
                duration: const Duration(milliseconds: 800),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/register');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        context.push('/programas-disponibles');
                      },
                      child: const Text(
                        'Ver programas como invitado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
