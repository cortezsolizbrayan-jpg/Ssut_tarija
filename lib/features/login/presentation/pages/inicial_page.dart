import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
                    _BuildingIllustration(width: width),
                    // Banner con icono y texto "Posgrado"
                    // Positioned(
                    //   bottom: height * 0.15,
                    //   child: _PosgradoBanner(width: width),
                    // ),
                  ],
                ),
              ),
            ),
            // Toggle switch en la parte inferior
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: height * 0.05),
                child: _CustomToggleSwitch(width: width),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para la ilustración del edificio en blanco
class _BuildingIllustration extends StatelessWidget {
  const _BuildingIllustration({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    // Intentar cargar como SVG primero, si no existe usar Image con ColorFilter
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: Image.asset(
        'assets/svg/edificio.webp',
        width: width * 0.8,
        height: width * 1.0,
        fit: BoxFit.contain,
      ),
    );
  }
}

// Animación de carga
class _CustomToggleSwitch extends StatefulWidget {
  const _CustomToggleSwitch({required this.width});

  final double width;

  @override
  State<_CustomToggleSwitch> createState() => _CustomToggleSwitchState();
}

class _CustomToggleSwitchState extends State<_CustomToggleSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switchWidth = widget.width * 0.30;
    final switchHeight = widget.width * 0.1;
    final padding = 3.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: switchWidth,
          height: switchHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF113A82),
            borderRadius: BorderRadius.circular(switchHeight / 2),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                (switchHeight - padding * 2) / 2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: (switchWidth - padding * 2) * _animation.value,
                  height: switchHeight - padding * 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      (switchHeight - padding * 2) / 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
