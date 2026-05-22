import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/constants.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/widgets/ios_date_picker.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';
import 'package:file_picker/file_picker.dart';

class MiCurriculumPantalla extends StatefulWidget {
  static const name = 'mi-curriculum';
  const MiCurriculumPantalla({super.key});

  @override
  State<MiCurriculumPantalla> createState() => _MiCurriculumPantallaState();
}

class _MiCurriculumPantallaState extends State<MiCurriculumPantalla> {
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

  /// Permite al usuario subir un PDF de su CV y simula/ejecuta el autocompletado
  Future<void> _pickAndProcessCV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Procesando CV de forma inteligente...'),
                    Text(
                      'Extrayendo formación académica...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return;
        Navigator.pop(context); // Cerrar loader

        final mockDataAcademica = {
          'nivelAcademico': 'LICENCIATURA',
          'descripcionTitulo': 'LICENCIADO EN INFORMÁTICA',
          'institucion': 'UNIVERSIDAD PÚBLICA DE EL ALTO',
          'numeroCodigo': 'UPEA-2023-456',
          'fechaEmision': '15/12/2023',
        };

        final docs =
            await LocalStorageService.getParticipantDocumentsData() ?? {};
        docs['hoja_vida_path'] = result.files.single.path;
        docs['hoja_vida_filename'] = result.files.single.name;
        await LocalStorageService.saveParticipantDocumentsData(docs);

        setState(() {
          bool existe = _formacionesAcademicas.any(
            (f) =>
                f['descripcionTitulo'] ==
                mockDataAcademica['descripcionTitulo'],
          );

          if (!existe) {
            _formacionesAcademicas.add(mockDataAcademica);
          }
        });

        await _saveCurriculumData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'CV procesado. Se ha detectado nueva formación académica.',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al procesar CV: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al procesar el archivo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparente para ver el degrade
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            // Header azul con degradado institucional (ahora sin SafeArea arriba para el degrade)
            _buildHeader(context, width, height),
            // Contenido scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.02),
                    // Nueva sección de Carga Inteligente
                    _buildIntelligentUploadCard(width),
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
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + (height * 0.01),
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
              // Botón de Atrás
              Material(
                color: Colors.white.withOpacity(0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/sistema/pantalla_principal');
                    }
                  },
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
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

  Widget _buildIntelligentUploadCard(double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.blue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_fix_high_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Carga Inteligente de CV',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sube tu CV en PDF/Word y autocompletaremos los datos por ti.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _pickAndProcessCV,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue.shade800,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SUBIR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
          _buildTextField('Tipo', formacion['tipo'] ?? '...'),
          const SizedBox(height: 12),
          _buildTextField('Institucion', formacion['institucion'] ?? '...'),
          const SizedBox(height: 12),
          _buildTextField(
            'Descripcion del Titulo',
            formacion['descripcionTitulo'] ?? '...',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Numero de Horas Academicas',
            formacion['horasAcademicas'] ?? '...',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            'Fecha de Emision *',
            formacion['fechaEmision'] ?? '...',
            isRequired: true,
          ),
          const SizedBox(height: 16),
          // Boton de completar
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isRequired ? FontWeight.bold : FontWeight.normal,
            color: const Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  // --- Diálogos de edición ---

  void _showAddFormacionAcademicaDialog(BuildContext context, double width) {
    String nivel = 'LICENCIATURA';
    final tituloCtrl = TextEditingController();
    final institucionCtrl = TextEditingController();
    final codigoCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir Formación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: nivel,
                  isExpanded: true,
                  items:
                      [
                            'TECNICO MEDIO',
                            'TECNICO SUPERIOR',
                            'LICENCIATURA',
                            'POSTGRADO',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setDialogState(() => nivel = v!),
                ),
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción Título',
                  ),
                ),
                TextField(
                  controller: institucionCtrl,
                  decoration: const InputDecoration(labelText: 'Institución'),
                ),
                TextField(
                  controller: codigoCtrl,
                  decoration: const InputDecoration(labelText: 'Número Código'),
                ),
                TextField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Emisión *',
                  ),
                  onTap: () async {
                    final date = await mostrarIosFechaPicker(context: context);
                    if (date != null) {
                      setDialogState(
                        () => fechaCtrl.text =
                            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fechaCtrl.text.isEmpty) return;
                setState(() {
                  _formacionesAcademicas.add({
                    'nivelAcademico': nivel,
                    'descripcionTitulo': tituloCtrl.text,
                    'institucion': institucionCtrl.text,
                    'numeroCodigo': codigoCtrl.text,
                    'fechaEmision': fechaCtrl.text,
                  });
                });
                await _saveCurriculumData();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFormacionAcademicaDialog(
    BuildContext context,
    double width,
    Map<String, dynamic> f,
    int index,
  ) {
    String nivel = f['nivelAcademico'] ?? 'LICENCIATURA';
    final tituloCtrl = TextEditingController(text: f['descripcionTitulo']);
    final institucionCtrl = TextEditingController(text: f['institucion']);
    final codigoCtrl = TextEditingController(text: f['numeroCodigo']);
    final fechaCtrl = TextEditingController(text: f['fechaEmision']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Formación'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: nivel,
                  isExpanded: true,
                  items:
                      [
                            'TECNICO MEDIO',
                            'TECNICO SUPERIOR',
                            'LICENCIATURA',
                            'POSTGRADO',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setDialogState(() => nivel = v!),
                ),
                TextField(
                  controller: tituloCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción Título',
                  ),
                ),
                TextField(
                  controller: institucionCtrl,
                  decoration: const InputDecoration(labelText: 'Institución'),
                ),
                TextField(
                  controller: codigoCtrl,
                  decoration: const InputDecoration(labelText: 'Número Código'),
                ),
                TextField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Emisión *',
                  ),
                  onTap: () async {
                    final date = await mostrarIosFechaPicker(context: context);
                    if (date != null) {
                      setDialogState(
                        () => fechaCtrl.text =
                            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _formacionesAcademicas[index] = {
                    'nivelAcademico': nivel,
                    'descripcionTitulo': tituloCtrl.text,
                    'institucion': institucionCtrl.text,
                    'numeroCodigo': codigoCtrl.text,
                    'fechaEmision': fechaCtrl.text,
                  };
                });
                await _saveCurriculumData();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddFormacionComplementariaDialog(
    BuildContext context,
    double width,
  ) {
    String tipo = 'CURSO';
    final instCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final horasCtrl = TextEditingController();
    final fechaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Añadir Complementaria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: tipo,
                  isExpanded: true,
                  items: ['CURSO', 'TALLER', 'SEMINARIO', 'CONGRESO', 'OTROS']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tipo = v!),
                ),
                TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(labelText: 'Institución'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: horasCtrl,
                  decoration: const InputDecoration(labelText: 'Horas Acad.'),
                ),
                TextField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Emisión *',
                  ),
                  onTap: () async {
                    final date = await mostrarIosFechaPicker(context: context);
                    if (date != null) {
                      setDialogState(
                        () => fechaCtrl.text =
                            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (fechaCtrl.text.isEmpty) return;
                setState(() {
                  _formacionesComplementarias.add({
                    'tipo': tipo,
                    'institucion': instCtrl.text,
                    'descripcionTitulo': descCtrl.text,
                    'horasAcademicas': horasCtrl.text,
                    'fechaEmision': fechaCtrl.text,
                  });
                });
                await _saveCurriculumData();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditFormacionComplementariaDialog(
    BuildContext context,
    double width,
    Map<String, dynamic> f,
    int index,
  ) {
    String tipo = f['tipo'] ?? 'CURSO';
    final instCtrl = TextEditingController(text: f['institucion']);
    final descCtrl = TextEditingController(text: f['descripcionTitulo']);
    final horasCtrl = TextEditingController(text: f['horasAcademicas']);
    final fechaCtrl = TextEditingController(text: f['fechaEmision']);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Complementaria'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: tipo,
                  isExpanded: true,
                  items: ['CURSO', 'TALLER', 'SEMINARIO', 'CONGRESO', 'OTROS']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tipo = v!),
                ),
                TextField(
                  controller: instCtrl,
                  decoration: const InputDecoration(labelText: 'Institución'),
                ),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                TextField(
                  controller: horasCtrl,
                  decoration: const InputDecoration(labelText: 'Horas Acad.'),
                ),
                TextField(
                  controller: fechaCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Fecha Emisión *',
                  ),
                  onTap: () async {
                    final date = await mostrarIosFechaPicker(context: context);
                    if (date != null) {
                      setDialogState(
                        () => fechaCtrl.text =
                            "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}",
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _formacionesComplementarias[index] = {
                    'tipo': tipo,
                    'institucion': instCtrl.text,
                    'descripcionTitulo': descCtrl.text,
                    'horasAcademicas': horasCtrl.text,
                    'fechaEmision': fechaCtrl.text,
                  };
                });
                await _saveCurriculumData();
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text('Actualizar'),
            ),
          ],
        ),
      ),
    );
  }
}



