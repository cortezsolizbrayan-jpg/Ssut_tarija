import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_ia_avanzado.dart';
import 'package:refactor_template/features/sistema/core/errors/ocr_excepciones.dart';
import 'package:refactor_template/features/sistema/core/theme/app_colors_escaneo.dart';
import 'package:refactor_template/features/sistema/domain/usecases/procesar_documento_usecase.dart';

// ============================================================================
/// 🔍 PANTALLA DE ESCANEO INTELIGENTE CON IA - V0.5.0
///
/// OCR avanzado con Google ML Kit para documentos de identidad.
///
/// FLUJO:
/// 1. Captura de imagen (cámara/galería)
/// 2. Preprocesamiento y OCR con ML Kit
/// 3. Análisis y estructurado con IA
/// 4. Retorno del resultado estructurado
// ============================================================================

class PantallaEscaneoInteligente extends StatefulWidget {
  static const name = 'pantalla-escaneo-inteligente';

  final TipoDocumento? tipoEsperado;
  final Function(ResultadoOcrIA)? onResultado;

  const PantallaEscaneoInteligente({
    super.key,
    this.tipoEsperado,
    this.onResultado,
  });

  @override
  State<PantallaEscaneoInteligente> createState() =>
      _PantallaEscaneoInteligenteState();
}

class _PantallaEscaneoInteligenteState extends State<PantallaEscaneoInteligente>
    with TickerProviderStateMixin {
  // ==========================================================================
  // SERVICIOS
  // ==========================================================================
  final ImagePicker _picker = ImagePicker();
  late final ProcesarDocumentoUsecase _procesarDocumentoUsecase;
  late final AnimationController _animationController;
  late final AnimationController _reversoEntradaController;
  late final TextRecognizer _textRecognizer;

  // ==========================================================================
  // ESTADO
  // ==========================================================================
  File? _imagenFrente;
  File? _imagenReverso;
  ResultadoOcrIA? _resultado;
  bool _procesando = false;
  bool _mostrarReverso = false;

  // Progreso del procesamiento por pasos
  int _pasoActual = 0; // 0=frente, 1=reverso, 2=análisis IA
  static const _pasos = [
    'Procesando frente...',
    'Procesando reverso...',
    'Analizando con IA...',
  ];

  // ==========================================================================
  // CICLO DE VIDA
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _procesarDocumentoUsecase = ProcesarDocumentoUsecase(
      textRecognizer: _textRecognizer,
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    // Controlador para la animación de entrada del reverso
    _reversoEntradaController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _animationController.dispose();
    _reversoEntradaController.dispose();
    super.dispose();
  }

  // ==========================================================================
  // CAPTURA DE IMÁGENES
  // ==========================================================================
  Future<void> _tomarFoto(bool esReverso) async {
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        maxWidth: 3000,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (foto == null) return;

      setState(
        () => esReverso
            ? _imagenReverso = File(foto.path)
            : _imagenFrente = File(foto.path),
      );
      await _maybeAutoProcess(esReverso: esReverso);
    } catch (e) {
      _mostrarError('Error al tomar la foto: $e');
    }
  }

  Future<void> _seleccionarDeGaleria(bool esReverso) async {
    try {
      final foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
        maxWidth: 3000,
      );
      if (foto == null) return;

      setState(
        () => esReverso
            ? _imagenReverso = File(foto.path)
            : _imagenFrente = File(foto.path),
      );
      await _maybeAutoProcess(esReverso: esReverso);
    } catch (e) {
      _mostrarError('Error al seleccionar la imagen: $e');
    }
  }

  // ==========================================================================
  // PROCESAMIENTO
  // ==========================================================================
  Future<void> _maybeAutoProcess({required bool esReverso}) async {
    if (_procesando) return;

    final listo =
        !_mostrarReverso && !esReverso ||
        _mostrarReverso && esReverso && _imagenFrente != null;

    if (listo) await _procesarImagenes();
  }

  Future<void> _procesarImagenes() async {
    if (_imagenFrente == null) {
      _mostrarError('Debes capturar al menos la imagen del frente');
      return;
    }
    if (_mostrarReverso && _imagenReverso == null) {
      _mostrarError('Debes capturar el reverso antes de procesar');
      return;
    }

    setState(() {
      _procesando = true;
      _resultado = null;
      _pasoActual = 0;
    });
    _animationController.repeat();

    try {
      // Paso 1: procesando frente
      setState(() => _pasoActual = 0);
      await Future.delayed(const Duration(milliseconds: 300));

      // Paso 2: procesando reverso (si aplica)
      if (_mostrarReverso && _imagenReverso != null) {
        setState(() => _pasoActual = 1);
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Paso 3: análisis IA
      setState(() => _pasoActual = 2);

      final resultado = await _procesarDocumentoUsecase.ejecutar(
        imagenFrente: _imagenFrente!,
        imagenReverso: _mostrarReverso ? _imagenReverso : null,
        tipoEsperado: widget.tipoEsperado,
      );

      if (!mounted) return;
      setState(() {
        _resultado = resultado;
        _procesando = false;
        _pasoActual = 0;
      });
      _animationController.stop();
      _animationController.reset();

      widget.onResultado?.call(resultado);
      if (mounted) Navigator.pop(context, resultado);
    } on OcrException catch (e) {
      _handleError(e.message);
    } catch (e) {
      _handleError('Error inesperado al procesar: $e');
    }
  }

  void _handleError(String mensaje) {
    if (!mounted) return;
    setState(() => _procesando = false);
    _animationController.stop();
    _mostrarError(mensaje);
  }

  // ==========================================================================
  // AYUDANTES DE UI
  // ==========================================================================
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text('')),
          ],
        ),
        backgroundColor: AppColorsEscaneo.kErrorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarResultado(ResultadoOcrIA resultado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResultadoModal(resultado: resultado),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Escaneo Inteligente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              FadeInDown(child: _buildInstruccionesCard()),
              const SizedBox(height: 24),
              if (_mostrarReverso &&
                  _imagenFrente != null &&
                  _imagenReverso == null) ...[
                FadeInUp(child: _buildAlertaReversoPendiente()),
                const SizedBox(height: 16),
              ],
              FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: _buildPasoImagen(
                  titulo: 'Documento (Frente)',
                  imagen: _imagenFrente,
                  esFrente: true,
                  paso: 1,
                  onCamara: () => _tomarFoto(false),
                  onGaleria: () => _seleccionarDeGaleria(false),
                  onEliminar: () => setState(() => _imagenFrente = null),
                ),
              ),
              const SizedBox(height: 16),
              FadeInRight(
                delay: const Duration(milliseconds: 80),
                child: _buildToggleReverso(),
              ),
              if (_mostrarReverso) ...[
                const SizedBox(height: 16),
                // Animación de entrada del reverso: slide desde abajo + fade
                AnimatedBuilder(
                  animation: _reversoEntradaController,
                  builder: (context, child) {
                    final curve = CurvedAnimation(
                      parent: _reversoEntradaController,
                      curve: Curves.easeOutCubic,
                    );
                    return FadeTransition(
                      opacity: curve,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(curve),
                        child: child,
                      ),
                    );
                  },
                  child: _buildPasoImagen(
                    titulo: 'Documento (Reverso)',
                    imagen: _imagenReverso,
                    esFrente: false,
                    paso: 2,
                    onCamara: () => _tomarFoto(true),
                    onGaleria: () => _seleccionarDeGaleria(true),
                    onEliminar: () => setState(() => _imagenReverso = null),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (_imagenFrente != null &&
                  (!_mostrarReverso || _imagenReverso != null) &&
                  !_procesando)
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: _buildBotonProcesar(),
                ),
              if (_resultado != null) ...[
                const SizedBox(height: 24),
                FadeInUp(child: _buildResumenResultado(_resultado!)),
              ],
              const SizedBox(height: 40),
            ],
          ),
          if (_procesando) _buildOverlayProcesando(),
        ],
      ),
    );
  }

  // ==========================================================================
  // WidgetS DE UI
  // ==========================================================================
  Widget _buildInstruccionesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorsEscaneo.kPrimaryColor.withOpacity(0.1),
            AppColorsEscaneo.kInfoColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColorsEscaneo.kPrimaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.lightbulb_outline,
                color: AppColorsEscaneo.kPrimaryColor,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Consejos para mejor escaneo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColorsEscaneo.kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConsejo('Buena iluminación natural o artificial'),
          _buildConsejo('Documento plano sobre superficie clara'),
          _buildConsejo('Evita sombras, reflejos y fotos borrosas'),
          _buildConsejo('Encuadra todo el carnet sin recortar bordes'),
          _buildConsejo('Mantén el teléfono estable al tomar la foto'),
        ],
      ),
    );
  }

  Widget _buildConsejo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColorsEscaneo.kSuccessColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                color: AppColorsEscaneo.kTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaReversoPendiente() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kWarningColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColorsEscaneo.kWarningColor.withOpacity(0.4),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColorsEscaneo.kWarningColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Captura el reverso para continuar el escaneo.',
              style: TextStyle(
                fontSize: 13,
                color: AppColorsEscaneo.kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasoImagen({
    required String titulo,
    required File? imagen,
    required bool esFrente,
    required int paso,
    required VoidCallback onCamara,
    required VoidCallback onGaleria,
    required VoidCallback onEliminar,
  }) {
    return Stack(
      children: [
        _buildImagenCard(
          titulo: titulo,
          imagen: imagen,
          onCamara: onCamara,
          onGaleria: onGaleria,
          onEliminar: onEliminar,
        ),
        Positioned(top: 12, right: 12, child: _buildBadgePaso(paso, esFrente)),
      ],
    );
  }

  Widget _buildBadgePaso(int paso, bool esFrente) {
    // Si es el reverso y ya tiene imagen, mostrar check animado
    final tieneImagen = esFrente
        ? _imagenFrente != null
        : _imagenReverso != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: tieneImagen
          ? Container(
              key: const ValueKey('check'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColorsEscaneo.kSuccessColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColorsEscaneo.kSuccessColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 18),
            )
          : Container(
              key: ValueKey('paso_$paso'),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: esFrente
                    ? AppColorsEscaneo.kPrimaryColor
                    : AppColorsEscaneo.kSuccessColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (esFrente
                                ? AppColorsEscaneo.kPrimaryColor
                                : AppColorsEscaneo.kSuccessColor)
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '$paso',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildToggleReverso() {
    return SwitchListTile(
      value: _mostrarReverso,
      onChanged: (val) {
        setState(() => _mostrarReverso = val);
        if (val) {
          // Animar entrada del reverso
          _reversoEntradaController.forward(from: 0);
        } else {
          _reversoEntradaController.reverse();
        }
      },
      title: const Text(
        '¿Tiene reverso?',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Activa si el documento tiene dos caras'),
      activeColor: AppColorsEscaneo.kPrimaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: AppColorsEscaneo.kCardColor,
    );
  }

  Widget _buildBotonProcesar() {
    return ElevatedButton(
      onPressed: _procesarImagenes,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColorsEscaneo.kPrimaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 4,
        shadowColor: AppColorsEscaneo.kPrimaryColor.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.auto_awesome, size: 24),
          SizedBox(width: 12),
          Text(
            'Procesar con IA',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayProcesando() {
    final pasoTexto = _pasoActual < _pasos.length
        ? _pasos[_pasoActual]
        : 'Finalizando...';
    final progreso = (_pasoActual + 1) / _pasos.length;

    return Container(
      color: Colors.black54,
      child: Center(
        child: FadeIn(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColorsEscaneo.kCardColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono animado
                RotationTransition(
                  turns: _animationController,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColorsEscaneo.kPrimaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: AppColorsEscaneo.kPrimaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Texto del paso actual
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.2),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    pasoTexto,
                    key: ValueKey(pasoTexto),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColorsEscaneo.kTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paso ${_pasoActual + 1} de ${_pasos.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColorsEscaneo.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 20),

                // Barra de progreso animada
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progreso),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: AppColorsEscaneo.kPrimaryColor
                              .withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColorsEscaneo.kPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColorsEscaneo.kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Indicadores de pasos
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pasos.length, (i) {
                    final activo = i <= _pasoActual;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: activo ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: activo
                            ? AppColorsEscaneo.kPrimaryColor
                            : AppColorsEscaneo.kPrimaryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagenCard({
    required String titulo,
    required File? imagen,
    required VoidCallback onCamara,
    required VoidCallback onGaleria,
    required VoidCallback onEliminar,
  }) {
    final esFrente = titulo.contains('Frente');

    return Container(
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImagenHeader(titulo, esFrente),
          imagen != null
              ? _buildImagenContenido(imagen, onEliminar)
              : _buildImagenEstadoVacio(onCamara, onGaleria),
        ],
      ),
    );
  }

  Widget _buildImagenHeader(String titulo, bool esFrente) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: esFrente
                    ? [
                        AppColorsEscaneo.kPrimaryColor,
                        AppColorsEscaneo.kPrimaryColor.withOpacity(0.7),
                      ]
                    : [
                        AppColorsEscaneo.kSuccessColor,
                        AppColorsEscaneo.kSuccessColor.withOpacity(0.7),
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color:
                      (esFrente
                              ? AppColorsEscaneo.kPrimaryColor
                              : AppColorsEscaneo.kSuccessColor)
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              esFrente ? Icons.credit_card : Icons.credit_card_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColorsEscaneo.kTextColor,
                  ),
                ),
                Text(
                  esFrente ? 'Anverso del documento' : 'Reverso del documento',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColorsEscaneo.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenContenido(File imagen, VoidCallback onEliminar) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          child: Image.file(
            imagen,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: onEliminar,
            icon: const Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: AppColorsEscaneo.kErrorColor,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagenEstadoVacio(
    VoidCallback onCamara,
    VoidCallback onGaleria,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildPlaceholder(),
          const SizedBox(height: 16),
          _buildBotonesCaptura(onCamara, onGaleria),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kSurfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorsEscaneo.kPrimaryColor.withOpacity(0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColorsEscaneo.kTextSecondary,
            ),
            SizedBox(height: 8),
            Text(
              'Sin imagen',
              style: TextStyle(
                color: AppColorsEscaneo.kTextSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonesCaptura(VoidCallback onCamara, VoidCallback onGaleria) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            onPressed: onCamara,
            icon: const Icon(Icons.camera_alt_rounded, size: 28),
            label: const Text(
              '📸 TOMAR FOTO',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorsEscaneo.kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColorsEscaneo.kPrimaryColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: onGaleria,
            icon: const Icon(Icons.photo_library_rounded, size: 22),
            label: const Text(
              'Seleccionar de Galería',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: BorderSide(
                color: AppColorsEscaneo.kPrimaryColor.withOpacity(0.5),
                width: 2,
              ),
              foregroundColor: AppColorsEscaneo.kPrimaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumenResultado(ResultadoOcrIA resultado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorsEscaneo.kSuccessColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColorsEscaneo.kSuccessColor,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Procesado Exitosamente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColorsEscaneo.kTextColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _mostrarResultado(resultado),
                child: const Text('Ver detalles'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Tipo',
            _getTipoDocumentoTexto(resultado.tipoDocumento),
          ),
          _buildInfoRow(
            'Confianza',
            '${(resultado.confianza * 100).toStringAsFixed(0)}%',
          ),
          _buildInfoRow('Campos extraídos', '${resultado.campos.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColorsEscaneo.kTextSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColorsEscaneo.kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getTipoDocumentoTexto(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.cedulaIdentidad:
        return 'Cédula de Identidad';
      case TipoDocumento.tituloAcademico:
        return 'Título Académico';
      case TipoDocumento.certificadoEstudios:
        return 'Certificado de Estudios';
      case TipoDocumento.certificadoNacimiento:
        return 'Certificado de Nacimiento';
      case TipoDocumento.cartaProrroga:
        return 'Carta de Prórroga';
      default:
        return 'Documento Genérico';
    }
  }
}

// ============================================================================
/// MODAL DE RESULTADO
// ============================================================================
class _ResultadoModal extends StatelessWidget {
  final ResultadoOcrIA resultado;
  const _ResultadoModal({required this.resultado});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildModalHeader(context),
          Expanded(child: _buildModalContent()),
          _buildModalFooter(context),
        ],
      ),
    );
  }

  Widget _buildModalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          bottom: BorderSide(color: AppColorsEscaneo.kBorderColor),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColorsEscaneo.kSuccessColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColorsEscaneo.kSuccessColor,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Resultado del Análisis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColorsEscaneo.kTextColor,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildModalContent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildConfianzaCard(),
        const SizedBox(height: 16),
        const Text(
          'CAMPOS EXTRAÍDOS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColorsEscaneo.kTextSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...resultado.campos.entries.map((e) => _buildCampoCard(e.key, e.value)),
        if (resultado.advertencias.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'ADVERTENCIAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColorsEscaneo.kTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...resultado.advertencias.map((a) => _buildAdvertenciaCard(a)),
        ],
        if (resultado.sugerencias.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text(
            'SUGERENCIAS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColorsEscaneo.kTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...resultado.sugerencias.map((s) => _buildSugerenciaCard(s)),
        ],
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildModalFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColorsEscaneo.kBorderColor)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsEscaneo.kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Aceptar',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildConfianzaCard() {
    final confianzaPorcentaje = (resultado.confianza * 100).toInt();
    final color = confianzaPorcentaje >= 80
        ? AppColorsEscaneo.kSuccessColor
        : confianzaPorcentaje >= 60
        ? AppColorsEscaneo.kWarningColor
        : AppColorsEscaneo.kErrorColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$confianzaPorcentaje%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nivel de Confianza',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColorsEscaneo.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getConfianzaTexto(confianzaPorcentaje),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColorsEscaneo.kTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoCard(String nombre, CampoExtraido campo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatearNombreCampo(nombre),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColorsEscaneo.kTextSecondary,
                  ),
                ),
              ),
              if (campo.corregido)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsEscaneo.kWarningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CORREGIDO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColorsEscaneo.kWarningColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campo.valor.isEmpty ? '(vacío)' : campo.valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: campo.valor.isEmpty
                  ? AppColorsEscaneo.kTextSecondary
                  : AppColorsEscaneo.kTextColor,
            ),
          ),
          if (campo.valorOriginal != null) ...[
            const SizedBox(height: 4),
            Text(
              'Original: ${campo.valorOriginal}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColorsEscaneo.kTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: campo.confianza,
            backgroundColor: const Color(0xFFE2E8F0),
            color: _getColorConfianza(campo.confianza),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            'Confianza: ${(campo.confianza * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              color: AppColorsEscaneo.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertenciaCard(String advertencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kWarningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorsEscaneo.kWarningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColorsEscaneo.kWarningColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advertencia,
              style: const TextStyle(
                fontSize: 13,
                color: AppColorsEscaneo.kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaCard(String sugerencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsEscaneo.kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColorsEscaneo.kPrimaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            color: AppColorsEscaneo.kPrimaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sugerencia,
              style: const TextStyle(
                fontSize: 13,
                color: AppColorsEscaneo.kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearNombreCampo(String nombre) {
    final palabras = nombre
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .split(RegExp(r'[_\s]+'));
    return palabras
        .map(
          (p) => p.isEmpty
              ? ''
              : p[0].toUpperCase() + p.substring(1).toLowerCase(),
        )
        .join(' ')
        .trim();
  }

  String _getConfianzaTexto(int porcentaje) {
    if (porcentaje >= 80) return 'Excelente';
    if (porcentaje >= 60) return 'Bueno';
    if (porcentaje >= 40) return 'Regular';
    return 'Bajo';
  }

  Color _getColorConfianza(double confianza) {
    if (confianza >= 0.8) return AppColorsEscaneo.kSuccessColor;
    if (confianza >= 0.6) return AppColorsEscaneo.kWarningColor;
    return AppColorsEscaneo.kErrorColor;
  }
}
