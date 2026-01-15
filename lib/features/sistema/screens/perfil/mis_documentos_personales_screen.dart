import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';
import 'package:refactor_template/core/services/servicio_compositor_cartas_ci.dart';
import 'package:refactor_template/core/services/servicio_ocr_ia_avanzado.dart';
import 'package:refactor_template/features/sistema/screens/perfil/pantalla_escaneo_inteligente.dart';
import 'package:share_plus/share_plus.dart';

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
  static const Color kPrimaryColor = Color(0xFF2563EB); // Vivid Blue
  static const Color kPrimaryDark = Color(0xFF1E3A8A); // Navy Blue
  static const Color kSurfaceColor = Color(0xFFF8FAFC); // Cool Gray 50
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF0F172A); // Slate 900
  static const Color kTextSecondary = Color(0xFF64748B); // Slate 500
  static const Color kSuccessColor = Color(0xFF10B981); // Emerald 500
  static const Color kErrorColor = Color(0xFFEF4444); // Red 500
  static const Color kWarningBg = Color(0xFFFFF7ED); // Orange 50
  static const Color kWarningText = Color(0xFFC2410C); // Orange 700

  // --- Typography ---
  static const String fontHeading = 'Poppins';
  static const String fontBody = 'Intel'; // Maps to Inter in pubspec

  final ImagePicker _picker = ImagePicker();

  String? _ciFrontPath;
  String? _ciBackPath;
  String? _ciLetterPath;
  String? _tituloPath;
  String? _prorrogaPath;

  bool _hasTitle = true; // Default assumption

  // Track busy state per action for granular feedback
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
    if (!mounted) return;
    setState(() {
      _ciFrontPath = data?['ci_front_path'] as String?;
      _ciBackPath = data?['ci_back_path'] as String?;
      _ciLetterPath = data?['ci_letter_path'] as String?;
      _tituloPath = data?['titulo_path'] as String?;
      _prorrogaPath = data?['prorroga_path'] as String?;

      // Determine mode based on existing data
      if (_prorrogaPath != null &&
          (_tituloPath == null || _tituloPath!.isEmpty)) {
        _hasTitle = false;
      } else {
        _hasTitle = true;
      }

      _busyGlobal = false;
    });
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
                            colors: [kPrimaryColor, Colors.purple],
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
                      subtitle: const Text(
                        'Detecta y extrae información automáticamente',
                        style: TextStyle(fontSize: 11),
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
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.photo_library_rounded,
                        color: Colors.purple,
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
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.insert_drive_file_rounded,
                          color: Colors.orange,
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
  // NUEVAS FUNCIONALIDADES CON IA
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
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
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
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
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

  Future<void> _previewDoc(String path) async {
    if (path.toLowerCase().endsWith('.pdf')) {
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
    // Is Image
    await _previewImage(path);
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

  Future<void> _onCiLetterAction() async {
    // Check if we can generate (need front and back)
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
      final personalData = await LocalStorageService.getPersonalData();
      final name =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final ci = personalData?['numeroCI'] ?? 'NO_CI';

      final out = await ServicioCompositorCartasCi.generateProrrogaLetter(
        fullName: name.isEmpty ? 'PARTICIPANTE' : name,
        ci: ci,
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
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.remove_red_eye_rounded,
                        color: Colors.purple,
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

      _showLegalDocumentReader(
        title: "Carta de Prórroga",
        content: body,
        onConfirm: () {
          Navigator.pop(context);
          _generateSignedProrroga();
        },
        confirmText: "Firmar y Guardar",
      );
    } catch (e) {
      if (mounted) setState(() => _busyGlobal = false);
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

  void _showLegalDocumentReader({
    required String title,
    required String content,
    VoidCallback? onConfirm,
    String confirmText = "Aceptar",
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
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
                          fontFamily:
                              'Times New Roman', // Serif looks more legal/official? Or use standard clean font
                          fontSize: 16,
                          height: 1.6,
                          color: Color(0xFF334155),
                        ),
                        textAlign: TextAlign.justify,
                      ),

                      const SizedBox(height: 40),

                      // Signature Placeholder
                      if (onConfirm != null) ...[
                        const Divider(height: 40, thickness: 1),
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
                          onPressed: onConfirm,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ciOk =
        (_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty;
    final tituloOk = _hasTitle ? (_tituloPath ?? '').isNotEmpty : true;
    final prorrogaOk = !_hasTitle ? (_prorrogaPath ?? '').isNotEmpty : true;
    // If hasTitle is true, prorrogaOk is effectively true (ignored requirement) and vice versa.

    final requiredTotal = 3;
    final requiredDone =
        (ciOk ? 2 : 0) +
        ((_hasTitle && (_tituloPath?.isNotEmpty ?? false)) ||
                (!_hasTitle && (_prorrogaPath?.isNotEmpty ?? false))
            ? 1
            : 0);
    final progress = requiredTotal == 0 ? 0.0 : (requiredDone / requiredTotal);

    return Scaffold(
      backgroundColor: kSurfaceColor,
      appBar: AppBar(
        title: const Text(
          'Documentos',
          style: TextStyle(
            fontFamily: fontHeading,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: kSurfaceColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Botón de estadísticas
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'Estadísticas',
            onPressed: _mostrarEstadisticas,
          ),
          // Menú de opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
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
              const PopupMenuItem(
                value: 'smart_scan',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: kPrimaryColor),
                    SizedBox(width: 12),
                    Text('Escaneo Inteligente'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Estadísticas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, size: 20),
                    SizedBox(width: 12),
                    Text('Ayuda'),
                  ],
                ),
              ),
            ],
          ),
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
                      if (!ciOk || !tituloOk) {
                        _showIncompleteSnackBar();
                        return;
                      }
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
      body: _busyGlobal
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
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
                  delay: const Duration(milliseconds: 200),
                  duration: const Duration(milliseconds: 500),
                  child: _buildSectionTitle('Identificación'),
                ),
                const SizedBox(height: 12),
                FadeInUp(
                  delay: const Duration(milliseconds: 300),
                  child: _DocUploadCard(
                    title: 'Cédula (Anverso)',
                    description: 'Foto clara del lado frontal',
                    path: _ciFrontPath,
                    isLoading: _busyKey == 'ci_front_path',
                    isRequired: true,
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
                    title: 'Cédula (Reverso)',
                    description: 'Foto clara del lado posterior',
                    path: _ciBackPath,
                    isLoading: _busyKey == 'ci_back_path',
                    isRequired: true,
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
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: _DocUploadCard(
                    title: 'Cédula Hoja Carta (Fusionado)',
                    description: 'Generada o Subida (PDF/Foto)',
                    path: _ciLetterPath,
                    isLoading: _busyKey == 'ci_letter_path',
                    isRequired: false,
                    isAutoGenerated: _ciLetterPath == null,
                    canGenerate:
                        true, // Always show action to allow upload even if cant generate
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
                const SizedBox(height: 24),
                FadeInLeft(
                  delay: const Duration(milliseconds: 600),
                  child: _buildSectionTitle('Académico'),
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
                      onChanged: (val) {
                        setState(() {
                          _hasTitle = val;
                          // Clear the other path to avoid confusion? Optional.
                          // For now we keep them but validation logic ignores the hidden one.
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
                const SizedBox(height: 40),
              ],
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
          colors: [kPrimaryDark, kPrimaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tu Progreso',
                style: TextStyle(
                  fontFamily: fontHeading,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$done / $total',
                  style: const TextStyle(
                    fontFamily: fontBody,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
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
              color: kSuccessColor,
              backgroundColor: Colors.black.withOpacity(0.2),
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
  final VoidCallback onUpload;
  final VoidCallback onPreview;
  final VoidCallback onDelete;

  const _DocUploadCard({
    required this.title,
    required this.description,
    required this.path,
    required this.onUpload,
    required this.onPreview,
    required this.onDelete,
    this.isRequired = false,
    this.isLoading = false,
    this.isAutoGenerated = false,
    this.canGenerate = true,
  });

  bool get hasFile => path != null && path!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _MisDocumentosPersonalesScreenState.kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasFile
              ? onPreview
              : (isAutoGenerated && !canGenerate ? null : onUpload),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Thumbnail or Icon
                Hero(
                  tag: 'doc_$title',
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: hasFile
                          ? Colors.transparent
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      image: (hasFile && !path!.toLowerCase().endsWith('.pdf'))
                          ? DecorationImage(
                              image: FileImage(File(path!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: hasFile
                          ? Border.all(
                              color: _MisDocumentosPersonalesScreenState
                                  .kPrimaryColor
                                  .withOpacity(0.2),
                              width: 1,
                            )
                          : null,
                    ),
                    child: isLoading
                        ? const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        : (!hasFile
                              ? Icon(
                                  isAutoGenerated
                                      ? Icons.auto_awesome
                                      : Icons.upload_file_rounded,
                                  color: _MisDocumentosPersonalesScreenState
                                      .kPrimaryColor,
                                  size: 28,
                                )
                              : (path!.toLowerCase().endsWith('.pdf')
                                    ? const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Colors.red,
                                        size: 32,
                                      )
                                    : null)),
                  ),
                ),
                const SizedBox(width: 16),
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
                                fontFamily: _MisDocumentosPersonalesScreenState
                                    .fontHeading,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
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
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _MisDocumentosPersonalesScreenState
                                    .kWarningBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'REQ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _MisDocumentosPersonalesScreenState
                                      .kWarningText,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasFile ? 'Documento cargado' : description,
                        style: TextStyle(
                          fontFamily:
                              _MisDocumentosPersonalesScreenState.fontBody,
                          fontSize: 12,
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
                if (hasFile)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _MisDocumentosPersonalesScreenState.kTextSecondary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'view') onPreview();
                      if (value == 'delete') onDelete();
                      if (value == 'update' && !isAutoGenerated) onUpload();
                      if (value == 'update' && isAutoGenerated)
                        onUpload(); // Regenerate
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Ver'),
                          ],
                        ),
                      ),
                      if (!isAutoGenerated)
                        const PopupMenuItem(
                          value: 'update',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Actualizar'),
                            ],
                          ),
                        ),
                      if (isAutoGenerated)
                        const PopupMenuItem(
                          value: 'update',
                          child: Row(
                            children: [
                              Icon(Icons.refresh_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('Regenerar'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
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
                              Icons.flash_on_rounded,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.add_rounded,
                              color: _MisDocumentosPersonalesScreenState
                                  .kPrimaryColor,
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
