import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refactor_template/features/sistema/presentation/providers/programa_posgrado_provider.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/detalle_programa_screen.dart';

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
      'color': const Color(0xFF87CEEB),
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Programas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Todos los programas que está cursando o cursó.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscador...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                ),
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
                child: Icon(Icons.clear, color: Colors.grey.shade600, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcons() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_categories.length, (index) {
            final category = _categories[index];
            final isSelected = _selectedCategory == index;
            final isLast = index == _categories.length - 1;

            return Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category['color'] as Color
                          : (category['color'] as Color).withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? category['color'] as Color
                            : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (category['color'] as Color).withOpacity(
                                  0.4,
                                ),
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
                      size: 28,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 40,
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFC900) : Colors.white,
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
                      color: isSelected ? Colors.black87 : Colors.grey.shade600,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filter,
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
          );
        },
      ),
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
            // Lista de programas
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                itemCount: filteredPrograms.length,
                itemBuilder: (context, index) {
                  final programa = filteredPrograms[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _ProgramCard(
                      programa: programa,
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
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
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

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({required this.programa, required this.onTap});

  final dynamic programa;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final estaCompletado =
        programa.estado.contains('INICIARON') ||
        programa.estado.contains('COMPLETADO');
    final progresoPago = estaCompletado ? 100.0 : 65.0; // Simulado

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de tipo y estado
            Row(
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
                    programa.tipo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (programa.descuento != null)
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
                      '${programa.descuento!.toInt()}% desc.',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Título
            Text(
              programa.titulo,
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
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  programa.duracion,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 16),
                Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  programa.modalidad,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: estaCompletado
                    ? Colors.green.shade50
                    : programa.estado.contains('ABIERTAS')
                    ? Colors.blue.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                programa.estado,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: estaCompletado
                      ? Colors.green.shade700
                      : programa.estado.contains('ABIERTAS')
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
                    color: const Color(0xFF87CEEB).withOpacity(0.3),
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
                onPressed: onTap,
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
    );
  }
}
