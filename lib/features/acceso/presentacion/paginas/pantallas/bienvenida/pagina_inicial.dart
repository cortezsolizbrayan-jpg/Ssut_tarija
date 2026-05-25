import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/acceso/presentacion/componentes/interrumptor_widget.dart';
import 'package:refactor_template/features/recepcion/pantalla_login_recepcion.dart';

class InicialPage extends StatefulWidget {
  static const name = 'inicial-page';
  const InicialPage({super.key});

  @override
  State<InicialPage> createState() => _InicialPageState();
}

class _InicialPageState extends State<InicialPage> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF113A82),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Texto superior
            Padding(
              padding: EdgeInsets.only(left: width * 0.08, top: height * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: height * 0.01),
                  Text(
                    'Bienvenido a la aplicación de Posgrado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.040,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Ilustración del edificio
            Expanded(
              child: Center(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/images/edificio.png',
                    width: width * 0.8,
                    height: width,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Interruptor animado
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: height * 0.03),
                child: InterruptorWidget(width: width),
              ),
            ),

            // Botones de acceso
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.1,
                vertical: height * 0.02,
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF005BAC),
                        elevation: 4,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Registrarme',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PantallaLoginRecepcion(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    label: const Text(
                      'Ingreso Personal (Recepción)',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
