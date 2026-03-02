import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/side_bar.dart';
import 'package:refactor_template/features/sistema/widgets/notification_icon_widget.dart';
import 'package:refactor_template/features/sistema/widgets/profile_avatar_widget.dart';
import 'package:rive/rive.dart'
    hide LinearGradient, Image, Animation, PaintingStyle;

/// Pantalla que muestra el detalle de un programa académico con información
/// de pagos, progreso y seguimiento.
class DetalleProgramaScreen extends StatefulWidget {
  final String titulo;
  final String tipo;

  const DetalleProgramaScreen({
    super.key,
    required this.titulo,
    required this.tipo,
  });

  @override
  State<DetalleProgramaScreen> createState() => _DetalleProgramaScreenState();
}

class _DetalleProgramaScreenState extends State<DetalleProgramaScreen>
    with TickerProviderStateMixin {
  bool isSideBarOpen = false;

  // Sección seleccionada: 'Colegiatura', 'Matrículas', 'Monografía / Tesis'
  String _selectedSection = 'Colegiatura';

  // Controlador de páginas para navegación con swipe
  late PageController _pageController;
  int _currentPage = 2; // Empezamos en "Mi Seguimiento de Pagos" (índice 2)

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  // Controladores de animación para transiciones de sección
  late AnimationController _sectionTransitionController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controlador para animaciones de tarjetas de pago
  late AnimationController _paymentCardsController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPage);
    _initializeAnimations();
    // Retrasar las animaciones iniciales para mejor hot reload
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _sectionTransitionController.forward();
        _paymentCardsController.forward();
      }
    });
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    scalAnimation = Tween<double>(begin: 1, end: 0.8).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );
    animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    // Animación para transiciones de sección
    _sectionTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sectionTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _sectionTransitionController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Animación para tarjetas de pago
    _paymentCardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    // Preservar el estado durante hot reload
    if (_sectionTransitionController.status != AnimationStatus.forward &&
        _sectionTransitionController.status != AnimationStatus.completed) {
      _sectionTransitionController.value = 1.0;
    }
    if (_paymentCardsController.status != AnimationStatus.forward &&
        _paymentCardsController.status != AnimationStatus.completed) {
      _paymentCardsController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sectionTransitionController.dispose();
    _paymentCardsController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _changeSection(String newSection) {
    if (_selectedSection != newSection) {
      _sectionTransitionController.reverse().then((_) {
        setState(() {
          _selectedSection = newSection;
        });
        _sectionTransitionController.forward();
        _paymentCardsController.reset();
        _paymentCardsController.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor2,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // Menú lateral
          AnimatedPositioned(
            width: 288,
            height: MediaQuery.of(context).size.height,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 0 : -288,
            top: 0,
            child: const SideBar(),
          ),
          // Contenido principal con efecto 3D
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(
                    1 * animation.value -
                        30 * (animation.value) * math.pi / 180,
                  ),
                child: Transform.translate(
                  offset: Offset(animation.value * 265, 0),
                  child: Transform.scale(
                    scale: scalAnimation.value,
                    child: ExcludeSemantics(
                      excluding: animation.value > 0.01,
                      child: ClipRRect(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(24)),
                        child: _buildContent(),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // El menú ahora está en la fila principal del header
        ],
      ),
    );
  }

  //se define el contenido de la pantalla
  Widget _buildContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8), // Fondo institucional
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header azul (degradé + iconos) que se desplaza junto con el contenido
            _buildHeader(),
            // Indicadores de página (dots) - estilo WhatsApp
            _buildPageIndicators(),
            // PageView con swipe para navegar entre secciones
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // Página 0: Mis Notas
                  _MisNotasSheet(tituloPrograma: widget.titulo),
                  // Página 1: Mis Matrículas
                  _MisMatriculasSheet(tituloPrograma: widget.titulo),
                  // Página 2: Mi Seguimiento de Pagos (página principal)
                  _buildSeguimientoPagosPage(),
                  // Página 3: Mis Documentos
                  _MisDocumentosSheet(tituloPrograma: widget.titulo),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        // Degradé azul institucional
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF005BAC), // Azul institucional
            Color(0xFF0F7BD7), // Azul brillante
          ],
          stops: [0.0, 1.0],
        ),
        borderRadius: BorderRadius.only(
          // Curva más sutil
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      // Padding interno: separa los iconos del borde superior
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primera fila: Menú, Logo Posgrado y otros iconos
          FadeInDown(
            duration: const Duration(milliseconds: 500),
            child: Row(
              children: [
                // Menú hamburguesa - Al principio
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black, size: 26),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (_animationController.value == 0) {
                        _animationController.forward();
                      } else {
                        _animationController.reverse();
                      }

                      setState(() {
                        isSideBarOpen = !isSideBarOpen;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Logo Posgrado con tamaño realmente responsivo
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final logoHeight = math.max(
                        32.0,
                        math.min(56.0, maxWidth * 0.35),
                      );
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Image.asset(
                          'assets/images/logoposgrado.jpg',
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(), // Espacio flexible sin texto
                ),
                // Iconos adicionales (Notificaciones, Configuración, Avatar)
                const SizedBox(width: 8),
                const NotificationIconWidget(size: 40, iconSize: 22),
                const SizedBox(width: 6),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () {
                      context.push('/configuracion');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF005BAC), Color(0xFF0F7BD7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Builder(
                  builder: (context) => ProfileAvatarWidget(
                    radius: 16,
                    showShadow: false,
                    onTap: () {
                      context.push('/mis-datos-personales');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Título con animación
          FadeInLeft(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 200),
            //se define el texto del titulo
            child: Text(
              'Mis Programas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.6),
                    offset: const Offset(1, 1),
                    blurRadius: 4,
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    offset: const Offset(0, 0),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Subtítulo con animación
          FadeInRight(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Todos los programas que está cursando',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.95),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.5),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 0),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye los indicadores de página (dots) estilo WhatsApp
  Widget _buildPageIndicators() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: _currentPage == index ? 24 : 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? const Color(0xFF005BAC)
                  : const Color(0xFF005BAC).withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }


  /// Página 2: Mi Seguimiento de Pagos (página principal)
  Widget _buildSeguimientoPagosPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgramInfo(),
          _buildProgressCards(),
          _buildColegiaturaSection(),
          _buildPaymentsList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  /// Construye la sección de información del programa.
  Widget _buildProgramInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de programa con animación
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            //se define el efecto scale del widget
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF005BAC),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF005BAC).withOpacity(0.3 * value),
                        blurRadius: 8 * value,
                        spreadRadius: 1 * value,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.tipo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Título del programa con animación mejorada
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              final safeOpacity = value.clamp(0.0, 1.0);
              return Opacity(
                opacity: safeOpacity,
                child: Transform.translate(
                  offset: Offset(30 * (1 - value), 0),
                  child: Text(
                    widget.titulo,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.1 * (1 - value)),
                          blurRadius: 4 * (1 - value),
                        ),
                      ],
                    ),
                    //se define el maximo de lineas del texto
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Construye las tarjetas de progreso (Colegiatura, Matrículas, Tesis).
  Widget _buildProgressCards() {
    // Tarjetas de progreso en la misma fila, sin solaparse con el título
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: safeOpacity,
                    child: _AnimatedProgressCard(
                      titulo: 'Colegiatura',
                      pagadas: 2,
                      total: 5,
                      porcentaje: 65,
                      isHighlighted: _selectedSection == 'Colegiatura',
                      onTap: () => _changeSection('Colegiatura'),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: safeOpacity,
                    child: _AnimatedProgressCard(
                      titulo: 'Matrículas',
                      pagadas: 2,
                      total: 3,
                      porcentaje: 60,
                      isHighlighted: _selectedSection == 'Matrículas',
                      onTap: () => _changeSection('Matrículas'),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                final safeOpacity = value.clamp(0.0, 1.0);
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: safeOpacity,
                    child: _AnimatedProgressCard(
                      titulo: 'Monografía / Tesis',
                      pagadas: 0,
                      total: 1,
                      porcentaje: 0,
                      isHighlighted: _selectedSection == 'Monografía / Tesis',
                      onTap: () => _changeSection('Monografía / Tesis'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Construye la sección de título dinámico según la sección seleccionada.
  Widget _buildColegiaturaSection() {
    // Animación más corta y liviana para el encabezado de sección
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            // Usamos start + SizedBox en lugar de spaceBetween para evitar overflow
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Título de la sección (lado izquierdo) con espacio flexible
              Expanded(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  builder: (context, value, child) {
                    final safeOpacity = value.clamp(0.0, 1.0);
                    return Opacity(
                      opacity: safeOpacity,
                      child: Transform.translate(
                        offset: Offset(-20 * (1 - value), 0),
                        child: Text(
                          _selectedSection,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            shadows: [
                              Shadow(
                                color: const Color(
                                  0xFF005BAC,
                                ).withOpacity(0.2 * value),
                                blurRadius: 8 * value,
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Botón "Ver Historial de Facturas" responsivo (lado derecho)
              Flexible(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  //se define el efecto scale del widget
                  builder: (context, value, child) {
                    final safeOpacity = value.clamp(0.0, 1.0);
                    return Opacity(
                      opacity: safeOpacity,
                      child: Transform.translate(
                        offset: Offset(20 * (1 - value), 0),
                        child: Transform.scale(
                          scale: 0.9 + (0.1 * value),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableWidth = constraints.maxWidth;
                                final screenWidth = MediaQuery.of(
                                  context,
                                ).size.width;
                                final fontSize = math
                                    .max(
                                      10.0,
                                      math.min(13.0, screenWidth * 0.03),
                                    )
                                    .toDouble();
                                final iconSize = math
                                    .max(
                                      14.0,
                                      math.min(18.0, screenWidth * 0.04),
                                    )
                                    .toDouble();
                                final paddingH = math
                                    .max(
                                      8.0,
                                      math.min(14.0, availableWidth * 0.12),
                                    )
                                    .toDouble();
                                final paddingV = math
                                    .max(
                                      6.0,
                                      math.min(10.0, screenWidth * 0.023),
                                    )
                                    .toDouble();
                                //se define el boton de pago
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Implementar navegación al historial de facturas
                                    },
                                    icon: Icon(
                                      Icons.description,
                                      size: iconSize,
                                    ),
                                    label: Text(
                                      'Ver Historial de Facturas',
                                      style: TextStyle(
                                        fontSize: fontSize,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(
                                        0xFF005BAC,
                                      ), // Azul institucional
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: paddingH,
                                        vertical: paddingV,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 2 + (2 * value),
                                      minimumSize: Size(
                                        0,
                                        math.max(36, screenWidth * 0.085),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la lista de pagos según la sección seleccionada.
  ///
  /// TODO: Reemplazar datos hardcodeados con datos reales del backend.
  Widget _buildPaymentsList() {
    List<Map<String, dynamic>> payments = _getPaymentsForSection(
      _selectedSection,
    );

    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No hay pagos registrados para $_selectedSection',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Lista de pagos sin animación por ítem para mejor rendimiento
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: payments.map((payment) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _PaymentCard(
                  numero: payment['numero'] as int,
                  concepto: payment['concepto'] as String,
                  fechaVencimiento: payment['fechaVencimiento'] as String,
                  montoDeuda: payment['montoDeuda'] as double,
                  fechaPago: payment['fechaPago'] as String?,
                  fechaPagoAtrasado: payment['fechaPagoAtrasado'] as String?,
                  responsable: payment['responsable'] as String?,
                  estaPagado: payment['estaPagado'] as bool,
                  estaAtrasado: payment['estaAtrasado'] as bool,
                  tipoSeccion: _selectedSection,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  /// Obtiene los pagos según la sección seleccionada.
  List<Map<String, dynamic>> _getPaymentsForSection(String section) {
    switch (section) {
      case 'Colegiatura':
        return [
          {
            'numero': 1,
            'concepto': 'Colegiatura del Programa',
            'fechaVencimiento': '12/08/25',
            'montoDeuda': 1200.0,
            'fechaPago': '12/11/2025',
            'fechaPagoAtrasado': null,
            'responsable': 'Coordinador: Juan Pérez',
            'estaPagado': true,
            'estaAtrasado': false,
          },
          {
            'numero': 2,
            'concepto': 'Colegiatura del Programa',
            'fechaVencimiento': '12/08/25',
            'montoDeuda': 1200.0,
            'fechaPago': '12/11/2025',
            'fechaPagoAtrasado': null,
            'responsable': 'Usuario: Guadalupe Flores Mamani',
            'estaPagado': true,
            'estaAtrasado': false,
          },
          {
            'numero': 3,
            'concepto': 'Colegiatura del Programa',
            'fechaVencimiento': '15/09/25',
            'montoDeuda': 1200.0,
            'fechaPago': null,
            'fechaPagoAtrasado': null,
            'responsable': null,
            'estaPagado': false,
            'estaAtrasado': false,
          },
          {
            'numero': 4,
            'concepto': 'Colegiatura del Programa',
            'fechaVencimiento': '15/10/25',
            'montoDeuda': 1200.0,
            'fechaPago': null,
            'fechaPagoAtrasado': null,
            'responsable': null,
            'estaPagado': false,
            'estaAtrasado': false,
          },
          {
            'numero': 5,
            'concepto': 'Colegiatura del Programa',
            'fechaVencimiento': '15/11/25',
            'montoDeuda': 1200.0,
            'fechaPago': null,
            'fechaPagoAtrasado': null,
            'responsable': null,
            'estaPagado': false,
            'estaAtrasado': false,
          },
        ];
      case 'Matrículas':
        return [
          {
            'numero': 1,
            'concepto': 'Matrícula del Programa',
            'fechaVencimiento': '12/08/25',
            'montoDeuda': 500.0,
            'fechaPago': '12/11/2025',
            'fechaPagoAtrasado': null,
            'responsable': 'Coordinador: Juan Pérez',
            'estaPagado': true,
            'estaAtrasado': false,
          },
          {
            'numero': 2,
            'concepto': 'Matrícula del Programa',
            'fechaVencimiento': '12/08/25',
            'montoDeuda': 500.0,
            'fechaPago': null,
            'fechaPagoAtrasado': '12/11/2025',
            'responsable': null,
            'estaPagado': false,
            'estaAtrasado': true,
          },
          {
            'numero': 3,
            'concepto': 'Matrícula del Programa',
            'fechaVencimiento': '15/09/25',
            'montoDeuda': 500.0,
            'fechaPago': null,
            'fechaPagoAtrasado': null,
            'responsable': null,
            'estaPagado': false,
            'estaAtrasado': false,
          },
        ];
      case 'Monografía / Tesis':
        return [
          {
            'numero': 1,
            'concepto': 'Monografía / Tesis del Programa',
            'fechaVencimiento': '15/12/25',
            'montoDeuda': 800.0,
            'fechaPago': null,
            'fechaPagoAtrasado': null,
            'responsable': null,
            'estaPagado': false,
            'estaAtrasado': false,
          },
        ];
      default:
        return [];
    }
  }

  /* ELIMINADO: Barra de navegación inferior - ahora usamos PageView con swipe
  /// Construye la barra de navegación inferior minimalista con Rive.
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF005BAC), // Azul institucional
            Color(0xFF004A8F), // Azul más oscuro
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _RiveNavBarItem(
              riveArtboard: 'SEARCH',
              label: 'Mis Notas',
              isSelected: _selectedNavItem == 'Mis Notas',
              onTap: () => _navigateToNavItem('Mis Notas'),
            ),
            _RiveNavBarItem(
              riveArtboard: 'USER',
              label: 'Mis Matrículas',
              isSelected: _selectedNavItem == 'Mis Matrículas',
              onTap: () => _navigateToNavItem('Mis Matrículas'),
            ),
            _RiveNavBarItem(
              riveArtboard: 'TIMER',
              label: 'Mi Seguimiento de Pagos',
              isSelected: _selectedNavItem == 'Mi Seguimiento de Pagos',
              onTap: () => _navigateToNavItem('Mi Seguimiento de Pagos'),
            ),
            _RiveNavBarItem(
              riveArtboard: 'BELL',
              label: 'Mis Documentos',
              isSelected: _selectedNavItem == 'Mis Documentos del Programa',
              onTap: () => _navigateToNavItem('Mis Documentos del Programa'),
            ),
          ],
        ),
      ),
    );
  }
  FIN DEL BLOQUE COMENTADO */
  /* ELIMINADO: Métodos de navegación del menú inferior - ahora usamos PageView
  /// Maneja la navegación a diferentes items del menú inferior.
  void _navigateToNavItem(String item) {
    if (_selectedNavItem == item) return;

    setState(() {
      _selectedNavItem = item;
    });

    // Navegar según el item seleccionado
    switch (item) {
      case 'Mis Notas':
        _showMisNotasScreen();
        break;
      case 'Mis Matrículas':
        _showMisMatriculasScreen();
        break;
      case 'Mi Seguimiento de Pagos':
        // Ya estamos en esta pantalla, solo actualizar el estado
        break;
      case 'Mis Documentos del Programa':
        _showMisDocumentosScreen();
        break;
    }
  }

  /// Muestra la pantalla de Mis Notas.
  void _showMisNotasScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MisNotasSheet(tituloPrograma: widget.titulo),
    );
  }

  /// Muestra la pantalla de Mis Matrículas.
  void _showMisMatriculasScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MisMatriculasSheet(tituloPrograma: widget.titulo),
    );
  }

  /// Muestra la pantalla de Mis Documentos.
  void _showMisDocumentosScreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MisDocumentosSheet(tituloPrograma: widget.titulo),
    );
  }
  */
}

/// Tarjeta animada que muestra el progreso de pagos con efectos de interacción.
class _AnimatedProgressCard extends StatefulWidget {
  final String titulo;
  final int pagadas;
  final int total;
  final double porcentaje;
  final bool isHighlighted;
  final VoidCallback onTap;

  const _AnimatedProgressCard({
    required this.titulo,
    required this.pagadas,
    required this.total,
    required this.porcentaje,
    required this.isHighlighted,
    required this.onTap,
  });

  @override
  State<_AnimatedProgressCard> createState() => _AnimatedProgressCardState();
}

class _AnimatedProgressCardState extends State<_AnimatedProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_AnimatedProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted != oldWidget.isHighlighted) {
      // Animación cuando cambia el estado de highlight
      if (widget.isHighlighted) {
        _controller.forward().then((_) => _controller.reverse());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              child: _ProgressCard(
                titulo: widget.titulo,
                pagadas: widget.pagadas,
                total: widget.total,
                porcentaje: widget.porcentaje,
                isHighlighted: widget.isHighlighted,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Tarjeta que muestra el progreso de pagos (Colegiatura, Matrículas, Tesis).
class _ProgressCard extends StatefulWidget {
  final String titulo;
  final int pagadas;
  final int total;
  final double porcentaje;
  final bool isHighlighted;

  const _ProgressCard({
    required this.titulo,
    required this.pagadas,
    required this.total,
    required this.porcentaje,
    required this.isHighlighted,
  });

  @override
  State<_ProgressCard> createState() => _ProgressCardState();
}

class _ProgressCardState extends State<_ProgressCard>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    // Animación del progreso circular (de 0 al valor final)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.porcentaje / 100)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Animación de brillo pulsante para tarjetas destacadas
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.5).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Iniciar animación del progreso
    _progressController.forward();
  }

  @override
  void didUpdateWidget(_ProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.porcentaje != oldWidget.porcentaje) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.porcentaje / 100,
            end: widget.porcentaje / 100,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _glowAnimation]),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isHighlighted
                ? const Color(0xFF005BAC)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              if (widget.isHighlighted)
                BoxShadow(
                  color: const Color(
                    0xFF2C5F8D,
                  ).withOpacity(_glowAnimation.value),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              BoxShadow(
                color: widget.isHighlighted
                    ? const Color(0xFF005BAC).withOpacity(0.4)
                    : Colors.black.withOpacity(0.05),
                blurRadius: widget.isHighlighted ? 12 : 6,
                offset: const Offset(0, 2),
                spreadRadius: widget.isHighlighted ? 2 : 0,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: widget.isHighlighted ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  height: 1.2,
                ),
                child: Text(
                  widget.titulo,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  color: widget.isHighlighted
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey.shade600,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                child: Text(
                  '${widget.pagadas} de ${widget.total} ${widget.total > 1 ? (widget.titulo.contains('Matrícula') ? 'Cuotas' : 'Pagadas') : (widget.titulo.contains('Matrícula') ? 'Cuota' : 'Pagada')}',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: _progressAnimation.value,
                        strokeWidth: 5,
                        backgroundColor: widget.isHighlighted
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.isHighlighted
                              ? Colors.white
                              : const Color(0xFF005BAC),
                        ),
                      ),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: widget.isHighlighted
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      child: Text(
                        '${(_progressAnimation.value * 100).toInt()}%',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tarjeta que muestra la información de un pago individual.
class _PaymentCard extends StatelessWidget {
  final int numero;
  final String concepto;
  final String fechaVencimiento;
  final double montoDeuda;
  final String? fechaPago;
  final String? fechaPagoAtrasado;
  final String? responsable;
  final bool estaPagado;
  final bool estaAtrasado;
  final String tipoSeccion;

  const _PaymentCard({
    required this.numero,
    required this.concepto,
    required this.fechaVencimiento,
    required this.montoDeuda,
    this.fechaPago,
    this.fechaPagoAtrasado,
    this.responsable,
    required this.estaPagado,
    required this.estaAtrasado,
    required this.tipoSeccion,
  });

  String _getTituloNumero() {
    switch (tipoSeccion) {
      case 'Matrículas':
        return 'Matricula Nro. $numero';
      case 'Colegiatura':
        return 'Colegiatura Nro. $numero';
      case 'Monografía / Tesis':
        return 'Monografía / Tesis Nro. $numero';
      default:
        return 'N.º de Pago: $numero';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final safeOpacity = value.clamp(0.0, 1.0);
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: safeOpacity,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(
                    0xFF005BAC,
                  ).withOpacity(0.25), // Borde azul institucional suave
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTituloNumero(),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Concepto de Pago: $concepto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fecha de Vencimiento: $fechaVencimiento',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Monto de deuda: ${montoDeuda.toInt()} bs.',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        if (fechaPago != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Fecha de Pago: $fechaPago',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (fechaPagoAtrasado != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Fecha de Pago Atrasado: $fechaPagoAtrasado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        if (responsable != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Responsable: $responsable',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botones de acción con mejor manejo de overflow
                  Flexible(
                    flex: 1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (estaPagado) ...[
                          // Fila responsiva para evitar overflow en pantallas pequeñas
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Pagado',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          //se define el espacio entre el texto y el boton
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _AnimatedButton(
                              onPressed: () {
                                // TODO: Implementar acción para pago completado
                              },
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Pagado'),
                              backgroundColor: Colors.grey.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ] else if (estaAtrasado) ...[
                          // Fila responsiva para "Pago Atrasado"
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.error, color: Colors.red, size: 20),
                                SizedBox(width: 4),
                                Text(
                                  'Pago Atrasado',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          //se define el espacio entre el texto y el boton
                          const SizedBox(height: 8),
                          //se define el boton de pago
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _AnimatedButton(
                              onPressed: () {
                                context.push(
                                  '/deposito-matricula',
                                  extra: {
                                    'numeroMatricula': numero.toString(),
                                    'monto': montoDeuda,
                                  },
                                );
                              },
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Pagar'),
                              backgroundColor: const Color(
                                0xFF005BAC,
                              ), // Azul institucional
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ] else ...[
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: _AnimatedButton(
                              onPressed: () {
                                context.push(
                                  '/deposito-matricula',
                                  extra: {
                                    'numeroMatricula': numero.toString(),
                                    'monto': montoDeuda,
                                  },
                                );
                              },
                              icon: const Icon(Icons.payments, size: 16),
                              label: const Text('Pagar'),
                              backgroundColor: const Color(0xFF005BAC),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _AnimatedButton(
                            onPressed: () {
                              // TODO: Implementar visualización/descarga de factura
                            },
                            icon: const Icon(Icons.description, size: 16),
                            label: const Text('Factura'),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF005BAC),
                            borderColor: const Color(0xFF005BAC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Botón animado con efectos de interacción.
class _AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Icon icon;
  final Text label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  const _AnimatedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  @override
  State<_AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<_AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: ElevatedButton.icon(
                onPressed: widget.onPressed,
                icon: widget.icon,
                label: widget.label,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.backgroundColor,
                  foregroundColor: widget.foregroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: widget.borderColor != null
                        ? BorderSide(color: widget.borderColor!)
                        : BorderSide.none,
                  ),
                  elevation: _scaleAnimation.value < 1.0 ? 4 : 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Item de la barra de navegación inferior minimalista con Rive.
class _RiveNavBarItem extends StatefulWidget {
  final String riveArtboard;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _RiveNavBarItem({
    required this.riveArtboard,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  State<_RiveNavBarItem> createState() => _RiveNavBarItemState();
}

class _RiveNavBarItemState extends State<_RiveNavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  SMIBool? _isActiveInput;
  StateMachineController? _stateMachineController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_RiveNavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isSelected != widget.isSelected) {
      _isActiveInput?.value = widget.isSelected;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _stateMachineController?.dispose();
    super.dispose();
  }

  void _onRiveInit(Artboard artboard) {
    _stateMachineController = StateMachineController.fromArtboard(
      artboard,
      '${widget.riveArtboard}_Interactivity',
    );

    if (_stateMachineController != null) {
      artboard.addController(_stateMachineController!);
      _isActiveInput =
          _stateMachineController!.findInput<bool>('active') as SMIBool?;
      _isActiveInput?.value = widget.isSelected;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra superior minimalista
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.isSelected ? 30 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 8),
                // Icono Rive minimalista
                SizedBox(
                  width: 32,
                  height: 32,
                  child: Opacity(
                    opacity: widget.isSelected ? 1.0 : 0.6,
                    child: RiveAnimation.asset(
                      'assets/RiveAssets/icons.riv',
                      artboard: widget.riveArtboard,
                      onInit: _onRiveInit,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Label minimalista
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 150),
                  style: TextStyle(
                    color: widget.isSelected ? Colors.white : Colors.white70,
                    fontSize: 8,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Sheet modal para mostrar Mis Notas.
class _MisNotasSheet extends StatelessWidget {
  final String tituloPrograma;

  const _MisNotasSheet({required this.tituloPrograma});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.grade_rounded, color: Color(0xFF005BAC)),
                const SizedBox(width: 12),
                const Text(
                  'Mis Notas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Programa: $tituloPrograma',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                _buildNotaCard(
                  'Matemáticas Avanzadas',
                  'Primer Semestre',
                  '85',
                  'Aprobado',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildNotaCard(
                  'Programación Orientada a Objetos',
                  'Primer Semestre',
                  '92',
                  'Aprobado',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildNotaCard(
                  'Base de Datos',
                  'Segundo Semestre',
                  '78',
                  'Aprobado',
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildNotaCard(
                  'Arquitectura de Software',
                  'Segundo Semestre',
                  '88',
                  'Aprobado',
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaCard(
    String materia,
    String semestre,
    String nota,
    String estado,
    Color colorEstado,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                nota,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorEstado,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  materia,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  semestre,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorEstado.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              estado,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorEstado,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sheet modal para mostrar Mis Matrículas.
class _MisMatriculasSheet extends StatelessWidget {
  final String tituloPrograma;

  const _MisMatriculasSheet({required this.tituloPrograma});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded, color: Color(0xFF005BAC)),
                const SizedBox(width: 12),
                const Text(
                  'Mis Matrículas',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Programa: $tituloPrograma',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                _buildMatriculaCard(
                  '2025-1',
                  'Primer Semestre 2025',
                  '15/01/2025',
                  'Activa',
                  Colors.green,
                ),
                const SizedBox(height: 16),
                _buildMatriculaCard(
                  '2024-2',
                  'Segundo Semestre 2024',
                  '15/08/2024',
                  'Completada',
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildMatriculaCard(
                  '2024-1',
                  'Primer Semestre 2024',
                  '15/01/2024',
                  'Completada',
                  Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatriculaCard(
    String codigo,
    String periodo,
    String fecha,
    String estado,
    Color colorEstado,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                codigo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorEstado.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colorEstado,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                periodo,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.event, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Fecha: $fecha',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sheet modal para mostrar Mis Documentos.
class _MisDocumentosSheet extends StatelessWidget {
  final String tituloPrograma;

  const _MisDocumentosSheet({required this.tituloPrograma});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_shared_rounded,
                  color: Color(0xFF005BAC),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Mis Documentos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Programa: $tituloPrograma',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                _buildDocumentoCard(
                  'Carta de Aceptación',
                  'PDF',
                  '15/01/2025',
                  Icons.description,
                  Colors.red,
                ),
                const SizedBox(height: 16),
                _buildDocumentoCard(
                  'Plan de Estudios',
                  'PDF',
                  '20/01/2025',
                  Icons.description,
                  Colors.red,
                ),
                const SizedBox(height: 16),
                _buildDocumentoCard(
                  'Certificado de Notas',
                  'PDF',
                  '15/06/2025',
                  Icons.school,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                _buildDocumentoCard(
                  'Constancia de Matrícula',
                  'PDF',
                  '15/01/2025',
                  Icons.assignment,
                  Colors.green,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard(
    String nombre,
    String tipo,
    String fecha,
    IconData icon,
    Color colorIcon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colorIcon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: colorIcon, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      tipo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Text('•', style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(width: 8),
                    Text(
                      fecha,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Color(0xFF005BAC)),
            onPressed: () {
              // TODO: Implementar descarga de documento
            },
          ),
        ],
      ),
    );
  }
}
