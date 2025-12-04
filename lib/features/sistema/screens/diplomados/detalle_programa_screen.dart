import 'dart:math';

import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/menu_btn.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/side_bar.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;

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
  late SMIBool isMenuOpenInput;

  // Sección seleccionada: 'Colegiatura', 'Matrículas', 'Monografía / Tesis'
  String _selectedSection = 'Matrículas';

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
    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          setState(() {});
        });
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

    _sectionTransitionController.forward();
    _paymentCardsController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sectionTransitionController.dispose();
    _paymentCardsController.dispose();
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
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(
                1 * animation.value - 30 * (animation.value) * pi / 180,
              ),
            child: Transform.translate(
              offset: Offset(animation.value * 265, 0),
              child: Transform.scale(
                scale: scalAnimation.value,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: _buildContent(),
                ),
              ),
            ),
          ),
          // Botón del menú 3D
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
            left: isSideBarOpen ? 220 : 0,
            top: 16,
            child: MenuBtn(
              press: () {
                isMenuOpenInput.value = !isMenuOpenInput.value;

                if (_animationController.value == 0) {
                  _animationController.forward();
                } else {
                  _animationController.reverse();
                }

                setState(() {
                  isSideBarOpen = !isSideBarOpen;
                });
              },
              riveOnInit: (artboard) {
                final controller = StateMachineController.fromArtboard(
                  artboard,
                  "State Machine",
                );

                artboard.addController(controller!);

                isMenuOpenInput =
                    controller.findInput<bool>("isOpen") as SMIBool;
                isMenuOpenInput.value = true;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header azul
            _buildHeader(context),
            // Información del programa y tarjetas de progreso
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del programa
                    _buildProgramInfo(),
                    // Tarjetas de progreso (Colegiatura, Matrículas, Tesis)
                    _buildProgressCards(),
                    // Sección Colegiatura
                    _buildColegiaturaSection(),
                    // Lista de pagos
                    _buildPaymentsList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Barra de navegación inferior
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  /// Construye el header azul completo con menú, notificaciones y información del programa.
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A3A5C), // Azul oscuro
            Color(0xFF2C5F8D), // Azul medio
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(175),
          bottomRight: Radius.circular(175),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Primera fila: Menu, Logo Posgrado, Banco Union, Notificaciones, Configuración y Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // El menú hamburguesa ahora se maneja con MenuBtn en el Stack
                  const SizedBox(width: 50),
                  const SizedBox(width: 12),
                  // Logo Posgrado
                  Expanded(
                    child: Image.asset(
                      'assets/images/logposgrado.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Banco Union
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BANCO UNION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Número de cuenta único',
                        style: TextStyle(fontSize: 8, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Notificaciones con badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // TODO: Abrir notificaciones
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
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
                  const SizedBox(width: 8),
                  // Icono de configuración
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: Abrir configuración
                    },
                  ),
                  const SizedBox(width: 8),
                  // Avatar del usuario
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: const AssetImage(
                        'assets/icons/profile_img.png',
                      ),
                      onBackgroundImageError: (_, __) {},
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Segunda fila: Botón de retroceso, Programa y Plan de Pagos
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Programa:',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.titulo,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Plan de Pagos del Programa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Descuento del Programa con %10',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
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
          // Tipo de programa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(8),
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
          const SizedBox(height: 12),
          // Título del programa
          Text(
            widget.titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Construye las tarjetas de progreso (Colegiatura, Matrículas, Tesis).
  Widget _buildProgressCards() {
    return Transform.translate(
      offset: const Offset(0, -40),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 1,
              child: _AnimatedProgressCard(
                titulo: 'Colegiatura',
                pagadas: 2,
                total: 5,
                porcentaje: 65,
                isHighlighted: _selectedSection == 'Colegiatura',
                onTap: () => _changeSection('Colegiatura'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _AnimatedProgressCard(
                titulo: 'Matrículas',
                pagadas: 2,
                total: 3,
                porcentaje: 60,
                isHighlighted: _selectedSection == 'Matrículas',
                onTap: () => _changeSection('Matrículas'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _AnimatedProgressCard(
                titulo: 'Monografía / Tesis',
                pagadas: 0,
                total: 1,
                porcentaje: 0,
                isHighlighted: _selectedSection == 'Monografía / Tesis',
                onTap: () => _changeSection('Monografía / Tesis'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la sección de título dinámico según la sección seleccionada.
  Widget _buildColegiaturaSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedSection,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar navegación al historial de facturas
                },
                icon: const Icon(Icons.description, size: 18),
                label: const Text('Ver Historial de Facturas'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800), // Naranja
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: payments.asMap().entries.map((entry) {
              final index = entry.key;
              final payment = entry.value;

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PaymentCard(
                          numero: payment['numero'] as int,
                          concepto: payment['concepto'] as String,
                          fechaVencimiento:
                              payment['fechaVencimiento'] as String,
                          montoDeuda: payment['montoDeuda'] as double,
                          fechaPago: payment['fechaPago'] as String?,
                          fechaPagoAtrasado:
                              payment['fechaPagoAtrasado'] as String?,
                          responsable: payment['responsable'] as String?,
                          estaPagado: payment['estaPagado'] as bool,
                          estaAtrasado: payment['estaAtrasado'] as bool,
                          tipoSeccion: _selectedSection,
                        ),
                      ),
                    ),
                  );
                },
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

  /// Construye la barra de navegación inferior.
  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C),
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
            _NavBarItem(
              icon: Icons.list,
              label: 'Mis Notas',
              isSelected: false,
              onTap: () {
                // TODO: Implementar navegación a Mis Notas
              },
            ),
            _NavBarItem(
              icon: Icons.person,
              label: 'Mis Matrículas',
              isSelected: false,
              onTap: () {
                // TODO: Implementar navegación a Mis Matrículas
              },
            ),
            _NavBarItem(
              icon: Icons.account_balance_wallet,
              label: 'Mi Seguimiento de Pagos',
              isSelected: true,
              onTap: () {
                // Ya estamos en esta pantalla
              },
            ),
            _NavBarItem(
              icon: Icons.description,
              label: 'Mis Documentos del Programa',
              isSelected: false,
              onTap: () {
                // TODO: Implementar navegación a Mis Documentos
              },
            ),
          ],
        ),
      ),
    );
  }
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
class _ProgressCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF2196F3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? const Color(0xFF2196F3).withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: isHighlighted ? 8 : 6,
            offset: const Offset(0, 2),
            spreadRadius: isHighlighted ? 1 : 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: isHighlighted ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            '$pagadas de $total ${total > 1 ? (titulo.contains('Matrícula') ? 'Cuotas' : 'Pagadas') : (titulo.contains('Matrícula') ? 'Cuota' : 'Pagada')}',
            style: TextStyle(
              color: isHighlighted
                  ? Colors.white.withOpacity(0.9)
                  : Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: porcentaje / 100),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 5,
                        backgroundColor: isHighlighted
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isHighlighted
                              ? Colors.white
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        color: isHighlighted ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
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
        return Transform.scale(
          scale: 0.95 + (0.05 * value),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(
                    0xFF87CEEB,
                  ).withOpacity(0.5), // Borde azul claro
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08 * value),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                            'Responsable del Registro de pago: $responsable',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botones de acción
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (estaPagado) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Pagado',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _AnimatedButton(
                            onPressed: () {
                              // TODO: Implementar acción para pago completado
                            },
                            icon: const Icon(Icons.payments, size: 16),
                            label: const Text('Pagado'),
                            backgroundColor: Colors.grey.shade700,
                            foregroundColor: Colors.white,
                          ),
                        ] else if (estaAtrasado) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Pago Atrasado',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _AnimatedButton(
                            onPressed: () {
                              // TODO: Implementar flujo de pago
                            },
                            icon: const Icon(Icons.payments, size: 16),
                            label: const Text('Pagar'),
                            backgroundColor: const Color(0xFFFF9800), // Naranja
                            foregroundColor: Colors.white,
                          ),
                        ] else ...[
                          _AnimatedButton(
                            onPressed: () {
                              // TODO: Implementar flujo de pago
                            },
                            icon: const Icon(Icons.payments, size: 16),
                            label: const Text('Pagar'),
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _AnimatedButton(
                          onPressed: () {
                            // TODO: Implementar visualización/descarga de factura
                          },
                          icon: const Icon(Icons.description, size: 16),
                          label: const Text('Factura'),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2196F3),
                          borderColor: const Color(0xFF2196F3),
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
                elevation: 2,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Item de la barra de navegación inferior.
class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF87CEEB).withOpacity(0.3)
                  : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
