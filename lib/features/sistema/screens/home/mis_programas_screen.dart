import 'package:flutter/material.dart';

/// Pantalla de "Mis Programas" con filtros y lista de programas.
class MisProgramasScreen extends StatefulWidget {
  const MisProgramasScreen({super.key});

  @override
  State<MisProgramasScreen> createState() => _MisProgramasScreenState();
}

class _MisProgramasScreenState extends State<MisProgramasScreen> {
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
            // Header con título y subtítulo
            _buildHeader(),
            // Barra de búsqueda
            _buildSearchBar(),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Programas',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Todos los programas que está cursando o cursó.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscador...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const Icon(Icons.search, color: Colors.grey),
        ],
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
    // Datos de ejemplo - aquí puedes conectar con tu backend
    final programs = _getFilteredPrograms();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: programs.length,
      itemBuilder: (context, index) {
        final program = programs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _ProgramCard(
            tipo: program['tipo'] as String,
            titulo: program['titulo'] as String,
            saldoPendiente: program['saldoPendiente'] as double?,
            progresoPago: program['progresoPago'] as double,
            estaCompletado: program['estaCompletado'] as bool,
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredPrograms() {
    final allPrograms = [
      {
        'tipo': 'DIPLOMADO',
        'titulo': 'DISEÑO, DESARROLLO Y MANTENIMIENTO',
        'saldoPendiente': 1200.0,
        'progresoPago': 45.0,
        'estaCompletado': false,
      },
      {
        'tipo': 'DIPLOMADO',
        'titulo':
            'EDUCACIÓN SUPERIOR BASADO EN COMPETENCIAS APLICADO A CIENCIAS DEL DESARROLLO',
        'saldoPendiente': 200.0,
        'progresoPago': 75.0,
        'estaCompletado': false,
      },
      {
        'tipo': 'MAESTRÍA',
        'titulo': 'EDUCACIÓN SUPERIOR',
        'saldoPendiente': null,
        'progresoPago': 100.0,
        'estaCompletado': true,
      },
    ];

    if (_selectedFilter == 'Todos') {
      return allPrograms;
    }

    return allPrograms
        .where((p) => p['tipo'] == _selectedFilter.toUpperCase())
        .toList();
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.tipo,
    required this.titulo,
    this.saldoPendiente,
    required this.progresoPago,
    required this.estaCompletado,
  });

  final String tipo;
  final String titulo;
  final double? saldoPendiente;
  final double progresoPago;
  final bool estaCompletado;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          // Badge de tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tipo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Título
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Estado o saldo pendiente
          if (estaCompletado)
            Row(
              children: [
                const Text(
                  'Completado: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...List.generate(5, (index) {
                  return const Icon(Icons.star, color: Colors.green, size: 18);
                }),
              ],
            )
          else if (saldoPendiente != null)
            Text(
              'Saldo Pendiente: ${saldoPendiente!.toInt()} Bs.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
          // Progreso del pago con mascota
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
                    estaCompletado ? '🎓' : '🎓',
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
              onPressed: () {
                // TODO: Navegar a detalle del programa
              },
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
    );
  }
}
