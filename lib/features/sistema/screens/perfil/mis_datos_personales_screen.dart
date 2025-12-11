import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';

class MisDatosPersonalesScreen extends StatefulWidget {
  static const name = 'mis-datos-personales';
  const MisDatosPersonalesScreen({super.key});

  @override
  State<MisDatosPersonalesScreen> createState() =>
      _MisDatosPersonalesScreenState();
}

class _MisDatosPersonalesScreenState extends State<MisDatosPersonalesScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  // Controladores de texto
  final TextEditingController _nombreController = TextEditingController(
    text: 'MARIA RENEE',
  );
  final TextEditingController _apPaternoController = TextEditingController(
    text: 'RODRIGUEZ',
  );
  final TextEditingController _apMaternoController = TextEditingController(
    text: 'GONZALES',
  );
  final TextEditingController _fechaNacimientoController =
      TextEditingController(text: '05/04/2003');
  final TextEditingController _numeroCIController = TextEditingController(
    text: '13693582',
  );
  final TextEditingController _complementoController = TextEditingController(
    text: '1K',
  );
  final TextEditingController _expedidoEnController = TextEditingController(
    text: 'LP',
  );
  final TextEditingController _nacionalidadController = TextEditingController(
    text: 'Boliviana',
  );
  final TextEditingController _ciudadNacimientoController =
      TextEditingController(text: 'El Alto');
  final TextEditingController _generoController = TextEditingController(
    text: 'FEMENINO',
  );
  final TextEditingController _ciudadResidenciaController =
      TextEditingController(text: 'SANTA CRUZ');
  final TextEditingController _direccionController = TextEditingController(
    text: 'C. SANCHEZ LIMA, Z. SOPOCACHI',
  );
  final TextEditingController _nroCasaController = TextEditingController();
  final TextEditingController _estadoCivilController = TextEditingController();

  String? _selectedGenero;
  String? _selectedCiudadResidencia;
  String? _selectedEstadoCivil;

  @override
  void initState() {
    super.initState();
    _selectedGenero = 'FEMENINO';
    _selectedCiudadResidencia = 'SANTA CRUZ';
    _loadSavedData();
  }

  /// Carga los datos guardados previamente
  Future<void> _loadSavedData() async {
    // Cargar datos personales
    final savedData = await LocalStorageService.getPersonalData();
    if (savedData != null) {
      setState(() {
        _nombreController.text = savedData['nombre'] ?? '';
        _apPaternoController.text = savedData['apPaterno'] ?? '';
        _apMaternoController.text = savedData['apMaterno'] ?? '';
        _fechaNacimientoController.text = savedData['fechaNacimiento'] ?? '';
        _numeroCIController.text = savedData['numeroCI'] ?? '';
        _complementoController.text = savedData['complemento'] ?? '';
        _expedidoEnController.text = savedData['expedidoEn'] ?? '';
        _nacionalidadController.text = savedData['nacionalidad'] ?? '';
        _ciudadNacimientoController.text = savedData['ciudadNacimiento'] ?? '';
        _ciudadResidenciaController.text = savedData['ciudadResidencia'] ?? '';
        _direccionController.text = savedData['direccion'] ?? '';
        _nroCasaController.text = savedData['nroCasa'] ?? '';
        _selectedGenero = savedData['genero'];
        _selectedCiudadResidencia = savedData['ciudadResidencia'];
        _selectedEstadoCivil = savedData['estadoCivil'];
      });
    }

    // Cargar foto de perfil
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (imageFile != null && mounted) {
      setState(() {
        _profileImage = imageFile;
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apPaternoController.dispose();
    _apMaternoController.dispose();
    _fechaNacimientoController.dispose();
    _numeroCIController.dispose();
    _complementoController.dispose();
    _expedidoEnController.dispose();
    _nacionalidadController.dispose();
    _ciudadNacimientoController.dispose();
    _generoController.dispose();
    _ciudadResidenciaController.dispose();
    _direccionController.dispose();
    _nroCasaController.dispose();
    _estadoCivilController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        final fileSize = await File(image.path).length();
        const maxSize = 3.1 * 1024 * 1024; // 3.1 MB
        if (fileSize > maxSize) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('El archivo excede el tamaño máximo de 3.1MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
        // Guardar la imagen en almacenamiento permanente
        final savedPath = await LocalStorageService.saveProfileImage(
          File(image.path),
        );
        if (savedPath != null && mounted) {
          setState(() {
            _profileImage = File(savedPath);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            const Text(
              'Posgrado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.school, color: Colors.amber, size: 18),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BANCO UNION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A3A5C),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.02),
              // Título
              const Text(
                'Mis Datos Personales',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A3A5C),
                ),
              ),
              SizedBox(height: height * 0.015),
              // Instrucciones
              const Text(
                'Complete sus Datos Personales de forma correcta. Esta información será utilizada para generar distintos documentos que usted pueda necesitar.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
              SizedBox(height: height * 0.03),
              // Sección de foto de perfil
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: width * 0.35,
                            height: width * 0.35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1A3A5C),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _profileImage != null
                                ? ClipOval(
                                    child: Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFC900),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.015),
                    const Text(
                      'Permitido *.jpeg, *.jpg, *.png, *.gif',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const Text(
                      'Tamaño máximo de 3.1MB',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    SizedBox(height: height * 0.01),
                    const Text(
                      'Foto de Perfil',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: height * 0.03),
              // Campos del formulario
              _buildFormField(
                label: 'Nombre(s)',
                controller: _nombreController,
                isRequired: true,
                width: width,
              ),
              SizedBox(height: height * 0.02),
              // Row responsive para Apellidos
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final spacing = math
                      .max(8.0, availableWidth * 0.025)
                      .toDouble();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Ap. Paterno',
                          controller: _apPaternoController,
                          isRequired: true,
                          width: width,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: _buildFormField(
                          label: 'Ap. Materno',
                          controller: _apMaternoController,
                          isRequired: false,
                          width: width,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: height * 0.02),
              _buildFormField(
                label: 'Fecha de Nacimiento',
                controller: _fechaNacimientoController,
                isRequired: true,
                width: width,
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2003, 4, 5),
                    firstDate: DateTime(1950),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaNacimientoController.text =
                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    });
                  }
                },
              ),
              SizedBox(height: height * 0.02),
              // Row responsive para CI, Complemento y Expedido en
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  // Espaciado más pequeño para pantallas pequeñas
                  final spacing = math
                      .max(4.0, math.min(8.0, availableWidth * 0.015))
                      .toDouble();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3, // Más espacio para CI
                        child: _buildFormField(
                          label: 'Número de CI',
                          controller: _numeroCIController,
                          isRequired: false,
                          width: width,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        flex: 2, // Espacio medio para Complemento
                        child: _buildFormField(
                          label: 'Complemento',
                          controller: _complementoController,
                          isRequired: true,
                          width: width,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        flex: 2, // Espacio medio para Expedido en
                        child: _buildFormField(
                          label: 'Expedido en',
                          controller: _expedidoEnController,
                          isRequired: false,
                          width: width,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: height * 0.02),
              // Row responsive para Nacionalidad y Ciudad de Nacimiento
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final spacing = math
                      .max(8.0, availableWidth * 0.025)
                      .toDouble();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildFormField(
                          label: 'Nacionalidad',
                          controller: _nacionalidadController,
                          isRequired: true,
                          width: width,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        child: _buildFormField(
                          label: 'Ciudad de Nacimiento',
                          controller: _ciudadNacimientoController,
                          isRequired: false,
                          width: width,
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: height * 0.02),
              _buildDropdownField(
                label: 'Género',
                value: _selectedGenero,
                items: const ['MASCULINO', 'FEMENINO', 'OTRO'],
                isRequired: true,
                width: width,
                onChanged: (value) {
                  setState(() {
                    _selectedGenero = value;
                  });
                },
              ),
              SizedBox(height: height * 0.02),
              _buildDropdownField(
                label: 'Ciudad de Residencia',
                value: _selectedCiudadResidencia,
                items: const [
                  'LA PAZ',
                  'SANTA CRUZ',
                  'COCHABAMBA',
                  'ORURO',
                  'POTOSÍ',
                  'SUCRE',
                  'TARIJA',
                  'BENI',
                  'PANDO',
                ],
                isRequired: false,
                width: width,
                onChanged: (value) {
                  setState(() {
                    _selectedCiudadResidencia = value;
                  });
                },
              ),
              SizedBox(height: height * 0.02),
              _buildFormField(
                label: 'Dirección',
                controller: _direccionController,
                isRequired: false,
                width: width,
              ),
              SizedBox(height: height * 0.02),
              // Row responsive para Nro de Casa y Estado Civil
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final spacing = math
                      .max(8.0, availableWidth * 0.02)
                      .toDouble();

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildFormField(
                          label: 'Nro de Casa',
                          controller: _nroCasaController,
                          isRequired: false,
                          width: width,
                        ),
                      ),
                      SizedBox(width: spacing),
                      Expanded(
                        flex: 1,
                        child: _buildDropdownField(
                          label: 'Estado Civil',
                          value: _selectedEstadoCivil,
                          items: const [
                            'SOLTERO(A)',
                            'CASADO(A)',
                            'DIVORCIADO(A)',
                            'VIUDO(A)',
                          ],
                          isRequired: false,
                          width: width,
                          onChanged: (value) {
                            setState(() {
                              _selectedEstadoCivil = value;
                            });
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: height * 0.04),
              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Guardar datos personales
                      final personalData = {
                        'nombre': _nombreController.text,
                        'apPaterno': _apPaternoController.text,
                        'apMaterno': _apMaternoController.text,
                        'fechaNacimiento': _fechaNacimientoController.text,
                        'numeroCI': _numeroCIController.text,
                        'complemento': _complementoController.text,
                        'expedidoEn': _expedidoEnController.text,
                        'nacionalidad': _nacionalidadController.text,
                        'ciudadNacimiento': _ciudadNacimientoController.text,
                        'genero': _selectedGenero,
                        'ciudadResidencia': _selectedCiudadResidencia,
                        'direccion': _direccionController.text,
                        'nroCasa': _nroCasaController.text,
                        'estadoCivil': _selectedEstadoCivil,
                      };

                      await LocalStorageService.savePersonalData(personalData);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Datos guardados correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC900),
                    foregroundColor: const Color(0xFF1A3A5C),
                    padding: EdgeInsets.symmetric(vertical: height * 0.02),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'GUARDAR DATOS',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: height * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required bool isRequired,
    required double width,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    // Calcular tamaños responsivos
    final labelFontSize = math
        .max(11.0, math.min(14.0, width * 0.033))
        .toDouble();
    final paddingH = math.max(10.0, math.min(16.0, width * 0.038)).toDouble();
    final paddingV = math.max(10.0, math.min(14.0, width * 0.033)).toDouble();
    final inputFontSize = math
        .max(12.0, math.min(14.0, width * 0.033))
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A3A5C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(fontSize: inputFontSize),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
            isDense: true, // Reduce el padding interno para campos pequeños
          ),
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                }
              : null,
          maxLines: 1,
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required bool isRequired,
    required double width,
    required Function(String?) onChanged,
  }) {
    // Calcular tamaños responsivos
    final fontSize = math.max(12.0, math.min(14.0, width * 0.035)).toDouble();
    final paddingH = math.max(12.0, math.min(16.0, width * 0.04)).toDouble();
    final paddingV = math.max(12.0, math.min(14.0, width * 0.035)).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: math
                      .max(12.0, math.min(14.0, width * 0.034))
                      .toDouble(),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A3A5C),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isRequired)
              const Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded:
              true, // Importante: permite que el dropdown use todo el ancho
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A3A5C), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: paddingH,
              vertical: paddingV,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(fontSize: fontSize),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'Este campo es obligatorio';
                  }
                  return null;
                }
              : null,
          selectedItemBuilder: (BuildContext context) {
            return items.map((String item) {
              return Text(
                item,
                style: TextStyle(fontSize: fontSize, color: Colors.black87),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
