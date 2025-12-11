import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/menu_btn.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/components/side_bar.dart';
import 'package:refactor_template/features/sistema/widgets/notification_icon_widget.dart';
import 'package:refactor_template/features/sistema/widgets/profile_avatar_widget.dart';
import 'package:rive/rive.dart' hide LinearGradient, Image;

class MiCurriculumScreen extends StatefulWidget {
  static const name = 'mi-curriculum';
  const MiCurriculumScreen({super.key});

  @override
  State<MiCurriculumScreen> createState() => _MiCurriculumScreenState();
}

class _MiCurriculumScreenState extends State<MiCurriculumScreen>
    with SingleTickerProviderStateMixin {
  bool _isFormacionAcademicaExpanded = true;
  bool _isFormacionComplementariaExpanded = true;
  bool isSideBarOpen = false;
  late SMIBool isMenuOpenInput;

  final List<Map<String, dynamic>> _formacionesAcademicas = [];
  final List<Map<String, dynamic>> _formacionesComplementarias = [];

  late AnimationController _animationController;
  late Animation<double> scalAnimation;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
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
    _animationController.dispose();
    super.dispose();
  }

  /// Carga los datos guardados del curriculum
  Future<void> _loadSavedData() async {
    final savedData = await LocalStorageService.getCurriculumData();
    if (savedData != null && mounted) {
      setState(() {
        if (savedData['formacionesAcademicas'] != null) {
          _formacionesAcademicas.clear();
          _formacionesAcademicas.addAll(
            List<Map<String, dynamic>>.from(savedData['formacionesAcademicas']),
          );
        }
        if (savedData['formacionesComplementarias'] != null) {
          _formacionesComplementarias.clear();
          _formacionesComplementarias.addAll(
            List<Map<String, dynamic>>.from(
              savedData['formacionesComplementarias'],
            ),
          );
        }
      });
    }
  }

  /// Guarda los datos del curriculum
  Future<void> _saveCurriculumData() async {
    final curriculumData = {
      'formacionesAcademicas': _formacionesAcademicas,
      'formacionesComplementarias': _formacionesComplementarias,
    };
    await LocalStorageService.saveCurriculumData(curriculumData);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
                1 * animation.value - 30 * (animation.value) * math.pi / 180,
              ),
            child: Transform.translate(
              offset: Offset(animation.value * 265, 0),
              child: Transform.scale(
                scale: scalAnimation.value,
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(24)),
                  child: _buildContent(context, width, height),
                ),
              ),
            ),
          ),
          // Botón de menú fuera del contenido transformado
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

  Widget _buildContent(BuildContext context, double width, double height) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header azul
            _buildHeader(context, width, height),
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.02),
                    // Sección Formación Académica
                    _buildFormacionAcademicaSection(width),
                    SizedBox(height: height * 0.02),
                    // Sección Formación Complementaria
                    _buildFormacionComplementariaSection(width),
                    SizedBox(height: height * 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double width, double height) {
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
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF2C5F8D).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Barra superior con navegación
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.015,
            ),
            child: Row(
              children: [
                // Espacio para el botón de menú (que está fuera del Stack)
                SizedBox(width: isSideBarOpen ? 220 : 52),
                const SizedBox(width: 6),
                // Logo Posgrado
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          'Posgrado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: math.min(18, width * 0.045),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.school, color: Colors.amber, size: 16),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Banco Union - Flexible y más compacto
                Flexible(
                  flex: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BANCO UNION',
                          style: TextStyle(
                            fontSize: math.max(7, math.min(8, width * 0.02)),
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A3A5C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Número de cuenta único',
                        style: TextStyle(
                          fontSize: math.max(5, math.min(6, width * 0.015)),
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Notificaciones
                const NotificationIconWidget(size: 36, iconSize: 20),
                const SizedBox(width: 4),
                // Configuración
                GestureDetector(
                  onTap: () {
                    context.push('/configuracion');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Avatar
                ProfileAvatarWidget(
                  radius: 14,
                  showShadow: false,
                  onTap: () {
                    context.push('/mis-datos-personales');
                  },
                ),
              ],
            ),
          ),
          // Título e instrucciones
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.05,
              vertical: height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mi Curriculum',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: height * 0.015),
                const Text(
                  'Ingrese únicamente la información que corresponda a su perfil. Los campos como idiomas, cursos o habilidades técnicas no son obligatorios si no aplican.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Personaje animado
          SizedBox(
            height: height * 0.12,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Onda azul
                CustomPaint(
                  size: Size(width, height * 0.12),
                  painter: _WavePainter(),
                ),
                // Personaje
                Positioned(
                  bottom: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Lápiz
                      Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC900),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Personaje con birrete
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF87CEEB),
                          shape: BoxShape.circle,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Cuerpo
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4A90E2),
                                shape: BoxShape.circle,
                              ),
                            ),
                            // Birrete
                            Positioned(
                              top: 5,
                              child: Container(
                                width: 50,
                                height: 15,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Ojos
                            Positioned(
                              top: 20,
                              left: 15,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 20,
                              right: 15,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Libro
                      Container(
                        width: 40,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Color(0xFF1A3A5C),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormacionAcademicaSection(double width) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de sección
          InkWell(
            onTap: () {
              setState(() {
                _isFormacionAcademicaExpanded = !_isFormacionAcademicaExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Formacion Academica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _isFormacionAcademicaExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          // Contenido expandible
          if (_isFormacionAcademicaExpanded) ...[
            // Tarjetas de formación académica existentes
            ...List.generate(
              _formacionesAcademicas.length,
              (index) => _buildFormacionAcademicaCard(
                width,
                _formacionesAcademicas[index],
                index,
              ),
            ),
            // Botón añadir
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _showAddFormacionAcademicaDialog(context, width);
                },
                icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
                label: const Text(
                  '+ Añadir Formación Academica',
                  style: TextStyle(color: Color(0xFF4A90E2)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4A90E2)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormacionAcademicaCard(
    double width,
    Map<String, dynamic> formacion,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de tarjeta
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formacion Academica : ${formacion['nivelAcademico'] ?? 'Nivel Academico'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formacion['descripcionTitulo'] ??
                          'Descripcion del Titulo...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Botones de acción
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () async {
                      setState(() {
                        _formacionesAcademicas.removeAt(index);
                      });
                      await _saveCurriculumData();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () {
                      _showEditFormacionAcademicaDialog(
                        context,
                        width,
                        formacion,
                        index,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Campos
          _buildTextField(
            'Nivel Academico',
            formacion['nivelAcademico'] ?? '...',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Descripcion del Titulo',
            formacion['descripcionTitulo'] ?? '...',
          ),
          const SizedBox(height: 12),
          _buildTextField('Institucion', formacion['institucion'] ?? '...'),
          const SizedBox(height: 12),
          _buildTextField(
            'Numero de Codigo',
            formacion['numeroCodigo'] ?? '...',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Fecha de Emision *',
            formacion['fechaEmision'] ?? '...',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  setState(() {
                    _formacionesAcademicas.removeAt(index);
                  });
                  await _saveCurriculumData();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Marcar como completado
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Completado'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormacionComplementariaSection(double width) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de sección
          InkWell(
            onTap: () {
              setState(() {
                _isFormacionComplementariaExpanded =
                    !_isFormacionComplementariaExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: const Text(
                      'Formacion Complementaria Cursos, Talleres, Otros',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    _isFormacionComplementariaExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          // Contenido expandible
          if (_isFormacionComplementariaExpanded) ...[
            // Tarjetas de formación complementaria existentes
            ...List.generate(
              _formacionesComplementarias.length,
              (index) => _buildFormacionComplementariaCard(
                width,
                _formacionesComplementarias[index],
                index,
              ),
            ),
            // Botón añadir
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () {
                  _showAddFormacionComplementariaDialog(context, width);
                },
                icon: const Icon(Icons.add, color: Color(0xFF4A90E2)),
                label: const Text(
                  '+ Añadir Formación Complementaria',
                  style: TextStyle(color: Color(0xFF4A90E2)),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4A90E2)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormacionComplementariaCard(
    double width,
    Map<String, dynamic> formacion,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de tarjeta
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formacion Complementario Curso, Talleres, Otros :',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formacion['tipo'] ?? 'Tipo...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Botones de acción
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () async {
                      setState(() {
                        _formacionesComplementarias.removeAt(index);
                      });
                      await _saveCurriculumData();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                    onPressed: () {
                      _showEditFormacionComplementariaDialog(
                        context,
                        width,
                        formacion,
                        index,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Campos
          _buildTextField(
            'Tipo',
            formacion['tipo'] ?? '',
            onTap: () {
              _showEditFormacionComplementariaDialog(
                context,
                width,
                formacion,
                index,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Detalle',
            formacion['detalle'] ?? '',
            onTap: () {
              _showEditFormacionComplementariaDialog(
                context,
                width,
                formacion,
                index,
              );
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Horas Academicas',
            formacion['horasAcademicas'] ?? '',
            onTap: () {
              _showEditFormacionComplementariaDialog(
                context,
                width,
                formacion,
                index,
              );
            },
          ),
          const SizedBox(height: 16),
          // Botones de acción
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  setState(() {
                    _formacionesComplementarias.removeAt(index);
                  });
                  await _saveCurriculumData();
                },
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Marcar como completado
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9800),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Completado'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value, {
    bool isRequired = false,
    VoidCallback? onTap,
  }) {
    final isEmpty = value.isEmpty || value == '...';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? '...' : value,
                    style: TextStyle(
                      fontSize: 14,
                      color: isEmpty ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.edit, size: 16, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showAddFormacionAcademicaDialog(BuildContext context, double width) {
    final formKey = GlobalKey<FormState>();
    final nivelController = TextEditingController();
    final descripcionController = TextEditingController();
    final institucionController = TextEditingController();
    final codigoController = TextEditingController();
    final fechaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Formación Académica'),
        content: SizedBox(
          width: width * 0.8,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nivelController,
                    decoration: const InputDecoration(
                      labelText: 'Nivel Académico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: institucionController,
                    decoration: const InputDecoration(
                      labelText: 'Institución',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Código',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fechaController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Emisión *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        fechaController.text =
                            '${date.day}/${date.month}/${date.year}';
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _formacionesAcademicas.add({
                    'nivelAcademico': nivelController.text,
                    'descripcionTitulo': descripcionController.text,
                    'institucion': institucionController.text,
                    'numeroCodigo': codigoController.text,
                    'fechaEmision': fechaController.text,
                  });
                });
                await _saveCurriculumData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formación académica guardada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditFormacionAcademicaDialog(
    BuildContext context,
    double width,
    Map<String, dynamic> formacion,
    int index,
  ) {
    final formKey = GlobalKey<FormState>();
    final nivelController = TextEditingController(
      text: formacion['nivelAcademico'] ?? '',
    );
    final descripcionController = TextEditingController(
      text: formacion['descripcionTitulo'] ?? '',
    );
    final institucionController = TextEditingController(
      text: formacion['institucion'] ?? '',
    );
    final codigoController = TextEditingController(
      text: formacion['numeroCodigo'] ?? '',
    );
    final fechaController = TextEditingController(
      text: formacion['fechaEmision'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Formación Académica'),
        content: SizedBox(
          width: width * 0.8,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nivelController,
                    decoration: const InputDecoration(
                      labelText: 'Nivel Académico',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción del Título',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: institucionController,
                    decoration: const InputDecoration(
                      labelText: 'Institución',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: codigoController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Código',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fechaController,
                    decoration: const InputDecoration(
                      labelText: 'Fecha de Emisión *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1950),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        fechaController.text =
                            '${date.day}/${date.month}/${date.year}';
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _formacionesAcademicas[index] = {
                    'nivelAcademico': nivelController.text,
                    'descripcionTitulo': descripcionController.text,
                    'institucion': institucionController.text,
                    'numeroCodigo': codigoController.text,
                    'fechaEmision': fechaController.text,
                  };
                });
                await _saveCurriculumData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formación académica actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showAddFormacionComplementariaDialog(
    BuildContext context,
    double width,
  ) {
    final formKey = GlobalKey<FormState>();
    final tipoController = TextEditingController();
    final detalleController = TextEditingController();
    final horasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Formación Complementaria'),
        content: SizedBox(
          width: width * 0.8,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tipoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detalleController,
                    decoration: const InputDecoration(
                      labelText: 'Detalle',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: horasController,
                    decoration: const InputDecoration(
                      labelText: 'Horas Académicas',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _formacionesComplementarias.add({
                    'tipo': tipoController.text,
                    'detalle': detalleController.text,
                    'horasAcademicas': horasController.text,
                  });
                });
                await _saveCurriculumData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formación complementaria guardada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditFormacionComplementariaDialog(
    BuildContext context,
    double width,
    Map<String, dynamic> formacion,
    int index,
  ) {
    final formKey = GlobalKey<FormState>();
    final tipoController = TextEditingController(text: formacion['tipo'] ?? '');
    final detalleController = TextEditingController(
      text: formacion['detalle'] ?? '',
    );
    final horasController = TextEditingController(
      text: formacion['horasAcademicas'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Formación Complementaria'),
        content: SizedBox(
          width: width * 0.8,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: tipoController,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: detalleController,
                    decoration: const InputDecoration(
                      labelText: 'Detalle',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: horasController,
                    decoration: const InputDecoration(
                      labelText: 'Horas Académicas',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                setState(() {
                  _formacionesComplementarias[index] = {
                    'tipo': tipoController.text,
                    'detalle': detalleController.text,
                    'horasAcademicas': horasController.text,
                  };
                });
                await _saveCurriculumData();
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formación complementaria actualizada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter para dibujar la onda azul en el header
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C5F8D)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.5,
        size.width * 0.5,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
