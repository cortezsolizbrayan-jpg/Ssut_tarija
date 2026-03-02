import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/core/animations/enhanced_animations.dart';
import 'package:refactor_template/core/utils/premium_alerts.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_procesador_imagen_perfil.dart';
import 'package:refactor_template/core/widgets/ios_date_picker.dart';

class MisDatosPersonalesScreen extends StatefulWidget {
  static const name = 'mis-datos-personales';
  const MisDatosPersonalesScreen({super.key});

  @override
  State<MisDatosPersonalesScreen> createState() =>
      _MisDatosPersonalesScreenState();
}

class _MisDatosPersonalesScreenState extends State<MisDatosPersonalesScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Llaves para scroll a errores específicos
  final _keyNombre = GlobalKey();
  final _keyApellidos = GlobalKey();
  final _keyCI = GlobalKey();
  final _keyExpedido = GlobalKey();
  final _keyNacionalidad = GlobalKey();
  final _keyGenero = GlobalKey();
  final _keyCelular = GlobalKey();
  final _keyCorreo = GlobalKey();

  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apPaternoController = TextEditingController();
  final TextEditingController _apMaternoController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  final TextEditingController _numeroCIController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _expedidoEnController = TextEditingController();
  final TextEditingController _nacionalidadController = TextEditingController();
  final TextEditingController _ciudadNacimientoController = TextEditingController();
  final TextEditingController _generoController = TextEditingController();
  final TextEditingController _ciudadResidenciaController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nroCasaController = TextEditingController();
  final TextEditingController _estadoCivilController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoAlternativoController = TextEditingController();
  final TextEditingController _telefonoTrabajoController = TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _fechaExpiracionController = TextEditingController();

  // Estados
  String? _selectedExpedidoEn;
  String? _selectedNacionalidad;
  String? _selectedCiudadNacimiento;
  String? _selectedGenero;
  String? _selectedCiudadResidencia;
  String? _selectedEstadoCivil;
  
  File? _profileImage;
  String? _signatureImagePath; // Nueva variable para la firma
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? _participantDocs;
  bool _isSaving = false;
  String? _ciFrontPath;
  String? _ciBackPath;
  String? _ciPhotocopyPath;
  String? _profilePhotoPath;
  Map<String, dynamic>? _pendingOcrData;
  int _errorCount = 0;
  bool _showErrorIndicator = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar imagen cuando se vuelve a la pantalla
    _refreshProfileImageIfNeeded();
  }

  /// Carga los datos guardados previamente
  Future<void> _loadSavedData() async {
    final savedData = await LocalStorageService.getPersonalData();
    final docs = await LocalStorageService.getParticipantDocumentsData();
    final session = await LocalStorageService.getSessionData();

    if (savedData != null) {
      String _str(dynamic v) => (v?.toString() ?? '').trim();
      String? _strOrNull(dynamic v) {
        if (v == null) return null;
        final s = v.toString().trim();
        return s.isEmpty ? null : s;
      }
      setState(() {
        _nombreController.text = _str(savedData['nombre']);
        _apPaternoController.text = _str(savedData['apPaterno']);
        _apMaternoController.text = _str(savedData['apMaterno']);
        _fechaNacimientoController.text = _str(savedData['fechaNacimiento']);
        _numeroCIController.text = _str(savedData['numeroCI']);
        _complementoController.text = _str(savedData['complemento']);
        _expedidoEnController.text = _str(savedData['expedidoEn']);
        _selectedExpedidoEn = _strOrNull(savedData['expedidoEn']);
        _nacionalidadController.text = _str(savedData['nacionalidad']);
        _selectedNacionalidad = _strOrNull(savedData['nacionalidad']);
        _ciudadNacimientoController.text = _str(savedData['ciudadNacimiento']);
        _selectedCiudadNacimiento = _strOrNull(savedData['ciudadNacimiento']);
        _ciudadResidenciaController.text = _str(savedData['ciudadResidencia']);
        _direccionController.text = _str(savedData['direccion']);
        _nroCasaController.text = _str(savedData['nroCasa']);
        _celularController.text = _str(savedData['celular']);
        _correoController.text = _str(savedData['correo']);
        _telefonoAlternativoController.text = _str(savedData['telefonoAlternativo']);
        _telefonoTrabajoController.text = _str(savedData['telefonoTrabajo']);
        _nitController.text = _str(savedData['nit']);
        _razonSocialController.text = _str(savedData['razonSocial']);
        _selectedGenero = _strOrNull(savedData['genero']);
        _selectedCiudadResidencia = _strOrNull(savedData['ciudadResidencia']);
        _selectedEstadoCivil = _strOrNull(savedData['estadoCivil']);
      _fechaEmisionController.text = _str(savedData['fechaEmision']);
      _fechaExpiracionController.text = _str(savedData['fechaExpiracion']);
    });
    }

    // Si no hay nombre/apellidos pero hay sesión (ej. usuario desde CI), prellenar
    if (mounted && (_nombreController.text.trim().isEmpty &&
        _apPaternoController.text.trim().isEmpty &&
        _apMaternoController.text.trim().isEmpty)) {
      final nombreUsuario = (session?['nombreUsuario'] as String?)?.trim();
      if (nombreUsuario != null && nombreUsuario.isNotEmpty) {
        final partes = nombreUsuario.split(RegExp(r'\s+'));
        setState(() {
          if (partes.length == 1) {
            _nombreController.text = partes[0];
          } else if (partes.length == 2) {
            _nombreController.text = partes[0];
            _apPaternoController.text = partes[1];
          } else {
            _nombreController.text = partes.first;
            _apPaternoController.text = partes[1];
            _apMaternoController.text = partes.skip(2).join(' ');
          }
        });
      }
    }

    if (docs != null && mounted) {
      setState(() {
        _participantDocs = docs;
        _ciFrontPath = docs['ci_front_path'] as String?;
        _ciBackPath = docs['ci_back_path'] as String?;
        _ciPhotocopyPath = docs['ci_photocopy_pdf_path'] as String?;
        _profilePhotoPath = docs['profile_photo_path'] as String?;
      });
    }

    final imageFile = await LocalStorageService.getProfileImageFile();
    if (imageFile != null && mounted) {
      setState(() {
        _profileImage = imageFile;
      });
    }

    // NUEVO: Cargar firma
    final firmaPath = await LocalStorageService.getSignatureImagePath();
    if (firmaPath != null && mounted) {
      if (File(firmaPath).existsSync()) {
        setState(() {
          _signatureImagePath = firmaPath;
        });
      }
    }

    // NUEVO: Verificar datos de OCR pendientes
    final ocrData = await getPendingOcrData();
    if (ocrData != null && mounted) {
      setState(() => _pendingOcrData = ocrData);
    }
  }

  void _aplicarOcrData() {
    if (_pendingOcrData == null) return;
    setState(() {
      if (_nombreController.text.isEmpty) {
        _nombreController.text = _pendingOcrData!['nombres']?.toString().toUpperCase() ?? '';
      }
      
      final apellidos = _pendingOcrData!['apellidos']?.toString().toUpperCase() ?? '';
      if (apellidos.isNotEmpty) {
        final parts = apellidos.split(RegExp(r'\s+'));
        if (_apPaternoController.text.isEmpty) _apPaternoController.text = parts[0];
        if (_apMaternoController.text.isEmpty && parts.length > 1) {
          _apMaternoController.text = parts.sublist(1).join(' ');
        }
      }

      if (_numeroCIController.text.isEmpty) {
        _numeroCIController.text = _pendingOcrData!['numeroDocumento']?.toString() ?? '';
      }

      if (_fechaNacimientoController.text.isEmpty && _pendingOcrData!['fechaNacimiento'] != null) {
        _fechaNacimientoController.text = _pendingOcrData!['fechaNacimiento'].toString();
      }

      // Limpiar para que no vuelva a aparecer el banner una vez aplicado (o dar opción de descartar)
      _pendingOcrData = null;
    });
    
    PremiumAlerts.showSuccess(
      context,
      'Datos recuperados de tu Cédula de Identidad',
      title: 'OCR Exitoso',
    );
  }

  /// Progreso del formulario: campos obligatorios completados (0.0 a 1.0)
  double _getFormProgress() {
    final tieneApellido = _apPaternoController.text.trim().isNotEmpty ||
        _apMaternoController.text.trim().isNotEmpty;
    final required = [
      _nombreController.text.trim().isNotEmpty,
      tieneApellido,
      (_selectedExpedidoEn ?? _expedidoEnController.text).trim().isNotEmpty,
      // Complemento ya NO es obligatorio
      _selectedGenero != null && _selectedGenero!.isNotEmpty,
      _selectedNacionalidad != null && _selectedNacionalidad!.trim().isNotEmpty,
      _celularController.text.trim().isNotEmpty,
      _correoController.text.trim().isNotEmpty,
    ];
    final filled = required.where((b) => b).length;
    return filled / required.length;
  }

  /// Valida que al menos uno de los dos apellidos esté completo
  String? _validateApellidoPaterno(String? value) {
    final paterno = value?.trim() ?? '';
    final materno = _apMaternoController.text.trim();
    if (paterno.isEmpty && materno.isEmpty) {
      return 'Ingrese al menos un apellido';
    }
    return null;
  }

  String? _validateApellidoMaterno(String? value) {
    final materno = value?.trim() ?? '';
    final paterno = _apPaternoController.text.trim();
    if (paterno.isEmpty && materno.isEmpty) {
      return 'Ingrese al menos un apellido';
    }
    return null;
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parseSavedDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s.trim().split(RegExp(r'[/\-.\s]')).where((p) => p.isNotEmpty).toList();
    if (parts.length != 3) return null;
    final p0 = int.tryParse(parts[0]);
    final p1 = int.tryParse(parts[1]);
    final p2 = int.tryParse(parts[2]);
    if (p0 == null || p1 == null || p2 == null) return null;
    int d, m, y;
    if (p0 > 31) {
      y = p0;
      m = p1;
      d = p2;
    } else if (p2 > 31) {
      d = p0;
      m = p1;
      y = p2;
    } else {
      d = p0;
      m = p1;
      y = p2;
    }
    if (d > 31 || d < 1 || m > 12 || m < 1 || y < 1900 || y > DateTime.now().year) return null;
    return DateTime(y, m, d);
  }

  Future<void> _pickFechaNacimiento() async {
    final initialDate = _parseSavedDate(_fechaNacimientoController.text) ??
        DateTime(DateTime.now().year - 25, 1, 1);
    
    final picked = await mostrarIosFechaPicker(
      context: context,
      initialDate: initialDate,
      titulo: 'Fecha de Nacimiento',
      esFechaNacimiento: true,
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaNacimientoController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickFechaEmision() async {
    final initialDate = _parseSavedDate(_fechaEmisionController.text) ?? DateTime.now();

    final picked = await mostrarIosFechaPicker(
      context: context,
      initialDate: initialDate,
      titulo: 'Fecha de Emisión',
      esFechaNacimiento: false,
      minimumYear: 1920,
      maximumYear: DateTime.now().year,
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaEmisionController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickFechaExpiracion() async {
    final initialDate = _parseSavedDate(_fechaExpiracionController.text) ?? DateTime.now().add(const Duration(days: 365 * 10));

    final picked = await mostrarIosFechaPicker(
      context: context,
      initialDate: initialDate,
      titulo: 'Fecha de Expiración',
      esFechaNacimiento: false,
      minimumYear: 1950,
      maximumYear: DateTime.now().year + 20,
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaExpiracionController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _refreshProfileImageIfNeeded() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (!mounted) return;
    
    // Siempre actualizar si hay una imagen nueva o si cambió el archivo
    final currentPath = _profileImage?.path ?? '';
    final nextPath = imageFile?.path ?? '';
    
    // Verificar si el archivo existe y si cambió
    bool shouldUpdate = false;
    if (nextPath.isNotEmpty && nextPath != currentPath) {
      shouldUpdate = true;
    } else if (nextPath.isNotEmpty && currentPath.isNotEmpty) {
      // Verificar si el archivo fue modificado (por timestamp)
      try {
        final currentFile = File(currentPath);
        final nextFile = File(nextPath);
        if (await currentFile.exists() && await nextFile.exists()) {
          final currentModified = await currentFile.lastModified();
          final nextModified = await nextFile.lastModified();
          if (nextModified.isAfter(currentModified)) {
            shouldUpdate = true;
          }
        }
      } catch (e) {
        debugPrint('Error verificando timestamp de imagen: $e');
      }
    }
    
    if (shouldUpdate || _profileImage == null && imageFile != null) {
      setState(() {
        _profileImage = imageFile;
      });
      debugPrint('✅ Foto de perfil actualizada en Mis Datos Personales');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    _celularController.dispose();
    _correoController.dispose();
    _telefonoAlternativoController.dispose();
    _telefonoTrabajoController.dispose();
    _nitController.dispose();
    _razonSocialController.dispose();
  _fechaEmisionController.dispose();
  _fechaExpiracionController.dispose();
  super.dispose();
}

  Future<void> _pickImage() async {
    bool loaderShown = false;
    bool processingDialogShown = false;
    
    // Guardar el ScaffoldMessenger antes de operaciones async
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Mostrar diálogo de selección de fuente
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Seleccionar foto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Mostrar indicador de carga
      if (mounted) {
        loaderShown = true;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (!mounted) return;
      if (loaderShown) {
        final navigator = Navigator.of(context, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
        loaderShown = false;
      }

      if (image != null) {
        final fileSize = await File(image.path).length();
        const maxSize = 3.1 * 1024 * 1024; // 3.1 MB
        if (fileSize > maxSize) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('El archivo excede el tamaño máximo de 3.1MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        File imageToSave = File(image.path);
        if (mounted) {
          processingDialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Loader animado
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF005BAC),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          '🎨 Procesando imagen...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF005BAC),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Removiendo fondo y aplicando\nfondo institucional',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Indicadores de progreso
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 8,
                          children: [
                            _buildProcessStep('🔄', 'Analizando'),
                            Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                            _buildProcessStep('✂️', 'Recortando'),
                            Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                            _buildProcessStep('🎨', 'Aplicando'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final processedImage =
            await ProfileImageProcessorService.processProfileImage(
              File(image.path),
              isFirstPhoto: true,
            );

        if (!mounted) return;
        if (processingDialogShown) {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop();
          }
          processingDialogShown = false;
        }

        if (processedImage != null) {
          imageToSave = processedImage;
        }

        // Guardar la imagen en almacenamiento permanente
        final savedPath = await LocalStorageService.saveProfileImage(
          imageToSave,
        );
        if (savedPath != null && mounted) {
          // Forzar a Flutter a purgar la imagen antigua del caché
          await FileImage(File(savedPath)).evict();
          
          setState(() {
            _profileImage = File(savedPath);
          });

          PremiumAlerts.showSuccess(
            context,
            'Fondo removido y aplicado fondo institucional',
            title: 'Foto Procesada',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (processingDialogShown || loaderShown) {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) {
            navigator.pop();
          }
        }
      }
      PremiumAlerts.showError(context, 'Error al seleccionar imagen: $e');
    }
  }

  Future<void> _refreshIdentityBackupIfNeeded() async {
    final docs = await LocalStorageService.getParticipantDocumentsData();
    if (!mounted) return;
    final nextFront = docs?['ci_front_path'] as String?;
    final nextBack = docs?['ci_back_path'] as String?;
    final nextPdf = docs?['ci_photocopy_pdf_path'] as String?;
    final nextProfile = docs?['profile_photo_path'] as String?;
    if (nextFront != _ciFrontPath ||
        nextBack != _ciBackPath ||
        nextPdf != _ciPhotocopyPath ||
        nextProfile != _profilePhotoPath) {
      setState(() {
        _participantDocs = docs;
        _ciFrontPath = nextFront;
        _ciBackPath = nextBack;
        _ciPhotocopyPath = nextPdf;
        _profilePhotoPath = nextProfile;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Intentar ir atrás, si no se puede, ir al inicio
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sistema/pantalla_principal');
            }
          },
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
          IconButton(
            icon: const Icon(Icons.home, color: Colors.white),
            onPressed: () => context.go('/sistema/pantalla_principal'),
            tooltip: 'Ir al Inicio',
          ),
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
                color: const Color(0xFF005BAC),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card perfil: foto + nombre visible
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: _buildPerfilCard(width, height),
              ),
              if (_pendingOcrData != null) ...[
                SizedBox(height: height * 0.02),
                FadeInRight(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF1976D2)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '¿Autocompletar datos?',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D47A1), fontSize: 13),
                              ),
                              Text(
                                'He recuperado información de tu carnet escaneado.',
                                style: TextStyle(color: const Color(0xFF0D47A1).withOpacity(0.8), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _aplicarOcrData,
                          child: const Text('LLENAR', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () => setState(() => _pendingOcrData = null),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SizedBox(height: height * 0.02),
              FadeIn(
                delay: const Duration(milliseconds: 100),
                child: _buildFormProgressBar(),
              ),
              SizedBox(height: height * 0.02),
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: _buildSectionHeader(
                  title: 'Datos de identidad',
                  subtitle: 'Nombre completo y documento. Al menos un apellido es obligatorio.',
                ),
              ),
              SizedBox(height: height * 0.015),
              _buildFormField(
                key: _keyNombre,
                label: 'Nombres',
                controller: _nombreController,
                isRequired: true,
                width: width,
                icon: Icons.person_outline,
              ),
              SizedBox(height: height * 0.02),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    key: _keyApellidos,
                    label: 'Apellido paterno *',
                    controller: _apPaternoController,
                    isRequired: false,
                    width: width,
                    icon: Icons.badge_outlined,
                    customValidator: _validateApellidoPaterno,
                    onChanged: (_) {
                      setState(() {});
                      _formKey.currentState?.validate();
                    },
                  ),
                  _buildFormField(
                    label: 'Apellido materno *',
                    controller: _apMaternoController,
                    isRequired: false,
                    width: width,
                    icon: Icons.badge_outlined,
                    customValidator: _validateApellidoMaterno,
                    onChanged: (_) {
                      setState(() {});
                      _formKey.currentState?.validate();
                    },
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              _buildFormField(
                label: 'Fecha de Nacimiento',
                controller: _fechaNacimientoController,
                isRequired: false,
                width: width,
                readOnly: true,
                onTap: _pickFechaNacimiento,
                icon: Icons.calendar_today_outlined,
              ),
              SizedBox(height: height * 0.02),
              _buildSectionHeader(
                title: 'Documento de identidad',
                subtitle: 'CI, complemento y expedido.',
              ),
              SizedBox(height: height * 0.015),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    key: _keyCI,
                    label: 'Número de CI',
                    controller: _numeroCIController,
                    isRequired: false,
                    width: width,
                    icon: Icons.badge_outlined,
                    customValidator: _validateCI,
                  ),
                  _buildFormField(
                    label: 'Complemento',
                    controller: _complementoController,
                    isRequired: false,
                    width: width,
                    icon: Icons.add_circle_outline,
                  ),
                  _buildDropdownField(
                    key: _keyExpedido,
                    label: 'Expedido en',
                    value: _selectedExpedidoEn,
                    items: const [
                      'LA PAZ', 'ORURO', 'POTOSÍ', 'SANTA CRUZ',
                      'BENI', 'PANDO', 'COCHABAMBA', 'CHUQUISACA', 'TARIJA',
                    ],
                    isRequired: false,
                    width: width,
                    icon: Icons.map_outlined,
                    onChanged: (value) {
                      setState(() {
                        _selectedExpedidoEn = value;
                        _expedidoEnController.text = value ?? '';
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    label: 'Fecha de Emisión',
                    controller: _fechaEmisionController,
                    isRequired: false,
                    width: width,
                    readOnly: true,
                    onTap: _pickFechaEmision,
                    icon: Icons.event_available_outlined,
                  ),
                  _buildFormField(
                    label: 'Fecha de Expiración',
                    controller: _fechaExpiracionController,
                    isRequired: false,
                    width: width,
                    readOnly: true,
                    onTap: _pickFechaExpiracion,
                    icon: Icons.event_busy_outlined,
                  ),
                ],
              ),
              //FUNCION DE NACIONALIDAD 
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildDropdownField(
                    key: _keyNacionalidad,
                    label: 'Nacionalidad',
                    value: _selectedNacionalidad,
                    items: const [
                      'BOLIVIANA', 'BOLIVIANO', 'EXTRANJERO', 'EXTRANJERA',
                    ],
                    isRequired: true,
                    width: width,
                    icon: Icons.flag_outlined,
                    onChanged: (value) {
                      setState(() {
                        _selectedNacionalidad = value;
                        _nacionalidadController.text = value ?? '';
                      });
                    },
                  ),
                  //CIUDADES MODENRA AS
                  
                  _buildDropdownField(
                    label: 'Ciudad de Nacimiento',
                    value: _selectedCiudadNacimiento,
                    items: const [
                      'LA PAZ', 'SANTA CRUZ', 'COCHABAMBA', 'ORURO',
                      'POTOSÍ', 'SUCRE', 'TARIJA', 'BENI', 'PANDO',
                    ],
                    isRequired: false,
                    width: width,
                    icon: Icons.location_city_outlined,
                    onChanged: (value) {
                      setState(() {
                        _selectedCiudadNacimiento = value;
                        _ciudadNacimientoController.text = value ?? '';
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              _buildDropdownField(
                key: _keyGenero,
                label: 'Género',
                value: _selectedGenero,
                items: const ['MASCULINO', 'FEMENINO', 'OTRO'],
                isRequired: true,
                width: width,
                icon: Icons.wc_outlined,
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
                icon: Icons.home_work_outlined,
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
                icon: Icons.location_on_outlined,
              ),
              SizedBox(height: height * 0.02),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    label: 'Nro de Casa',
                    controller: _nroCasaController,
                    isRequired: false,
                    width: width,
                    icon: Icons.home_outlined,
                  ),
                  _buildDropdownField(
                    label: 'Estado Civil',
                    value: _selectedEstadoCivil,
                    items: const [
                      'SOLTERO(A)', 'CASADO(A)', 'DIVORCIADO(A)', 'VIUDO(A)',
                    ],
                    isRequired: false,
                    width: width,
                    icon: Icons.favorite_border_outlined,
                    onChanged: (value) {
                      setState(() {
                        _selectedEstadoCivil = value;
                      });
                    },
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              _buildSectionHeader(
                title: 'Informacion de contacto',
                subtitle: 'Metodos para comunicarnos contigo.',
              ),
              SizedBox(height: height * 0.02),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    key: _keyCelular,
                    label: 'Celular',
                    controller: _celularController,
                    isRequired: true,
                    width: width,
                    icon: Icons.phone_android_outlined,
                    customValidator: _validateCelular,
                  ),
                  _buildFormField(
                    key: _keyCorreo,
                    label: 'Correo Electrónico',
                    controller: _correoController,
                    isRequired: true,
                    width: width,
                    icon: Icons.email_outlined,
                    customValidator: _validateEmail,
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    label: 'Teléfono Alternativo',
                    controller: _telefonoAlternativoController,
                    isRequired: false,
                    width: width,
                    icon: Icons.phone_outlined,
                    customValidator: _validateTelefono,
                  ),
                  _buildFormField(
                    label: 'Teléfono de Trabajo',
                    controller: _telefonoTrabajoController,
                    isRequired: false,
                    width: width,
                    icon: Icons.phone_in_talk_outlined,
                    customValidator: _validateTelefono,
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
              _buildSectionHeader(
                title: 'Datos de facturacion',
                subtitle: 'Informacion para emitir comprobantes.',
              ),
              SizedBox(height: height * 0.02),
              _buildResponsiveGroup(
                width: width,
                children: [
                  _buildFormField(
                    label: 'NIT',
                    controller: _nitController,
                    isRequired: false,
                    width: width,
                    icon: Icons.receipt_long_outlined,
                  ),
                  _buildFormField(
                    label: 'Razón Social',
                    controller: _razonSocialController,
                    isRequired: false,
                    width: width,
                    icon: Icons.business_outlined,
                  ),
                ],
              ),
              SizedBox(height: height * 0.03),
              _buildSectionHeader(
                title: 'Respaldo de identidad',
                subtitle: 'Fotocopia de C.I. y foto 4x4.',
              ),
              SizedBox(height: height * 0.015),
              _buildIdentityBackupCard(),
              SizedBox(height: height * 0.03),

              SizedBox(height: height * 0.04),
              // Botón guardar
              Semantics(
                button: true,
                label: 'Guardar datos personales',
                child: AnimatedButton(
                  onTap: _isSaving
                    ? null
                    : () async {
                        if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
                          HapticFeedback.vibrate(); // Vibración de error
                          _scrollToFirstError();
                          return;
                        }

                        HapticFeedback.heavyImpact();
                        setState(() => _isSaving = true);

                        final scaffoldMessenger = ScaffoldMessenger.of(context);

                        try {
                          // Fusionar con datos existentes para no perder campos de otras pantallas
                          final existing = await LocalStorageService.getPersonalData();
                          final personalData = <String, dynamic>{
                            ...?existing,
                            'nombre': _nombreController.text.trim(),
                            'apPaterno': _apPaternoController.text.trim(),
                            'apMaterno': _apMaternoController.text.trim(),
                            'fechaNacimiento': _fechaNacimientoController.text.trim(),
                            'numeroCI': _numeroCIController.text.trim(),
                            'complemento': _complementoController.text.trim(),
                            'expedidoEn': _selectedExpedidoEn ?? _expedidoEnController.text.trim(),
                            'nacionalidad': _selectedNacionalidad ?? _nacionalidadController.text.trim(),
                            'ciudadNacimiento': _selectedCiudadNacimiento ?? _ciudadNacimientoController.text.trim(),
                            'genero': _selectedGenero,
                            'ciudadResidencia': _selectedCiudadResidencia,
                            'direccion': _direccionController.text.trim(),
                            'nroCasa': _nroCasaController.text.trim(),
                            'estadoCivil': _selectedEstadoCivil,
                            'celular': _celularController.text.trim(),
                            'correo': _correoController.text.trim(),
                            'telefonoAlternativo': _telefonoAlternativoController.text.trim(),
                            'telefonoTrabajo': _telefonoTrabajoController.text.trim(),
                            'nit': _nitController.text.trim(),
                            'razonSocial': _razonSocialController.text.trim(),
                            'fechaEmision': _fechaEmisionController.text.trim(),
                            'fechaExpiracion': _fechaExpiracionController.text.trim(),
                          };

                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Guardando...'),
                                ],
                              ),
                              duration: Duration(seconds: 2),
                              backgroundColor: Color(0xFF005BAC),
                            ),
                          );

                          // Normalizar nacionalidad
                          String normalizedNacionalidad = _selectedNacionalidad ?? '';
                          if (normalizedNacionalidad == 'BOLIVIANO') normalizedNacionalidad = 'BOLIVIANA';
                          if (normalizedNacionalidad == 'EXTRANJERO') normalizedNacionalidad = 'EXTRANJERA';
                          
                          personalData['nacionalidad'] = normalizedNacionalidad;

                          await LocalStorageService.savePersonalData(personalData);

                          if (!mounted) return;
                          setState(() => _isSaving = false);

                          // Verificar que se guardó leyendo de nuevo
                          final verificacion = await LocalStorageService.getPersonalData();
                          if (verificacion == null || verificacion['nombre'] != personalData['nombre']) {
                            if (mounted) {
                              PremiumAlerts.showError(context, 'No se pudo verificar el guardado. Intente de nuevo.');
                            }
                            return;
                          }

                          scaffoldMessenger.hideCurrentSnackBar();
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text('Datos guardados correctamente'),
                                ],
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          if (!context.mounted) return;
                          PremiumAlerts.showPremiumDialog(
                            context,
                            title: '¡Datos Guardados!',
                            message: 'Sus datos personales se guardaron correctamente.',
                            icon: Icons.check_circle_rounded,
                            color: Colors.green,
                            primaryButtonText: 'CONTINUAR',
                          ).then((_) {
                            if (mounted) _loadSavedData();
                          });
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _isSaving = false);
                          scaffoldMessenger.hideCurrentSnackBar();
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text('Error al guardar: $e'),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: height * 0.02),
                    decoration: BoxDecoration(
                      color: _isSaving ? Colors.grey.shade400 : const Color(0xFF005BAC),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF005BAC).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'GUARDAR DATOS',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ), // AnimatedButton
              ), // Semantics
            ],
          ), // Column
        ), // SingleChildScrollView
      ), // Form
    ], // Stack children
  ), // Stack
      floatingActionButton: (_showErrorIndicator && _errorCount > 0)
          ? FadeInRight(
              child: FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _scrollToFirstError();
                },
                backgroundColor: Colors.redAccent,
                icon: const Icon(Icons.arrow_upward, color: Colors.white),
                label: Text(
                  '$_errorCount errores arriba',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  void _scrollToFirstError() {
    final Map<GlobalKey, bool> fieldStates = {
      _keyNombre: _nombreController.text.trim().isEmpty,
      _keyApellidos: _apPaternoController.text.trim().isEmpty && _apMaternoController.text.trim().isEmpty,
      _keyExpedido: _selectedExpedidoEn == null,
      _keyNacionalidad: _selectedNacionalidad == null,
      _keyGenero: _selectedGenero == null,
      _keyCelular: _celularController.text.trim().isEmpty,
      _keyCorreo: _correoController.text.trim().isEmpty,
    };

    GlobalKey? firstErrorKey;
    int totalErrors = 0;

    fieldStates.forEach((key, hasError) {
      if (hasError) {
        totalErrors++;
        firstErrorKey ??= key;
      }
    });

    setState(() {
      _errorCount = totalErrors;
      _showErrorIndicator = totalErrors > 0;
    });

    if (firstErrorKey != null && firstErrorKey!.currentContext != null) {
      Scrollable.ensureVisible(
        firstErrorKey!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.1,
      );
    }
  }

  static const Color _primaryBlue = Color(0xFF005BAC);
  static const Color _background = Color(0xFFEEF1F8);

  Widget _buildFormProgressBar() {
    final progress = _getFormProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completado ${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF005BAC).withOpacity(0.8),
              ),
            ),
            if (progress >= 1.0)
              Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EEF7),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : const Color(0xFF005BAC),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerfilCard(double width, double height) {
    final nombreCompleto = [
      _nombreController.text.trim(),
      _apPaternoController.text.trim(),
      _apMaternoController.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ').trim();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF0F4F8)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005BAC).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primaryBlue, const Color(0xFF0F7BD7)],
                  ),
                ),
                child: GestureDetector(
                  onTap: _profileImage != null ? _showFullImage : _pickImage,
                  onLongPress: _pickImage, // Long press para cambiar foto
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: CircleAvatar(
                      key: ValueKey('${_profileImage?.path ?? 'empty'}_${_profileImage?.existsSync() == true ? _profileImage!.lastModifiedSync().millisecondsSinceEpoch : ''}'),
                      radius: 54,
                      backgroundColor: Colors.white,
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? Icon(Icons.person_rounded, size: 60, color: _primaryBlue.withOpacity(0.2))
                          : null,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF005BAC),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            nombreCompleto.isEmpty ? 'Usuario de Posgrado' : nombreCompleto,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF005BAC),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Gestione su información personal y firma digital',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          // Botón Mi Firma
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final resultPath = await context.pushNamed<String>('pantalla_firma');
              if (resultPath != null && mounted) {
                // Forzar purga de caché por si cambió
                await FileImage(File(resultPath)).evict();
                setState(() {
                  _signatureImagePath = resultPath;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _signatureImagePath != null ? const Color(0xFFE8F4F8) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _signatureImagePath != null ? const Color(0xFF005BAC) : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Icon(
                        Icons.draw_rounded, 
                        color: _signatureImagePath != null ? const Color(0xFF005BAC) : Colors.grey.shade700, 
                        size: 24,
                      ),
                      if (_signatureImagePath != null)
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _signatureImagePath != null ? 'Firma Configurada' : 'Configurar Mi Firma',
                    style: TextStyle(
                      color: _signatureImagePath != null ? const Color(0xFF005BAC) : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGroup({
    required List<Widget> children,
    required double width,
    int columns = 2,
  }) {
    // Si la pantalla es pequeña, siempre una columna
    if (width < 500) {
      return Column(
        children: children.map((child) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: child,
        )).toList(),
      );
    }
    
    // Para 3 campos que se apretaban (CI, Compl, Exp), los dividimos en 2:1 o similar
    if (children.length >= 3) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 16),
              Expanded(child: children[1]),
            ],
          ),
          const SizedBox(height: 16),
          children.length > 2 ? children[2] : const SizedBox.shrink(),
          if (children.length > 3) ...children.sublist(3).map((c) => Padding(
            padding: const EdgeInsets.only(top: 16),
            child: c,
          )),
        ],
      );
    }

    // Comportamiento estándar de 2 columnas
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 16),
        Expanded(child: children.length > 1 ? children[1] : const SizedBox.shrink()),
      ],
    );
  }

  Widget _buildSectionHeader({required String title, String? subtitle}) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAC),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          if (subtitle != null && subtitle.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 14),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIdentityBackupCard() {
    final hasFront = (_ciFrontPath ?? '').isNotEmpty;
    final hasBack = (_ciBackPath ?? '').isNotEmpty;
    final hasPdf = (_ciPhotocopyPath ?? '').isNotEmpty;
    final hasPhoto = (_profilePhotoPath ?? '').isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EEF7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005BAC).withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildCompactStatusTile('Anverso C.I.', hasFront, Icons.badge_outlined),
                _buildCompactStatusTile('Reverso C.I.', hasBack, Icons.badge_outlined),
                _buildCompactStatusTile('Fotocopia PDF', hasPdf, Icons.picture_as_pdf_outlined),
                _buildCompactStatusTile('Foto 4x4', hasPhoto, Icons.face_retouching_natural_outlined),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EEF7)),
          InkWell(
            onTap: () {
              context.push(
                '/upload-ci',
                extra: {'ci': _numeroCIController.text},
              );
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload_outlined, color: Color(0xFF005BAC), size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'GESTIONAR DOCUMENTOS',
                    style: TextStyle(
                      color: Color(0xFF005BAC),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusTile(String label, bool isReady, IconData icon) {
    return Container(
      width: (MediaQuery.of(context).size.width * 0.45) - 34, // Aproximadamente half width con padding
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isReady 
            ? Colors.green.withOpacity(0.05) 
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isReady 
              ? Colors.green.withOpacity(0.2) 
              : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isReady ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 16,
            color: isReady ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF005BAC).withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }



  static String? _validateCI(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 5 || digits.length > 8) return 'CI debe tener 5 a 8 dígitos';
    return null;
  }

  static String? _validateCelular(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return 'Celular debe tener 8 dígitos';
    return null;
  }

  static String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final emailRegex = RegExp(r'^[\w\-\.]+@[\w\-\.]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Formato de correo inválido';
    return null;
  }

  static String? _validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 9) return 'Teléfono debe tener 7 a 9 dígitos';
    return null;
  }

  Widget _buildFormField({
    Key? key,
    required String label,
    required TextEditingController controller,
    required bool isRequired,
    required double width,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
    String? Function(String?)? customValidator,
    void Function(String)? onChanged,
  }) {
    final isSmallScreen = width < 400;
    final bool isFilled = controller.text.isNotEmpty;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: isFilled ? FontWeight.w800 : FontWeight.w700,
                    color: isFilled ? const Color(0xFF005BAC) : const Color(0xFF005BAC).withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            color: const Color(0xFF005BAC),
            fontWeight: isFilled ? FontWeight.bold : FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: isFilled ? const Color(0xFFE8F0FE) : (readOnly ? Colors.grey[50] : Colors.white),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: isFilled ? const Color(0xFF005BAC) : const Color(0xFF005BAC).withOpacity(0.5),
                    size: 20,
                  )
                : null,
            hintText: 'Ingrese ${label.toLowerCase()}',
            hintStyle: TextStyle(
              color: Colors.grey.withOpacity(0.4),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isFilled ? const Color(0xFF005BAC).withOpacity(0.3) : const Color(0xFFE8EEF7),
                width: isFilled ? 1.5 : 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF005BAC),
                width: 1.8,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Campo requerido';
            }
            return customValidator?.call(value);
          },
          onChanged: (value) {
            setState(() {});
            if (onChanged != null) onChanged(value);
          },
        ), // end TextFormField
      ], // end children Column
      ), // end Column
    ); // end Container
  }

  Widget _buildDropdownField({
    Key? key,
    required String label,
    required String? value,
    required List<String> items,
    required bool isRequired,
    required double width,
    required Function(String?) onChanged,
    IconData? icon,
  }) {
    final isSmallScreen = width < 400;

    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF005BAC).withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        DropdownButtonFormField<String>(
          value: value != null && items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF005BAC),
          ),
          dropdownColor: Colors.white, // Fondo blanco para el menú desplegable
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 15,
            color: const Color(0xFF005BAC),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    color: const Color(0xFF005BAC).withOpacity(0.5),
                    size: 20,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: const Color(0xFFE8EEF7), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF005BAC),
                width: 1.8,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF005BAC),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          validator: isRequired
              ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null
              : null,
        ), // end DropdownButtonFormField
      ], // end children Column
      ), // end Column
    ); // end Container
  }

  /// Widget helper para mostrar pasos del proceso
  Widget _buildProcessStep(String emoji, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF005BAC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF005BAC),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra la imagen de perfil en tamaño completo
  void _showFullImage() {
    if (_profileImage == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Imagen en tamaño completo
            Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      _profileImage!,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            // Botón de cerrar
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Botón de cambiar foto
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _pickImage();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Cambiar foto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BAC),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
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
