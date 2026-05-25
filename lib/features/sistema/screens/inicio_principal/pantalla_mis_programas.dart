import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/presentation/providers/programa_posgrado_provider.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/pantalla_detalle_programa.dart';

import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_tarjeta.dart';
import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_categorias.dart';
import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_estado_vacio.dart';
import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_filtros.dart';
import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_encabezado.dart';
import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_cargando.dart';
import 'package:refactor_template/features/sistema/screens/inicio_principal/componentes/mis_programas_barra_busqueda.dart';

/// Pantalla de "Mis Programas" con filtros y lista de programas.
class MisProgramasPantalla extends ConsumerStatefulWidget {
  const MisProgramasPantalla({super.key});

  @override
  ConsumerState<MisProgramasPantalla> createState() =>
      _MisProgramasPantallaState();
}

class _MisProgramasPantallaState extends ConsumerState<MisProgramasPantalla> {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0; // ÃƒÂndice del icono seleccionado
  String _sortBy = 'nombre'; // 'nombre', 'progreso', 'saldo'
  bool _isGridView = false; // Vista de lista o grilla
  final Set<String> _favorites = {}; // IDs de programas favoritos
  bool _showOnlyFavorites = false;
  String _username = 'anon';
  bool _loadingUserPrograms = true;
  Set<String> _enrolledProgramIds = {};

  // Debounce para busqueda
  Timer? _searchDebounce;
  String _searchQuery = '';

  final List<String> _filters = [
    'Todos',
    'MaestrÃƒÂ­a',
    'Especialidad',
    'Diplomado',
    'Doctorado',
    'Posdoctorado',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPrograms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Widget que muestra el estado vacÃƒÂ­o cuando el usuario no tiene programas inscritos
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(
          ResponsiveUtils.horizontalPadding(context) * 1.5,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de medalla en plomo (gris oscuro)
            Container(
              padding: EdgeInsets.all(
                ResponsiveUtils.horizontalPadding(context),
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.workspace_premium,
                size: ResponsiveUtils.largeIconSize(context) * 1.2,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalPadding(context) * 1.5),

            // TÃƒÂ­tulo
            Text(
              'Ã‚Â¡AÃƒÂºn no tienes programas!',
              style: TextStyle(
                fontSize: ResponsiveUtils.titleFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.cardSpacing(context)),

            // DescripciÃƒÂ³n
            Text(
              'Todas tus medallas estÃƒÂ¡n en plomo.\nInscrÃƒÂ­bete a un programa para comenzar a ganar medallas y avanzar en tu carrera profesional.',
              style: TextStyle(
                fontSize: ResponsiveUtils.bodyFontSize(context),
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.verticalPadding(context) * 1.5),

            // Fila de medallas en plomo
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMedalIcon(
                  Icons.military_tech,
                  Colors.grey.shade400,
                  'Bronce',
                ),
                SizedBox(width: ResponsiveUtils.cardSpacing(context)),
                _buildMedalIcon(Icons.stars, Colors.grey.shade400, 'Plata'),
                SizedBox(width: ResponsiveUtils.cardSpacing(context)),
                _buildMedalIcon(
                  Icons.emoji_events,
                  Colors.grey.shade400,
                  'Oro',
                ),
              ],
            ),
            SizedBox(height: ResponsiveUtils.verticalPadding(context) * 2),

            // BotÃƒÂ³n de acciÃƒÂ³n
            ElevatedButton.icon(
              onPressed: () {
                // Navegar a la pantalla de programas vigentes
                context.go('/sistema/programas-vigentes');
              },
              icon: Icon(
                Icons.add_circle_outline,
                size: ResponsiveUtils.mediumIconSize(context),
              ),
              label: Text(
                'Explorar Programas',
                style: TextStyle(
                  fontSize: ResponsiveUtils.subtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 16),

            // Texto secundario
            Text(
              'Descubre maestrÃƒÂ­as, especialidades y diplomados\nque impulsarÃƒÂ¡n tu crecimiento profesional',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedalIcon(IconData icon, Color color, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> _loadUserPrograms() async {
    try {
      final session = await LocalStorageService.getSessionData().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );
      final nombreUsuario = (session?['nombreUsuario'] as String?)?.trim();
      final username = (nombreUsuario != null && nombreUsuario.isNotEmpty)
          ? nombreUsuario
          : 'anon';
      final enrolled = await LocalStorageService.getUserPrograms(
        username,
      ).timeout(const Duration(seconds: 5), onTimeout: () => <String>{});
      if (!mounted) return;
      setState(() {
        _username = username;
        _enrolledProgramIds = enrolled;
        _loadingUserPrograms = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUserPrograms = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF005BAC),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF005BAC),
        body: SafeArea(
          bottom: false,
          top: false,
          child: Container(
            color: isDark
                ? const Color(0xFF0D1B2E) // azul marino oscuro
                : const Color(0xFFF5F5F5), // gris claro
            child: Consumer(
              builder: (context, ref, _) {
                final programasAsync = ref.watch(
                  programasPosgradoProvider({
                    'area': null,
                    'tipo': _selectedFilter == 'Todos' ? null : _selectedFilter,
                  }),
                );

                return programasAsync.when(
                  data: (programas) {
                    final visiblePrograms = programas
                        .where((p) => _enrolledProgramIds.contains(p.id))
                        .toList();

                    // Nodos estÃƒÂ¡ticos del mapa de progreso acadÃƒÂ©mico
                    // Siempre se muestran los 4 niveles, independiente de inscripciones
                    // El agua indica el nivel alcanzado por el usuario
                    final tiposInscritos = visiblePrograms
                        .map((p) => p.tipo.toUpperCase())
                        .toSet();

                    bool tieneDiplomado = tiposInscritos.any(
                      (t) => t.contains('DIPLOMADO'),
                    );
                    bool tieneMaestria = tiposInscritos.any(
                      (t) => t.contains('MAESTR'),
                    );
                    bool tieneDoctorado = tiposInscritos.any(
                      (t) => t.contains('DOCTOR'),
                    );
                    bool tienePosdoctorado = tiposInscritos.any(
                      (t) =>
                          t.contains('POSDOCTOR') || t.contains('POSDOCTORADO'),
                    );

                    // DEMO: CI 12865123 y 12865213 tienen Diplomado + MaestrÃƒÂ­a para mostrar efecto agua
                    if (_username == '12865123' || _username == '12865213') {
                      tieneDiplomado = true;
                      tieneMaestria = true;
                    }

                    // Mapa de progreso: siempre 4 nodos fijos
                    List<Map<String, dynamic>> dynamicCategories = [
                      {
                        'id': 'diplomado',
                        'icon': Icons.menu_book_rounded,
                        'label': 'Diplomado',
                        'color': const Color(0xFFD4AF37), // Dorado
                        'riveArtboard': 'TIMER',
                        'activo': tieneDiplomado,
                      },
                      {
                        'id': 'maestria',
                        'icon': Icons.school_rounded,
                        'label': 'MaestrÃƒÂ­a',
                        'color': const Color(0xFF005BAC), // Azul UPEA
                        'riveArtboard': 'SEARCH',
                        'activo': tieneMaestria,
                      },
                      {
                        'id': 'doctorado',
                        'icon': Icons.account_balance_rounded,
                        'label': 'Doctorado',
                        'color': const Color(0xFF7B1FA2), // PÃƒÂºrpura
                        'riveArtboard': 'USER',
                        'activo': tieneDoctorado,
                      },
                      {
                        'id': 'posdoctorado',
                        'icon': Icons.workspace_premium_rounded,
                        'label': 'Posdoctorado',
                        'color': const Color(0xFFC62828), // Rojo institucional
                        'riveArtboard': 'BELL',
                        'activo': tienePosdoctorado,
                      },
                    ];

                    // selectedCategory basado en el nivel mÃƒÂ¡s alto alcanzado
                    int nivelAlcanzado = 0;
                    if (tieneDiplomado) nivelAlcanzado = 0;
                    if (tieneMaestria) nivelAlcanzado = 1;
                    if (tieneDoctorado) nivelAlcanzado = 2;
                    if (tienePosdoctorado) nivelAlcanzado = 3;

                    // Si el usuario seleccionÃƒÂ³ manualmente, respetar su selecciÃƒÂ³n
                    // Si no, mostrar el nivel mÃƒÂ¡s alto alcanzado
                    final categoriaEfectiva =
                        (_selectedCategory > 0
                                ? _selectedCategory
                                : nivelAlcanzado)
                            .clamp(0, dynamicCategories.length - 1);

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // 1. Cabecera
                        const SliverToBoxAdapter(child: MisProgramasHeader()),

                        // 2. Buscador
                        SliverToBoxAdapter(
                          child: MisProgramasSearchBar(
                            controller: _searchController,
                            onChanged: (value) {
                              // Debounce: esperar 300ms antes de filtrar
                              _searchDebounce?.cancel();
                              _searchDebounce = Timer(
                                const Duration(milliseconds: 300),
                                () {
                                  if (mounted) {
                                    setState(() => _searchQuery = value);
                                  }
                                },
                              );
                            },
                            onClear: () {
                              _searchDebounce?.cancel();
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          ),
                        ),

                        // 3. MAPA DE PROGRESO ACADÃƒâ€°MICO (siempre visible)
                        SliverToBoxAdapter(
                          child: MisProgramasCategories(
                            categories: dynamicCategories,
                            selectedCategory: categoriaEfectiva,
                            onCategorySelected: (index) =>
                                setState(() => _selectedCategory = index),
                          ),
                        ),

                        // 4. Filtros
                        SliverToBoxAdapter(
                          child: MisProgramasFilters(
                            filters: _filters,
                            selectedFilter: _selectedFilter,
                            onFilterSelected: (filter) =>
                                setState(() => _selectedFilter = filter),
                            sortLabel: _getSortLabel(),
                            onShowSortDialog: () => _showSortDialog(context),
                            isGridView: _isGridView,
                            onToggleView: () =>
                                setState(() => _isGridView = !_isGridView),
                            showOnlyFavorites: _showOnlyFavorites,
                            onToggleFavorites: () => setState(
                              () => _showOnlyFavorites = !_showOnlyFavorites,
                            ),
                          ),
                        ),

                        // 5. Lista de Programas
                        _buildProgramsSliverList(
                          visiblePrograms,
                          selectedId: null,
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    );
                  },
                  loading: () => const Center(child: MisProgramasLoading()),
                  error: (e, s) =>
                      const Center(child: Text('Error al cargar programas')),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'nombre':
        return 'Nombre';
      case 'progreso':
        return 'Progreso';
      case 'saldo':
        return 'Saldo';
      default:
        return 'Ordenar';
    }
  }

  void _showSortDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: ResponsiveUtils.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: ResponsiveUtils.cardSpacing(context) * 1.2),
            _buildSortOption(
              context,
              'nombre',
              'Nombre A-Z',
              Icons.sort_by_alpha,
            ),
            _buildSortOption(
              context,
              'progreso',
              'Progreso',
              Icons.trending_up,
            ),
            _buildSortOption(
              context,
              'saldo',
              'Saldo Pendiente',
              Icons.account_balance_wallet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(
    BuildContext context,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
      ),
      title: Text(label),
      trailing: isSelected
          ? const Icon(Icons.check, color: Color(0xFF2196F3))
          : null,
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
    );
  }

  Widget _buildProgramsSliverList(
    List<ProgramaPosgrado> programs, {
    String? selectedId,
  }) {
    if (_loadingUserPrograms) {
      return const SliverToBoxAdapter(child: MisProgramasLoading());
    }
    if (programs.isEmpty) {
      return const SliverToBoxAdapter(child: MisProgramasEmptyState());
    }

    var filtered = programs.where((p) {
      if (selectedId != null && selectedId != 'todos') {
        return p.id == selectedId;
      }
      if (_searchQuery.isEmpty) return true;
      final s = _searchQuery.toLowerCase();
      return p.titulo.toLowerCase().contains(s) ||
          p.area.toLowerCase().contains(s);
    }).toList();

    if (_showOnlyFavorites && selectedId == 'todos') {
      filtered = filtered.where((p) => _favorites.contains(p.titulo)).toList();
    }

    if (filtered.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: Text('No hay resultados')),
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
        vertical: ResponsiveUtils.scale(context, 8),
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final p = filtered[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.cardSpacing(context),
            ),
            child: MisProgramasCard(
              programa: p,
              index: index,
              isFavorite: _favorites.contains(p.titulo),
              onFavoriteToggle: () => setState(() {
                if (_favorites.contains(p.titulo)) {
                  _favorites.remove(p.titulo);
                } else {
                  _favorites.add(p.titulo);
                }
              }),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      DetalleProgramaPantalla(titulo: p.titulo, tipo: p.tipo),
                ),
              ),
            ),
          );
        }, childCount: filtered.length),
      ),
    );
  }
}

//se muestra el Widget de la tarjeta del programa
class _ProgramCard extends StatefulWidget {
  const _ProgramCard({
    required this.programa,
    required this.onTap,
    required this.index,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });
  //Se definen los parametros del Widget de la tarjeta del programa
  final dynamic programa;
  final VoidCallback onTap;
  final int index;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

//Se define el estado del Widget de la tarjeta del programa
class _ProgramCardState extends State<_ProgramCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;
  // se inicializan las animaciones
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    //se define la animaciÃƒÂ³n de escala del Widget
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
      //se define la curva de la animaciÃƒÂ³n
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(
      //se define el valor inicial y final de la animaciÃƒÂ³n
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  //se libera la memoria de las animaciones
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //se muestra el Widget de la tarjeta del programa
  @override
  Widget build(BuildContext context) {
    final estaCompletado =
        widget.programa.estado.contains('ESTADO_COMPLETO') ||
        widget.programa.estado.contains('COMPLETADO');
    //widget.programa.estado.contains('ESTADO');
    final progresoPago = estaCompletado ? 100.0 : 65.0; // Simulado
    //se muestra el Widget de la tarjeta del programa
    return GestureDetector(
      //se presiona el Widget
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      //se levanta el Widget
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap();
      },
      //se cancela la animaciÃƒÂ³n
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      //se anima el Widget
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, hijo) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _isPressed
                          ? const Color(0xFF2196F3).withOpacity(0.3)
                          : Colors.black.withOpacity(0.08),
                      blurRadius: _isPressed ? 20 : 10,
                      spreadRadius: _isPressed ? 2 : 0,
                      offset: Offset(0, _isPressed ? 8 : 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de tipo y estado con botÃƒÂ³n de favorito
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A3A5C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.programa.tipo,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    // ignore: unnecessary_cast
                                  ),
                                ),
                              ),
                              //se muestra el descuento del programa
                              const SizedBox(width: 8),
                              if (widget.programa.descuento != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${widget.programa.descuento!.toInt()}% desc.',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // BotÃƒÂ³n de favorito
                        if (widget.onFavoriteToggle != null)
                          //se muestra el boton de favorito
                          GestureDetector(
                            onTap: widget.onFavoriteToggle,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.isFavorite
                                    ? Colors.red.shade50
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                widget.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                size: 20,
                                color: widget.isFavorite
                                    ? Colors.red
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // TÃƒÂ­tulo
                    //se muestra el titulo del programa
                    Text(
                      widget.programa.titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    // InformaciÃƒÂ³n del programa
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.programa.duracion,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.school,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.programa.modalidad,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      //se define el color del estado del programa
                      decoration: BoxDecoration(
                        color: estaCompletado
                            ? Colors.green.shade50
                            : widget.programa.estado.contains('ABIERTAS')
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      //se
                      child: Text(
                        widget.programa.estado,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: estaCompletado
                              ? Colors.green.shade700
                              : widget.programa.estado.contains('ABIERTAS')
                              ? Colors.blue.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Progreso del pago
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Progreso del Pago',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progresoPago / 100,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    estaCompletado
                                        ? Colors.green
                                        : const Color(0xFF2196F3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              //se muestra el progreso del pago
                              Text(
                                '${progresoPago.toInt()}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        //se muestra el icono de la mascota
                        Container(
                          width: 60,
                          height: 60,
                          //se define el color del contenedor de la mascota
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A3A5C).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              estaCompletado ? 'Ã°Å¸Å½â€œ' : 'Ã°Å¸â€œÅ¡',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    //se muestra el boton de ver programa
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Ver Programa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Widget de carga con candado animado
class _LoadingStateWidget extends StatefulWidget {
  @override
  State<_LoadingStateWidget> createState() => _LoadingStateWidgetState();
}

//se define el estado del Widget de carga con candado animado
class _LoadingStateWidgetState extends State<_LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  //se define el efecto scale del Widget
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;
  //se inicializan las animaciones
  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          //se repite la animaciÃƒÂ³n
          ..repeat();
    //se define la animaciÃƒÂ³n de rotaciÃƒÂ³n del Widget

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
    //se define el efecto scale del Widget
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    //se define el efecto shimmer del Widget
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  //se libera la memoria de las animaciones
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  //se muestra el Widget de carga con candado animado
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //se muestra el efecto shimmer del Widget
          AnimatedBuilder(
            animation: _controller,
            builder: (context, hijo) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
                  //se muestra el contenedor del Widget
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1A3A5C),
                          const Color(0xFF2C5F8D),
                        ],
                      ),
                      //se muestra el shadow del Widget
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A3A5C).withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Efecto shimmer
                        ClipOval(
                          child: AnimatedBuilder(
                            animation: _shimmerAnimation,
                            builder: (context, hijo) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    //se define el efecto shimmer del Widget
                                    begin: Alignment(
                                      _shimmerAnimation.value - 1,
                                      0,
                                    ),
                                    end: Alignment(_shimmerAnimation.value, 0),
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.3),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        // Icono de candado
                        const Icon(Icons.lock, size: 60, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          //se muestra el texto de cargando programas
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, hijo) {
              return Opacity(
                opacity: value,
                child: Column(
                  children: [
                    const Text(
                      'Cargando Programas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    //se muestra el progreso de carga
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 200,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Por favor espera...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
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

