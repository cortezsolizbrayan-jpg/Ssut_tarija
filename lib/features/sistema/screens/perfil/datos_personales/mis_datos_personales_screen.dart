import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/image_processing/servicio_procesador_imagen_perfil.dart';
import 'package:refactor_template/core/utils/premium_alerts.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/core/widgets/ios_date_picker.dart';
import 'package:refactor_template/features/sistema/presentation/blocs/perfil/perfil_bloc.dart';
import 'package:refactor_template/features/sistema/presentation/blocs/perfil/perfil_event.dart';

import '../componentes/personal_data_perfil_card.dart';
import '../componentes/personal_data_progress_bar.dart';
import '../componentes/personal_data_section_header.dart';
import '../componentes/personal_data_form_field.dart';
import '../componentes/personal_data_dropdown_field.dart';
import '../componentes/personal_data_identity_card.dart';
import '../componentes/personal_data_responsive_group.dart';
import '../componentes/datos_personales_validators.dart';
import '../componentes/dialogo_procesamiento_magico.dart';

class MisDatosPersonalesPantalla extends StatefulWidget {
  static const name = 'mis-datos-personales';
  const MisDatosPersonalesPantalla({super.key});

  @override
  State<MisDatosPersonalesPantalla> createState() =>
      _MisDatosPersonalesPantallaState();
}

class _MisDatosPersonalesPantallaState
    extends State<MisDatosPersonalesPantalla> {
  // Controllers
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apPaternoController = TextEditingController();
  final TextEditingController _apMaternoController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  final TextEditingController _numeroCIController = TextEditingController();
  final TextEditingController _complementoController = TextEditingController();
  final TextEditingController _expedidoEnController = TextEditingController();
  final TextEditingController _nacionalidadController = TextEditingController();
  final TextEditingController _ciudadNacimientoController =
      TextEditingController();
  final TextEditingController _generoController = TextEditingController();
  final TextEditingController _ciudadResidenciaController =
      TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _nroCasaController = TextEditingController();
  final TextEditingController _estadoCivilController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _telefonoAlternativoController =
      TextEditingController();
  final TextEditingController _telefonoTrabajoController =
      TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _fechaExpiracionController =
      TextEditingController();

  // States
  String? _selectedExpedidoEn;
  String? _selectedNacionalidad;
  String? _selectedCiudadNacimiento;
  String? _selectedGenero;
  String? _selectedCiudadResidencia;
  String? _selectedEstadoCivil;

  File? _profileImage;
  String? _signatureImagePath;
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  String? _ciFrontPath;
  String? _ciBackPath;
  String? _ciPhotocopyPath;
  String? _profilePhotoPath;
  Map<String, dynamic>? _pendingOcrData;
  int _errorCount = 0;
  bool _showErrorIndicator = false;

  // Global Keys for scroll to error
  final _keyNombre = GlobalKey();
  final _keyApellidos = GlobalKey();
  final _keyCI = GlobalKey();
  final _keyExpedido = GlobalKey();
  final _keyNacionalidad = GlobalKey();
  final _keyGenero = GlobalKey();
  final _keyCelular = GlobalKey();
  final _keyCorreo = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshProfileImageIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
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
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final titleSize = ResponsiveUtils.subtitleFontSize(context);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final sectionGap = ResponsiveUtils.cardSpacing(context);

    final isTablet = width > 600;
    final maxFormWidth = isTablet ? 600.0 : width;
    final formPadding = isTablet
        ? EdgeInsets.symmetric(horizontal: (width - maxFormWidth) / 2)
        : EdgeInsets.symmetric(horizontal: horizontalPadding);

    return Scaffold(
      backgroundColor: DatosPersonalesConstants.background,
      appBar: AppBar(
        backgroundColor: DatosPersonalesConstants.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/sistema/pantalla_principal');
            }
          },
        ),
        title: Text(
          'Mis Datos Personales',
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: _isSaving ? null : _guardarDatos,
            tooltip: 'Guardar',
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: formPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeIn(
                    duration: const Duration(milliseconds: 800),
                    child: PersonalDataPerfilCard(
                      profileImage: _profileImage,
                      nombre: _nombreController.text,
                      apPaterno: _apPaternoController.text,
                      apMaterno: _apMaternoController.text,
                      signatureImagePath: _signatureImagePath,
                      onTapCamera: _pickImage,
                      onTapSignature: _pickSignature,
                      onTapImage: _showFullImage,
                    ),
                  ),
                  if (_pendingOcrData != null) ...[
                    SizedBox(height: sectionGap),
                    _buildOcrNotification(),
                  ],
                  SizedBox(height: sectionGap),
                  FadeIn(
                    duration: const Duration(milliseconds: 800),
                    child: PersonalDataProgressBar(
                      progress: _getFormProgress(),
                    ),
                  ),
                  SizedBox(height: sectionGap),
                  _buildFormSections(width, height),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: (_showErrorIndicator && _errorCount > 0)
          ? FadeIn(
              duration: const Duration(milliseconds: 600),
              child: FloatingActionButton.extended(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _scrollToFirstError();
                },
                backgroundColor: Colors.redAccent,
                icon: const Icon(Icons.arrow_upward, color: Colors.white),
                label: Text(
                  '$_errorCount errores arriba',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildOcrNotification() {
    return FadeIn(
      duration: const Duration(milliseconds: 800),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'He recuperado información de tu carnet escaneado.',
                    style: TextStyle(
                      color: const Color(0xFF0D47A1).withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _aplicarOcrData,
              child: const Text(
                'LLENAR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.grey),
              onPressed: () => setState(() => _pendingOcrData = null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSections(double width, double height) {
    final sectionGap = ResponsiveUtils.cardSpacing(context);

    return Column(
      children: [
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: const PersonalDataSectionHeader(
            title: 'Datos de identidad',
            subtitle:
                'Nombre completo y documento. Al menos un apellido es obligatorio.',
          ),
        ),
        SizedBox(height: sectionGap * 0.75),
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              fieldKey: _keyNombre,
              label: 'Nombres',
              controller: _nombreController,
              isRequired: true,
              width: width,
              icon: Icons.person_outline,
            ),
            PersonalDataFormField(
              fieldKey: _keyApellidos,
              label: 'Apellido paterno *',
              controller: _apPaternoController,
              isRequired: false,
              width: width,
              icon: Icons.badge_outlined,
              customValidator: _validateApellidoPaterno,
              onChanged: (_) => _formKey.currentState?.validate(),
            ),
            PersonalDataFormField(
              label: 'Apellido materno *',
              controller: _apMaternoController,
              isRequired: false,
              width: width,
              icon: Icons.badge_outlined,
              customValidator: _validateApellidoMaterno,
              onChanged: (_) => _formKey.currentState?.validate(),
            ),
          ],
        ),
        SizedBox(height: height * 0.02),
        PersonalDataFormField(
          label: 'Fecha de Nacimiento',
          controller: _fechaNacimientoController,
          isRequired: false,
          width: width,
          readOnly: true,
          onTap: _pickFechaNacimiento,
          icon: Icons.calendar_today_outlined,
        ),
        SizedBox(height: height * 0.02),
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: const PersonalDataSectionHeader(
            title: 'Documento de identidad',
            subtitle: 'CI, complemento y expedido.',
          ),
        ),
        SizedBox(height: height * 0.015),
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              fieldKey: _keyCI,
              label: 'Número de CI',
              controller: _numeroCIController,
              isRequired: false,
              width: width,
              icon: Icons.badge_outlined,
              customValidator: DatosPersonalesValidators.validateCI,
            ),
            PersonalDataFormField(
              label: 'Complemento',
              controller: _complementoController,
              isRequired: false,
              width: width,
              icon: Icons.add_circle_outline,
            ),
            PersonalDataDropdownField(
              fieldKey: _keyExpedido,
              label: 'Expedido en',
              value: _selectedExpedidoEn,
              items: DatosPersonalesConstants.expedidoEnItems,
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
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              label: 'Fecha de Emisión',
              controller: _fechaEmisionController,
              isRequired: false,
              width: width,
              readOnly: true,
              onTap: _pickFechaEmision,
              icon: Icons.event_available_outlined,
            ),
            PersonalDataFormField(
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
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: PersonalDataResponsiveGroup(
            width: width,
            children: [
              PersonalDataDropdownField(
                fieldKey: _keyNacionalidad,
                label: 'Nacionalidad',
                value: _selectedNacionalidad,
                items: DatosPersonalesConstants.nacionalidadItems,
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
              PersonalDataDropdownField(
                label: 'Ciudad de Nacimiento',
                value: _selectedCiudadNacimiento,
                items: DatosPersonalesConstants.ciudadItems,
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
        ),
        SizedBox(height: height * 0.02),
        PersonalDataDropdownField(
          fieldKey: _keyGenero,
          label: 'Género',
          value: _selectedGenero,
          items: DatosPersonalesConstants.generoItems,
          isRequired: true,
          width: width,
          icon: Icons.wc_outlined,
          onChanged: (value) => setState(() => _selectedGenero = value),
        ),
        SizedBox(height: height * 0.02),
        PersonalDataDropdownField(
          label: 'Ciudad de Residencia',
          value: _selectedCiudadResidencia,
          items: DatosPersonalesConstants.ciudadItems,
          isRequired: false,
          width: width,
          icon: Icons.home_work_outlined,
          onChanged: (value) =>
              setState(() => _selectedCiudadResidencia = value),
        ),
        SizedBox(height: height * 0.02),
        PersonalDataFormField(
          label: 'Dirección',
          controller: _direccionController,
          isRequired: false,
          width: width,
          icon: Icons.location_on_outlined,
        ),
        SizedBox(height: height * 0.02),
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              label: 'Nro de Casa',
              controller: _nroCasaController,
              isRequired: false,
              width: width,
              icon: Icons.home_outlined,
            ),
            PersonalDataDropdownField(
              label: 'Estado Civil',
              value: _selectedEstadoCivil,
              items: DatosPersonalesConstants.estadoCivilItems,
              isRequired: false,
              width: width,
              icon: Icons.favorite_border_outlined,
              onChanged: (value) =>
                  setState(() => _selectedEstadoCivil = value),
            ),
          ],
        ),
        SizedBox(height: height * 0.02),
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: const PersonalDataSectionHeader(
            title: 'Informacion de contacto',
            subtitle: 'Metodos para comunicarnos contigo.',
          ),
        ),
        SizedBox(height: height * 0.02),
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              fieldKey: _keyCelular,
              label: 'Celular',
              controller: _celularController,
              isRequired: true,
              width: width,
              icon: Icons.phone_android_outlined,
              customValidator: DatosPersonalesValidators.validateCelular,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            PersonalDataFormField(
              fieldKey: _keyCorreo,
              label: 'Correo Electrónico',
              controller: _correoController,
              isRequired: true,
              width: width,
              icon: Icons.email_outlined,
              customValidator: DatosPersonalesValidators.validateEmail,
            ),
          ],
        ),
        SizedBox(height: height * 0.02),
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              label: 'Teléfono Alternativo',
              controller: _telefonoAlternativoController,
              isRequired: false,
              width: width,
              icon: Icons.phone_outlined,
              customValidator: DatosPersonalesValidators.validateTelefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            PersonalDataFormField(
              label: 'Teléfono de Trabajo',
              controller: _telefonoTrabajoController,
              isRequired: false,
              width: width,
              icon: Icons.phone_in_talk_outlined,
              customValidator: DatosPersonalesValidators.validateTelefono,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        SizedBox(height: height * 0.02),
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: const PersonalDataSectionHeader(
            title: 'Datos de facturacion',
            subtitle: 'Informacion para emitir comprobantes.',
          ),
        ),
        SizedBox(height: height * 0.02),
        PersonalDataResponsiveGroup(
          width: width,
          children: [
            PersonalDataFormField(
              label: 'NIT',
              controller: _nitController,
              isRequired: false,
              width: width,
              icon: Icons.receipt_long_outlined,
            ),
            PersonalDataFormField(
              label: 'Razón Social',
              controller: _razonSocialController,
              isRequired: false,
              width: width,
              icon: Icons.business_outlined,
            ),
          ],
        ),
        SizedBox(height: height * 0.03),
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: const PersonalDataSectionHeader(
            title: 'Respaldo de identidad',
            subtitle: 'Fotocopia de C.I. y foto 4x4.',
          ),
        ),
        SizedBox(height: height * 0.015),
        FadeIn(
          duration: const Duration(milliseconds: 800),
          child: PersonalDataIdentityCard(
            ciFrontPath: _ciFrontPath,
            ciBackPath: _ciBackPath,
            ciPhotocopyPath: _ciPhotocopyPath,
            profilePhotoPath: _profilePhotoPath,
            ciNumber: _numeroCIController.text,
            onTapManage: _navigateToUpload,
          ),
        ),
        SizedBox(height: height * 0.04),
        Semantics(
          button: true,
          label: 'Guardar datos personales',
          child: InkWell(
            onTap: _isSaving ? null : _guardarDatos,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: height * 0.02),
              decoration: BoxDecoration(
                color: _isSaving
                    ? Colors.grey.shade400
                    : DatosPersonalesConstants.primaryBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: DatosPersonalesConstants.primaryBlue.withOpacity(
                      0.3,
                    ),
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
          ),
        ),
      ],
    );
  }

  // ===== DATA LOADING METHODS =====

  Future<void> _loadSavedData() async {
    final savedData = await LocalStorageService.getPersonalData();
    final docs = await LocalStorageService.getParticipantDocumentsData();
    final session = await LocalStorageService.getSessionData();

    if (savedData != null) {
      setState(() {
        _populateControllers(savedData);
        _setDropdownValues(savedData);
      });
    }

    if (mounted &&
        (_nombreController.text.trim().isEmpty &&
            _apPaternoController.text.trim().isEmpty &&
            _apMaternoController.text.trim().isEmpty)) {
      final nombreUsuario = (session?['nombreUsuario'] as String?)?.trim();
      if (nombreUsuario != null && nombreUsuario.isNotEmpty) {
        _populateFromSession(nombreUsuario);
      }
    }

    if (docs != null && mounted) {
      setState(() {
        _ciFrontPath = docs['ci_front_path'] as String?;
        _ciBackPath = docs['ci_back_path'] as String?;
        _ciPhotocopyPath = docs['ci_photocopy_pdf_path'] as String?;
        _profilePhotoPath = docs['profile_photo_path'] as String?;
      });
    }

    await _loadProfileImage();
    await _loadSignature();

    final ocrData = await getPendingOcrData();
    if (ocrData != null && mounted) {
      setState(() => _pendingOcrData = ocrData);
    }
  }

  void _populateControllers(Map<String, dynamic> savedData) {
    _nombreController.text = DatosPersonalesHelpers.str(savedData['nombre']);
    _apPaternoController.text = DatosPersonalesHelpers.str(
      savedData['apPaterno'],
    );
    _apMaternoController.text = DatosPersonalesHelpers.str(
      savedData['apMaterno'],
    );
    _fechaNacimientoController.text = DatosPersonalesHelpers.str(
      savedData['fechaNacimiento'],
    );
    _numeroCIController.text = DatosPersonalesHelpers.str(
      savedData['numeroCI'],
    );
    _complementoController.text = DatosPersonalesHelpers.str(
      savedData['complemento'],
    );
    _direccionController.text = DatosPersonalesHelpers.str(
      savedData['direccion'],
    );
    _nroCasaController.text = DatosPersonalesHelpers.str(savedData['nroCasa']);
    _celularController.text = DatosPersonalesHelpers.str(savedData['celular']);
    _correoController.text = DatosPersonalesHelpers.str(savedData['correo']);
    _telefonoAlternativoController.text = DatosPersonalesHelpers.str(
      savedData['telefonoAlternativo'],
    );
    _telefonoTrabajoController.text = DatosPersonalesHelpers.str(
      savedData['telefonoTrabajo'],
    );
    _nitController.text = DatosPersonalesHelpers.str(savedData['nit']);
    _razonSocialController.text = DatosPersonalesHelpers.str(
      savedData['razonSocial'],
    );
    _fechaEmisionController.text = DatosPersonalesHelpers.str(
      savedData['fechaEmision'],
    );
    _fechaExpiracionController.text = DatosPersonalesHelpers.str(
      savedData['fechaExpiracion'],
    );
  }

  void _setDropdownValues(Map<String, dynamic> savedData) {
    _selectedExpedidoEn = DatosPersonalesHelpers.matchDropdownItem(
      DatosPersonalesHelpers.str(savedData['expedidoEn']),
      DatosPersonalesConstants.expedidoEnItems,
    );
    if (_selectedExpedidoEn != null) {
      _expedidoEnController.text = _selectedExpedidoEn!;
    }

    _selectedNacionalidad = DatosPersonalesHelpers.matchDropdownItem(
      DatosPersonalesHelpers.str(savedData['nacionalidad']),
      DatosPersonalesConstants.nacionalidadItems,
    );
    _nacionalidadController.text =
        _selectedNacionalidad ??
        DatosPersonalesHelpers.str(savedData['nacionalidad']);

    _selectedGenero = DatosPersonalesHelpers.matchDropdownItem(
      DatosPersonalesHelpers.str(savedData['genero']),
      DatosPersonalesConstants.generoItems,
    );

    _selectedCiudadNacimiento = DatosPersonalesHelpers.matchDropdownItem(
      DatosPersonalesHelpers.str(savedData['ciudadNacimiento']),
      DatosPersonalesConstants.ciudadItems,
    );
    _ciudadNacimientoController.text =
        _selectedCiudadNacimiento ??
        DatosPersonalesHelpers.str(savedData['ciudadNacimiento']);

    _selectedCiudadResidencia = DatosPersonalesHelpers.matchDropdownItem(
      DatosPersonalesHelpers.str(savedData['ciudadResidencia']),
      DatosPersonalesConstants.ciudadItems,
    );
    _ciudadResidenciaController.text =
        _selectedCiudadResidencia ??
        DatosPersonalesHelpers.str(savedData['ciudadResidencia']);

    _selectedEstadoCivil = DatosPersonalesHelpers.matchDropdownItem(
      DatosPersonalesHelpers.str(savedData['estadoCivil']),
      DatosPersonalesConstants.estadoCivilItems,
    );
  }

  void _populateFromSession(String nombreUsuario) {
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

  Future<void> _loadProfileImage() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (imageFile != null && mounted) {
      setState(() => _profileImage = imageFile);
    } else if (_profilePhotoPath != null && mounted) {
      final photoFile = File(_profilePhotoPath!);
      try {
        if (await photoFile.exists()) {
          setState(() => _profileImage = photoFile);
        }
      } catch (e) {
        debugPrint('Error al cargar foto 4x4: $e');
      }
    }
  }

  Future<void> _loadSignature() async {
    final firmaPath = await LocalStorageService.getSignatureImagePath();
    if (firmaPath != null && mounted && File(firmaPath).existsSync()) {
      setState(() => _signatureImagePath = firmaPath);
    }
  }

  // ===== OCR METHODS =====

  void _aplicarOcrData() {
    if (_pendingOcrData == null) return;

    setState(() {
      _applyOcrToControllers();
      _pendingOcrData = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.validate();
    });

    PremiumAlerts.showSuccess(
      context,
      'Datos recuperados exitosamente de tu Cédula de Identidad',
      title: 'OCR Exitoso',
    );
  }

  void _applyOcrToControllers() {
    final nombres = _pendingOcrData!['nombres']?.toString().trim() ?? '';
    if (nombres.isNotEmpty && _nombreController.text.isEmpty) {
      _nombreController.text = nombres.toUpperCase();
    }

    final apellidos = _pendingOcrData!['apellidos']?.toString().trim() ?? '';
    if (apellidos.isNotEmpty) {
      final parts = apellidos
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isNotEmpty && _apPaternoController.text.isEmpty) {
        _apPaternoController.text = parts[0].toUpperCase();
      }
      if (parts.length > 1 && _apMaternoController.text.isEmpty) {
        _apMaternoController.text = parts.sublist(1).join(' ').toUpperCase();
      }
    }

    if (_numeroCIController.text.isEmpty) {
      final ci = _pendingOcrData!['numeroDocumento']?.toString().trim() ?? '';
      if (ci.isNotEmpty) _numeroCIController.text = ci;
    }

    if (_fechaNacimientoController.text.isEmpty &&
        _pendingOcrData!['fechaNacimiento'] != null) {
      _fechaNacimientoController.text = _pendingOcrData!['fechaNacimiento']
          .toString();
    }

    if (_selectedCiudadNacimiento == null) {
      final lugarNacimiento =
          _pendingOcrData!['lugarNacimiento']
              ?.toString()
              .trim()
              .toUpperCase() ??
          '';
      if (lugarNacimiento.isNotEmpty) {
        for (final ciudad in DatosPersonalesConstants.ciudadItems) {
          if (lugarNacimiento.contains(ciudad)) {
            _selectedCiudadNacimiento = ciudad;
            _ciudadNacimientoController.text = ciudad;
            break;
          }
        }
      }
    }

    if (_fechaEmisionController.text.isEmpty &&
        _pendingOcrData!['fechaEmision'] != null) {
      _fechaEmisionController.text = _pendingOcrData!['fechaEmision']
          .toString();
    }

    if (_fechaExpiracionController.text.isEmpty &&
        _pendingOcrData!['fechaExpiracion'] != null) {
      _fechaExpiracionController.text = _pendingOcrData!['fechaExpiracion']
          .toString();
    }
  }

  // ===== VALIDATION METHODS =====

  double _getFormProgress() {
    return DatosPersonalesHelpers.calculateFormProgress(
      nombre: _nombreController.text,
      apPaterno: _apPaternoController.text,
      apMaterno: _apMaternoController.text,
      expedidoEn: _selectedExpedidoEn,
      expedidoEnController: _expedidoEnController.text,
      genero: _selectedGenero,
      nacionalidad: _selectedNacionalidad,
      celular: _celularController.text,
      correo: _correoController.text,
    );
  }

  String? _validateApellidoPaterno(String? value) {
    return DatosPersonalesValidators.validateApellidoPaterno(
      value,
      _apMaternoController.text,
    );
  }

  String? _validateApellidoMaterno(String? value) {
    return DatosPersonalesValidators.validateApellidoMaterno(
      value,
      _apPaternoController.text,
    );
  }

  // ===== DATE PICKER METHODS =====

  Future<void> _pickFechaNacimiento() async {
    final initialDate =
        DatosPersonalesHelpers.parseSavedDate(
          _fechaNacimientoController.text,
        ) ??
        DateTime(DateTime.now().year - 25, 1, 1);

    final picked = await mostrarIosFechaPicker(
      context: context,
      initialDate: initialDate,
      titulo: 'Fecha de Nacimiento',
      esFechaNacimiento: true,
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaNacimientoController.text = DatosPersonalesHelpers.formatDate(
          picked,
        );
      });
    }
  }

  Future<void> _pickFechaEmision() async {
    final initialDate =
        DatosPersonalesHelpers.parseSavedDate(_fechaEmisionController.text) ??
        DateTime.now();

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
        _fechaEmisionController.text = DatosPersonalesHelpers.formatDate(
          picked,
        );
      });
    }
  }

  Future<void> _pickFechaExpiracion() async {
    final initialDate =
        DatosPersonalesHelpers.parseSavedDate(
          _fechaExpiracionController.text,
        ) ??
        DateTime.now().add(const Duration(days: 365 * 10));

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
        _fechaExpiracionController.text = DatosPersonalesHelpers.formatDate(
          picked,
        );
      });
    }
  }

  // ===== IMAGE METHODS =====

  Future<void> _refreshProfileImageIfNeeded() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    File? finalImage = imageFile;

    if (finalImage == null) {
      final docs = await LocalStorageService.getParticipantDocumentsData();
      final photoPath = docs?['profile_photo_path'] as String?;
      if (photoPath != null) {
        final photoFile = File(photoPath);
        if (await photoFile.exists()) {
          finalImage = photoFile;
        }
      }
    }

    if (!mounted) return;

    final currentPath = _profileImage?.path ?? '';
    final nextPath = finalImage?.path ?? '';

    bool shouldUpdate = false;
    if (nextPath.isNotEmpty && nextPath != currentPath) {
      shouldUpdate = true;
    } else if (nextPath.isNotEmpty && currentPath.isNotEmpty) {
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

    if (shouldUpdate || (_profileImage == null && finalImage != null)) {
      setState(() => _profileImage = finalImage);
      debugPrint('✅ Foto de perfil actualizada en Mis Datos Personales');
    }
  }

  Future<void> _pickImage() async {
    bool loaderShown = false;
    bool processingDialogShown = false;

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
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
        if (navigator.canPop()) navigator.pop();
        loaderShown = false;
      }

      if (image != null) {
        final fileSize = await File(image.path).length();
        const maxSize = 3.1 * 1024 * 1024;
        if (fileSize > maxSize) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('El archivo excede el tamaño máximo de 3.1MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        if (mounted) {
          processingDialogShown = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const DialogoProcesamientoMagico(),
          );
        }

        final processedImage =
            await ProfileImageProcessorService.processProfileImage(
              File(image.path),
              isFirstPhoto: true,
            );

        debugPrint('🔍 Imagen procesada: ${processedImage?.path}');
        if (processedImage != null) {
          final size = await processedImage.length();
          debugPrint(
            '🔍 Tamaño archivo procesado: ${(size / 1024).toStringAsFixed(2)} KB',
          );
        }

        if (!mounted) return;
        if (processingDialogShown) {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) navigator.pop();
          processingDialogShown = false;
        }

        if (processedImage != null) {
          final savedPath = await LocalStorageService.saveProfileImage(
            processedImage,
          );
          if (savedPath != null && mounted) {
            await FileImage(File(savedPath)).evict();
            await Future.delayed(const Duration(milliseconds: 100));

            setState(() => _profileImage = File(savedPath));

            try {
              context.read<PerfilBloc>().add(LoadPerfilData());
            } catch (_) {}

            PremiumAlerts.showSuccess(
              context,
              'Fondo removido y aplicado fondo institucional',
              title: 'Foto Procesada',
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        if (processingDialogShown || loaderShown) {
          final navigator = Navigator.of(context, rootNavigator: true);
          if (navigator.canPop()) navigator.pop();
        }
      }
      PremiumAlerts.showError(context, 'Error al seleccionar imagen: $e');
    }
  }

  Future<void> _pickSignature() async {
    HapticFeedback.lightImpact();
    final resultPath = await context.pushNamed<String>('pantalla_firma');
    if (resultPath != null && mounted) {
      await FileImage(File(resultPath)).evict();
      setState(() => _signatureImagePath = resultPath);
    }
  }

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
                    child: Image.file(_profileImage!, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
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
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
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
                    backgroundColor: DatosPersonalesConstants.primaryBlue,
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

  void _navigateToUpload() {
    context.push('/upload-ci', extra: {'ci': _numeroCIController.text});
  }

  // ===== SAVE METHODS =====

  Future<void> _guardarDatos() async {
    final nombreOk = _nombreController.text.trim().isNotEmpty;
    final tieneApellido =
        _apPaternoController.text.trim().isNotEmpty ||
        _apMaternoController.text.trim().isNotEmpty;
    final celularOk =
        _celularController.text.trim().isEmpty ||
        _celularController.text.trim().length == 8;
    final correoOk =
        _correoController.text.trim().isEmpty ||
        RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_correoController.text.trim());

    if (!nombreOk || !tieneApellido) {
      vibrateOnError(context);
      _scrollToFirstError();
      if (mounted) {
        PremiumAlerts.showError(
          context,
          'Ingrese al menos el nombre y un apellido.',
        );
      }
      return;
    }

    if (!celularOk) {
      vibrateOnError(context);
      if (mounted) {
        PremiumAlerts.showError(context, 'El celular debe tener 8 dígitos.');
      }
      return;
    }

    if (!correoOk) {
      vibrateOnError(context);
      if (mounted) {
        PremiumAlerts.showError(
          context,
          'Ingrese un correo electrónico válido.',
        );
      }
      return;
    }

    vibrateHeavy(context);
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      debugPrint('💾 Intentando guardar datos personales...');

      final existing = await LocalStorageService.getPersonalData();

      final personalData = DatosPersonalesHelpers.buildPersonalData(
        nombre: _nombreController.text,
        apPaterno: _apPaternoController.text,
        apMaterno: _apMaternoController.text,
        fechaNacimiento: _fechaNacimientoController.text,
        numeroCI: _numeroCIController.text,
        complemento: _complementoController.text,
        selectedExpedidoEn: _selectedExpedidoEn,
        expedidoEnController: _expedidoEnController.text,
        selectedNacionalidad: _selectedNacionalidad,
        nacionalidadController: _nacionalidadController.text,
        selectedCiudadNacimiento: _selectedCiudadNacimiento,
        ciudadNacimientoController: _ciudadNacimientoController.text,
        selectedGenero: _selectedGenero,
        selectedCiudadResidencia: _selectedCiudadResidencia,
        direccion: _direccionController.text,
        nroCasa: _nroCasaController.text,
        celular: _celularController.text,
        correo: _correoController.text,
        telefonoAlternativo: _telefonoAlternativoController.text,
        telefonoTrabajo: _telefonoTrabajoController.text,
        nit: _nitController.text,
        razonSocial: _razonSocialController.text,
        fechaEmision: _fechaEmisionController.text,
        fechaExpiracion: _fechaExpiracionController.text,
        existing: existing,
      );

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

      await LocalStorageService.savePersonalData(personalData);

      if (!mounted) return;
      setState(() => _isSaving = false);
      await Future.delayed(const Duration(milliseconds: 100));

      final verificacion = await LocalStorageService.getPersonalData();
      if (verificacion == null) {
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          PremiumAlerts.showError(context, 'No se pudo verificar el guardado.');
        }
        return;
      }

      if (verificacion['nombre']?.toString().trim() !=
          personalData['nombre']?.toString().trim()) {
        if (mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          PremiumAlerts.showError(
            context,
            'Los datos no se guardaron correctamente. Intente de nuevo.',
          );
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
              Expanded(child: Text('Datos guardados correctamente')),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (!context.mounted) return;

      try {
        context.read<PerfilBloc>().add(LoadPerfilData());
      } catch (_) {}

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
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _scrollToFirstError() {
    final Map<GlobalKey, bool> fieldStates = {
      _keyNombre: _nombreController.text.trim().isEmpty,
      _keyApellidos:
          _apPaternoController.text.trim().isEmpty &&
          _apMaternoController.text.trim().isEmpty,
      _keyExpedido: (_selectedExpedidoEn ?? _expedidoEnController.text)
          .trim()
          .isEmpty,
      _keyNacionalidad: (_selectedNacionalidad ?? _nacionalidadController.text)
          .trim()
          .isEmpty,
      _keyGenero: (_selectedGenero ?? '').trim().isEmpty,
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
}
