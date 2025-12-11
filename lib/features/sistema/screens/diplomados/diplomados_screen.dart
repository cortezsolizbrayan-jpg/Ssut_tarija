import 'dart:math';

import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/menu_btn.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/side_bar.dart';
import 'package:rive/rive.dart';

import 'components/app_header.dart';
import 'components/diplomado_card.dart';

class DiplomadosScreen extends StatefulWidget {
  const DiplomadosScreen({super.key});

  @override
  State<DiplomadosScreen> createState() => _DiplomadosScreenState();
}

class _DiplomadosScreenState extends State<DiplomadosScreen>
    with SingleTickerProviderStateMixin {
  String _selectedFilter = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  bool isSideBarOpen = false;
  late SMIBool isMenuOpenInput;

  final List<String> _filters = [
    'Todos',
    'Maestría',
    'Especialidad',
    'Diplomado',
    'Doctorado',
    'Posdoctorado',
  ];

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
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
          // El menú ahora está en la fila principal del header
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header azul oscuro
          AppHeader(
            searchController: _searchController,
            onSearchChanged: (value) {
              setState(() {});
            },
            menuButton: MenuBtn(
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
          // Filtros horizontales (debajo del header)
          _buildFilters(),
          // Lista de programas
          Expanded(child: _buildProgramsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 50,
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
                        color: isSelected
                            ? Colors.black87
                            : Colors.grey.shade600,
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
      ),
    );
  }

  Widget _buildProgramsList() {
    final programs = _getFilteredPrograms();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
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

    // Filtrar por tipo seleccionado
    var filtered = allPrograms;
    if (_selectedFilter != 'Todos') {
      filtered = allPrograms
          .where((p) => p['tipo'] == _selectedFilter.toUpperCase())
          .toList();
    }

    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchLower = _searchController.text.toLowerCase();
      filtered = filtered.where((program) {
        final titulo = (program['titulo'] ?? '').toString().toLowerCase();
        return titulo.contains(searchLower);
      }).toList();
    }

    return filtered;
  }
}
