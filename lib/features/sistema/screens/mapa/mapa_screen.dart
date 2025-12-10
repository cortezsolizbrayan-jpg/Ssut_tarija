import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Pantalla de mapa que muestra ubicaciones de programas y sedes.
class MapaScreen extends ConsumerStatefulWidget {
  const MapaScreen({super.key});

  @override
  ConsumerState<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends ConsumerState<MapaScreen>
    with TickerProviderStateMixin {
  String _selectedLocation = 'Todas';

  // Controladores de animación
  late AnimationController _headerAnimationController;
  late AnimationController _mapAnimationController;
  late AnimationController _markersAnimationController;
  late AnimationController _listAnimationController;

  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _mapScaleAnimation;
  late Animation<double> _mapFadeAnimation;

  final List<Map<String, dynamic>> _locations = [
    {
      'nombre': 'Sede Principal UPEA',
      'direccion': 'El Alto, La Paz, Bolivia',
      'lat': -16.5048,
      'lng': -68.1633,
      'tipo': 'Sede Principal',
      'programas': ['DIPLOMADO', 'MAESTRÍA', 'DOCTORADO'],
      'telefono': '+591 2 2830000',
      'email': 'info@upea.edu.bo',
      'horario': 'Lunes a Viernes: 8:00 AM - 6:00 PM',
    },
    {
      'nombre': 'Campus Virtual Posgrado UAP',
      'direccion': 'Plataforma Moodle - posgradouap.edu.bo',
      'lat': -16.5000,
      'lng': -68.1500,
      'tipo': 'Virtual',
      'programas': ['Todos los programas virtuales'],
      'telefono': '+591 2 2830000',
      'email': 'uapnetpostgrado@gmail.com',
      'horario': '24/7 - Acceso en línea',
      'url': 'https://posgradouap.edu.bo',
    },
    {
      'nombre': 'Centro de Extensión La Paz',
      'direccion': 'La Paz, Bolivia',
      'lat': -16.4950,
      'lng': -68.1400,
      'tipo': 'Extensión',
      'programas': ['DIPLOMADO', 'ESPECIALIDAD'],
      'telefono': '+591 2 2830000',
      'email': 'extension@upea.edu.bo',
      'horario': 'Lunes a Viernes: 8:00 AM - 6:00 PM',
    },
    {
      'nombre': 'Sede Pando',
      'direccion': 'Cobija, Pando, Bolivia',
      'lat': -11.0267,
      'lng': -68.7692,
      'tipo': 'Sede Principal',
      'programas': ['DIPLOMADO', 'MAESTRÍA'],
      'telefono': '+591 3 8420000',
      'email': 'pando@uap.edu.bo',
      'horario': 'Lunes a Viernes: 8:00 AM - 6:00 PM',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Animación del header
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _headerAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Animación del mapa
    _mapAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _mapScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mapAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
    _mapFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mapAnimationController, curve: Curves.easeIn),
    );

    // Animación de marcadores
    _markersAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Animación de lista
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Iniciar animaciones
    _headerAnimationController.forward();
    _mapAnimationController.forward();
    _markersAnimationController.forward();
    _listAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _mapAnimationController.dispose();
    _markersAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Filtros de ubicación
            _buildLocationFilters(),
            // Mapa (simulado con imagen o widget de mapa)
            Expanded(child: _buildMapView()),
            // Lista de ubicaciones
            _buildLocationsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFadeAnimation,
      child: SlideTransition(
        position: _headerSlideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A3A5C), Color(0xFF2C5F8D)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      );
                    },
                  ),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(20 * (1 - value), 0),
                            child: const Text(
                              'Mapa de Ubicaciones',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - value)),
                      child: Text(
                        'Encuentra sedes y centros de programas de posgrado',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFilters() {
    final tipos = ['Todas', 'Sede Principal', 'Virtual', 'Extensión'];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: tipos.length,
                  itemBuilder: (context, index) {
                    final tipo = tipos[index];
                    final isSelected = _selectedLocation == tipo;
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOut,
                      builder: (context, animValue, child) {
                        return Opacity(
                          opacity: animValue,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * animValue),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedLocation = tipo;
                                    // Reiniciar animación de marcadores
                                    _markersAnimationController.reset();
                                    _markersAnimationController.forward();
                                  });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFFFC900)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFFC900)
                                          : Colors.grey.shade300,
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFFFC900,
                                              ).withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.location_on
                                            : Icons.location_on_outlined,
                                        color: isSelected
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tipo,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    final filteredLocations = _selectedLocation == 'Todas'
        ? _locations
        : _locations.where((loc) => loc['tipo'] == _selectedLocation).toList();

    return ScaleTransition(
      scale: _mapScaleAnimation,
      child: FadeTransition(
        opacity: _mapFadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Mapa simulado mejorado con imagen de fondo
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF87CEEB).withOpacity(0.4),
                        const Color(0xFF2196F3).withOpacity(0.3),
                        const Color(0xFF1A3A5C).withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: (1 - value) * 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF2196F3,
                                      ).withOpacity(0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.map,
                                  size: 60,
                                  color: const Color(0xFF2196F3),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 10 * (1 - value)),
                              child: Text(
                                'Mapa de Ubicaciones',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.scale(
                              scale: 0.8 + (0.2 * value),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF2196F3,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${filteredLocations.length} ubicaciones encontradas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: ElevatedButton.icon(
                                onPressed: () => _openInMaps(filteredLocations),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Abrir en Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Marcadores de ubicación animados
                ...filteredLocations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final location = entry.value;
                  // Distribuir marcadores de forma más inteligente
                  final left = 30.0 + ((index % 3) * 100.0);
                  final top = 80.0 + ((index ~/ 3) * 120.0);

                  return _AnimatedMarker(
                    left: left.clamp(20.0, 300.0),
                    top: top.clamp(50.0, 400.0),
                    location: location,
                    delay: Duration(milliseconds: 400 + (index * 200)),
                    onTap: () => _showLocationDetails(location),
                    getLocationColor: _getLocationColor,
                    getLocationIcon: _getLocationIcon,
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationsList() {
    final filteredLocations = _selectedLocation == 'Todas'
        ? _locations
        : _locations.where((loc) => loc['tipo'] == _selectedLocation).toList();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text(
                          'Ubicaciones',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${filteredLocations.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        final location = filteredLocations[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 100)),
                          curve: Curves.easeOut,
                          builder: (context, animValue, child) {
                            return Opacity(
                              opacity: animValue,
                              child: Transform.translate(
                                offset: Offset(20 * (1 - animValue), 0),
                                child: _LocationCard(
                                  location: location,
                                  onTap: () => _showLocationDetails(location),
                                ),
                              ),
                            );
                          },
                        );
                      },
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

  Color _getLocationColor(String tipo) {
    switch (tipo) {
      case 'Sede Principal':
        return Colors.red;
      case 'Virtual':
        return Colors.blue;
      case 'Extensión':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getLocationIcon(String tipo) {
    switch (tipo) {
      case 'Sede Principal':
        return Icons.business;
      case 'Virtual':
        return Icons.cloud;
      case 'Extensión':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }

  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      transitionAnimationController: _listAnimationController,
      builder: (context) => _LocationDetailsSheet(
        location: location,
        getLocationColor: _getLocationColor,
        getLocationIcon: _getLocationIcon,
        openInMaps: _openInMaps,
      ),
    );
  }

  Future<void> _openInMaps(List<Map<String, dynamic>> locations) async {
    if (locations.isEmpty) return;

    // Si hay una sola ubicación, abrir esa
    if (locations.length == 1) {
      final location = locations.first;
      final lat = location['lat'] as double;
      final lng = location['lng'] as double;
      final url = 'https://www.google.com/maps?q=$lat,$lng';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } else {
      // Si hay múltiples, abrir con todas las ubicaciones
      final centerLat =
          locations.map((l) => l['lat'] as double).reduce((a, b) => a + b) /
          locations.length;
      final centerLng =
          locations.map((l) => l['lng'] as double).reduce((a, b) => a + b) /
          locations.length;
      final url = 'https://www.google.com/maps?q=$centerLat,$centerLng';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }
}

/// Marcador animado para el mapa.
class _AnimatedMarker extends StatefulWidget {
  const _AnimatedMarker({
    required this.left,
    required this.top,
    required this.location,
    required this.delay,
    required this.onTap,
    required this.getLocationColor,
    required this.getLocationIcon,
  });

  final double left;
  final double top;
  final Map<String, dynamic> location;
  final Duration delay;
  final VoidCallback onTap;
  final Color Function(String) getLocationColor;
  final IconData Function(String) getLocationIcon;

  @override
  State<_AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<_AnimatedMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Iniciar animación después del delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value * (_isPressed ? 0.9 : 1.0),
              child: Transform.translate(
                offset: Offset(0, -5 * _bounceAnimation.value),
                child: Column(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: widget.getLocationColor(
                          widget.location['tipo'] as String,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: widget
                                .getLocationColor(
                                  widget.location['tipo'] as String,
                                )
                                .withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        widget.getLocationIcon(
                          widget.location['tipo'] as String,
                        ),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.location['nombre'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LocationCard extends StatefulWidget {
  const _LocationCard({required this.location, required this.onTap});

  final Map<String, dynamic> location;
  final VoidCallback onTap;

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: _isPressed
                    ? []
                    : [
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
                      color: _getLocationColor(
                        widget.location['tipo'] as String,
                      ).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getLocationIcon(widget.location['tipo'] as String),
                      color: _getLocationColor(
                        widget.location['tipo'] as String,
                      ),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.location['nombre'] as String,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.location['direccion'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLocationColor(String tipo) {
    switch (tipo) {
      case 'Sede Principal':
        return Colors.red;
      case 'Virtual':
        return Colors.blue;
      case 'Extensión':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getLocationIcon(String tipo) {
    switch (tipo) {
      case 'Sede Principal':
        return Icons.business;
      case 'Virtual':
        return Icons.cloud;
      case 'Extensión':
        return Icons.location_city;
      default:
        return Icons.place;
    }
  }
}

class _LocationDetailsSheet extends StatelessWidget {
  const _LocationDetailsSheet({
    required this.location,
    required this.getLocationColor,
    required this.getLocationIcon,
    required this.openInMaps,
  });

  final Map<String, dynamic> location;
  final Color Function(String) getLocationColor;
  final IconData Function(String) getLocationIcon;
  final void Function(List<Map<String, dynamic>>) openInMaps;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: getLocationColor(
                      location['tipo'] as String,
                    ).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    getLocationIcon(location['tipo'] as String),
                    color: getLocationColor(location['tipo'] as String),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location['nombre'] as String,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: getLocationColor(
                            location['tipo'] as String,
                          ).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          location['tipo'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: getLocationColor(location['tipo'] as String),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.location_on,
              label: 'Dirección',
              value: location['direccion'] as String,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              icon: Icons.school,
              label: 'Programas disponibles',
              value: (location['programas'] as List).join(', '),
            ),
            if (location['telefono'] != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.phone,
                label: 'Teléfono',
                value: location['telefono'] as String,
              ),
            ],
            if (location['email'] != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.email,
                label: 'Email',
                value: location['email'] as String,
              ),
            ],
            if (location['horario'] != null) ...[
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.access_time,
                label: 'Horario',
                value: location['horario'] as String,
              ),
            ],
            if (location['url'] != null) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _openUrl(context, location['url'] as String),
                child: _DetailRow(
                  icon: Icons.language,
                  label: 'Sitio Web',
                  value: location['url'] as String,
                  isClickable: true,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openInMapsForLocation(context),
                    icon: const Icon(Icons.directions),
                    label: const Text('Abrir en Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                if (location['url'] != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _openUrl(context, location['url'] as String),
                      icon: const Icon(Icons.language),
                      label: const Text('Sitio Web'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openInMapsForLocation(BuildContext context) async {
    final lat = location['lat'] as double;
    final lng = location['lng'] as double;
    final url = 'https://www.google.com/maps?q=$lat,$lng';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  static Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No se pudo abrir la URL')));
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isClickable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isClickable;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: isClickable ? const Color(0xFF2196F3) : Colors.black87,
                  fontWeight: FontWeight.w500,
                  decoration: isClickable ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
