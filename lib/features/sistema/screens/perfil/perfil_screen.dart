import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/animations/enhanced_animations.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/icono_notificaciones_widget.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen>
    with TickerProviderStateMixin {
  String? _nombreUsuario;

  // Controla las rotaciones de cada medalla
  final List<double> _medalTurns = List<double>.filled(5, 0.0);
  final List<AnimationController> _medalControllers = [];
  final List<Animation<double>> _medal3DRotations = [];
  final List<Animation<double>> _medal3DScales = [];

  // Animaciones de entrada secuencial para cada medalla
  final List<AnimationController> _medalEntryControllers = [];
  final List<Animation<double>> _medalEntryFades = [];
  final List<Animation<double>> _medalEntryScales = [];
  final List<Animation<double>> _medalEntryRotations = [];

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
  double _lastPanAngle = 0.0;

  // Estado para el efecto de 'presionar' el banner de descuentos
  double _bannerScale = 1.0;

  // Índice de la medalla "destacada" (moneda de oro cumplida)
  final int _highlightedMedalIndex = 0;

  // Animación de pulso para la medalla destacada
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final Animation<double> _bannerFloatAnimation; // Nueva float animation

  // Animaciones de entrada
  late final AnimationController _entryController;
  late final Animation<double> _headerSlideAnimation;
  late final Animation<double> _circleScaleAnimation;
  late final Animation<double> _footerSlideAnimation;

  void _rotateMedal(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _medalTurns[index] += 1; // una vuelta completa
    });

    // Animación 3D de la medalla individual
    _medalControllers[index].forward(from: 0.0).then((_) {
      _medalControllers[index].reverse();
    });
  }

  // Animación secuencial de entrada de medallas
  void _startSequentialMedalAnimation() {
    for (int i = 0; i < 5; i++) {
      Future.delayed(Duration(milliseconds: 200 * i), () {
        if (mounted) {
          HapticFeedback.selectionClick();
          _medalEntryControllers[i].forward();
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _loadSessionData();

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

    // Controlador de pulso para medalla destacada
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bannerFloatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // Animaciones de entrada
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _circleScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _footerSlideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Iniciar animación de entrada
    _entryController.forward();

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

      // Animación de entrada secuencial
      final entryController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
      _medalEntryControllers.add(entryController);

      _medalEntryFades.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: entryController, curve: Curves.easeOut),
        ),
      );

      _medalEntryScales.add(
        Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: entryController, curve: Curves.easeOutBack),
        ),
      );

      _medalEntryRotations.add(
        Tween<double>(begin: 0.0, end: math.pi * 2).animate(
          CurvedAnimation(parent: entryController, curve: Curves.easeOutCubic),
        ),
      );
    }

    // Giro automático inicial más atrevido de toda la ruleta
    _rotationVelocity = 0.1;

    // Animación secuencial de entrada de medallas (una por una)
    _startSequentialMedalAnimation();

    // Resaltar automáticamente la medalla destacada con una vuelta inicial (con delay mayor)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) _rotateMedal(_highlightedMedalIndex);
    });

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

  Future<void> _loadSessionData() async {
    final personal = await LocalStorageService.getPersonalData();
    final session = await LocalStorageService.getSessionData();
    if (!mounted) return;

    String str(dynamic v) => (v?.toString() ?? '').trim();
    final nombre = str(personal?['nombre']);
    final apPaterno = str(personal?['apPaterno']);
    final apMaterno = str(personal?['apMaterno']);

    final nombreCompleto = [
      if (nombre.isNotEmpty) nombre,
      if (apPaterno.isNotEmpty) apPaterno,
      if (apMaterno.isNotEmpty) apMaterno,
    ].join(' ').trim();

    final sessionNombre = str(session?['nombreUsuario']);
    setState(() {
      _nombreUsuario = nombreCompleto.isNotEmpty
          ? nombreCompleto
          : (sessionNombre.isNotEmpty ? sessionNombre : null);
    });
  }

  @override
  void dispose() {
    _mascotController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    _entryController.dispose();
    for (var controller in _medalControllers) {
      controller.dispose();
    }
    for (var controller in _medalEntryControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Forzar fondo claro para evitar el "fondo negro" detrás del círculo
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            return Stack(
              children: [
                // Header azul con curva - posición fija con animación de entrada
                Positioned(
                  top: screenHeight * _headerSlideAnimation.value,
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.40, // 30% de la pantalla
                  child: Opacity(
                    opacity: _entryController.value,
                    child: ExcludeSemantics(
                      excluding: _entryController.isAnimating,
                      child: _buildHeader(context),
                    ),
                  ),
                ),
                // Banner "Descuentos Especiales" flotando debajo de "Ver mis programas"
                Positioned(
                  top: screenHeight * 0.325, // Subimos el banner
                  left: 0,
                  right: 0,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bannerFloatAnimation.value),
                        child: Opacity(
                          opacity: _entryController.value.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: _buildFloatingDiscountBanner(screenWidth),
                  ),
                ),
                // Sección de medallas con mascota - bajada un poco
                Positioned(
                  top: screenHeight * 0.40, // Ajuste para acompañar la subida del banner
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.42, // Agrandamos un poco para recuperar espacio
                  child: ExcludeSemantics(
                    excluding: _rotationController.isAnimating,
                    child: Transform.scale(
                      scale: _circleScaleAnimation.value,
                      child: Opacity(
                        // La curva easeOutBack puede superar 1.0; se acota para evitar asserts
                        opacity: _circleScaleAnimation.value.clamp(0.0, 1.0),
                        child: _buildAchievementsCircle(),
                      ),
                    ),
                  ),
                ),
                // Footer azul con CEUB - posición fija con animación de entrada
                Positioned(
                  top:
                      screenHeight * 0.80 +
                      (screenHeight * 0.20 * _footerSlideAnimation.value),
                  left: 0,
                  right: 0,
                  height: screenHeight * 0.12, // 12% de la pantalla (reducido)
                  child: Opacity(
                    opacity: 1.0 - _footerSlideAnimation.value,
                    child: _buildFooter(context),
                  ),
                ),
                // Logo JQ19 - posición fija con animación de entrada
                Positioned(
                  top:
                      screenHeight * 0.93 +
                      (screenHeight * 0.20 * _footerSlideAnimation.value),
                  left: 0,
                  right: 0,
                  bottom: 0, // Usa el espacio restante
                  child: Opacity(
                    opacity: 1.0 - _footerSlideAnimation.value,
                    child: _buildBottomLogo(),
                  ),
                ),
              ],
            );
          },
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
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  2,
                  math.min(16, height * 0.05) + MediaQuery.of(context).padding.top,
                  2,
                  math.min(16, height * 0.05),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Logo
                        Expanded(
                          child: Image.asset(
                            'assets/images/logoposgrado.jpg',
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
                                colors: [Color(0xFF005BAC), Color(0xFF64748B)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(102),
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
                        AnimatedButton(
                          onTap: () async {
                            HapticFeedback.selectionClick();
                            await context.push('/mis-datos-personales');
                            if (mounted) setState(() {}); // Forzar el refresco de Widgets como el avatar
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: ProfileAvatarWidget(
                            radius: math.min(18, width * 0.045).toDouble(),
                            showShadow: true,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: math.max(8, height * 0.2)),
                    // Nombre del usuario
                    Text(
                      _nombreUsuario ?? 'Usuario',
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
                      child: AnimatedButton(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          context.push('/diplomados');
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: math.max(12, width * 0.025),
                            vertical: math.max(8, height * 0.01),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                    color: const Color(0xFF004080),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
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
    // Versión completa con ruleta 3D interactiva de medallas
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
                // Subir un poco más el conjunto (banner + círculo)
                offset: Offset(0, -circleSize * 0.16),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: EdgeInsets.all(circleSize * 0.05),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F4F8).withAlpha(200),
                    shape: BoxShape.circle, // círculo perfecto
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Área base circular para hit-testing
                      SizedBox(width: circleSize, height: circleSize),
                      // Círculo contenedor de medallas - Posicionado abajo del área de hit
                      Positioned(
                        bottom: 0,
                        child: SizedBox(
                          width: circleSize,
                          height: circleSize,
                          child: LayoutBuilder(
                            builder: (context, innerConstraints) {
                              // Calcular el centro y radio del círculo
                              final centerX = innerConstraints.maxWidth / 2;
                              final centerY = innerConstraints.maxHeight / 2;
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

                                  if (_isTouchInsideCircle) {
                                    final dx = touchPosition.dx - centerX;
                                    final dy = touchPosition.dy - centerY;
                                    _lastPanAngle = math.atan2(dy, dx);
                                  }
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

                                  // Calcular el ángulo actual del dedo respecto al centro
                                  final dx = touchPosition.dx - centerX;
                                  final dy = touchPosition.dy - centerY;
                                  final currentAngle = math.atan2(dy, dx);

                                  // Diferencia de ángulo (ajustada para evitar saltos bruscos en -pi/+pi)
                                  var deltaAngle = currentAngle - _lastPanAngle;
                                  if (deltaAngle > math.pi) {
                                    deltaAngle -= 2 * math.pi;
                                  } else if (deltaAngle < -math.pi) {
                                    deltaAngle += 2 * math.pi;
                                  }

                                  _lastPanAngle = currentAngle;

                                  setState(() {
                                    // Aplicar rotación basada en el movimiento angular real del dedo
                                    _wheelAngle += deltaAngle;

                                    // Velocidad para inercia (un poco amplificada para que se sienta viva)
                                    _rotationVelocity = deltaAngle * 8.0;
                                  });
                                },
                                onPanEnd: (details) {
                                  // Mantener la rotación con inercia continua solo si estaba dentro del círculo
                                  if (!_isTouchInsideCircle) {
                                    setState(() {
                                      _rotationVelocity = 0.0;
                                    });
                                  }
                                  _isTouchInsideCircle = false;
                                },
                                onPanCancel: () {
                                  if (!_isTouchInsideCircle) {
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
                                      angle: _wheelAngle,
                                      child: Stack(
                                        children: _buildUniformMedals(
                                          circleSize,
                                        ),
                                      ),
                                    ),
                                    // Mascota en el centro (no gira, solo rebota)
                                    Positioned.fill(
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                // Animación al tocar la mascota
                                                setState(() {
                                                  _rotationVelocity = 0.15;
                                                });
                                              },
                                              child: AnimatedBuilder(
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
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF005BAC,
                                                    ),
                                                    shape: BoxShape.circle,
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF005BAC,
                                                        ).withOpacity(0.3),
                                                        blurRadius: 20,
                                                        spreadRadius: 5,
                                                      ),
                                                    ],
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
                                                        child: AnimatedBuilder(
                                                          animation:
                                                              _mascotController,
                                                          builder: (context, child) {
                                                            return Transform.rotate(
                                                              angle:
                                                                  math.sin(
                                                                    _mascotController
                                                                            .value *
                                                                        math.pi *
                                                                        2,
                                                                  ) *
                                                                  0.2,
                                                              child: child,
                                                            );
                                                          },
                                                          child: Text(
                                                            '✋',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  circleSize *
                                                                  0.09,
                                                              color:
                                                                  const Color(
                                                                    0xFF005BAC,
                                                                  ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        right: 0,
                                                        top: circleSize * 0.12,
                                                        child: AnimatedBuilder(
                                                          animation:
                                                              _mascotController,
                                                          builder: (context, child) {
                                                            return Transform.rotate(
                                                              angle:
                                                                  -math.sin(
                                                                    _mascotController
                                                                            .value *
                                                                        math.pi *
                                                                        2,
                                                                  ) *
                                                                  0.2,
                                                              child: child,
                                                            );
                                                          },
                                                          child: Text(
                                                            '✋',
                                                            style: TextStyle(
                                                              fontSize:
                                                                  circleSize *
                                                                  0.09,
                                                              color:
                                                                  const Color(
                                                                    0xFF005BAC,
                                                                  ),
                                                            ),
                                                          ),
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
                                    ),
                                  ],
                                ),
                              );
                            },
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

  /// Genera las 5 medallas distribuidas uniformemente en un círculo
  List<Widget> _buildUniformMedals(double circleSize) {
    final medalAssets = [
      'assets/images/grupodorado.png',
      'assets/images/grupodiplomado.png',
      'assets/images/grupoplomo.png',
      'assets/images/grupoespecialidad.png',
      'assets/images/grupoplomo.png',
    ];

    final medalSize = circleSize * 0.26;
    final radius =
        (circleSize - medalSize) / 2; // Radio del círculo de distribución
    final centerX = circleSize / 2;
    final centerY = circleSize / 2;

    // Ángulo inicial: -90° para que la primera medalla esté arriba
    final startAngle = -math.pi / 2;
    // Separación uniforme: 360° / 5 medallas = 72° por medalla
    final angleStep = (2 * math.pi) / 5;

    return List.generate(5, (index) {
      final angle = startAngle + (angleStep * index);
      final x = centerX + radius * math.cos(angle) - (medalSize / 2);
      final y = centerY + radius * math.sin(angle) - (medalSize / 2);

      return Positioned(
        left: x,
        top: y,
        child: _buildMedal(index, medalAssets[index], circleSize),
      );
    });
  }

  Widget _buildFloatingDiscountBanner(double screenWidth) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value * _bannerScale,
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: child,
            ),
          );
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _bannerScale = 0.94),
          onTapUp: (_) => setState(() => _bannerScale = 1.0),
          onTapCancel: () => setState(() => _bannerScale = 1.0),
          onTap: () {
            HapticFeedback.heavyImpact();
            context.push('/programas-vigentes');
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/banerdescuento.png',
                  width: screenWidth * 0.58, // Tamaño reducido para que no ocupe tanto (58% de la pantalla)
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedal(int index, String assetPath, double circleSize) {
    final medalSize = circleSize * 0.26; // Tamaño proporcional al círculo
    final isHighlighted = index == _highlightedMedalIndex;

    return GestureDetector(
      onTap: () => _rotateMedal(index),
      child: Transform.rotate(
        // Compensa el giro de la ruleta para que la medalla siempre se vea derecha
        angle: -_wheelAngle,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _medalControllers[index],
            _medalEntryControllers[index],
            _rotationController,
            if (isHighlighted) _pulseController,
          ]),
          builder: (context, child) {
            // Animación de entrada
            final entryOpacity = _medalEntryFades[index].value;
            final entryScale = _medalEntryScales[index].value;
            final entryRotationY = _medalEntryRotations[index].value;

            // Rotación 3D usando Matrix4
            final rotation3D = _medal3DRotations[index].value;
            final scale = _medal3DScales[index].value;
            final pulseScale = isHighlighted ? _pulseAnimation.value : 1.0;
            final finalScale = scale * pulseScale * entryScale;
            final amberShadowAlpha = (255 * 0.3 * finalScale).round().clamp(
              0,
              255,
            );

            // Efecto de rotación 3D en el eje Y (perspectiva) + rotación de entrada
            final perspective = Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspectiva
              ..rotateY(
                (rotation3D * 0.3) + entryRotationY,
              ) // Rotación 3D en Y + entrada
              ..rotateX(rotation3D * 0.1) // Rotación 3D en X
              ..scale(finalScale, finalScale, finalScale);

            return Opacity(
              opacity: entryOpacity,
              child: Transform(
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
                        // Imagen de medalla con efecto 3D mejorado y halo más intenso si es destacada
                        Container(
                          width: medalSize * 0.91,
                          height: medalSize * 0.91,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(102),
                                blurRadius: 12,
                                offset: Offset(0, 4 * finalScale),
                                spreadRadius: 2 * finalScale,
                              ),
                              BoxShadow(
                                color: Colors.amber.withAlpha(amberShadowAlpha),
                                blurRadius: 20 * (isHighlighted ? 1.6 : 1.0),
                                offset: const Offset(0, 0),
                                spreadRadius: isHighlighted ? 5 : 0,
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
                color: const Color(0xFF0861C4).withAlpha(64),
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
                    // Botón "Verificar programas" (restaurado)
                    Padding(
                      padding: EdgeInsets.only(
                        left: math.max(8.0, anchoPantalla * 0.02).toDouble(),
                        right: math.max(4.0, anchoPantalla * 0.01).toDouble(),
                      ),
                      child: AnimatedButton(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Aquí podríamos navegar a una pantalla de programas acreditados en el futuro
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
                          height: buttonHeight,
                          padding: EdgeInsets.symmetric(
                            horizontal: buttonPaddingH,
                            vertical: buttonPaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
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
                                    color: const Color(0xFF004080),
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
      Colors.black.withAlpha(71),
      12,
      false,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

