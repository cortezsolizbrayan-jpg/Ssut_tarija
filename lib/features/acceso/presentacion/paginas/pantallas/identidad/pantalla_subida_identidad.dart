import 'dart:async';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/widgets/ios_date_picker.dart';

import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/animations/custom_animations.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/documentos/servicio_compositor_cartas_ci.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_turbo_ram.dart';
import 'package:refactor_template/features/acceso/presentacion/bloques/identity/identity_bloc.dart';
import 'package:refactor_template/features/acceso/presentacion/bloques/identity/identity_event.dart';
import 'package:refactor_template/features/acceso/presentacion/bloques/identity/identity_state.dart';
import 'package:refactor_template/features/acceso/presentacion/mixins/identity_ocr_mixin.dart';
import 'package:refactor_template/features/acceso/presentacion/componentes/fondo_azul_curvo_widget.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantalla_subida_identidad/tareas/tareas_carga_imagen_ci.dart';

class IDUploadPantalla extends StatefulWidget {
  static const name = 'id-upload-Pantalla';
  final String? initialCI;

  const IDUploadPantalla({super.key, this.initialCI});

  @override
  State<IDUploadPantalla> createState() => _IDUploadPantallaState();
}

class _IDUploadPantallaState extends State<IDUploadPantalla>
    with IdentityOcrMixin, TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _fechaExpiracionController =
      TextEditingController();

  late AnimationController _scanController;
  bool _showCorrectionForm = false;
  bool _loaderIsOpen = false;
  bool _frontProcessing = false;
  bool _backProcessing = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    if (widget.initialCI != null) _ciController.text = widget.initialCI!;
    // Pre-inicializar el TextRecognizer para cargar modelos TFLite en background
    Future.delayed(const Duration(milliseconds: 300), () {
      ServicioOcrTurboRam.inicializarRecognizer();
    });
  }

  @override
  void dispose() {
    _ciController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _fechaEmisionController.dispose();
    _fechaExpiracionController.dispose();
    _scanController.dispose();
    // Liberar el TextRecognizer persistente al salir
    ServicioOcrTurboRam.liberarRecognizer();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  LÓGICA DE CAPTURA ASÍNCRONA (SIN COLGARSE)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showPickerOptions(bool isFront) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _buildPickerSheet(isFront),
    );
  }

  Future<void> _handleCamera(bool isFront) async {
    Navigator.pop(context);
    final res = await context.push<String?>(
      '/id-camera-capture',
      extra: {'isFront': isFront},
    );
    if (res != null) _processImageAsync(res, isFront, fromCamera: true);
  }

  Future<void> _handleGallery(bool isFront) async {
    Navigator.pop(context);
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (photo != null) _processImageAsync(photo.path, isFront);
  }

  Future<void> _handlePdfPick() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (res != null && res.files.single.path != null) {
      final file = File(res.files.single.path!);
      context.read<IdentityBloc>().add(IdentityPdfFileChanged(file));
      _showSuccessSnackBar("✅ PDF de Carnet cargado");
    }
  }

  Future<void> _processImageAsync(
    String path,
    bool isFront, {
    bool fromCamera = false,
  }) async {
    try {
      if (mounted) {
        setState(() {
          if (isFront) {
            _frontProcessing = true;
          } else {
            _backProcessing = true;
          }
        });
      }
      context.read<IdentityBloc>().add(IdentityCaptureStarted(isFront));

      // 1. Mostrar Loader inmediatamente
      _showPremiumLoader(
        isFront ? "Analizando Anverso..." : "Analizando Reverso...",
      );

      // 2. Normalizar imagen
      File baseFile = File(path);
      if (fromCamera) {
        baseFile = await compute(cropImageTask, {
          'inputPath': path,
          'outputPath': '${path}_c.jpg',
          'useCenterFrame': true,
        });
      }

      if (mounted) {
        _updateLoaderMessage(
          isFront ? "Normalizando imagen..." : "Procesando reverso...",
        );
      }
      final normFile = await compute(normalizeImageTask, {
        'inputPath': baseFile.path,
        'outputPath': '${baseFile.path}_n.jpg',
      });

      // 3. Copiar a ubicación permanente para evitar que se elimine
      final permDir = await getApplicationDocumentsDirectory();
      final permFileName =
          'ci_${isFront ? 'front' : 'back'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final permFile = await normFile.copy('${permDir.path}/$permFileName');

      // 4. Actualizar Estado con la imagen permanente
      if (isFront) {
        context.read<IdentityBloc>().add(IdentityFrontImageChanged(permFile));
      } else {
        context.read<IdentityBloc>().add(IdentityBackImageChanged(permFile));
      }

      // 5. Persistir para carta (usar archivo permanente)
      unawaited(_persistForLetter(permFile, isFront));
    } catch (e) {
      _showErrorSnackBar("Error: $e");
    } finally {
      _dismissLoader();
      if (mounted) {
        setState(() {
          if (isFront) {
            _frontProcessing = false;
          } else {
            _backProcessing = false;
          }
        });
      }
    }
  }

  /// Actualiza el mensaje del loader sin cerrarlo
  void _updateLoaderMessage(String msg) {
    if (!_loaderIsOpen || !mounted) return;
    try {
      Navigator.of(context, rootNavigator: true).pop();
      _loaderIsOpen = false;
    } catch (_) {}
    _showPremiumLoader(msg);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  UI - RESTAURACIÓN FIEL (FONDO AZUL CURVO + PDF)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<IdentityBloc, IdentityState>(
      listener: (context, state) {
        if (state.status == IdentityStatus.success) {
          _onOcrSuccess(state.extractedData!);
          if (mounted) {
            setState(() {
              _frontProcessing = false;
              _backProcessing = false;
            });
          }
        }
        if (state.status == IdentityStatus.error) {
          _dismissLoader();
          _showErrorSnackBar(state.errorMessage ?? "Error en análisis");
          if (mounted) {
            setState(() {
              _frontProcessing = false;
              _backProcessing = false;
            });
          }
        }
        // Mostrar loader cuando el Bloc inicia el análisis automático
        if (state.status == IdentityStatus.loading && !_loaderIsOpen) {
          _showPremiumLoader(
            state.scanningMessage.isNotEmpty
                ? state.scanningMessage
                : "Analizando documentos...",
          );
        }
        // Actualizar mensaje del loader si ya está abierto
        if (state.status == IdentityStatus.loading &&
            _loaderIsOpen &&
            state.scanningMessage.isNotEmpty) {
          _updateLoaderMessage(state.scanningMessage);
        }
        // Auto-disparar análisis cuando ambas imágenes estén listas
        if (state.status == IdentityStatus.initial &&
            state.frontImage != null &&
            state.backImage != null &&
            !_frontProcessing &&
            !_backProcessing) {
          // Pequeño delay para que la UI muestre la segunda imagen antes de procesar
          Future.delayed(const Duration(milliseconds: 600), () {
            if (mounted && !_showCorrectionForm) {
              context.read<IdentityBloc>().add(
                IdentityProcessStarted(isPdfMode: false),
              );
            }
          });
        }
        // Estado initial = imagen cargada pero no procesada aún, cerrar loader
        if (state.status == IdentityStatus.initial) {
          if (_loaderIsOpen) _dismissLoader();
          if (mounted) {
            setState(() {
              _frontProcessing = false;
              _backProcessing = false;
            });
          }
        }
      },
      builder: (context, state) => Scaffold(
        backgroundColor: DesignTokens.mainBackground,
        body: Stack(
          children: [
            _buildMainBody(state),
            if (_showCorrectionForm) _buildCorrectionOverlay(state),
          ],
        ),
      ),
    );
  }

  Widget _buildMainBody(IdentityState state) {
    return Column(
      children: [
        // 1. CABECERA COMPACTA
        FondoAzulCurvoWidget(
          height: 130,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Registro de Identidad",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: DesignTokens.secondaryFont,
                          ),
                        ),
                        Text(
                          "Sube tu carnet vigente para validar tu perfil",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // INDICADOR DE PASOS
                  _buildSteps(state),
                  const SizedBox(height: 20),

                  // TARJETAS DE CARGA
                  if (!state.isPdfMode) ...[
                    _buildCard(
                      title: "Lado Frontal (Anverso)",
                      icon: Icons.person_pin_rounded,
                      file: state.frontImage,
                      onTap: () => _showPickerOptions(true),
                      isProcessing: _frontProcessing,
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      title: "Lado Posterior (Reverso)",
                      icon: Icons.credit_card_rounded,
                      file: state.backImage,
                      onTap: () => _showPickerOptions(false),
                      isProcessing: _backProcessing,
                    ),
                  ] else
                    _buildPdfActiveIndicator(state),

                  const SizedBox(height: 16),
                  _buildPdfToggle(state),
                  const SizedBox(height: 16),
                  _buildFinalAction(state),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(IdentityState state) {
    int current = state.status == IdentityStatus.success ? 3 : 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _step(1, "Captura", current >= 1),
        _line(current >= 2),
        _step(2, "Análisis", current >= 2),
        _line(current >= 3),
        _step(3, "Validación", current >= 3),
      ],
    );
  }

  Widget _step(int n, String lb, bool active) => Column(
    children: [
      Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? DesignTokens.primaryBlue : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? DesignTokens.primaryBlue : Colors.grey[300]!,
            width: 2,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: DesignTokens.primaryBlue.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            "$n",
            style: TextStyle(
              color: active ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        lb,
        style: TextStyle(
          fontSize: 10,
          color: active ? DesignTokens.primaryBlue : Colors.grey,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );

  Widget _line(bool active) => Expanded(
    child: Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20, left: 8, right: 8),
      color: active ? DesignTokens.primaryBlue : Colors.grey[200],
    ),
  );

  Widget _buildCard({
    required String title,
    required IconData icon,
    File? file,
    required VoidCallback onTap,
    bool isProcessing = false,
  }) {
    return FadeInUp(
      child: GestureDetector(
        onTap: isProcessing ? null : onTap,
        child: Container(
          height: 145,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: file != null
                  ? DesignTokens.primaryBlue
                  : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (file != null)
                  Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 36,
                          color: DesignTokens.primaryBlue.withOpacity(0.2),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "Toca para capturar",
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isProcessing)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfToggle(IdentityState state) {
    if (state.isPdfMode) return const SizedBox.shrink();
    return TextButton.icon(
      onPressed: _handlePdfPick,
      icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.blueGrey),
      label: const Text(
        "¿Tienes tu carnet escaneado en PDF?",
        style: TextStyle(
          color: Colors.blueGrey,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPdfActiveIndicator(IdentityState state) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.green[50],
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.green),
    ),
    child: Row(
      children: [
        const Icon(Icons.picture_as_pdf, color: Colors.green, size: 30),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ARCHIVO PDF CARGADO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              Text(
                state.pdfFile?.path.split('/').last ?? "carnet.pdf",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () =>
              context.read<IdentityBloc>().add(const IdentityReset()),
          icon: const Icon(Icons.close, color: Colors.red),
        ),
      ],
    ),
  );

  Widget _buildFinalAction(IdentityState state) {
    final ambasListas =
        state.frontImage != null && state.backImage != null && !state.isPdfMode;

    // Si ambas imágenes están listas y el formulario está cerrado,
    // mostrar botón para re-analizar (evita quedar atrapado)
    if (ambasListas && !_showCorrectionForm) {
      return ScaleInAnimation(
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: DesignTokens.primaryBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: () => context.read<IdentityBloc>().add(
              IdentityProcessStarted(isPdfMode: false),
            ),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            label: const Text(
              'ANALIZAR CARNET',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ),
      );
    }

    // Si el formulario está abierto, no mostrar botón
    if (ambasListas && _showCorrectionForm) {
      return const SizedBox.shrink();
    }

    final bool ready =
        (state.frontImage != null && state.backImage != null) ||
        state.isPdfMode;

    return ScaleInAnimation(
      child: Container(
        width: double.infinity,
        height: 62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: ready
              ? [
                  BoxShadow(
                    color: DesignTokens.primaryBlue.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: ready
              ? () => context.read<IdentityBloc>().add(
                  IdentityProcessStarted(isPdfMode: state.isPdfMode),
                )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: ready
                ? DesignTokens.primaryBlue
                : Colors.grey[300],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0,
          ),
          child: Text(
            ready ? 'CONTINUAR ANÁLISIS' : 'CARGA LAS FOTOS PARA EMPEZAR',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  OVERLAY DE CORRECCIÓN (RESTORED)
  // ═══════════════════════════════════════════════════════════════════════════

  void _onOcrSuccess(Map<String, dynamic> data) {
    // Palabras que NO son nombres válidos (ruido del OCR del carnet boliviano)
    const palabrasRuido = {
      'SERIE',
      'SERIES',
      'NUMERO',
      'NÚMERO',
      'CI',
      'CEDULA',
      'CÉDULA',
      'IDENTIDAD',
      'BOLIVIANA',
      'BOLIVIA',
      'ESTADO',
      'PLURINACIONAL',
    };

    String limpiarCampo(String? valor) {
      if (valor == null || valor.isEmpty) return '';
      final upper = valor.trim().toUpperCase();
      if (palabrasRuido.contains(upper)) return '';
      // Si todas las palabras son ruido, retornar vacío
      final palabras = upper.split(RegExp(r'\s+'));
      if (palabras.every((p) => palabrasRuido.contains(p))) return '';
      return valor.trim();
    }

    String manejarExpiracion(String? valor) {
      if (valor == null || valor.isEmpty) return '';
      final upper = valor.trim().toUpperCase();
      // Manejar "ILIMITADO" o variantes
      if (upper.contains('ILIMITADO') ||
          upper.contains('INDEFINIDO') ||
          upper.contains('PERMANENTE')) {
        return 'ILIMITADO';
      }
      return _fmtDate(valor);
    }

    setState(() {
      _ciController.text = data['ci'] ?? "";
      _nombresController.text = limpiarCampo(data['nombres']?.toString());
      _apellidosController.text = limpiarCampo(data['apellidos']?.toString());
      _fechaEmisionController.text = _fmtDate(data['fechaEmision'] ?? "");
      _fechaExpiracionController.text = manejarExpiracion(
        data['fechaExpiracion']?.toString(),
      );
      _showCorrectionForm = true;
    });
    _dismissLoader();
  }

  Widget _buildCorrectionOverlay(IdentityState state) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: FadeInUp(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 44),
                const SizedBox(height: 8),
                const Text(
                  "Validar Datos",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A3A5C),
                  ),
                ),
                const SizedBox(height: 16),
                _input(
                  _ciController,
                  "Cédula de Identidad",
                  Icons.badge_outlined,
                ),
                _input(_nombresController, "Nombres", Icons.person_outline),
                _input(_apellidosController, "Apellidos", Icons.people_outline),
                Row(
                  children: [
                    Expanded(
                      child: _input(
                        _fechaEmisionController,
                        "Emisión",
                        Icons.calendar_today,
                        readOnly: true,
                        onTap: () =>
                            _pickDate("Emisión", _fechaEmisionController),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _input(
                        _fechaExpiracionController,
                        "Expiración",
                        Icons.event_available,
                        readOnly: true,
                        onTap: () =>
                            _pickDate("Expiración", _fechaExpiracionController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF005BAC),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      "Confirmar y Continuar",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _showCorrectionForm = false),
                  child: const Text(
                    "Volver a tomar fotos",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _input(
    TextEditingController c,
    String lb,
    IconData i, {
    bool readOnly = false,
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.black87, fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(i, color: DesignTokens.primaryBlue),
        labelText: lb,
        labelStyle: const TextStyle(color: Color(0xFF005BAC)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF005BAC), width: 1.5),
        ),
      ),
    ),
  );

  // ─── Utilidades ───
  void _showPremiumLoader(String msg) {
    if (_loaderIsOpen) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
    }
    _loaderIsOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (ctx) => _OcrLoaderDialog(message: msg),
    );
  }

  void _dismissLoader() {
    if (_loaderIsOpen) {
      try {
        Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      _loaderIsOpen = false;
    }
  }

  void _showErrorSnackBar(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.redAccent));
  void _showSuccessSnackBar(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.green));
  String _fmtDate(String d) => d.contains('/')
      ? d
      : (d.length == 8
            ? "${d.substring(0, 2)}/${d.substring(2, 4)}/${d.substring(4)}"
            : d);
  Future<void> _pickDate(String l, TextEditingController c) async {
    final bool esExpiracion = l.toLowerCase().contains('expira');
    final res = await mostrarIosFechaPicker(
      context: context,
      initialDate: DateTime.now(),
      titulo: l,
      maximumYear: esExpiracion
          ? DateTime.now().year + 20
          : DateTime.now().year,
    );
    if (res != null) {
      c.text =
          "${res.day.toString().padLeft(2, '0')}/${res.month.toString().padLeft(2, '0')}/${res.year}";
    }
  }

  Future<void> _persistForLetter(File f, bool isFront) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory("${dir.path}/participant_documents");
    if (!await outDir.exists()) await outDir.create(recursive: true);
    final dest = File(
      "${outDir.path}/${isFront ? 'ci_front_latest.jpg' : 'ci_back_latest.jpg'}",
    );
    await f.copy(dest.path);
    final current =
        await LocalStorageService.getParticipantDocumentsData() ?? {};
    current[isFront ? 'ci_front_path' : 'ci_back_path'] = dest.path;
    await LocalStorageService.saveParticipantDocumentsData(current);
    if (current['ci_front_path'] != null && current['ci_back_path'] != null) {
      final out = await ServicioCompositorCartasCi.composeLetterFromCiImages(
        front: File(current['ci_front_path']),
        back: File(current['ci_back_path']),
      );
      if (out != null) {
        current['ci_letter_path'] = out.path;
        await LocalStorageService.saveParticipantDocumentsData(current);
      }
    }
  }

  void _confirm() {
    if (_ciController.text.isEmpty || _nombresController.text.isEmpty) {
      _showErrorSnackBar("Datos incompletos");
      return;
    }
    context.push(
      '/face-recognition',
      extra: {
        'ci': _ciController.text.replaceAll(RegExp(r'\D'), ''),
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'fechaEmision': _fechaEmisionController.text.trim(),
        'fechaExpiracion': _fechaExpiracionController.text.trim(),
      },
    );
  }

  Widget _buildPickerSheet(bool isFront) => SlideInUp(
    child: Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 45),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            isFront ? "Subir Anverso" : "Subir Reverso",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: _pickBtn(
                  Icons.camera_alt,
                  "Cámara",
                  DesignTokens.primaryBlue,
                  () => _handleCamera(isFront),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _pickBtn(
                  Icons.photo_library,
                  "Galería",
                  DesignTokens.warningOrange,
                  () => _handleGallery(isFront),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _pickBtn(IconData i, String lb, Color c, VoidCallback t) =>
      ElevatedButton(
        onPressed: t,
        style: ElevatedButton.styleFrom(
          backgroundColor: c,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Icon(i, size: 28),
            const SizedBox(height: 8),
            Text(lb, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

// ── Loader OCR con animación que NO se congela aunque el hilo esté ocupado ──
// Usa Timer periódico para rotar mensajes y LinearProgressIndicator nativo
class _OcrLoaderDialog extends StatefulWidget {
  final String message;
  const _OcrLoaderDialog({required this.message});

  @override
  State<_OcrLoaderDialog> createState() => _OcrLoaderDialogState();
}

class _OcrLoaderDialogState extends State<_OcrLoaderDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  int _dotCount = 1;
  int _msgIndex = 0;
  Timer? _msgTimer;

  // Mensajes rotativos para dar sensación de progreso
  static const _mensajes = [
    'Procesando imagen...',
    'Leyendo texto del documento...',
    'Extrayendo datos del carnet...',
    'Identificando CI y nombres...',
    'Casi listo...',
  ];

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    // Rotar mensajes cada 2.5 segundos
    _msgTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        setState(() {
          _msgIndex = (_msgIndex + 1) % _mensajes.length;
          _dotCount = (_dotCount % 3) + 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _dotController.dispose();
    _msgTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dots = '.' * _dotCount;
    final msg = _msgIndex == 0 ? widget.message : _mensajes[_msgIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono animado con pulso
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1.1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
              builder: (_, scale, hijo) =>
                  Transform.scale(scale: scale, child: hijo),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: DesignTokens.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.document_scanner_rounded,
                  color: DesignTokens.primaryBlue,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mensaje rotativo
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(
                '$msg$dots',
                key: ValueKey(_msgIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.primaryBlue,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // LinearProgressIndicator - más estable que Circular en hilo ocupado
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                minHeight: 4,
                valueColor: AlwaysStoppedAnimation<Color>(
                  DesignTokens.primaryBlue,
                ),
                backgroundColor: Color(0xFFE3EDF7),
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Por favor espera, esto puede tomar unos segundos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
