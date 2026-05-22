import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/widgets/ios_date_picker.dart';
import 'package:refactor_template/features/sistema/screens/contenedor/menu_lateral_scope.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/icono_notificaciones_widget.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';

class MiCurriculumScreen extends StatefulWidget {
  static const name = 'mi-curriculum';
  const MiCurriculumScreen({super.key});

  @override
  State<MiCurriculumScreen> createState() => _MiCurriculumScreenState();
}

class _MiCurriculumScreenState extends State<MiCurriculumScreen> {
  bool _isFormacionAcademicaExpanded = true;
  bool _isFormacionComplementariaExpanded = true;

  final List<Map<String, dynamic>> _formacionesAcademicas = [];
  final List<Map<String, dynamic>> _formacionesComplementarias = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1B2E) : const Color(0xFFF5F5F5);

    // Pantalla simple: sidebar y MenuBtn los provee el MainShell
    return Scaffold(
      backgroundColor: bgColor,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: _buildContent(context, width, height),
    );
  }

  Widget _buildContent(BuildContext context, double width, double height) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0D1B2E) : const Color(0xFFF5F5F5);
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        top: false,
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

  //AQUI SE PRODUCE EL BUILD HEADER
  Widget _buildHeader(BuildContext context, double width, double height) {
    return Container(
      padding: EdgeInsets.only(
        top: height * 0.02 + MediaQuery.of(context).padding.top,
        bottom: height * 0.03,
        left: width * 0.05,
        right: width * 0.05,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF005BAC), // Azul institucional
            Color(0xFF0F7BD7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005BAC).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra superior con iconos
          Row(
            children: [
              // Botón de menú lateral
              const BotonMenuLateral(),
              SizedBox(width: math.max(6, width * 0.015)),
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
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: math.max(4, width * 0.01)),
                    Icon(
                      Icons.school,
                      color: Colors.amber,
                      size: math.min(18, width * 0.045),
                    ),
                  ],
                ),
              ),
              SizedBox(width: math.max(6, width * 0.015)),
              // Notificaciones
              NotificationIconWidget(
                size: math.min(40, width * 0.1),
                iconSize: math.min(22, width * 0.055),
              ),
              SizedBox(width: math.max(6, width * 0.015)),
              // Configuración
              GestureDetector(
                onTap: () => context.push('/configuracion'),
                child: Container(
                  width: math.min(40, width * 0.1),
                  height: math.min(40, width * 0.1),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(102),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: math.min(22, width * 0.055),
                  ),
                ),
              ),
              SizedBox(width: math.max(6, width * 0.015)),
              // Avatar
              ProfileAvatarWidget(
                radius: math.min(18, width * 0.045),
                showShadow: true,
                onTap: () => context.push('/mis-datos-personales'),
              ),
            ],
          ),
          SizedBox(height: height * 0.025),
          // Título
          Row(
            children: [
              Icon(
                Icons.description_outlined,
                color: Colors.white,
                size: math.min(32, width * 0.08),
              ),
              SizedBox(width: math.max(12, width * 0.03)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mi Curriculum',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: math.min(26, width * 0.065),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: math.max(4, height * 0.005)),
                    Text(
                      'Gestiona tu formación académica y complementaria',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: math.min(13, width * 0.0325),
                        fontFamily: 'Intel',
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormacionAcademicaSection(double width) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
        color: Theme.of(context).cardColor,
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
              color: isEmpty ? Colors.white : const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEmpty
                    ? Colors.grey.shade300
                    : const Color(0xFF005BAC).withOpacity(0.3),
                width: isEmpty ? 1 : 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? '...' : value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isEmpty ? FontWeight.normal : FontWeight.bold,
                      color: isEmpty
                          ? Colors.grey.shade400
                          : const Color(0xFF003D73),
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: isEmpty
                        ? Colors.grey.shade400
                        : const Color(0xFF005BAC),
                  ),
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
                      final DateTime now = DateTime.now();
                      final DateTime? picked = await mostrarIosFechaPicker(
                        context: context,
                        initialDate: now,
                        titulo: 'Fecha de Emisión',
                        esFechaNacimiento: false,
                        minimumYear: 1950,
                        maximumYear: now.year,
                      );
                      if (picked != null) {
                        fechaController.text =
                            '${picked.day}/${picked.month}/${picked.year}';
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
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formación académica guardada'),
                    backgroundColor: Colors.green,
                  ),
                );
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
                      final DateTime now = DateTime.now();
                      final DateTime initial =
                          _parseDate(fechaController.text) ?? now;
                      final DateTime? picked = await mostrarIosFechaPicker(
                        context: context,
                        initialDate: initial,
                        titulo: 'Fecha de Emisión',
                        esFechaNacimiento: false,
                        minimumYear: 1950,
                        maximumYear: now.year,
                      );
                      if (picked != null) {
                        fechaController.text =
                            '${picked.day}/${picked.month}/${picked.year}';
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
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formación académica actualizada'),
                    backgroundColor: Colors.green,
                  ),
                );
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
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formación complementaria guardada'),
                    backgroundColor: Colors.green,
                  ),
                );
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
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Formación complementaria actualizada'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty || text == '...') return null;
    try {
      final parts = text.split('/');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (e) {
      return null;
    }
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
