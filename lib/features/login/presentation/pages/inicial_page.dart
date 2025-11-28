import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/login/presentation/widgets/widgets.dart';

class InicialPage extends StatefulWidget {
  static const name = 'inicial-page';
  const InicialPage({super.key});

  @override
  State<InicialPage> createState() => _InicialPageState();
}

class _InicialPageState extends State<InicialPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      context.go('/login');
    });
  }

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
            // Texto de bienvenida
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
            // Espacio para el edificio
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ilustración del edificio en blanco
                    IlustracionWidget(width: width),
                  ],
                ),
              ),
            ),
            // Toggle switch en la parte inferior
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: height * 0.05),
                child: InterruptorWidget(width: width),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
