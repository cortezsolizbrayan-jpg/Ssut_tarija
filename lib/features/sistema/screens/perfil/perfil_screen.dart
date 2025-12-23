import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/widgets/notification_icon_widget.dart';
import 'package:refactor_template/features/sistema/widgets/profile_avatar_widget.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with TickerProviderStateMixin {
  // Controla las rotaciones de cada medalla
  final List<double> _medalTurns = List<double>.filled(5, 0.0);
  final List<AnimationController> _medalControllers = [];
  final List<Animation<double>> _medal3DRotations = [];
  final List<Animation<double>> _medal3DScales = [];

  // Animación suave de rebote para la mascota central
  late final AnimationController _mascotController;
  late final Animation<double> _mascotOffset;

  // Ángulo actual de giro del grupo de medallas (ruleta) - Sin límites
  double _wheelAngle = 0.0;

  // Velocidad de rotación para animación continua
  double _rotationVelocity = 0.0;
  late AnimationController _rotationController;

  // Validación de toque dentro del círculo
  bool _isTouchInsideCircle = false;

  // Índice de la medalla "destacada" (moneda de oro cumplida)
  final int _highlightedMedalIndex = 0;

  void _rotateMedal(int index) {
    setState(() {
      _medalTurns[index] += 1; // una vuelta completa
    });

    // Animación 3D de la medalla individual
    _medalControllers[index].forward(from: 0.0).then((_) {
      _medalControllers[index].reverse();
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

    // Controlador para rotación continua suave
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16), // ~60fps
    )..repeat();

    // Inicializar controladores y animaciones 3D para cada medalla
    for (int i = 0; i < 5; i++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      _medalControllers.add(controller);

      _medal3DRotations.add(
        Tween<double>(begin: 0, end: math.pi * 2).animate(
          CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
        ),
      );

      _medal3DScales.add(
        Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: controller, curve: Curves.elasticOut),
        ),
      );
    }

    // Giro automático inicial suave de toda la ruleta
    _rotationVelocity = 0.04;

    // Resaltar automáticamente la medalla destacada con una vuelta inicial
    _rotateMedal(_highlightedMedalIndex);

    // Animación continua de rotación suave - Rotación infinita sin límites
    _rotationController.addListener(() {
      if (_rotationVelocity.abs() > 0.0001) {
        setState(() {
          // Rotación infinita - sin resetear, sin límites, sin normalización
          _wheelAngle += _rotationVelocity;

          // Fricción suave para detener gradualmente
          _rotationVelocity *= 0.97;
        });
      }
    });
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _rotationController.dispose();
    for (var controller in _medalControllers) {
      controller.dispose();
    }
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
                        // Banco Union - Reducido
                        Icon(
                          Icons.credit_card,
                          size: math.min(32, width * 0.08),
                          color: Colors.white,
                        ),
                        SizedBox(width: math.max(6, width * 0.015)),
                        // Notificaciones - Reducido
                        NotificationIconWidget(
                          size: math.min(40, width * 0.1),
                          iconSize: math.min(22, width * 0.055),
                        ),
                        SizedBox(width: math.max(6, width * 0.015)),
                        // Configuración - Reducido
                        GestureDetector(
                          onTap: () {
                            context.push('/configuracion');
                          },
                          child: Container(
                            width: math.min(40, width * 0.1),
                            height: math.min(40, width * 0.1),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: math.min(22, width * 0.055),
                            ),
                          ),
                        ),
                        SizedBox(width: math.max(6, width * 0.015)),
                        // Avatar - Reducido
                        ProfileAvatarWidget(
                          radius: math.min(18, width * 0.045).toDouble(),
                          showShadow: true,
                          onTap: () {
                            context.push('/mis-datos-personales');
                          },
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
                    // Botón "Ver Mis Programas" - Ajustado para evitar overflow
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: math.max(8, width * 0.02),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/diplomados');
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF004080),
                          padding: EdgeInsets.symmetric(
                            horizontal: math.max(12, width * 0.025),
                            vertical: math.max(8, height * 0.01),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          shadowColor: Colors.black.withOpacity(0.25),
                          minimumSize: Size(0, math.max(40, height * 0.05)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: math.min(30, width * 0.08),
                              height: math.min(30, width * 0.08),
                              decoration: BoxDecoration(
                                color: const Color(0xFF004080),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.menu_book,
                                color: Colors.white,
                                size: math.min(18, width * 0.045),
                              ),
                            ),
                            SizedBox(width: math.max(8, width * 0.02)),
                            Flexible(
                              child: Text(
                                'Ver Mis Programas',
                                style: TextStyle(
                                  fontSize: math.min(12, width * 0.03),
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calcular el centro y radio del círculo
                            final centerX = constraints.maxWidth / 2;
                            final centerY = constraints.maxHeight / 2;
                            final radius = circleSize / 2;

                            return GestureDetector(
                              onPanStart: (details) {
                                // Validar si el toque inicial está dentro del círculo
                                final touchPosition = details.localPosition;
                                final distanceFromCenter =
                                    (touchPosition - Offset(centerX, centerY))
                                        .distance;
                                _isTouchInsideCircle =
                                    distanceFromCenter <= radius;
                              },
                              onPanUpdate: (details) {
                                // Solo girar si el toque está dentro del círculo
                                if (!_isTouchInsideCircle) return;

                                // Validar continuamente que el toque siga dentro del círculo
                                final touchPosition = details.localPosition;
                                final distanceFromCenter =
                                    (touchPosition - Offset(centerX, centerY))
                                        .distance;

                                if (distanceFromCenter > radius) {
                                  _isTouchInsideCircle = false;
                                  return;
                                }

                                setState(() {
                                  // Dirección corregida: dedo a la derecha = giro a la derecha
                                  // Rotación infinita sin límites
                                  // dx positivo (derecha) = rotación positiva (derecha)
                                  final delta =
                                      details.delta.dx *
                                      0.02; // Sensibilidad ajustada

                                  // Aplicar rotación inmediata - sin límites
                                  _wheelAngle += delta;

                                  // Actualizar velocidad para inercia continua
                                  _rotationVelocity =
                                      delta * 3.0; // Mayor inercia

                                  // Rotación infinita - sin restricciones
                                });
                              },
                              onPanEnd: (details) {
                                // Mantener la rotación con inercia continua solo si estaba dentro del círculo
                                if (_isTouchInsideCircle) {
                                  // La velocidad se reducirá gradualmente por la fricción
                                  // No se resetea, continúa girando hasta detenerse
                                } else {
                                  // Si salió del círculo, detener la rotación
                                  setState(() {
                                    _rotationVelocity = 0.0;
                                  });
                                }
                                _isTouchInsideCircle = false;
                              },
                              onPanCancel: () {
                                // Similar a onPanEnd - mantener inercia solo si estaba dentro
                                if (_isTouchInsideCircle) {
                                  // Mantener inercia
                                } else {
                                  setState(() {
                                    _rotationVelocity = 0.0;
                                  });
                                }
                                _isTouchInsideCircle = false;
                              },
                              child: Stack(
                                children: [
                                  // Grupo de medallas que gira como ruleta con efecto 3D - Rotación infinita
                                  Transform.rotate(
                                    angle:
                                        _wheelAngle, // Rotación infinita sin límites
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
                                  // Etiqueta "Cumplido Diplomado" cerca de la medalla de oro
                                  Positioned(
                                    right: circleSize * 0.02,
                                    bottom: circleSize * 0.12,
                                    child: TweenAnimationBuilder<double>(
                                      tween: Tween(begin: 0.0, end: 1.0),
                                      duration: const Duration(
                                        milliseconds: 900,
                                      ),
                                      curve: Curves.easeOutBack,
                                      builder: (context, value, child) {
                                        return Opacity(
                                          opacity: value.clamp(0.0, 1.0),
                                          child: Transform.translate(
                                            offset: Offset(
                                              16 * (1 - value),
                                              12 * (1 - value),
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: circleSize * 0.06,
                                          vertical: circleSize * 0.025,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.amber.withOpacity(
                                                0.6,
                                              ),
                                              blurRadius: 16,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                          border: Border.all(
                                            color: const Color(0xFFFFC900),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.workspace_premium,
                                              color: const Color(0xFFB8860B),
                                              size: circleSize * 0.07,
                                            ),
                                            SizedBox(width: circleSize * 0.02),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Cumplido',
                                                  style: TextStyle(
                                                    fontSize:
                                                        circleSize * 0.045,
                                                    fontWeight: FontWeight.bold,
                                                    color: const Color(
                                                      0xFF1A3A5C,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  'Diplomado',
                                                  style: TextStyle(
                                                    fontSize:
                                                        circleSize * 0.038,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
                                                color: const Color(0xFF1A3A5C),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Text(
                                                    '🎓',
                                                    style: TextStyle(
                                                      fontSize:
                                                          circleSize * 0.23,
                                                    ),
                                                  ),
                                                  Positioned(
                                                    left: 0,
                                                    top: circleSize * 0.12,
                                                    child: Text(
                                                      '✋',
                                                      style: TextStyle(
                                                        fontSize:
                                                            circleSize * 0.09,
                                                        color: const Color(
                                                          0xFF1A3A5C,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    top: circleSize * 0.12,
                                                    child: Text(
                                                      '✋',
                                                      style: TextStyle(
                                                        fontSize:
                                                            circleSize * 0.09,
                                                        color: const Color(
                                                          0xFF1A3A5C,
                                                        ),
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
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _medalControllers[index],
            _rotationController,
          ]),
          builder: (context, child) {
            // Rotación 3D usando Matrix4
            final rotation3D = _medal3DRotations[index].value;
            final scale = _medal3DScales[index].value;

            // Efecto de rotación 3D en el eje Y (perspectiva)
            final perspective = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspectiva
              ..rotateY(rotation3D * 0.3) // Rotación 3D en Y
              ..rotateX(rotation3D * 0.1) // Rotación 3D en X
              ..scale(scale);

            return Transform(
              transform: perspective,
              alignment: Alignment.center,
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
                      // Imagen de medalla con efecto 3D mejorado
                      Container(
                        width: medalSize * 0.91,
                        height: medalSize * 0.91,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: Offset(0, 4 * scale),
                              spreadRadius: 2 * scale,
                            ),
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.3 * scale),
                              blurRadius: 20,
                              offset: Offset(0, 0),
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
            );
          },
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

        // Calcular tamaños responsivos
        final paddingHorizontal = math
            .max(8.0, anchoPantalla * 0.03)
            .toDouble();
        final paddingVertical = math
            .max(4.0, alturaDisponible * 0.06)
            .toDouble();
        final iconSize = math
            .max(16.0, math.min(20.0, anchoPantalla * 0.05))
            .toDouble();
        final fontSize = math
            .max(10.0, math.min(12.0, anchoPantalla * 0.028))
            .toDouble();
        final buttonHeight = math
            .max(36.0, math.min(44.0, alturaDisponible * 0.12))
            .toDouble();
        final buttonPaddingH = math.max(8.0, anchoPantalla * 0.025).toDouble();
        final buttonPaddingV = math
            .max(4.0, alturaDisponible * 0.06)
            .toDouble();

        return Container(
          width: double.infinity,
          height: alturaDisponible,
          padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingVertical,
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
                      padding: EdgeInsets.only(
                        left: math.max(8.0, anchoPantalla * 0.02).toDouble(),
                        top: math.max(2.0, alturaDisponible * 0.05).toDouble(),
                      ),
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
                          SizedBox(
                            height: math
                                .max(1.0, alturaDisponible * 0.02)
                                .toDouble(),
                          ),
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
                    // Espaciado antes del botón
                    SizedBox(
                      height: math.max(6.0, alturaDisponible * 0.08).toDouble(),
                    ),
                    // Botón responsive
                    Padding(
                      padding: EdgeInsets.only(
                        left: math.max(8.0, anchoPantalla * 0.02).toDouble(),
                        right: math.max(4.0, anchoPantalla * 0.01).toDouble(),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF004080),
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: Size(0, buttonHeight),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF004080),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Icon(
                                  Icons.fact_check,
                                  color: Colors.white,
                                  size: iconSize * 0.6,
                                ),
                              ),
                              SizedBox(
                                width: math
                                    .max(4.0, anchoPantalla * 0.015)
                                    .toDouble(),
                              ),
                              Flexible(
                                child: Text(
                                  'Verificar programas',
                                  style: TextStyle(
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Logo CEUB en la esquina superior derecha
              Padding(
                padding: EdgeInsets.only(
                  top: math.max(2.0, alturaDisponible * 0.08).toDouble(),
                  right: math.max(4.0, anchoPantalla * 0.01).toDouble(),
                ),
                child: Container(
                  width: tamanoLogo,
                  height: tamanoLogo,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber,
                      width: math.max(1.5, anchoPantalla * 0.004).toDouble(),
                    ),
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
