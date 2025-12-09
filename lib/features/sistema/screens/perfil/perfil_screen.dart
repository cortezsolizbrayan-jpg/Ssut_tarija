import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  // Controla las rotaciones de cada medalla
  final List<double> _medalTurns = List<double>.filled(5, 0.0);

  // Animación suave de rebote para la mascota central
  late final AnimationController _mascotController;
  late final Animation<double> _mascotOffset;

  // Ángulo actual de giro del grupo de medallas (ruleta)
  double _wheelAngle = 0;

  void _rotateMedal(int index) {
    setState(() {
      _medalTurns[index] += 1; // una vuelta completa
    });
  }

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _mascotOffset = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mascotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Stack(
          children: [
            // Header azul con curva - posición fija
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: screenHeight * 0.40, // 30% de la pantalla
              child: _buildHeader(context),
            ),
            // Sección de medallas con mascota - posición fija
            Positioned(
              top: screenHeight * 0.38, // Empieza antes del final del header
              left: 0,
              right: 0,
              height: screenHeight * 0.45, // 45% de la pantalla
              child: _buildAchievementsCircle(),
            ),
            // Footer azul con CEUB - posición fija
            Positioned(
              top: screenHeight * 0.80,
              left: 0,
              right: 0,
              height: screenHeight * 0.12, // 12% de la pantalla (reducido)
              child: _buildFooter(context),
            ),
            // Logo JQ19 - posición fija
            Positioned(
              top: screenHeight * 0.93,
              left: 0,
              right: 0,
              bottom: 0, // Usa el espacio restante
              child: _buildBottomLogo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _PintorEncabezado(),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: math.min(16, height * 0.05),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Logo
                        Expanded(
                          child: Image.asset(
                            'assets/images/logoposgrado.png',
                            height: math.min(40, height * 0.12),
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Banco Union
                        Icon(Icons.credit_card, size: 40, color: Colors.white),
                        const SizedBox(width: 12),
                        // Notificaciones
                        Stack(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E293B),
                                    Color(0xFF64748B),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Configuración
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.white,
                            backgroundImage: AssetImage(
                              'assets/icons/profile_img.png',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: math.max(8, height * 0.2)),
                    // Nombre del usuario
                    Text(
                      'Guadalupe Flores Mamani',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(22, height * 0.07),
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: math.max(8, height * 0.08)),
                    // Botón "Ver Mis Programas"
                    ElevatedButton(
                      onPressed: () {
                        context.push('/diplomados');
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 10,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF004080),
                        padding: EdgeInsets.symmetric(
                          horizontal: math.max(16, width * 0.03),
                          vertical: math.max(10, height * 0.01),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        shadowColor: Colors.black.withOpacity(0.25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF004080),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Ver Mis Programas',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementsCircle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula el tamaño del círculo basado en ancho y altura disponible
        final screenWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final circleSize = math.min(
          screenWidth * 0.88, // 88% del ancho de la pantalla
          availableHeight * 0.85, // 85% de la altura disponible
        );

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: Offset(
                  0,
                  -circleSize * 0.08,
                ), // Posición fija del banner
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  padding: EdgeInsets.all(circleSize * 0.05),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(220),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Banner "Descuentos Especiales" sobre el header/rueda
                      Positioned(
                        top: -circleSize * 0.2,
                        child: _buildDiscountBanner(circleSize),
                      ),
                      // Círculo contenedor de medallas
                      SizedBox(
                        width: circleSize,
                        height: circleSize,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _wheelAngle += details.delta.dx * 0.01;
                            });
                          },
                          child: Stack(
                            children: [
                              // Grupo de medallas que gira como ruleta
                              Transform.rotate(
                                angle: _wheelAngle,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: circleSize * 0.03,
                                      top: circleSize * 0.12,
                                      child: _buildMedal(
                                        0,
                                        'assets/images/grupodorado.png',
                                        circleSize,
                                      ),
                                    ),
                                    Positioned(
                                      right: circleSize * 0.03,
                                      top: circleSize * 0.12,
                                      child: _buildMedal(
                                        1,
                                        'assets/images/grupodiplomado.png',
                                        circleSize,
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      top: circleSize * 0.47,
                                      child: _buildMedal(
                                        2,
                                        'assets/images/grupoplomo.png',
                                        circleSize,
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: circleSize * 0.47,
                                      child: _buildMedal(
                                        3,
                                        'assets/images/grupoespecialidad.png',
                                        circleSize,
                                      ),
                                    ),
                                    Positioned(
                                      left: circleSize * 0.28,
                                      bottom: circleSize * 0.07,
                                      child: _buildMedal(
                                        4,
                                        'assets/images/grupoplomo.png',
                                        circleSize,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Mascota en el centro (no gira, solo rebota)
                              Positioned.fill(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      AnimatedBuilder(
                                        animation: _mascotController,
                                        builder: (context, child) {
                                          return Transform.translate(
                                            offset: Offset(
                                              0,
                                              _mascotOffset.value,
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: Container(
                                          width: circleSize * 0.41,
                                          height: circleSize * 0.41,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF87CEEB),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Text(
                                                '🎓',
                                                style: TextStyle(
                                                  fontSize: circleSize * 0.23,
                                                ),
                                              ),
                                              Positioned(
                                                left: 0,
                                                top: circleSize * 0.12,
                                                child: Text(
                                                  '✋',
                                                  style: TextStyle(
                                                    fontSize: circleSize * 0.09,
                                                    color: Colors.blue.shade300,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                right: 0,
                                                top: circleSize * 0.12,
                                                child: Text(
                                                  '✋',
                                                  style: TextStyle(
                                                    fontSize: circleSize * 0.09,
                                                    color: Colors.blue.shade300,
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDiscountBanner(double circleSize) {
    final bannerHeight = circleSize * 0.26; // Tamaño proporcional
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            // Imagen de \"Descuentos Especiales\" provista en assets
            'assets/images/descuentos .png',
            height: bannerHeight,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildMedal(int index, String assetPath, double circleSize) {
    final medalSize = circleSize * 0.26; // Tamaño proporcional al círculo
    return GestureDetector(
      onTap: () => _rotateMedal(index),
      child: Transform.rotate(
        // Compensa el giro de la ruleta para que la medalla siempre se vea derecha
        angle: -_wheelAngle,
        child: AnimatedRotation(
          turns: _medalTurns[index],
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: medalSize,
            height: medalSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Imagen de medalla (grupos dorado, diplomado, especialidad, plomo)
                Container(
                  width: medalSize * 0.91,
                  height: medalSize * 0.91,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(assetPath, fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final anchoPantalla = constraints.maxWidth;
        final alturaDisponible = constraints.maxHeight;
        final tamanoFuente = math.min(
          anchoPantalla * 0.032,
          math.min(12.0, alturaDisponible * 0.08),
        );
        final tamanoLogo = math.min(
          anchoPantalla * 0.15,
          math.min(55.0, alturaDisponible * 0.7),
        );

        return Container(
          width: double.infinity,
          height: alturaDisponible,
          padding: EdgeInsets.only(
            left: 12,
            right: math.max(12, tamanoLogo + 8),
            top: math.max(4, alturaDisponible * 0.08),
            bottom: math.max(4, alturaDisponible * 0.08),
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF4DB5FF), Color(0xFF0861C4)],
            ),
            borderRadius: BorderRadius.zero,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0861C4).withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contenido principal: texto y botón
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Texto
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18.0, 6.0, 0, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Busca Nuestros Programas Certificados y',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: tamanoFuente,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Registrados por la CEUB',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: tamanoFuente,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Botón centrado debajo del texto
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: SizedBox(
                        height: math.max(8, alturaDisponible * 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF004080),
                          padding: EdgeInsets.symmetric(
                            horizontal: math.max(12, anchoPantalla * 0.035),
                            vertical: math.max(6, alturaDisponible * 0.08),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: math.max(20, anchoPantalla * 0.05),
                              height: math.max(20, anchoPantalla * 0.05),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004080),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.fact_check,
                                color: Colors.white,
                                size: math.max(12, anchoPantalla * 0.03),
                              ),
                            ),
                            SizedBox(width: math.max(6, anchoPantalla * 0.015)),
                            Text(
                              'Verificar programas',
                              style: TextStyle(
                                fontSize: math.max(11, anchoPantalla * 0.032),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Logo CEUB en la esquina superior derecha
              Padding(
                padding: EdgeInsets.only(
                  top: math.max(4, alturaDisponible * 0.1),
                  right: math.max(8, anchoPantalla * 0.02),
                ),
                child: Container(
                  width: tamanoLogo * 1,
                  height: tamanoLogo * 1,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/ceub.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomLogo() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final logoSize = math.min(
          screenWidth * 0.18,
          math.min(85.0, availableHeight * 0.65),
        );
        final fontSize = math.min(
          screenWidth * 0.09,
          math.min(17.0, availableHeight * 1),
        );

        return Container(
          width: double.infinity,
          height: availableHeight,
          padding: EdgeInsets.symmetric(
            horizontal: 10,
            vertical: math.max(1, availableHeight * 0.02),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/19.png',
                    fit: BoxFit.contain,
                    height: logoSize,
                  ),
                ),
              ),
              SizedBox(width: math.max(4, screenWidth * 0.012)),
              Expanded(
                child: Text(
                  '"¡Democratizando la educación superior, por encargo social !"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Parisienne',
                    color: Colors.black87,
                    fontSize: fontSize,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PintorEncabezado extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF00448A), Color(0xFF0F7BD7), Color(0xFF0B5FB4)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(rect);

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.83)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.05,
        0,
        size.height * 0.83,
      )
      ..close();

    canvas.drawShadow(
      path.shift(const Offset(0, 2)),
      Colors.black.withOpacity(0.28),
      12,
      false,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
