import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_progress_indicator_v2/liquid_progress_indicator.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'componentes/encabezado_aplicacion.dart';
import 'componentes/tarjeta_diplomado.dart';

class DiplomadosPantalla extends StatefulWidget {
  const DiplomadosPantalla({super.key});

  @override
  State<DiplomadosPantalla> createState() => _DiplomadosPantallaState();
}

class _DiplomadosPantallaState extends State<DiplomadosPantalla>
    with TickerProviderStateMixin {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _filters = [
    'Todos',
    'Maestría',
    'Especialidad',
    'Diplomado',
    'Doctorado',
    'Posdoctorado',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF005BAC),
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header azul oscuro
            AppHeader(
              searchController: _searchController,
              onSearchChanged: (value) {
                setState(() {});
              },
              showProgramTypeRow: false,
            ),
            // MAPA DE PROGRESO ACADÉMICO CON ONDAS DE AGUA
            Transform.translate(
              offset: const Offset(0, -4),
              child: _buildAcademicProgressMap(),
            ),
            // Filtros horizontales (debajo del mapa)
            _buildFilters(),
            // Lista de programas
            Expanded(child: _buildProgramsList()),
          ],
        ),
      ),
    );
  }

  // MAPA DE PROGRESO ACADÉMICO CON ONDAS DE AGUA
  Widget _buildAcademicProgressMap() {
    final programs = _getFilteredPrograms();
    final tiposInscritos = programs
        .map((p) => p['tipo'] as String)
        .map((t) => t.toUpperCase())
        .toSet();

    bool tieneDiplomado = tiposInscritos.any((t) => t.contains('DIPLOMADO'));
    bool tieneMaestria = tiposInscritos.any((t) => t.contains('MAESTR'));
    bool tieneDoctorado = tiposInscritos.any((t) => t.contains('DOCTOR'));
    bool tienePosdoctorado = tiposInscritos.any(
      (t) => t.contains('POSDOCTOR') || t.contains('POSDOCTORADO'),
    );

    // Mapa de progreso: siempre 4 nodos fijos
    List<Map<String, dynamic>> dynamicCategories = [
      {
        'id': 'diplomado',
        'icon': Icons.menu_book_rounded,
        'label': 'Diplomado',
        'color': const Color(0xFFD4AF37), // Dorado
        'activo': tieneDiplomado,
      },
      {
        'id': 'maestria',
        'icon': Icons.school_rounded,
        'label': 'Maestría',
        'color': const Color(0xFF005BAC), // Azul UPEA
        'activo': tieneMaestria,
      },
      {
        'id': 'doctorado',
        'icon': Icons.account_balance_rounded,
        'label': 'Doctorado',
        'color': const Color(0xFF7B1FA2), // Púrpura
        'activo': tieneDoctorado,
      },
      {
        'id': 'posdoctorado',
        'icon': Icons.workspace_premium_rounded,
        'label': 'Posdoctorado',
        'color': const Color(0xFFC62828), // Rojo institucional
        'activo': tienePosdoctorado,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
        vertical: ResponsiveUtils.verticalPadding(context) * 0.5,
      ),
      child: _buildAcademicProgressNodes(
        categories: dynamicCategories,
      ),
    );
  }

  // Nodos del mapa con ondas de agua
  Widget _buildAcademicProgressNodes({
    required List<Map<String, dynamic>> categories,
  }) {
    final iconSize = 56.0;
    final spacing = iconSize * 0.5;
    final lineWidth = spacing * 0.6;
    final lineHeight = 6.0;

    return SizedBox(
      height: iconSize * 1.8,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: spacing),
        children: List.generate(categories.length, (index) {
          final category = categories[index];
          final isSelected = false;
          final isLast = index == categories.length - 1;
          final bool esActivo = (category['activo'] as bool?) ?? false;
          final waterLevel = esActivo ? 0.60 : 0.0;
          final bool nextActivo = !isLast
              ? ((categories[index + 1]['activo'] as bool?) ?? false)
              : false;
          final bool isStrongFlow = esActivo && nextActivo;
          final bool isMediumFlow = esActivo || nextActivo;

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryMapNode(
                category: category,
                isSelected: isSelected,
                iconSize: iconSize,
                waterLevel: waterLevel,
              ),
              if (!isLast)
                Padding(
                  padding: EdgeInsets.only(top: iconSize * 0.42),
                  child: _FlowingConnector(
                    lineWidth: lineWidth,
                    lineHeight: lineHeight,
                    accent: category['color'] as Color,
                    isStrongFlow: isStrongFlow,
                    isMediumFlow: isMediumFlow,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveUtils.cardSpacing(context),
      ),
      child: SizedBox(
        height: ResponsiveUtils.buttonHeight(context),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.horizontalPadding(context),
          ),
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: EdgeInsets.only(
                right: ResponsiveUtils.cardSpacing(context),
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context) * 0.8,
                    vertical: ResponsiveUtils.cardSpacing(context) * 0.67,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFC900) : Colors.white,
                    borderRadius: BorderRadius.circular(
                      ResponsiveUtils.buttonBorderRadius(context) * 2,
                    ),
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
                        size: ResponsiveUtils.smallIconSize(context),
                      ),
                      SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.67),
                      Text(
                        filter,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.bodyFontSize(context),
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgramsList() {
    final programs = _getFilteredPrograms();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(ResponsiveUtils.cardBorderRadius(context) * 1.5),
          topRight: Radius.circular(ResponsiveUtils.cardBorderRadius(context) * 1.5),
        ),
      ),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.horizontalPadding(context),
          vertical: ResponsiveUtils.verticalPadding(context),
        ),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: ResponsiveUtils.cardSpacing(context) * 1.5,
            ),
            child: DiplomadoCard(
              tipo: program['tipo'] as String,
              titulo: program['titulo'] as String,
              saldoPendiente: program['saldoPendiente'] as double?,
              progresoPago: program['progresoPago'] as double,
              estaCompletado: program['estaCompletado'] as bool,
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredPrograms() {
    final allPrograms = [
      {
        'tipo': 'DIPLOMADO',
        'titulo': 'Diseño, Desarrollo y Mantenimiento de Sistemas',
        'subtitulo': 'Tecnologías de la Información',
        'saldoPendiente': 1200.0,
        'progresoPago': 45.0,
        'estaCompletado': false,
        'modalidad': '100% Virtual',
        'duracion': '6 meses',
        'creditos': 20,
      },
      {
        'tipo': 'DIPLOMADO',
        'titulo': 'Educación Superior Basado en Competencias',
        'subtitulo': 'Aplicado a Ciencias del Desarrollo',
        'saldoPendiente': 200.0,
        'progresoPago': 75.0,
        'estaCompletado': false,
        'modalidad': 'Semipresencial',
        'duracion': '8 meses',
        'creditos': 25,
      },
      {
        'tipo': 'MAESTRÍA',
        'titulo': 'Maestría en Educación Superior',
        'subtitulo': 'Gestión y Evaluación Educativa',
        'saldoPendiente': null,
        'progresoPago': 100.0,
        'estaCompletado': true,
        'modalidad': 'Presencial',
        'duracion': '18 meses',
        'creditos': 60,
      },
    ];

    var filtered = allPrograms;
    if (_selectedFilter != 'Todos') {
      filtered = allPrograms
          .where((p) => p['tipo'] == _selectedFilter.toUpperCase())
          .toList();
    }

    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((program) {
        final titulo = (program['titulo'] ?? '').toString().toLowerCase();
        final subtitulo = (program['subtitulo'] ?? '').toString().toLowerCase();
        return titulo.contains(searchLower) || subtitulo.contains(searchLower);
      }).toList();
    }

    return filtered;
  }
}

// NODO DEL MAPA CON ONDAS DE AGUA
class _CategoryMapNode extends StatelessWidget {
  const _CategoryMapNode({
    required this.category,
    required this.isSelected,
    required this.iconSize,
    required this.waterLevel,
  });

  final Map<String, dynamic> category;
  final bool isSelected;
  final double iconSize;
  final double waterLevel;

  @override
  Widget build(BuildContext context) {
    final color = category['color'] as Color;
    final label = category['label'] as String;
    final icon = category['icon'] as IconData;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Círculo con icono y agua
        Stack(
          alignment: Alignment.center,
          children: [
            // Círculo de fondo
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
            // Onda de agua (solo si waterLevel > 0)
            if (waterLevel > 0)
              Positioned.fill(
                child: ClipOval(
                  child: LiquidCircularProgressIndicator(
                    value: waterLevel,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      color.withValues(alpha: 0.9),
                    ),
                    backgroundColor: Colors.transparent,
                    borderColor: Colors.transparent,
                    borderWidth: 0,
                    direction: Axis.vertical,
                  ),
                ),
              ),
            // Icono centrado
            Icon(
              icon,
              size: iconSize * 0.5,
              color: isSelected
                  ? color
                  : Colors.white.withValues(alpha: 0.9),
            ),
            // Borde seleccionado
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Etiqueta
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? color : Colors.grey.shade700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// CONECTOR ANIMADO ENTRE NODOS
class _FlowingConnector extends StatelessWidget {
  const _FlowingConnector({
    required this.lineWidth,
    required this.lineHeight,
    required this.accent,
    required this.isStrongFlow,
    required this.isMediumFlow,
  });

  final double lineWidth;
  final double lineHeight;
  final Color accent;
  final bool isStrongFlow;
  final bool isMediumFlow;

  @override
  Widget build(BuildContext context) {
    final h = lineHeight * 2.5;
    final waterColor = isStrongFlow
        ? accent.withValues(alpha: 0.96)
        : isMediumFlow
        ? accent.withValues(alpha: 0.78)
        : accent.withValues(alpha: 0.45);
    final bgColor = isStrongFlow
        ? accent.withValues(alpha: 0.22)
        : isMediumFlow
        ? accent.withValues(alpha: 0.12)
        : Colors.grey.shade200;

    return SizedBox(
      width: lineWidth,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: Stack(
          children: [
            Container(color: bgColor),
            LiquidLinearProgressIndicator(
              value: 1.0,
              valueColor: AlwaysStoppedAnimation<Color>(waterColor),
              backgroundColor: Colors.transparent,
              borderColor: Colors.transparent,
              borderWidth: 0,
              direction: Axis.horizontal,
              center: null,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 1,
                color: accent.withValues(alpha: 0.28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




