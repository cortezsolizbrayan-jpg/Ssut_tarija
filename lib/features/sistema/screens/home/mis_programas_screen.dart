import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/presentation/providers/programa_posgrado_provider.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/detalle_programa_screen.dart';
import 'package:refactor_template/features/sistema/widgets/notification_icon_widget.dart';
import 'package:refactor_template/features/sistema/widgets/profile_avatar_widget.dart';

/// Pantalla de "Mis Programas" con filtros y lista de programas.
class MisProgramasScreen extends ConsumerStatefulWidget {
  const MisProgramasScreen({super.key});

  @override
  ConsumerState<MisProgramasScreen> createState() => _MisProgramasScreenState();
}

class _MisProgramasScreenState extends ConsumerState<MisProgramasScreen> {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategory = 0; // Índice del icono seleccionado
  String _sortBy = 'nombre'; // 'nombre', 'progreso', 'saldo'
  bool _isGridView = false; // Vista de lista o grilla
  Set<String> _favorites = {}; // IDs de programas favoritos
  bool _showOnlyFavorites = false;

  final List<String> _filters = [
    'Todos',
    'Maestría',
    'Especialidad',
    'Diplomado',
    'Doctorado',
    'Posdoctorado',
  ];

  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.check_circle, 'label': 'Completados', 'color': Colors.amber},
    {
      'icon': Icons.school,
      'label': 'En Curso',
      'color': const Color(0xFF1A3A5C),
    },
    {'icon': Icons.menu_book, 'label': 'Pendientes', 'color': Colors.grey},
    {
      'icon': Icons.workspace_premium,
      'label': 'Certificados',
      'color': Colors.grey,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
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
            // Header azul con título y subtítulo
            _buildHeader(),
            // Barra de búsqueda
            _buildSearchBar(),
            // Iconos de categorías conectados
            _buildCategoryIcons(),
            // Filtros horizontales
            _buildFilters(),
            // Lista de programas
            Expanded(child: _buildProgramsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A3A5C), // Azul oscuro
            Color(0xFF2C5F8D), // Azul medio
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 20, 24),
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
                      // TODO: Abrir menú lateral
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Logo Posgrado con animación
                Image.asset(
                  'assets/images/logposgrado.png',
                  height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'POSGRADO',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(2, 2),
                              blurRadius: 6,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(-1, -1),
                              blurRadius: 4,
                            ),
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 0),
                              blurRadius: 8,
                            ),
                          ],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
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
                          colors: [Color(0xFF1E293B), Color(0xFF64748B)],
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
              'Todos los programas que está cursando o cursó.',
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

  Widget _buildSearchBar() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscador...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final iconSize = math
            .max(50.0, math.min(60.0, screenWidth * 0.14))
            .toDouble();
        final iconInnerSize = math
            .max(24.0, math.min(28.0, screenWidth * 0.065))
            .toDouble();
        final lineWidth = math
            .max(30.0, math.min(40.0, screenWidth * 0.095))
            .toDouble();
        final lineMargin = math
            .max(6.0, math.min(8.0, screenWidth * 0.019))
            .toDouble();

        return RepaintBoundary(
          child: Container(
            margin: EdgeInsets.only(
              top: math.max(4.0, screenWidth * 0.01).toDouble(),
              bottom: math
                  .max(12.0, math.min(16.0, screenWidth * 0.038))
                  .toDouble(),
            ),
            padding: EdgeInsets.symmetric(
              vertical: math
                  .max(16.0, math.min(20.0, screenWidth * 0.048))
                  .toDouble(),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: math
                    .max(16.0, math.min(20.0, screenWidth * 0.045))
                    .toDouble(),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_categories.length, (index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == index;
                  final isLast = index == _categories.length - 1;
                  final isCompleted = index <= _selectedCategory;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = index;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? category['color'] as Color
                                : (category['color'] as Color).withOpacity(0.3),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? category['color'] as Color
                                  : Colors.transparent,
                              width: math
                                  .max(2.0, math.min(3.0, screenWidth * 0.007))
                                  .toDouble(),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (category['color'] as Color)
                                          .withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            category['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : category['color'] as Color,
                            size: iconInnerSize,
                          ),
                        ),
                      ),
                      if (!isLast)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          width: lineWidth,
                          height: math
                              .max(2.0, math.min(3.0, screenWidth * 0.007))
                              .toDouble(),
                          margin: EdgeInsets.symmetric(horizontal: lineMargin),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? (category['color'] as Color).withOpacity(0.6)
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: isCompleted
                                ? [
                                    BoxShadow(
                                      color: (category['color'] as Color)
                                          .withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final fontSize = math
                .max(11.0, math.min(14.0, screenWidth * 0.033))
                .toDouble();
            final iconSize = math
                .max(16.0, math.min(18.0, screenWidth * 0.04))
                .toDouble();
            final paddingH = math
                .max(12.0, math.min(20.0, screenWidth * 0.045))
                .toDouble();
            final paddingV = math
                .max(6.0, math.min(8.0, screenWidth * 0.019))
                .toDouble();
            final spacing = math
                .max(8.0, math.min(12.0, screenWidth * 0.028))
                .toDouble();

            return SizedBox(
              height: math
                  .max(50.0, math.min(60.0, screenWidth * 0.14))
                  .toDouble(),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(
                  horizontal: math
                      .max(16.0, math.min(20.0, screenWidth * 0.045))
                      .toDouble(),
                ),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: spacing),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedFilter = filter;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: paddingH,
                          vertical: paddingV,
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
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.grid_view,
                              color: isSelected
                                  ? Colors.black87
                                  : Colors.grey.shade600,
                              size: iconSize,
                            ),
                            SizedBox(
                              width: math
                                  .max(6.0, screenWidth * 0.015)
                                  .toDouble(),
                            ),
                            Flexible(
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          },
        ),
        // Barra de herramientas (ordenar, vista, favoritos)
        LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final paddingH = math
                .max(16.0, math.min(20.0, screenWidth * 0.045))
                .toDouble();
            final paddingV = math
                .max(6.0, math.min(8.0, screenWidth * 0.019))
                .toDouble();
            final iconSize = math
                .max(16.0, math.min(20.0, screenWidth * 0.047))
                .toDouble();
            final fontSize = math
                .max(10.0, math.min(12.0, screenWidth * 0.028))
                .toDouble();
            final buttonPaddingH = math
                .max(10.0, math.min(12.0, screenWidth * 0.028))
                .toDouble();
            final buttonPaddingV = math
                .max(6.0, math.min(8.0, screenWidth * 0.019))
                .toDouble();
            final spacing = math
                .max(6.0, math.min(8.0, screenWidth * 0.019))
                .toDouble();
            final iconButtonPadding = math
                .max(6.0, math.min(8.0, screenWidth * 0.019))
                .toDouble();

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingH,
                vertical: paddingV,
              ),
              child: Row(
                children: [
                  // Botón de ordenar
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _showSortDialog(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: buttonPaddingH,
                          vertical: buttonPaddingV,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort,
                              size: iconSize,
                              color: Colors.grey.shade700,
                            ),
                            SizedBox(width: spacing),
                            Flexible(
                              child: Text(
                                _getSortLabel(),
                                style: TextStyle(
                                  fontSize: fontSize,
                                  color: Colors.grey.shade700,
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
                  const Spacer(),
                  // Botón de favoritos
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showOnlyFavorites = !_showOnlyFavorites;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(iconButtonPadding),
                      decoration: BoxDecoration(
                        color: _showOnlyFavorites
                            ? Colors.red.shade50
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _showOnlyFavorites
                              ? Colors.red
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Icon(
                        _showOnlyFavorites
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: iconSize,
                        color: _showOnlyFavorites
                            ? Colors.red
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  // Botón de vista (lista/grilla)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isGridView = !_isGridView;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(iconButtonPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        size: iconSize,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Ordenar por',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
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
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildProgramsList() {
    // Obtener programas desde el provider
    final programasAsync = ref.watch(
      programasPosgradoProvider({
        'area': null,
        'tipo': _selectedFilter == 'Todos' ? null : _selectedFilter,
      }),
    );

    return programasAsync.when(
      data: (programas) {
        // Filtrar por búsqueda
        var filteredPrograms = programas.where((programa) {
          if (_searchController.text.isNotEmpty) {
            final searchLower = _searchController.text.toLowerCase();
            return programa.titulo.toLowerCase().contains(searchLower) ||
                programa.area.toLowerCase().contains(searchLower) ||
                programa.modalidad.toLowerCase().contains(searchLower);
          }
          return true;
        }).toList();

        // Filtrar por favoritos si está activo
        if (_showOnlyFavorites) {
          filteredPrograms = filteredPrograms
              .where((p) => _favorites.contains(p.titulo))
              .toList();
        }

        // Filtrar por categoría seleccionada
        if (_selectedCategory == 0) {
          // Completados
          filteredPrograms = filteredPrograms
              .where(
                (p) =>
                    p.estado.contains('INICIARON') ||
                    p.estado.contains('COMPLETADO'),
              )
              .toList();
        } else if (_selectedCategory == 1) {
          // En Curso
          filteredPrograms = filteredPrograms
              .where(
                (p) =>
                    p.estado.contains('ABIERTAS') ||
                    p.estado.contains('EN CURSO'),
              )
              .toList();
        } else if (_selectedCategory == 2) {
          // Pendientes
          filteredPrograms = filteredPrograms
              .where((p) => p.estado.contains('PREINSCRIPCIONES'))
              .toList();
        } else if (_selectedCategory == 3) {
          // Certificados (similar a completados)
          filteredPrograms = filteredPrograms
              .where(
                (p) =>
                    p.estado.contains('INICIARON') ||
                    p.estado.contains('COMPLETADO'),
              )
              .toList();
        }

        // Ordenar programas
        filteredPrograms.sort((a, b) {
          switch (_sortBy) {
            case 'nombre':
              return a.titulo.compareTo(b.titulo);
            case 'progreso':
              final progresoA =
                  a.estado.contains('INICIARON') ||
                      a.estado.contains('COMPLETADO')
                  ? 100.0
                  : 65.0;
              final progresoB =
                  b.estado.contains('INICIARON') ||
                      b.estado.contains('COMPLETADO')
                  ? 100.0
                  : 65.0;
              return progresoB.compareTo(progresoA); // Mayor a menor
            case 'saldo':
              // Simulado - en producción vendría del backend
              final saldoA = 1200.0;
              final saldoB = 200.0;
              return saldoA.compareTo(saldoB); // Mayor a menor
            default:
              return 0;
          }
        });

        if (filteredPrograms.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchController.text.isNotEmpty
                      ? Icons.search_off
                      : Icons.school_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isNotEmpty
                      ? 'No se encontraron programas con "${_searchController.text}"'
                      : 'No hay programas en esta categoría',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                if (_searchController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                    child: const Text('Limpiar búsqueda'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            // Contador de resultados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${filteredPrograms.length} programa${filteredPrograms.length != 1 ? 's' : ''} encontrado${filteredPrograms.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Lista o grilla de programas
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(programasPosgradoProvider);
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemCount: filteredPrograms.length,
                        cacheExtent: 500, // Cache más items fuera de vista
                        itemBuilder: (context, index) {
                          final programa = filteredPrograms[index];
                          return RepaintBoundary(
                            child: _ProgramCard(
                              programa: programa,
                              index: index,
                              isFavorite: _favorites.contains(programa.titulo),
                              onFavoriteToggle: () {
                                setState(() {
                                  if (_favorites.contains(programa.titulo)) {
                                    _favorites.remove(programa.titulo);
                                  } else {
                                    _favorites.add(programa.titulo);
                                  }
                                });
                              },
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleProgramaScreen(
                                      titulo: programa.titulo,
                                      tipo: programa.tipo,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: filteredPrograms.length,
                        itemExtent: 280, // Altura fija para mejor rendimiento
                        cacheExtent: 500, // Cache más items fuera de vista
                        itemBuilder: (context, index) {
                          final programa = filteredPrograms[index];
                          return RepaintBoundary(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ProgramCard(
                                programa: programa,
                                index: index,
                                isFavorite: _favorites.contains(
                                  programa.titulo,
                                ),
                                onFavoriteToggle: () {
                                  setState(() {
                                    if (_favorites.contains(programa.titulo)) {
                                      _favorites.remove(programa.titulo);
                                    } else {
                                      _favorites.add(programa.titulo);
                                    }
                                  });
                                },
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetalleProgramaScreen(
                                            titulo: programa.titulo,
                                            tipo: programa.tipo,
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
      loading: () => _LoadingStateWidget(),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error al cargar programas',
              style: TextStyle(fontSize: 16, color: Colors.red.shade600),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.invalidate(programasPosgradoProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramCard extends StatefulWidget {
  const _ProgramCard({
    required this.programa,
    required this.onTap,
    required this.index,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final dynamic programa;
  final VoidCallback onTap;
  final int index;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estaCompletado =
        widget.programa.estado.contains('INICIARON') ||
        widget.programa.estado.contains('COMPLETADO');
    final progresoPago = estaCompletado ? 100.0 : 65.0; // Simulado

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
        animation: _controller,
        builder: (context, child) {
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
                    // Badge de tipo y estado con botón de favorito
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
                                  ),
                                ),
                              ),
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
                        // Botón de favorito
                        if (widget.onFavoriteToggle != null)
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
                    // Título
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
                    // Información del programa
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
                      decoration: BoxDecoration(
                        color: estaCompletado
                            ? Colors.green.shade50
                            : widget.programa.estado.contains('ABIERTAS')
                            ? Colors.blue.shade50
                            : Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                        // Mascota
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A3A5C).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              estaCompletado ? '🎓' : '📚',
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Botón Ver Programa
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

class _LoadingStateWidgetState extends State<_LoadingStateWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value * 0.1,
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
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
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
          const SizedBox(height: 32),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
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
