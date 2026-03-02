import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_fotocopia_carnet.dart';
import 'package:refactor_template/core/services/servicio_procesador_imagen_perfil.dart';
import 'package:refactor_template/core/services/servicio_compositor_cartas_ci.dart';
import 'package:refactor_template/core/services/servicio_generador_carta_inscripcion.dart';
import 'package:refactor_template/core/services/servicio_ocr_ia_avanzado.dart';
import 'package:refactor_template/features/sistema/screens/perfil/pantalla_escaneo_inteligente.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum _SourceType { camera, gallery, file }

class MisDocumentosPersonalesScreen extends StatefulWidget {
  static const name = 'mis-documentos-personales-screen';

  const MisDocumentosPersonalesScreen({super.key});

  @override
  State<MisDocumentosPersonalesScreen> createState() =>
      _MisDocumentosPersonalesScreenState();
}

class _MisDocumentosPersonalesScreenState
    extends State<MisDocumentosPersonalesScreen> {
  // --- Modern Color Palette ---
  // --- Modern Color Palette (Alineado con Requisitos) ---
  static const Color kPrimaryColor = Color(0xFF005BAC); // Official Blue
  static const Color kPrimaryDark = Color(0xFF003F7A); 
  static const Color kSurfaceColor = Color(0xFFF0F4F8); 
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF333333); 
  static const Color kTextSecondary = Color(0xFF666666); 
  static const Color kSuccessColor = Color(0xFF4CAF50);
  static const Color kErrorColor = Color(0xFFD32F2F);
  static const Color kWarningBg = Color(0xFFFFF7ED); 
  static const Color kWarningText = Color(0xFF005BAC); 

  // --- Typography ---
  static const String fontHeading = 'Poppins';
  static const String fontBody = 'Intel'; // Maps to Inter in pubspec

  final ImagePicker _picker = ImagePicker();

  String? _ciFrontPath;
  String? _ciBackPath;
  String? _ciLetterPath;
  String? _tituloPath;
  String? _prorrogaPath;
  String? _cartaInscripcionPath;
  String? _comprobanteMatriculaPath;
  String? _comprobanteColegiaturaPath;
  String? _fichaInscripcionPath;
  String? _hojaVidaPath;
  File? _profilePhoto;
  Uint8List? _signaturePng;
  Map<String, dynamic>? _participantDocs;
  bool _deferDocuments = false;

  bool _hasTitle = true; // Default assumption

  // Seguir estado ocupado por acción para feedback detallado
  bool _busyGlobal = false;
  String? _busyKey; // Which specific doc key is currently processing

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _busyGlobal = true);
    final data = await LocalStorageService.getParticipantDocumentsData();
    final profilePhoto = await LocalStorageService.getProfileImageFile();
    if (!mounted) return;
    setState(() {
      _participantDocs = data;
      _ciFrontPath = data?['ci_front_path'] as String?;
      _ciBackPath = data?['ci_back_path'] as String?;
      _ciLetterPath = data?['ci_letter_path'] as String?;
      _tituloPath = data?['titulo_path'] as String?;
      _prorrogaPath = data?['prorroga_path'] as String?;
      _cartaInscripcionPath = data?['carta_inscripcion_path'] as String?;
      _comprobanteMatriculaPath = data?['comprobante_matricula_path'] as String?;
      _comprobanteColegiaturaPath = data?['comprobante_colegiatura_path'] as String?;
      _fichaInscripcionPath = data?['ficha_inscripcion_path'] as String?;
      _hojaVidaPath = data?['hoja_vida_path'] as String?;
      _deferDocuments = (data?['defer_documents'] as bool?) ?? false;
      _profilePhoto = profilePhoto;

      // Determine mode based on existing data
      if (_prorrogaPath != null &&
          (_tituloPath == null || _tituloPath!.isEmpty)) {
        _hasTitle = false;
      } else {
        _hasTitle = true;
      }

      _busyGlobal = false;
    });
    // Auto-generar fotocopia de carnet si existen anverso y reverso y aún no hay PDF
    _maybeAutoGenerateCarnetPdf();
  }

  /// Genera automáticamente el PDF del carnet cuando existen anverso y reverso
  /// y aún no se ha generado (p. ej. tras escanear en pantalla de identidad).
  Future<void> _maybeAutoGenerateCarnetPdf() async {
    final front = _ciFrontPath;
    final back = _ciBackPath;
    final existingPdf = _participantDocs?['ci_photocopy_pdf_path'] as String?;
    if (front == null || back == null || front.isEmpty || back.isEmpty) return;
    if (existingPdf != null && existingPdf.isNotEmpty) return;
    if (!mounted) return;
    try {
      final pdfPath = await CarnetPhotocopyService.generatePdf(
        frontFile: File(front),
        backFile: File(back),
      );
      if (pdfPath != null && mounted) {
        await _saveDocPath('ci_photocopy_pdf_path', pdfPath);
        if (!mounted) return;
        setState(() {
          _participantDocs ??= <String, dynamic>{};
          _participantDocs!['ci_photocopy_pdf_path'] = pdfPath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotocopia de carnet generada automáticamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error auto-generando fotocopia PDF: $e");
    }
  }

  Future<void> _setDeferDocuments(bool value) async {
    final current =
        await LocalStorageService.getParticipantDocumentsData() ??
        <String, dynamic>{};
    current['defer_documents'] = value;
    await LocalStorageService.saveParticipantDocumentsData(current);
    if (!mounted) return;
    setState(() => _deferDocuments = value);
  }

  Future<void> _saveDocPath(String key, String? path) async {
    final current =
        await LocalStorageService.getParticipantDocumentsData() ??
        <String, dynamic>{};
    if (path == null) {
      current.remove(key);
    } else {
      current[key] = path;
    }
    await LocalStorageService.saveParticipantDocumentsData(current);
  }

  Future<File> _copyToParticipantDocs(
    String originalPath,
    String prefix,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory(
      '${dir.path}${Platform.pathSeparator}participant_documents',
    );
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    String ext = 'jpg';
    if (originalPath.toLowerCase().endsWith('.png')) ext = 'png';
    if (originalPath.toLowerCase().endsWith('.pdf')) ext = 'pdf';

    final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final dest = File('${outDir.path}${Platform.pathSeparator}$fileName');
    return File(originalPath).copy(dest.path);
  }

  String _fileName(String path) {
    final sep = Platform.pathSeparator;
    final parts = path.split(sep);
    return parts.isNotEmpty ? parts.last : path;
  }

  Future<void> _generatePhotocopyFromPaths() async {
    final front = _ciFrontPath;
    final back = _ciBackPath;
    if (front == null || back == null || front.isEmpty || back.isEmpty) return;
    setState(() => _busyKey = 'ci_photocopy_pdf_path');
    try {
      final pdfPath = await CarnetPhotocopyService.generatePdf(
        frontFile: File(front),
        backFile: File(back),
      );
      if (pdfPath != null) {
        await _saveDocPath('ci_photocopy_pdf_path', pdfPath);
        if (!mounted) return;
        setState(() {
          _participantDocs ??= <String, dynamic>{};
          _participantDocs!['ci_photocopy_pdf_path'] = pdfPath;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotocopia de carnet generada'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error generando fotocopia PDF: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generando fotocopia: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<bool> _confirmDelete(String title) async {
    if (!mounted) return false;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Eliminar documento',
                style: TextStyle(fontFamily: fontHeading),
              ),
              content: Text(
                '¿Estás seguro de eliminar: $title?',
                style: TextStyle(fontFamily: fontBody),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      fontFamily: fontBody,
                      color: kTextSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(
                    'Eliminar',
                    style: TextStyle(
                      fontFamily: fontBody,
                      color: kErrorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<_SourceType?> _askSource({
    bool allowFile = false,
    bool allowSmartScan = false,
  }) async {
    return showModalBottomSheet<_SourceType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar origen',
                    style: TextStyle(
                      fontFamily: fontHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Escaneo Inteligente con IA (NUEVO)
                  if (allowSmartScan)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [kPrimaryColor, kPrimaryDark],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                        ),
                      ),
                      title: const Text(
                        'Escaneo Inteligente con IA',
                        style: TextStyle(
                          fontFamily: fontBody,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Detecta y extrae información automáticamente',
                        style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width < 360 ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF005BAC),
                ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _abrirEscaneoInteligente();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: kPrimaryColor.withOpacity(0.05),
                    ),
                  if (allowSmartScan) const SizedBox(height: 12),

                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: const Text(
                      'Tomar una foto',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, _SourceType.camera),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: const Text(
                      'Galería de imágenes',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, _SourceType.gallery),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  if (allowFile) ...[
                    const SizedBox(height: 8),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_rounded,
                          color: kPrimaryColor,
                        ),
                      ),
                      title: const Text(
                        'Subir Archivo (PDF)',
                        style: TextStyle(
                          fontFamily: fontBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, _SourceType.file),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================================
  // Nuevas funcionalidades con IA
  // ============================================================================

  /// Abre la pantalla de escaneo inteligente con IA
  Future<void> _abrirEscaneoInteligente() async {
    final resultado = await Navigator.push<ResultadoOcrIA>(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEscaneoInteligente(
          tipoEsperado: TipoDocumento.cedulaIdentidad,
          onResultado: (resultado) {
            // Procesar resultado
            debugPrint('Resultado OCR IA: ${resultado.toJson()}');
          },
        ),
      ),
    );

    if (resultado != null) {
      // Autocompletar campos con la información extraída
      await _procesarResultadoIA(resultado);
    }
  }

  /// Procesa el resultado del OCR con IA y autocompleta campos
  Future<void> _procesarResultadoIA(ResultadoOcrIA resultado) async {
    try {
      // Guardar datos personales extraídos
      if (resultado.tipoDocumento == TipoDocumento.cedulaIdentidad) {
        final personalData = <String, dynamic>{};

        if (resultado.campos.containsKey('ci')) {
          personalData['numeroCI'] = resultado.campos['ci']!.valor;
        }
        if (resultado.campos.containsKey('nombres')) {
          personalData['nombre'] = resultado.campos['nombres']!.valor;
        }
        if (resultado.campos.containsKey('apellidos')) {
          final apellidos = resultado.campos['apellidos']!.valor.split(' ');
          if (apellidos.isNotEmpty) {
            personalData['apPaterno'] = apellidos[0];
          }
          if (apellidos.length > 1) {
            personalData['apMaterno'] = apellidos.sublist(1).join(' ');
          }
        }
        if (resultado.campos.containsKey('fechaNacimiento')) {
          personalData['fechaNacimiento'] =
              resultado.campos['fechaNacimiento']!.valor;
        }

        // Guardar en LocalStorage
        await LocalStorageService.savePersonalData(personalData);

        if (!mounted) return;

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '¡Información extraída!',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${resultado.campos.length} campos detectados',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: kSuccessColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );

        // Mostrar advertencias si las hay
        if (resultado.advertencias.isNotEmpty) {
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            _mostrarAdvertenciasIA(resultado.advertencias);
          });
        }
      }
    } catch (e) {
      debugPrint('Error procesando resultado IA: $e');
    }
  }

  /// Muestra advertencias del análisis IA
  void _mostrarAdvertenciasIA(List<String> advertencias) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: kPrimaryColor),
            SizedBox(width: 12),
            Text('Advertencias'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: advertencias.map((adv) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(fontSize: 16)),
                  Expanded(child: Text(adv)),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// Comparte un documento
  Future<void> _compartirDocumento(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _mostrarMensaje('El archivo no existe', esError: true);
        return;
      }

      await Share.shareXFiles(
        [XFile(path)],
        subject: 'Documento Personal',
        text: 'Compartiendo documento',
      );
    } catch (e) {
      _mostrarMensaje('Error al compartir: $e', esError: true);
    }
  }

  /// Copia información al portapapeles
  Future<void> _copiarAlPortapapeles(String texto, String etiqueta) async {
    await Clipboard.setData(ClipboardData(text: texto));
    _mostrarMensaje('$etiqueta copiado al portapapeles');
  }

  /// Muestra estadísticas de documentos
  void _mostrarEstadisticas() {
    final total = 5; // CI frente, CI reverso, CI letra, título/prórroga
    int completados = 0;

    if (_ciFrontPath != null) completados++;
    if (_ciBackPath != null) completados++;
    if (_ciLetterPath != null) completados++;
    if (_hasTitle && _tituloPath != null) completados++;
    if (!_hasTitle && _prorrogaPath != null) completados++;

    final porcentaje = ((completados / total) * 100).toInt();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.analytics_outlined, color: kPrimaryColor),
            SizedBox(width: 12),
            Text('Estadísticas'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: completados / total,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(kPrimaryColor),
                  ),
                  Center(
                    child: Text(
                      '$porcentaje%',
                      style: const TextStyle(
                      color: Color(0xFF005BAC),
                      fontWeight: FontWeight.w700,
                    ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '$completados de $total documentos',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              completados == total
                  ? '¡Todos los documentos completados!'
                  : 'Faltan ${total - completados} documentos',
              style: TextStyle(
                fontSize: 13,
                color: completados == total ? kSuccessColor : kTextSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Muestra un mensaje genérico
  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: esError ? kErrorColor : kSuccessColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Muestra pantalla de ayuda
  void _mostrarAyuda() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.help_outline, color: kPrimaryColor),
            SizedBox(width: 12),
            Text('Ayuda'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Cómo usar esta pantalla?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildAyudaItem(
                Icons.auto_awesome,
                'Escaneo Inteligente',
                'Usa la IA para detectar automáticamente el tipo de documento y extraer información. Ideal para cédulas de identidad.',
              ),
              const SizedBox(height: 12),
              _buildAyudaItem(
                Icons.camera_alt,
                'Captura Manual',
                'Toma fotos individuales de cada documento. Asegúrate de tener buena iluminación.',
              ),
              const SizedBox(height: 12),
              _buildAyudaItem(
                Icons.analytics_outlined,
                'Estadísticas',
                'Ve tu progreso y cuántos documentos has completado.',
              ),
              const SizedBox(height: 12),
              _buildAyudaItem(
                Icons.share,
                'Compartir',
                'Comparte tus documentos directamente desde la app.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.tips_and_updates,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tip: El escaneo inteligente funciona mejor con documentos bien iluminados y sin reflejos.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Widget _buildAyudaItem(IconData icon, String titulo, String descripcion) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: kPrimaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                descripcion,
                style: const TextStyle(fontSize: 12, color: kTextSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndSave({
    required String key,
    required String prefix,
    required void Function(String path) onSet,
    bool allowFile = false,
    bool allowSmartScan = false,
  }) async {
    final source = await _askSource(
      allowFile: allowFile,
      allowSmartScan: allowSmartScan,
    );
    if (source == null) return;

    setState(() => _busyKey = key);
    try {
      String? originalPath;

      if (source == _SourceType.file) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        );
        if (result != null && result.files.single.path != null) {
          originalPath = result.files.single.path;
        }
      } else {
        final imageSource = source == _SourceType.camera
            ? ImageSource.camera
            : ImageSource.gallery;
        final picked = await _picker.pickImage(
          source: imageSource,
          imageQuality: 92,
          maxWidth: 2200,
        );
        originalPath = picked?.path;
      }

      if (originalPath == null) return;

      final copied = await _copyToParticipantDocs(originalPath, prefix);
      await _saveDocPath(key, copied.path);
      if (!mounted) return;
      setState(() => onSet(copied.path));
    } catch (e) {
      debugPrint('Error picking file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar el archivo: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _updateProfilePhoto() async {
    final source = await _askSource();
    if (source == null) return;

    setState(() => _busyKey = 'profile_photo');
    try {
      final imageSource = source == _SourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery;
      final picked = await _picker.pickImage(
        source: imageSource,
        imageQuality: 92,
        maxWidth: 2000,
      );
      if (picked == null) return;

      final original = File(picked.path);
      final processed = await ProfileImageProcessorService.processProfileImage(
        original,
        isFirstPhoto: true,
      );
      final toSave = processed ?? original;
      final savedPath = await LocalStorageService.saveProfileImage(toSave);
      if (savedPath == null) {
        throw Exception('No se pudo guardar la foto');
      }
      if (!mounted) return;
      setState(() => _profilePhoto = File(savedPath));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto 4x4 actualizada correctamente.'),
          backgroundColor: kSuccessColor,
        ),
      );
    } catch (e) {
      debugPrint('Error actualizando foto: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar la foto: $e'),
          backgroundColor: kErrorColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _previewDoc(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        _mostrarMensaje('El archivo no existe', esError: true);
        return;
      }

      final lower = path.toLowerCase();
      
      // PDFs se muestran en WebView
      if (lower.endsWith('.pdf')) {
        await _showPdfPreview(path);
        return;
      }
      
      // HTML se abre con la app del sistema (navegador para HTML)
      if (lower.endsWith('.html') || lower.endsWith('.htm')) {
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No existe una aplicación para abrir este archivo.'),
            ),
          );
        }
        return;
      }
      
      // Imágenes (jpg, png, jpeg, etc.)
      if (lower.endsWith('.jpg') || 
          lower.endsWith('.jpeg') || 
          lower.endsWith('.png')) {
        await _previewImage(path);
        return;
      }

      // Para otros tipos de archivo, intentar abrir con app externa
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        _mostrarMensaje(
          'No se pudo abrir el archivo. Tipo: ${result.type}',
          esError: true,
        );
      }
    } catch (e) {
      debugPrint('Error previewing document: $e');
      _mostrarMensaje('Error al abrir el documento: $e', esError: true);
    }
  }

  Future<void> _previewImage(String path) async {
    final file = File(path);
    if (!await file.exists()) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) {
        return FadeIn(
          duration: const Duration(milliseconds: 300),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(file),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black26,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Muestra vista previa de PDFs en WebView con PDF.js
  Future<void> _showPdfPreview(String path) async {
    // Mostrar indicador de carga
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(kPrimaryColor),
                ),
                SizedBox(height: 16),
                Text(
                  'Cargando PDF...',
                  style: TextStyle(
                    fontFamily: fontBody,
                    fontSize: 14,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final file = File(path);
      if (!await file.exists()) {
        if (mounted) Navigator.pop(context); // Cerrar loader
        _mostrarMensaje('El PDF no existe en el dispositivo.', esError: true);
        return;
      }

      // Convertir PDF a base64
      final bytes = await file.readAsBytes();
      final base64Pdf = base64Encode(bytes);
      
      if (mounted) Navigator.pop(context); // Cerrar loader
      
      if (!mounted) return;

      // HTML mejorado con PDF.js para mejor compatibilidad
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      background: #f5f5f5;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    }
    #pdf-container {
      width: 100%;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 16px;
      background: #f5f5f5;
    }
    .pdf-page {
      margin-bottom: 16px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      background: white;
      max-width: 100%;
      border-radius: 8px;
      overflow: hidden;
    }
    iframe {
      width: 100%;
      min-height: 100vh;
      border: none;
      background: white;
    }
    .loading {
      position: fixed;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      text-align: center;
      color: #005BAC;
      font-size: 16px;
      font-weight: 500;
    }
    .spinner {
      border: 3px solid #f3f3f3;
      border-top: 3px solid #005BAC;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
      margin: 0 auto 12px;
    }
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
  </style>
</head>
<body>
  <div id="pdf-container">
    <div class="loading">
      <div class="spinner"></div>
      <div>Cargando documento...</div>
    </div>
    <iframe id="pdf-frame" src="data:application/pdf;base64,$base64Pdf#toolbar=1&navpanes=0&scrollbar=1&view=FitH"></iframe>
  </div>
  <script>
    // Ocultar loading cuando el iframe cargue
    document.getElementById('pdf-frame').onload = function() {
      document.querySelector('.loading').style.display = 'none';
    };
    
    // Timeout de seguridad
    setTimeout(function() {
      document.querySelector('.loading').style.display = 'none';
    }, 3000);
  </script>
</body>
</html>
''';

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF5F5F5))
        ..loadHtmlString(htmlContent);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) {
            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F5),
              appBar: AppBar(
                backgroundColor: kPrimaryColor,
                elevation: 0,
                title: const Text(
                  'Fotocopia de Carnet',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontHeading,
                    fontSize: 18,
                  ),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_rounded, color: Colors.white),
                    tooltip: 'Compartir',
                    onPressed: () async {
                      try {
                        await _compartirDocumento(path);
                      } catch (e) {
                        _mostrarMensaje('Error al compartir: $e', esError: true);
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                    tooltip: 'Abrir con otra app',
                    onPressed: () async {
                      try {
                        final result = await OpenFilex.open(path);
                        if (result.type != ResultType.done) {
                          _mostrarMensaje(
                            'No se pudo abrir con otra aplicación',
                            esError: true,
                          );
                        }
                      } catch (e) {
                        _mostrarMensaje('Error al abrir: $e', esError: true);
                      }
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: WebViewWidget(controller: controller),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        // Intentar cerrar el loader si aún está abierto
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
      debugPrint('Error mostrando PDF: $e');
      _mostrarMensaje('No se pudo mostrar el PDF: $e', esError: true);
      
      // Fallback: intentar abrir con app externa
      try {
        await OpenFilex.open(path);
      } catch (e2) {
        debugPrint('Error abriendo con app externa: $e2');
      }
    }
  }

  Future<void> _onCiLetterAction() async {
    // Comprobar si podemos generar (se necesita anverso y reverso)
    final canGenerate =
        (_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documento Fusionado',
                    style: TextStyle(
                      fontFamily: fontHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes generar la hoja automáticamente si ya subiste las fotos, o subir un PDF/Foto existente.',
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  if (canGenerate)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.auto_awesome,
                          color: kPrimaryColor,
                        ),
                      ),
                      title: const Text(
                        'Generar Automáticamente',
                        style: TextStyle(
                          fontFamily: fontBody,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Usa las fotos de anverso y reverso',
                        style: TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _generateCiLetter();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  if (canGenerate) const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        color: Colors.blueGrey,
                      ),
                    ),
                    title: const Text(
                      'Subir Archivo',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'PDF o Imagen de tu galería',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSave(
                        key: 'ci_letter_path',
                        prefix: 'ci_hoja_carta_custom',
                        onSet: (p) => _ciLetterPath = p,
                        allowFile: true,
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateCiLetter() async {
    const key = 'ci_letter_path';
    final front = _ciFrontPath;
    final back = _ciBackPath;
    if (front == null || back == null) return;

    setState(() => _busyKey = key);
    try {
      final out = await ServicioCompositorCartasCi.composeLetterFromCiImages(
        front: File(front),
        back: File(back),
      );
      if (out == null) return;
      await _saveDocPath(key, out.path);
      if (!mounted) return;
      setState(() {
        _ciLetterPath = out.path;
      });
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _generateSignedProrroga() async {
    const key = 'prorroga_path';
    setState(() => _busyKey = key);
    try {
      // Usa la última firma capturada (si existe)
      final personalData = await LocalStorageService.getPersonalData();
      final name =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final ci = personalData?['numeroCI'] ?? 'NO_CI';

      final out = await ServicioCompositorCartasCi.generateProrrogaLetter(
        fullName: name.isEmpty ? 'PARTICIPANTE' : name,
        ci: ci,
        signatureBytes: _signaturePng,
      );
      if (out == null) return;

      await _saveDocPath(key, out.path);
      if (!mounted) return;
      setState(() => _prorrogaPath = out.path);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _onProrrogaAction() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carta de Prórroga',
                    style: TextStyle(
                      fontFamily: fontHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Puedes firmar digitalmente una carta estándar o subir tu propio documento.',
                    style: const TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.draw_rounded,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: const Text(
                      'Firmar Digitalmente',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Genera la carta con tus datos',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _generateSignedProrroga();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_rounded,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: const Text(
                      'Previsualizar Carta',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Ver cómo quedará antes de firmar',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _previewProrrogaTemplate();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.upload_file,
                        color: kPrimaryColor,
                      ),
                    ),
                    title: const Text(
                      'Subir Archivo',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSave(
                        key: 'prorroga_path',
                        prefix: 'prorroga_custom',
                        onSet: (p) => _prorrogaPath = p,
                        allowFile: true,
                      );
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _previewProrrogaTemplate() async {
    setState(() => _busyGlobal = true);
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final name =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final ci = personalData?['numeroCI'] ?? 'NO_CI';

      final now = DateTime.now();
      final dateStr =
          "La Paz, ${now.day} de ${_getMonthName(now.month)} de ${now.year}";
      final career = "Educación Superior"; // Could be dynamic if needed

      final String body =
          """$dateStr

Señor:
Dr. Richard Jorge Torrez Juaniquina Ph. D.
DIRECTOR DE POSGRADO - UPEA
Presente.-

Ref.: SOLICITUD DE PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TITULO EN PROVISIÓN NACIONAL

Distinguido Magister:

Me es grato hacerle llegar un saludo cordial y fraterno a nombre mío, deseándole mis mejores deseos de éxitos en las labores que desempeña.

El motivo de la presente es para solicitar a su autoridad una PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL, para la inscripción al PROGRAMA: “Diplomado en: $career” MODALIDAD: Virtual; siendo que mi persona debe realizar solicitud en la Universidad de origen de estudios, por ese motivo es que le mando mi solicitud de prórroga. Por ese motivo es que le mando mi solicitud, esperando el visto bueno de su autoridad me despido.

Atentamente,


$name
C.I. $ci""";

      if (mounted) setState(() => _busyGlobal = false);

      // Generate responsive HTML for WebView preview
      final String htmlContent = '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Carta de Prórroga</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Times New Roman', Times, serif;
      background-color: #f5f5f5;
      padding: 20px 10px;
    }
    
    .page {
      width: 100%;
      max-width: 612px;
      margin: 0 auto;
      background: white;
      padding: 60px 40px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      line-height: 1.6;
    }
    
    .date {
      text-align: right;
      margin-bottom: 40px;
      font-size: 11pt;
    }
    
    .recipient {
      margin-bottom: 30px;
      font-size: 11pt;
    }
    
    .recipient p {
      margin: 2px 0;
    }
    
    .reference {
      margin-bottom: 30px;
      font-size: 11pt;
      font-weight: bold;
    }
    
    .salutation {
      margin-bottom: 20px;
      font-size: 11pt;
    }
    
    .body-text {
      text-align: justify;
      margin-bottom: 30px;
      font-size: 11pt;
    }
    
    .closing {
      margin-top: 40px;
      margin-bottom: 80px;
      font-size: 11pt;
    }
    
    .signature-area {
      text-align: center;
      margin-top: 60px;
    }
    
    .signature-line {
      border-top: 1px solid #333;
      width: 250px;
      margin: 0 auto 10px;
    }
    
    .signature-info {
      font-size: 11pt;
      line-height: 1.4;
    }
    
    /* Responsive adjustments for mobile */
    @media (max-width: 768px) {
      body {
        padding: 10px 5px;
      }
      
      .page {
        width: 95%;
        padding: 40px 20px;
        font-size: 10.5pt;
      }
      
      .date,
      .recipient,
      .reference,
      .salutation,
      .body-text,
      .closing,
      .signature-info {
        font-size: 10pt;
      }
      
      .signature-line {
        width: 200px;
      }
    }
  </style>
</head>
<body>
  <div class="page">
    <div class="date">$dateStr</div>
    
    <div class="recipient">
      <p>Señor:</p>
      <p><strong>Dr. Richard Jorge Torrez Juaniquina Ph. D.</strong></p>
      <p><strong>DIRECTOR DE POSGRADO - UPEA</strong></p>
      <p><strong>Presente.-</strong></p>
    </div>
    
    <div class="reference">
      Ref.: SOLICITUD DE PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL
    </div>
    
    <div class="salutation">
      Distinguido Magister:
    </div>
    
    <div class="body-text">
      Me es grato hacerle llegar un saludo cordial y fraterno a nombre mío, deseándole mis mejores deseos de éxitos en las labores que desempeña.
    </div>
    
    <div class="body-text">
      El motivo de la presente es para solicitar a su autoridad una <strong>PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL</strong>, para la inscripción al PROGRAMA: "Diplomado en: $career" MODALIDAD: Virtual; siendo que mi persona debe realizar solicitud en la Universidad de origen de estudios, por ese motivo es que le mando mi solicitud de prórroga. Por ese motivo es que le mando mi solicitud, esperando el visto bueno de su autoridad me despido.
    </div>
    
    <div class="closing">
      Atentamente,
    </div>
    
    <div class="signature-area">
      <div class="signature-line"></div>
      <div class="signature-info">
        <p><strong>$name</strong></p>
        <p>C.I. $ci</p>
      </div>
    </div>
  </div>
</body>
</html>
''';

      // Save HTML to temporary file for preview
      final dir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${dir.path}${Platform.pathSeparator}temp_previews');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      
      final tempFile = File('${tempDir.path}${Platform.pathSeparator}prorroga_preview_${DateTime.now().millisecondsSinceEpoch}.html');
      await tempFile.writeAsString(htmlContent);

      // Show HTML preview in WebView
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, color: kPrimaryColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Vista Previa - Carta de Prórroga',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: kTextColor,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                // WebView
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: WebViewWidget(
                      controller: WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..setBackgroundColor(Colors.white)
                        ..loadFile(tempFile.path),
                    ),
                  ),
                ),
                // Action buttons
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: kPrimaryColor),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _generateSignedProrroga();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Firmar y Guardar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Clean up temp file
      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) setState(() => _busyGlobal = false);
      _mostrarMensaje('Error al generar vista previa: $e', esError: true);
    }
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    if (month < 1 || month > 12) return 'mes';
    return months[month - 1];
  }

  Future<void> _generarCartaInscripcion() async {
    setState(() => _busyKey = 'carta_inscripcion_path');
    try {
      final personalData = await LocalStorageService.getPersonalData();
      var nombreCompleto =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      if (nombreCompleto.isEmpty) {
        final session = await LocalStorageService.getSessionData();
        nombreCompleto = (session?['nombreUsuario'] as String?)?.trim() ?? '';
      }
      final numeroCI = (personalData?['numeroCI'] ?? '').toString().trim();
      if (numeroCI.isEmpty || nombreCompleto.isEmpty) {
        _mostrarMensaje(
          'Complete nombre, apellidos y CI en Mi perfil personal para generar la carta.',
          esError: true,
        );
        return;
      }
      final expedidoEn = (personalData?['expedidoEn'] ?? '').toString().trim();
      final nombrePrograma =
          (personalData?['nombreProgramaCarta'] ?? '').toString().trim();
      final modalidad =
          (personalData?['modalidadProgramaCarta'] ?? 'Virtual').toString().trim();
      final numeroRef = DateTime.now().millisecondsSinceEpoch % 10000;
      
      // Obtener la ruta de la firma digital
      final firmaPath = await LocalStorageService.getSignatureImagePath();
      
      final generador = ServicioGeneradorCartaInscripcion();
      final ruta = await generador.generarCarta(
        tipoPrograma: TipoPrograma.diplomado,
        nombrePrograma: nombrePrograma.isEmpty
            ? 'Formulación y Evaluación de Proyectos'
            : nombrePrograma,
        modalidad: modalidad,
        nombreCompleto: nombreCompleto,
        numeroCI: numeroCI,
        expedidoEn: expedidoEn.isEmpty ? null : expedidoEn,
        montoDeposito: '2400',
        numeroRef: '$numeroRef',
        signatureImagePath: firmaPath, // ✅ Pasar la firma
        guardarEnPreferencias: false,
      );
      await _saveDocPath('carta_inscripcion_path', ruta);
      if (!mounted) return;
      setState(() => _cartaInscripcionPath = ruta);
      _mostrarMensaje('Carta de inscripción generada');
    } catch (e) {
      _mostrarMensaje('Error al generar carta: $e', esError: true);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }
//Funcion que genera la ficha de inscripcion
  Future<void> _generarFichaInscripcion() async {
    setState(() => _busyKey = 'ficha_inscripcion_path');
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final nombreCompleto =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final numeroCI = (personalData?['numeroCI'] ?? '').toString().trim();
      final email = (personalData?['email'] ?? '').toString().trim();
      final telefono = (personalData?['telefono'] ?? '').toString().trim();
      final now = DateTime.now();
      final fechaStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      final html = '''
<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Ficha de Inscripción</title>
<style>body{font-family:Segoe UI,Arial;padding:24px;max-width:600px;margin:0 auto}
h1{color:#1E3A8A;border-bottom:2px solid #2563EB;padding-bottom:8px}
table{width:100%;border-collapse:collapse;margin:16px 0}
th,td{border:1px solid #ddd;padding:10px;text-align:left}
th{background:#F1F5F9;font-weight:600}
.footer{margin-top:24px;font-size:12px;color:#64748B}</style></head>
<body>
<h1>Ficha de Inscripción - Posgrado UPEA</h1>
<p>Generada el $fechaStr</p>
<table>
<tr><th>Apellidos y Nombres</th><td>$nombreCompleto</td></tr>
<tr><th>C.I.</th><td>$numeroCI</td></tr>
<tr><th>Correo</th><td>$email</td></tr>
<tr><th>Teléfono</th><td>$telefono</td></tr>
<tr><th>Programa</th><td>Diplomado</td></tr>
<tr><th>Modalidad</th><td>Virtual</td></tr>
</table>
<p class="footer">Documento generado automáticamente por la aplicación de preinscripción.</p>
</body></html>''';
      final dir = await getApplicationDocumentsDirectory();
      final fichaDir = Directory('${dir.path}/fichas_inscripcion');
      if (!await fichaDir.exists()) await fichaDir.create(recursive: true);
      final file = File(
        '${fichaDir.path}/ficha_${numeroCI}_${now.millisecondsSinceEpoch}.html',
      );
      await file.writeAsString(html);
      await _saveDocPath('ficha_inscripcion_path', file.path);
      if (!mounted) return;
      setState(() => _fichaInscripcionPath = file.path);
      _mostrarMensaje('Ficha de inscripción generada');
    } catch (e) {
      _mostrarMensaje('Error al generar ficha: $e', esError: true);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  void _showLegalDocumentReader({
    required String title,
    required String content,
    VoidCallback? onConfirm,
    String confirmText = "Aceptar",
  }) {
    _signaturePng = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final signatureKey = GlobalKey();
        List<Offset?> points = [];

        Future<Uint8List?> captureSignature() async {
          if (points.length < 2) return null;
          try {
            final boundary = signatureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
            if (boundary == null) return null;
            final image = await boundary.toImage(pixelRatio: 3.0);
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            return data?.buffer.asUint8List();
          } catch (_) {
            return null;
          }
        }

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: fontHeading,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: kTextColor,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Scrollable Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Paper Header Effect
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Actual Text Content
                            SelectableText(
                              content,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 16,
                                height: 1.6,
                                color: Color(0xFF334155),
                              ),
                              textAlign: TextAlign.justify,
                            ),

                            if (onConfirm != null) ...[
                              const Divider(height: 32, thickness: 1),
                              Text(
                                "Firma digital",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              RepaintBoundary(
                                key: signatureKey,
                                child: Container(
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: points.length < 2
                                          ? const Color(0xFFCBD5E1)
                                          : kPrimaryColor.withOpacity(0.6),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onPanStart: (details) {
                                      final box = signatureKey.currentContext?.findRenderObject() as RenderBox?;
                                      if (box == null) return;
                                      final local = box.globalToLocal(details.globalPosition);
                                      setModalState(() {
                                        points = List.of(points)..add(local);
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      final box = signatureKey.currentContext?.findRenderObject() as RenderBox?;
                                      if (box == null) return;
                                      final local = box.globalToLocal(details.globalPosition);
                                      setModalState(() {
                                        points = List.of(points)..add(local);
                                      });
                                    },
                                    onPanEnd: (_) {
                                      setModalState(() {
                                        points = List.of(points)..add(null);
                                      });
                                    },
                                    child: CustomPaint(
                                      painter: _SignaturePainter(points),
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: points.length < 2
                                            ? const Text(
                                                "Firma aquí con tu dedo",
                                                style: TextStyle(
                                                  color: Color(0xFF94A3B8),
                                                  fontSize: 13,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Puedes borrar y volver a firmar si lo necesitas.",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {
                                      setModalState(() => points = []);
                                      _signaturePng = null;
                                    },
                                    icon: const Icon(Icons.refresh, size: 16),
                                    label: const Text("Limpiar"),
                                  ),
                                ],
                              ),
                              const Divider(height: 24, thickness: 1),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: kSuccessColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Al continuar, aceptas firmar este documento digitalmente con tus datos registrados.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Fixed Bottom Action
                  if (onConfirm != null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  "Cancelar",
                                  style: TextStyle(
                                    color: kTextSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (onConfirm != null) {
                                    final png = await captureSignature();
                                    if (mounted) {
                                      setState(() => _signaturePng = png);
                                    }
                                  }
                                  onConfirm?.call();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  confirmText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ciOk =
        (_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty;
    final tituloOk = _hasTitle ? (_tituloPath ?? '').isNotEmpty : true;
    final prorrogaOk = !_hasTitle ? (_prorrogaPath ?? '').isNotEmpty : true;
    // Si hasTitle es true, prorrogaOk se considera cumplido (requisito ignorado) y viceversa.

    final requiredTotal = 3;
    final requiredDone =
        (ciOk ? 2 : 0) +
        ((_hasTitle && (_tituloPath?.isNotEmpty ?? false)) ||
                (!_hasTitle && (_prorrogaPath?.isNotEmpty ?? false))
            ? 1
            : 0);
    final progress = requiredTotal == 0 ? 0.0 : (requiredDone / requiredTotal);

    return WillPopScope(
      onWillPop: () async {
        final canPop = context.canPop();
        if (canPop) {
          context.pop();
        } else {
          context.go('/sistema/pantalla_principal');
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: kSurfaceColor,
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF005BAC), // Primary Blue
                  Color(0xFF0077CC), // Medium Blue
                  Color(0xFF3D8FE0), // Light Blue
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005BAC).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: AppBar(
                toolbarHeight: 80,
                title: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      // Icono con animación de escala
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.folder_special_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      // Título con animación de fade
                      Expanded(
                        child: FadeInLeft(
                          duration: const Duration(milliseconds: 500),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mis Documentos',
                                style: TextStyle(
                                  fontFamily: fontHeading,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Gestiona tus archivos personales',
                                style: TextStyle(
                                  fontFamily: fontBody,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 13,
                                  color: Colors.white70,
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                centerTitle: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/sistema/pantalla_principal');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  // Botón de escaneo inteligente con efecto pulsante
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 8),
                    child: FadeInRight(
                      duration: const Duration(milliseconds: 500),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 1.0, end: 1.05),
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  _abrirEscaneoInteligente();
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4CAF50),
                                        Color(0xFF66BB6A),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF4CAF50).withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.document_scanner_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Botón de estadísticas
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 8),
                    child: FadeInRight(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _mostrarEstadisticas();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.analytics_outlined,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Menú de opciones mejorado
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 8),
                    child: FadeInRight(
                      duration: const Duration(milliseconds: 700),
                      delay: const Duration(milliseconds: 200),
                      child: Material(
                        color: Colors.transparent,
                        child: PopupMenuButton<String>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 12,
                          offset: const Offset(0, 55),
                          color: Colors.white,
                          shadowColor: Colors.black.withOpacity(0.2),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.more_vert_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          onSelected: (value) {
                            HapticFeedback.selectionClick();
                            switch (value) {
                              case 'smart_scan':
                                _abrirEscaneoInteligente();
                                break;
                              case 'stats':
                                _mostrarEstadisticas();
                                break;
                              case 'help':
                                _mostrarAyuda();
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'smart_scan',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFF4CAF50).withOpacity(0.15),
                                          const Color(0xFF66BB6A).withOpacity(0.1),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.auto_awesome,
                                      size: 22,
                                      color: Color(0xFF4CAF50),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Escaneo Inteligente',
                                          style: TextStyle(
                                            fontFamily: fontHeading,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: kTextColor,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'OCR avanzado con IA',
                                          style: TextStyle(
                                            fontFamily: fontBody,
                                            fontSize: 12,
                                            color: kTextSecondary,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: kTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem(
                              value: 'stats',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.analytics_outlined,
                                      size: 22,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Estadísticas',
                                          style: TextStyle(
                                            fontFamily: fontHeading,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: kTextColor,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Ver tu progreso',
                                          style: TextStyle(
                                            fontFamily: fontBody,
                                            fontSize: 12,
                                            color: kTextSecondary,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: kTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                            const PopupMenuDivider(height: 1),
                            PopupMenuItem(
                              value: 'help',
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.help_outline_rounded,
                                      size: 22,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Ayuda',
                                          style: TextStyle(
                                            fontFamily: fontHeading,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: kTextColor,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Guía de uso completa',
                                          style: TextStyle(
                                            fontFamily: fontBody,
                                            fontSize: 12,
                                            color: kTextSecondary,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16,
                                    color: kTextSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: _busyGlobal
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              )
            : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                SlideInUp(
                  duration: const Duration(milliseconds: 600),
                  child: _buildProgressCard(
                    progress,
                    requiredDone,
                    requiredTotal,
                    ciOk,
                    tituloOk,
                    prorrogaOk,
                  ),
                ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 100),
                  duration: const Duration(milliseconds: 500),
                  child: _buildSectionTitle('Foto de perfil'),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 150),
                  child: _buildProfilePhotoCard(),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 220),
                  child: Container(
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                    ),
                    child: SwitchListTile(
                      value: _deferDocuments,
                      activeColor: kPrimaryColor,
                      title: const Text(
                        'Cargaré mis documentos después',
                        style: TextStyle(
                          fontFamily: fontBody,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: kPrimaryColor,
                        ),
                      ),
                      subtitle: const Text(
                        'Puedes continuar ahora y subirlos más tarde.',
                        style: TextStyle(fontSize: 12),
                      ),
                      onChanged: (val) => _setDeferDocuments(val),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 600),
                  child: _buildSectionTitle('Academico'),
                ),
                const SizedBox(height: 12),

                // Toggle Title vs Prorroga
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SwitchListTile(
                      value: _hasTitle,
                      activeColor: kPrimaryColor,
                      title: const Text(
                        'Tengo Título en Provisión Nacional',
                        style: TextStyle(
                          fontFamily: fontBody,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      onChanged: _deferDocuments
                          ? null
                          : (val) {
                          setState(() {
                            _hasTitle = val;
                            // Opcional: limpiar la otra ruta para evitar confusión.
                            // Por ahora se mantienen; la validación ignora la oculta.
                          });
                        },
                    ),
                  ),
                ),

                if (_hasTitle)
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: _DocUploadCard(
                      title: 'Título Académico',
                      description: 'Foto o escaneo legible',
                      path: _tituloPath,
                      isLoading: _busyKey == 'titulo_path',
                      isRequired: true,
                      enabled: !_deferDocuments,
                      onUpload: () => _pickAndSave(
                        key: 'titulo_path',
                        prefix: 'titulo_prov_nacional',
                        onSet: (p) => _tituloPath = p,
                        allowFile: true,
                      ),
                      onPreview: () => _previewDoc(_tituloPath!),
                      onDelete: () async {
                        if (await _confirmDelete('Título')) {
                          await _saveDocPath('titulo_path', null);
                          setState(() => _tituloPath = null);
                        }
                      },
                    ),
                  )
                else
                  FadeInUp(
                    delay: const Duration(milliseconds: 800),
                    child: _DocUploadCard(
                      title: 'Carta de Prórroga',
                      description: 'Firmar o subir documento',
                      path: _prorrogaPath,
                      isLoading: _busyKey == 'prorroga_path',
                      isRequired: true,
                      enabled: !_deferDocuments,
                      isAutoGenerated:
                          _prorrogaPath == null ||
                          (_prorrogaPath!.contains(
                            'generada',
                          )), // Guessing check
                      canGenerate: true,
                      onUpload: _onProrrogaAction,
                      onPreview: () => _previewDoc(_prorrogaPath!),
                      onDelete: () async {
                        if (await _confirmDelete('Prórroga')) {
                          await _saveDocPath('prorroga_path', null);
                          setState(() => _prorrogaPath = null);
                        }
                      },
                    ),
                  ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 250),
                  child: _buildSectionTitle('Preinscripción'),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 260),
                  child: _DocUploadCard(
                    title: 'Carta de solicitud (diplomado)',
                    description: 'Se genera con sus datos',
                    path: _cartaInscripcionPath,
                    isLoading: _busyKey == 'carta_inscripcion_path',
                    isRequired: true,
                    enabled: !_deferDocuments,
                    canGenerate: true,
                    onUpload: _generarCartaInscripcion,
                    onPreview: _cartaInscripcionPath != null ? () => _previewDoc(_cartaInscripcionPath!) : null,
                    onDelete: () async {
                      if (await _confirmDelete('Carta de inscripción')) {
                        await _saveDocPath('carta_inscripcion_path', null);
                        setState(() => _cartaInscripcionPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 270),
                  child: _DocUploadCard(
                    title: 'Comprobante de pago (matrícula)',
                    description: 'Adjuntar comprobante de pago por matrícula',
                    path: _comprobanteMatriculaPath,
                    isLoading: _busyKey == 'comprobante_matricula_path',
                    isRequired: false,
                    enabled: true, // Siempre habilitado para subir comprobantes
                    onUpload: () => _pickAndSave(
                      key: 'comprobante_matricula_path',
                      prefix: 'pago_matricula',
                      onSet: (p) => _comprobanteMatriculaPath = p,
                      allowFile: true,
                    ),
                    onPreview: _comprobanteMatriculaPath != null ? () => _previewDoc(_comprobanteMatriculaPath!) : null,
                    onDelete: () async {
                      if (await _confirmDelete('Comprobante matrícula')) {
                        await _saveDocPath('comprobante_matricula_path', null);
                        setState(() => _comprobanteMatriculaPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 280),
                  child: _DocUploadCard(
                    title: 'Comprobante de pago (colegiatura)',
                    description: 'Adjuntar comprobante de pago por colegiatura (opción 2 de 2)',
                    path: _comprobanteColegiaturaPath,
                    isLoading: _busyKey == 'comprobante_colegiatura_path',
                    isRequired: false,
                    enabled: true, // Siempre habilitado para subir comprobantes
                    onUpload: () => _pickAndSave(
                      key: 'comprobante_colegiatura_path',
                      prefix: 'pago_colegiatura',
                      onSet: (p) => _comprobanteColegiaturaPath = p,
                      allowFile: true,
                    ),
                    onPreview: _comprobanteColegiaturaPath != null ? () => _previewDoc(_comprobanteColegiaturaPath!) : null,
                    onDelete: () async {
                      if (await _confirmDelete('Comprobante colegiatura')) {
                        await _saveDocPath('comprobante_colegiatura_path', null);
                        setState(() => _comprobanteColegiaturaPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 290),
                  child: _DocUploadCard(
                    title: 'Ficha de inscripción',
                    description: 'Se genera automáticamente con sus datos. Pulse Generar.',
                    path: _fichaInscripcionPath,
                    isLoading: _busyKey == 'ficha_inscripcion_path',
                    isRequired: true,
                    enabled: !_deferDocuments,
                    canGenerate: true,
                    onUpload: _generarFichaInscripcion,
                    onPreview: _fichaInscripcionPath != null ? () => _previewDoc(_fichaInscripcionPath!) : null,
                    onDelete: () async {
                      if (await _confirmDelete('Ficha de inscripción')) {
                        await _saveDocPath('ficha_inscripcion_path', null);
                        setState(() => _fichaInscripcionPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _DocUploadCard(
                    title: 'Hoja de vida (CV)',
                    description: 'Adjuntar currículum o hoja de vida',
                    path: _hojaVidaPath,
                    isLoading: _busyKey == 'hoja_vida_path',
                    isRequired: true,
                    enabled: !_deferDocuments,
                    onUpload: () => _pickAndSave(
                      key: 'hoja_vida_path',
                      prefix: 'hoja_vida',
                      onSet: (p) => _hojaVidaPath = p,
                      allowFile: true,
                    ),
                    onPreview: _hojaVidaPath != null ? () => _previewDoc(_hojaVidaPath!) : null,
                    onDelete: () async {
                      if (await _confirmDelete('Hoja de vida')) {
                        await _saveDocPath('hoja_vida_path', null);
                        setState(() => _hojaVidaPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: _buildSectionTitle('Identificacion'),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _DocUploadCard(
                    title: 'Cedula (Anverso)',
                    description: 'Foto clara del lado frontal',
                    path: _ciFrontPath,
                    isLoading: _busyKey == 'ci_front_path',
                    isRequired: false,
                    enabled: !_deferDocuments,
                    onUpload: () => _pickAndSave(
                      key: 'ci_front_path',
                      prefix: 'cedula_anverso',
                      onSet: (p) => _ciFrontPath = p,
                    ),
                    onPreview: () => _previewDoc(_ciFrontPath!),
                    onDelete: () async {
                      if (await _confirmDelete('C.I. Anverso')) {
                        await _saveDocPath('ci_front_path', null);
                        setState(() => _ciFrontPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 400),
                  child: _DocUploadCard(
                    title: 'Cedula (Reverso)',
                    description: 'Foto clara del lado posterior',
                    path: _ciBackPath,
                    isLoading: _busyKey == 'ci_back_path',
                    isRequired: false,
                    enabled: !_deferDocuments,
                    onUpload: () => _pickAndSave(
                      key: 'ci_back_path',
                      prefix: 'cedula_reverso',
                      onSet: (p) => _ciBackPath = p,
                    ),
                    onPreview: () => _previewDoc(_ciBackPath!),
                    onDelete: () async {
                      if (await _confirmDelete('C.I. Reverso')) {
                        await _saveDocPath('ci_back_path', null);
                        setState(() => _ciBackPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                if ((_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty)
                  FadeInUp(
                    delay: const Duration(milliseconds: 450),
                    child: _DocUploadCard(
                      title: 'Fotocopia de C.I. (PDF)',
                      description: 'Se genera automáticamente desde anverso y reverso, o pulse Generar',
                      path: (_participantDocs?['ci_photocopy_pdf_path'] as String?) ?? '',
                      isLoading: _busyKey == 'ci_photocopy_pdf_path',
                      isRequired: false,
                      enabled: !_deferDocuments,
                      canGenerate: true,
                      onUpload: () => _generatePhotocopyFromPaths(),
                      onPreview: () {
                        final p = _participantDocs?['ci_photocopy_pdf_path'] as String?;
                        if (p != null && p.isNotEmpty) {
                          _previewDoc(p);
                        }
                      },
                      onDelete: () async {
                        if (await _confirmDelete('Fotocopia de C.I.')) {
                          await _saveDocPath('ci_photocopy_pdf_path', null);
                          setState(() {
                            _participantDocs?.remove('ci_photocopy_pdf_path');
                          });
                        }
                      },
                    ),
                  ),
                if ((_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _busyKey == 'ci_photocopy_pdf_path'
                          ? null
                          : _generatePhotocopyFromPaths,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerar PDF'),
                    ),
                  ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _DocUploadCard(
                    title: 'Cedula Hoja Carta (Fusionado)',
                    description: 'Generada o Subida (PDF/Foto)',
                    path: _ciLetterPath,
                    isLoading: _busyKey == 'ci_letter_path',
                    isRequired: false,
                    isAutoGenerated: _ciLetterPath == null,
                    enabled: !_deferDocuments,
                    canGenerate: true,
                    onUpload: _onCiLetterAction,
                    onPreview: () => _previewDoc(_ciLetterPath!),
                    onDelete: () async {
                      if (await _confirmDelete('Hoja Carta')) {
                        await _saveDocPath('ci_letter_path', null);
                        setState(() => _ciLetterPath = null);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          decoration: BoxDecoration(
            color: kCardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: ElasticIn(
              duration: const Duration(milliseconds: 1000),
              child: ElevatedButton(
                onPressed: (_busyGlobal || _busyKey != null)
                    ? null
                    : () {
                        context.pop();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: kPrimaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Guardar y Continuar',
                  style: TextStyle(
                    fontFamily: fontHeading,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showIncompleteSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: kErrorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: const [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text('Completa los documentos requeridos.')),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: fontBody,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: kTextSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfilePhotoCard() {
    final hasPhoto = _profilePhoto != null;
    final isBusy = _busyKey == 'profile_photo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 96,
              height: 96,
               color: const Color(0xFF808080),
              child: hasPhoto
                  ? Image.file(_profilePhoto!, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.white70, size: 48),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foto 4x4 (Fondo Plomo)',
                  style: TextStyle(
                    fontFamily: fontHeading,
                    fontWeight: FontWeight.w600,
                    color: kTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Se procesa con recorte del rostro y fondo gris 4x4. Si ya registraste una foto, se usa como base.',
                  style: TextStyle(
                    fontFamily: fontBody,
                    fontSize: 12,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: isBusy ? null : _updateProfilePhoto,
                      icon: isBusy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.camera_alt_outlined, size: 18),
                      label: const Text('Actualizar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (hasPhoto)
                      OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : () => _previewImage(_profilePhoto!.path),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kPrimaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Ver'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    double progress,
    int done,
    int total,
    bool ciOk,
    bool tituloOk,
    bool prorrogaOk,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimaryColor, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Progreso de Documentos',
                  style: TextStyle(
                    fontFamily: fontHeading,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$done / $total Obligatorios',
                  style: const TextStyle(
                    fontFamily: fontBody,
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.15),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          _StatusRow(label: 'Cédula de Identidad', isDone: ciOk),
          const SizedBox(height: 8),
          _StatusRow(
            label: _hasTitle ? 'Título Académico' : 'Carta de Prórroga',
            isDone: _hasTitle ? (_tituloPath != null) : (_prorrogaPath != null),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isOptional;

  const _StatusRow({
    required this.label,
    required this.isDone,
    this.isOptional = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone
                ? _MisDocumentosPersonalesScreenState.kSuccessColor
                : Colors.white.withOpacity(0.2),
          ),
          child: Icon(
            Icons.check,
            size: 12,
            color: isDone ? Colors.white : Colors.transparent,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$label ${isOptional ? '(Opcional)' : ''}',
          style: TextStyle(
            fontFamily: _MisDocumentosPersonalesScreenState.fontBody,
            color: Colors.white.withOpacity(isDone ? 1.0 : 0.6),
            fontSize: 13,
            decoration: isDone ? null : null,
          ),
        ),
      ],
    );
  }
}

class _DocUploadCard extends StatelessWidget {
  final String title;
  final String description;
  final String? path;
  final bool isRequired;
  final bool isLoading;
  final bool isAutoGenerated;
  final bool canGenerate;
  final bool enabled;
  final VoidCallback onUpload;
  final VoidCallback? onPreview;
  final VoidCallback onDelete;

  const _DocUploadCard({
    required this.title,
    required this.description,
    required this.path,
    required this.onUpload,
    this.onPreview,
    required this.onDelete,
    this.isRequired = false,
    this.isLoading = false,
    this.isAutoGenerated = false,
    this.canGenerate = true,
    this.enabled = true,
  });

  bool get hasFile => path != null && path!.isNotEmpty;

  
  @override
  Widget build(BuildContext context) {
    final color = hasFile ? _MisDocumentosPersonalesScreenState.kSuccessColor : _MisDocumentosPersonalesScreenState.kPrimaryColor;
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: AbsorbPointer(
        absorbing: !enabled,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _MisDocumentosPersonalesScreenState.kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.15), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.07),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Línea de acento lateral
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    color: color,
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: hasFile
                        ? onPreview
                        : (isAutoGenerated && !canGenerate ? null : onUpload),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Thumbnail or Icon
                          Hero(
                            tag: 'doc_$title',
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: hasFile
                                    ? Colors.transparent
                                    : color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                // Solo mostrar preview de imagen para archivos de imagen reales
                                image: (hasFile &&
                                        !path!.toLowerCase().endsWith('.pdf') &&
                                        !path!.toLowerCase().endsWith('.html') &&
                                        !path!.toLowerCase().endsWith('.htm'))
                                    ? DecorationImage(
                                        image: FileImage(File(path!)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: hasFile
                                    ? Border.all(
                                        color: color.withOpacity(0.2),
                                        width: 1,
                                      )
                                    : null,
                              ),
                              child: isLoading
                                  ? Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: color,
                                        ),
                                      ),
                                    )
                                  : (!hasFile
                                      ? Icon(
                                          isAutoGenerated
                                              ? Icons.auto_awesome_rounded
                                              : Icons.cloud_upload_rounded,
                                          color: color,
                                          size: 26,
                                        )
                                      : (path!.toLowerCase().endsWith('.pdf')
                                          ? const Icon(
                                              Icons.picture_as_pdf_rounded,
                                              color: Colors.red,
                                              size: 28,
                                            )
                                          : null)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          fontFamily:
                                              _MisDocumentosPersonalesScreenState
                                                  .fontHeading,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14.5,
                                          color: _MisDocumentosPersonalesScreenState
                                              .kTextColor,
                                        ),
                                      ),
                                    ),
                                    if (hasFile)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: _MisDocumentosPersonalesScreenState
                                            .kSuccessColor,
                                        size: 18,
                                      )
                                    else if (isRequired)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _MisDocumentosPersonalesScreenState
                                              .kWarningBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _MisDocumentosPersonalesScreenState.kWarningText.withOpacity(0.2)),
                                        ),
                                        child: const Text(
                                          'REQ',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w900,
                                            color:
                                                _MisDocumentosPersonalesScreenState
                                                    .kWarningText,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasFile ? 'Documento cargado correctamente' : description,
                                  style: TextStyle(
                                    fontFamily:
                                        _MisDocumentosPersonalesScreenState.fontBody,
                                    fontSize: 11.5,
                                    color: _MisDocumentosPersonalesScreenState
                                        .kTextSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          const SizedBox(width: 8),
                          if (hasFile)
                            PopupMenuButton<String>(
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color:
                                    _MisDocumentosPersonalesScreenState.kTextSecondary,
                                size: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              onSelected: (value) {
                                if (value == 'view') onPreview?.call();
                                if (value == 'delete') onDelete();
                                if (value == 'update' && !isAutoGenerated) onUpload();
                                if (value == 'update' && isAutoGenerated) {
                                  onUpload(); // Regenerate
                                }
                              },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility_outlined, size: 20, color: _MisDocumentosPersonalesScreenState.kPrimaryColor),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Ver documento',
                                          style: TextStyle(
                                            color: _MisDocumentosPersonalesScreenState.kTextColor,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: _MisDocumentosPersonalesScreenState.fontBody,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!isAutoGenerated)
                                    PopupMenuItem(
                                      value: 'update',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 20, color: _MisDocumentosPersonalesScreenState.kPrimaryColor),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Actualizar',
                                            style: TextStyle(
                                              color: _MisDocumentosPersonalesScreenState.kTextColor,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: _MisDocumentosPersonalesScreenState.fontBody,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (isAutoGenerated)
                                    PopupMenuItem(
                                      value: 'update',
                                      child: Row(
                                        children: [
                                          Icon(Icons.refresh_rounded, size: 20, color: _MisDocumentosPersonalesScreenState.kPrimaryColor),
                                          const SizedBox(width: 10),
                                          Text(
                                            'Regenerar',
                                            style: TextStyle(
                                              color: _MisDocumentosPersonalesScreenState.kTextColor,
                                              fontWeight: FontWeight.w700,
                                              fontFamily: _MisDocumentosPersonalesScreenState.fontBody,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Eliminar',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w900,
                                            fontFamily: _MisDocumentosPersonalesScreenState.fontBody,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                            ),
                          if (!hasFile)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: isAutoGenerated
                                  ? IconButton(
                                      onPressed: canGenerate ? onUpload : null,
                                      icon: Icon(
                                        Icons.auto_fix_high_rounded,
                                        color: canGenerate
                                            ? _MisDocumentosPersonalesScreenState
                                                  .kPrimaryColor
                                            : Colors.grey.withOpacity(0.3),
                                      ),
                                    )
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: _MisDocumentosPersonalesScreenState
                                            .kPrimaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        color: _MisDocumentosPersonalesScreenState
                                            .kPrimaryColor,
                                        size: 20,
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
