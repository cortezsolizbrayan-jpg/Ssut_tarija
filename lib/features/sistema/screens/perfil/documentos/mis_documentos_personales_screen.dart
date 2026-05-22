import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:refactor_template/core/services/documentos/servicio_compositor_cartas_ci.dart';
import 'package:refactor_template/core/services/documentos/servicio_fotocopia_carnet.dart';
import 'package:refactor_template/core/services/documentos/servicio_generador_carta_inscripcion.dart';
import 'package:refactor_template/core/services/image_processing/servicio_procesador_imagen_perfil.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_ia_avanzado.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import '../escaneo/pantalla_escaneo_inteligente.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// 📄 TIPOS DE FUENTE PARA SELECCIÓN DE DOCUMENTOS
///
/// Enum que define los diferentes orígenes desde donde el usuario puede
/// obtener documentos para subir al sistema.
enum _SourceType { camera, gallery, file }

/// 📋 PANTALLA DE MIS DOCUMENTOS PERSONALES - V0.4.4
///
/// Pantalla principal para la gestión completa de documentos personales del estudiante.
/// Permite capturar, procesar, generar y administrar todos los documentos requeridos
/// para el proceso de inscripción en programas de posgrado UPEA.
///
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Gestión completa de documentos de identidad (CI anverso/reverso)
/// ✅ Escaneo inteligente con IA para extracción automática de datos
/// ✅ Generación automática de fotocopias y cartas legales
/// ✅ Soporte para títulos académicos y cartas de prórroga
/// ✅ Vista previa de documentos con WebView y PDF.js
/// ✅ Compartir documentos directamente desde la app
/// ✅ Estadísticas de progreso de documentación
/// ✅ Firma digital para cartas oficiales
/// ✅ Persistencia local con LocalStorageService
///
/// DOCUMENTOS SOPORTADOS:
/// - Cédula de Identidad (anverso y reverso)
/// - Fotocopia de carnet (generación automática)
/// - Hoja de carta fusionada (CI completo)
/// - Título académico o carta de prórroga
/// - Carta de inscripción generada
/// - Comprobantes de matrícula y colegiatura
/// - Ficha de inscripción
/// - Hoja de vida
/// - Foto 4x4 para perfil
///
/// FUNCIONALIDADES AVANZADAS:
/// - OCR con IA para extracción automática de datos personales
/// - Generación de PDFs profesionales con diseño UPEA
/// - Firma digital integrada para documentos oficiales
/// - Vista previa de PDFs con controles de zoom y compartir
/// - Detección automática de tipo de documento
/// - Validación y corrección de datos extraídos
///
/// INTEGRACIÓN:
/// - LocalStorageService para persistencia de documentos
/// - ServicioOcrIaAvanzado para procesamiento inteligente
/// - ServicioCompositorCartasCi para generación de cartas
/// - ServicioFotocopiaCarnet para PDFs de identidad
/// - Share Plus para compartir documentos
/// - WebView para vista previa de PDFs
class MisDocumentosPersonalesPantalla extends StatefulWidget {
  static const name = 'mis-documentos-personales-Pantalla';
  final String? idPrograma;

  const MisDocumentosPersonalesPantalla({super.key, this.idPrograma});

  @override
  State<MisDocumentosPersonalesPantalla> createState() =>
      _MisDocumentosPersonalesPantallaState();
}

class _MisDocumentosPersonalesPantallaState
    extends State<MisDocumentosPersonalesPantalla> {
  // 🎨 PALETA DE COLORES MODERNA ALINEADA CON SISTEMA UPEA
  /// Colores principales del sistema UPEA para consistencia visual
  static const Color kPrimaryColor = Color(0xFF005BAC); // Azul oficial UPEA
  static const Color kPrimaryDark = Color(
    0xFF003F7A,
  ); // Azul oscuro para contraste
  static const Color kSurfaceColor = Color(
    0xFFF0F4F8,
  ); // Fondo de superficie suave
  static const Color kCardColor = Colors.white; // Fondo de tarjetas
  static const Color kTextColor = Color(0xFF333333); // Texto principal
  static const Color kTextSecondary = Color(0xFF666666); // Texto secundario
  static const Color kSuccessColor = Color(0xFF4CAF50); // Verde de éxito
  static const Color kErrorColor = Color(0xFFD32F2F); // Rojo de error
  static const Color kWarningBg = Color(0xFFFFF7ED); // Fondo de advertencia
  static const Color kWarningText = Color(0xFF005BAC); // Texto de advertencia

  // 📝 TIPOGRAFÍA DEL SISTEMA
  /// Familias de fuentes definidas según design system UPEA
  static const String fontHeading = 'Poppins'; // Encabezados y títulos
  static const String fontBody = 'Intel'; // Cuerpo de texto (mapea a Inter)

  // 📷 SELECTOR DE IMÁGENES
  final ImagePicker _picker =
      ImagePicker(); // Servicio para capturar/seleccionar imágenes

  // 📁 RUTAS DE DOCUMENTOS ALMACENADOS
  /// Rutas de archivos de documentos de identidad
  String? _ciFrontPath; // Ruta del anverso de CI
  String? _ciBackPath; // Ruta del reverso de CI
  String? _ciLetterPath; // Ruta de la hoja de carta fusionada

  /// Rutas de documentos académicos
  String? _tituloPath; // Ruta del título académico
  String? _prorrogaPath; // Ruta de la carta de prórroga
  String? _cartaProrrogaPath; // Ruta de la carta de prórroga generada

  /// Rutas de documentos de inscripción y pagos
  String?
  _cartaInscripcionPath; // Ruta de la carta oficial de inscripción (solo para regeneración interna)
  String?
  _cartaInscripcionEjemploPath; // Ruta de la carta de solicitud (ejemplo)
  String? _comprobanteMatriculaPath; // Ruta del comprobante de matrícula
  // Nota: la ruta del comprobante de colegiatura se eliminó porque no se usa actualmente
  // Si se requiere de nuevo, volver a añadirla aquí como: String? _comprobanteColegiaturaPath;
  String? _fichaInscripcionPath; // Ruta de la ficha de inscripción
  String? _hojaVidaPath; // Ruta de la hoja de vida

  /// Archivos multimedia
  File? _profilePhoto; // Archivo de foto de perfil 4x4
  Uint8List? _signaturePng; // Bytes de la firma digital

  /// Datos y configuración
  Map<String, dynamic>?
  _participantDocs; // Mapa completo de documentos del participante
  bool _deferDocuments = false; // Si el usuario difiere la subida de documentos
  bool _hasTitle = true; // Si el usuario tiene título (vs prórroga)
  bool _willGraduateSoon =
      false; // Si se titulará pronto y no necesita prórroga
  final bool _mostrarOpcionColegiatura =
      false; // Simplificar UI: ocultar opción secundaria

  // 🔄 VARIABLES DE CONTROL DE REGENERACIÓN AUTOMÁTICA
  /// Para detectar cambios y regenerar documentos automáticamente
  String? _lastSignaturePath; // Última firma usada para regeneración
  String? _lastProgramName; // Último programa usado para cartas

  // ⏳ ESTADO DE CARGA Y PROCESAMIENTO
  /// Control de estado ocupado para feedback detallado al usuario
  bool _busyGlobal = false; // Estado global de carga
  String? _busyKey; // Clave específica del documento en procesamiento

  /// 🚀 INICIALIZACIÓN DEL Widget
  ///
  /// Configura el estado inicial de la pantalla de documentos personales.
  /// Se ejecuta una sola vez al crear el widget.
  @override
  void initState() {
    super.initState();
    // Cargar todos los documentos y configuración existente
    _load();
  }

  /// 📂 CARGAR DATOS Y DOCUMENTOS EXISTENTES
  ///
  /// Método principal de carga que recupera todos los documentos y configuración
  /// del usuario desde el almacenamiento local. Configura el estado inicial
  /// de la pantalla basado en los datos existentes.
  ///
  /// PROCESO DE CARGA:
  /// 1. Activa indicador de carga global
  /// 2. Recupera datos de documentos desde LocalStorageService
  /// 3. Carga foto de perfil si existe
  /// 4. Actualiza todas las rutas de documentos en el estado
  /// 5. Determina el modo (título vs prórroga) basado en datos existentes
  /// 6. Desactiva indicador de carga
  /// 7. Ejecuta generaciones automáticas si es necesario
  ///
  /// GENERACIONES AUTOMÁTICAS:
  /// - Fotocopia de carnet si existen anverso y reverso
  /// - Verificación y regeneración de carta de inscripción
  Future<void> _load() async {
    setState(() => _busyGlobal = true);
    final data = await LocalStorageService.getParticipantDocumentsData(
      widget.idPrograma,
    );
    final profilePhoto = await LocalStorageService.getProfileImageFile();
    if (!mounted) return;
    setState(() {
      _participantDocs = data;
      _ciFrontPath = data?['ci_front_path'] as String?;
      _ciBackPath = data?['ci_back_path'] as String?;
      _ciLetterPath = data?['ci_letter_path'] as String?;
      _tituloPath = data?['titulo_path'] as String?;
      _prorrogaPath = data?['prorroga_path'] as String?;
      _cartaProrrogaPath = data?['carta_prorroga_path'] as String?;
      _cartaInscripcionPath = data?['carta_inscripcion_path'] as String?;
      _cartaInscripcionEjemploPath =
          data?['carta_inscripcion_ejemplo_path'] as String?;
      _comprobanteMatriculaPath =
          data?['comprobante_matricula_path'] as String?;
      _fichaInscripcionPath = data?['ficha_inscripcion_path'] as String?;
      _hojaVidaPath = data?['hoja_vida_path'] as String?;
      _deferDocuments = (data?['defer_documents'] as bool?) ?? false;
      _willGraduateSoon = (data?['will_graduate_soon'] as bool?) ?? false;
      _profilePhoto = profilePhoto;

      // Determine mode based on existing data
      // Si NO hay título cargado, mostramos por defecto la opción de Prórroga
      // para que el usuario no se quede sin alternativas (título en trámite).
      _hasTitle = _tituloPath != null && _tituloPath!.isNotEmpty;

      _busyGlobal = false;
    });
    // Auto-generar fotocopia de carnet si existen anverso y reverso y aún no hay PDF
    _maybeAutoGenerateCarnetPdf();

    // ✅ Verificar si necesita regenerar la carta de inscripción
    _checkAndRegenerateCartaIfNeeded();

    // ✅ Auto-generar ficha de inscripción si aún no existe
    if (_fichaInscripcionPath == null || _fichaInscripcionPath!.isEmpty) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _generarFichaInscripcion();
      });
    }
  }

  /// 🔄 GENERACIÓN AUTOMÁTICA DE FOTOCOPIA DE CARNET
  ///
  /// Genera automáticamente el PDF de fotocopia de carnet cuando existen
  /// las imágenes de anverso y reverso pero aún no se ha generado el PDF.
  /// Útil después de escanear documentos en la pantalla de identidad.
  ///
  /// CONDICIONES PARA GENERACIÓN:
  /// - Existe imagen del anverso de CI
  /// - Existe imagen del reverso de CI
  /// - No existe PDF de fotocopia generado previamente
  ///
  /// PROCESO:
  /// 1. Valida que existan ambas imágenes
  /// 2. Verifica que no exista PDF previo
  /// 3. Genera PDF usando CarnetPhotocopyService
  /// 4. Guarda la ruta del PDF generado
  /// 5. Actualiza el estado de la UI
  /// 6. Muestra notificación de éxito al usuario
  ///
  /// @return Future<void> - Operación asíncrona de generación
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

  Future<void> _setHasTitleMode(bool value) async {
    final current =
        await LocalStorageService.getParticipantDocumentsData(
          widget.idPrograma,
        ) ??
        <String, dynamic>{};
    current['will_graduate_soon'] = !value;
    await LocalStorageService.saveParticipantDocumentsData(
      current,
      widget.idPrograma,
    );

    if (!mounted) return;
    setState(() {
      _hasTitle = value;
      if (value) {
        // Reversible: si luego ya tiene título, desactivar modo prórroga.
        _willGraduateSoon = false;
      }
    });
  }

  /// 💾 GUARDAR RUTA DE DOCUMENTO
  ///
  /// Guarda o elimina la ruta de un documento específico en el almacenamiento local.
  /// Mantiene la persistencia de todos los documentos del usuario.
  ///
  /// @param key - Clave identificadora del documento (ej: 'ci_front_path')
  /// @param path - Ruta del archivo a guardar, null para eliminar
  /// @return Future<void> - Operación asíncrona de guardado
  Future<void> _saveDocPath(String key, String? path) async {
    final current =
        await LocalStorageService.getParticipantDocumentsData(
          widget.idPrograma,
        ) ??
        <String, dynamic>{};
    if (path == null) {
      current.remove(key);
    } else {
      current[key] = path;
    }
    await LocalStorageService.saveParticipantDocumentsData(
      current,
      widget.idPrograma,
    );
  }

  /// 📁 COPIAR ARCHIVO A DIRECTORIO DE DOCUMENTOS
  ///
  /// Copia un archivo desde su ubicación original al directorio específico
  /// de documentos del participante, organizando los archivos de manera estructurada.
  ///
  /// PROCESO:
  /// 1. Obtiene el directorio de documentos de la aplicación
  /// 2. Crea subdirectorio 'participant_documents' si no existe
  /// 3. Determina la extensión del archivo original
  /// 4. Genera nombre único con timestamp para evitar conflictos
  /// 5. Copia el archivo a la nueva ubicación
  ///
  /// @param originalPath - Ruta del archivo original a copiar
  /// @param prefix - Prefijo para el nombre del archivo (ej: 'ci_front')
  /// @return Future<File> - Archivo copiado en la nueva ubicación
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

  /// 📄 EXTRAER NOMBRE DE ARCHIVO
  ///
  /// Extrae solo el nombre del archivo de una ruta completa,
  /// útil para mostrar nombres legibles en la interfaz.
  ///
  /// @param path - Ruta completa del archivo
  /// @return String - Solo el nombre del archivo con extensión
  String _fileName(String path) {
    final sep = Platform.pathSeparator;
    final parts = path.split(sep);
    return parts.isNotEmpty ? parts.last : path;
  }

  /// 📄 GENERAR FOTOCOPIA DESDE RUTAS EXISTENTES
  ///
  /// Genera el PDF de fotocopia de carnet usando las imágenes de anverso y reverso
  /// ya almacenadas. Incluye indicadores de carga y manejo de errores.
  ///
  /// VALIDACIONES:
  /// - Verifica que existan rutas de anverso y reverso
  /// - Valida que las rutas no estén vacías
  ///
  /// PROCESO:
  /// 1. Activa indicador de carga específico
  /// 2. Genera PDF usando CarnetPhotocopyService
  /// 3. Guarda la ruta del PDF generado
  /// 4. Actualiza el estado de la UI
  /// 5. Muestra mensaje de éxito o error
  /// 6. Limpia el indicador de carga
  ///
  /// @return Future<void> - Operación asíncrona de generación
  Future<void> _generatePhotocopyFromPaths() async {
    final front = _ciFrontPath;
    final back = _ciBackPath;
    if (front == null || back == null || front.isEmpty || back.isEmpty) return;
    setState(() => _busyKey = 'ci_photocopy_pdf_path');
    try {
      final frontRectMap = _participantDocs?['ci_front_rect'] as Map?;
      final backRectMap = _participantDocs?['ci_back_rect'] as Map?;
      Rect? frontRect;
      if (frontRectMap != null) {
        frontRect = Rect(
          left: (frontRectMap['left'] as num).toDouble(),
          top: (frontRectMap['top'] as num).toDouble(),
          width: (frontRectMap['width'] as num).toDouble(),
          height: (frontRectMap['height'] as num).toDouble(),
        );
      }
      Rect? backRect;
      if (backRectMap != null) {
        backRect = Rect(
          left: (backRectMap['left'] as num).toDouble(),
          top: (backRectMap['top'] as num).toDouble(),
          width: (backRectMap['width'] as num).toDouble(),
          height: (backRectMap['height'] as num).toDouble(),
        );
      }
      final pdfPath = await CarnetPhotocopyService.generatePdf(
        frontFile: File(front),
        backFile: File(back),
        frontCropRect: frontRect,
        backCropRect: backRect,
        profilePhoto: _profilePhoto,
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

  /// ❓ CONFIRMAR ELIMINACIÓN DE DOCUMENTO
  ///
  /// Muestra un diálogo de confirmación antes de eliminar un documento.
  /// Previene eliminaciones accidentales con interfaz clara y accesible.
  ///
  /// CARACTERÍSTICAS DEL DIÁLOGO:
  /// - Diseño redondeado moderno
  /// - Tipografía consistente con design system
  /// - Botones claramente diferenciados (Cancelar/Eliminar)
  /// - Colores semánticos (gris para cancelar, rojo para eliminar)
  ///
  /// @param title - Título del documento a eliminar
  /// @return Future<bool> - true si el usuario confirma, false si cancela
  Future<bool> _confirmDelete(String title) async {
    if (!mounted) return false;
    final result = await showCupertinoDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Eliminar documento'),
        content: Text('¿Estás seguro de eliminar: $title?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    return result ?? false;
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
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
                          fontSize: MediaQuery.of(context).size.width < 360
                              ? 14
                              : 15,
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
      // Guardar anverso/reverso para que avance el progreso automáticamente
      await _guardarCiPathsDesdeResultadoIA(resultado);
    }
  }

  /// Procesa el resultado del OCR con IA y autocompleta campos
  Future<void> _procesarResultadoIA(ResultadoOcrIA resultado) async {
    try {
      // Guardar datos personales extraídos
      if (resultado.tipoDocumento == TipoDocumento.cedulaIdentidad) {
        // OPTIMIZACIÓN: Fusionar con datos existentes para no sobrescribir todo
        final existingData =
            await LocalStorageService.getPersonalData() ?? <String, dynamic>{};
        final personalData = Map<String, dynamic>.from(existingData);

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

        // ✅ CORRECCIÓN: Guardar fechas de emisión y expiración extraídas por IA
        if (resultado.campos.containsKey('fechaEmision')) {
          personalData['fechaEmision'] =
              resultado.campos['fechaEmision']!.valor;
        }
        if (resultado.campos.containsKey('fechaExpiracion')) {
          personalData['fechaExpiracion'] =
              resultado.campos['fechaExpiracion']!.valor;
        }

        // Guardar en LocalStorage
        await LocalStorageService.savePersonalData(personalData);

        if (!mounted) return;

        // Se eliminó el SnackBar de éxito para evitar ruidos al usuario según feedback

        // Mostrar advertencias solo si son críticas o relevantes
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

  Future<void> _guardarCiPathsDesdeResultadoIA(ResultadoOcrIA resultado) async {
    final meta = resultado.metadatos;
    final frontOriginalPath = meta['ci_front_path'] as String?;
    final backOriginalPath = meta['ci_back_path'] as String?;

    if ((frontOriginalPath ?? '').trim().isEmpty &&
        (backOriginalPath ?? '').trim().isEmpty) {
      return;
    }

    try {
      bool updated = false;

      if ((frontOriginalPath ?? '').trim().isNotEmpty) {
        final frontFile = await _copyToParticipantDocs(
          frontOriginalPath!,
          'cedula_anverso',
        );
        await _saveDocPath('ci_front_path', frontFile.path);
        _ciFrontPath = frontFile.path;
        updated = true;
      }

      if ((backOriginalPath ?? '').trim().isNotEmpty) {
        final backFile = await _copyToParticipantDocs(
          backOriginalPath!,
          'cedula_reverso',
        );
        await _saveDocPath('ci_back_path', backFile.path);
        _ciBackPath = backFile.path;
        updated = true;
      }

      if (!mounted) return;
      if (updated) {
        setState(() {});
        await _maybeAutoGenerateCarnetPdf();
      }
    } catch (e) {
      debugPrint('⚠️ Error guardando CI desde OCR: $e');
    }
  }

  /// 🚨 MOSTRAR ADVERTENCIAS DEL ANÁLISIS IA
  ///
  /// Presenta al usuario las advertencias detectadas durante el análisis OCR con IA.
  /// Utiliza un diálogo modal con diseño consistente del sistema UPEA.
  ///
  /// CARACTERÍSTICAS DEL DIÁLOGO:
  /// - Diseño redondeado moderno con bordes suaves
  /// - Icono de advertencia en color azul UPEA
  /// - Lista de advertencias con viñetas
  /// - Botón de confirmación para cerrar
  /// - Tipografía consistente con design system
  ///
  /// CASOS DE USO:
  /// - Calidad de imagen insuficiente
  /// - Texto parcialmente ilegible
  /// - Campos no detectados correctamente
  /// - Recomendaciones de mejora
  ///
  /// @param advertencias - Lista de mensajes de advertencia a mostrar
  /// @return Future<void> - Operación asíncrona de presentación del diálogo
  void _mostrarAdvertenciasIA(List<String> advertencias) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Advertencias'),
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
          CupertinoDialogAction(
            child: const Text('Entendido'),
            onPressed: () => Navigator.pop(ctx),
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
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Ayuda'),
        content: const Text(
          '¿Cómo usar esta pantalla?\n\n'
          '• Escaneo Inteligente: Usa la IA para detectar automáticamente el tipo de documento y extraer información.\n'
          '• Captura Manual: Toma fotos individuales. Buena iluminación es clave.\n'
          '• Estadísticas: Ve tu progreso y documentos completados.\n'
          '• Compartir: Comparte documentos directamente.\n\n'
          'Tip: El escaneo funciona mejor con buena luz y sin reflejos.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Entendido'),
            onPressed: () => Navigator.pop(ctx),
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

      // PDFs: renderizar con PDF.js dentro del WebView (evita pantalla negra)
      if (lower.endsWith('.pdf')) {
        await _showPdfPreview(path);
        return;
      }

      // HTML se muestra dentro de la app en pantalla completa
      if (lower.endsWith('.html') || lower.endsWith('.htm')) {
        await _showHtmlPreview(path);
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

  Future<void> _showHtmlPreview(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      _mostrarMensaje('El archivo no existe', esError: true);
      return;
    }
    if (!mounted) return;

    final html = await file.readAsString();

    // Envolver el HTML en un contenedor que centra la hoja tipo A4
    final htmlCentrado =
        '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      background: #e0e0e0;
      display: flex;
      justify-content: center;
      align-items: flex-start;
      min-height: 100vh;
      padding: 24px 12px;
      font-family: Arial, sans-serif;
    }
    .page-wrapper {
      background: white;
      width: 100%;
      max-width: 794px;
      min-height: 1123px;
      box-shadow: 0 4px 24px rgba(0,0,0,0.18);
      border-radius: 4px;
      overflow: hidden;
    }
    .page-content { padding: 0; }
  </style>
</head>
<body>
  <div class="page-wrapper">
    <div class="page-content">
      $html
    </div>
  </div>
</body>
</html>''';

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFE0E0E0))
      ..loadHtmlString(htmlCentrado);

    // Determinar título según el archivo
    final fileName = path.split('/').last.toLowerCase();
    final titulo = fileName.contains('ficha')
        ? 'Ficha de Inscripción'
        : fileName.contains('carta') || fileName.contains('prorroga')
        ? 'Carta de Inscripción'
        : 'Vista Previa';

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: const Color(0xFFE0E0E0),
          appBar: AppBar(
            backgroundColor: kPrimaryColor,
            elevation: 0,
            title: Text(
              titulo,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: fontHeading,
              ),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            actions: [
              // Botón Regenerar
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Regenerar',
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  if (fileName.contains('ficha')) {
                    await _generarFichaInscripcion();
                  } else if (fileName.contains('carta') ||
                      fileName.contains('prorroga')) {
                    await _generarCartaInscripcionEjemplo();
                  }
                },
              ),
              // Botón Descargar / Compartir
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                tooltip: 'Descargar',
                onPressed: () async {
                  try {
                    await Share.shareXFiles(
                      [XFile(path)],
                      subject: titulo,
                      text: 'Documento generado por UPEA Posgrado',
                    );
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Error al compartir: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          body: SafeArea(child: WebViewWidget(controller: controller)),
        ),
      ),
    );
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

  /// Muestra vista previa de PDFs usando PDF.js (renderiza en canvas, sin plugin nativo)
  Future<void> _showPdfPreview(String path) async {
    if (!mounted) return;

    // Loader mientras se lee el archivo
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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

    try {
      final file = File(path);
      if (!await file.exists()) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        _mostrarMensaje('El PDF no existe en el dispositivo.', esError: true);
        return;
      }

      final bytes = await file.readAsBytes();
      final base64Pdf = base64Encode(bytes);

      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;

      // PDF.js renderiza el PDF en <canvas> → funciona en Android WebView sin plugin
      final htmlContent =
          '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=3.0, user-scalable=yes">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.min.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #e0e0e0; font-family: Arial, sans-serif; }
    #loading {
      position: fixed; top: 50%; left: 50%;
      transform: translate(-50%, -50%);
      text-align: center; color: #005BAC; font-size: 15px;
    }
    .spinner {
      border: 3px solid #f3f3f3; border-top: 3px solid #005BAC;
      border-radius: 50%; width: 36px; height: 36px;
      animation: spin 0.8s linear infinite; margin: 0 auto 10px;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    #pages {
      display: flex; flex-direction: column;
      align-items: center; padding: 16px; gap: 16px;
    }
    canvas {
      background: white;
      box-shadow: 0 2px 12px rgba(0,0,0,0.18);
      border-radius: 4px;
      max-width: 100%;
      display: block;
    }
  </style>
</head>
<body>
  <div id="loading"><div class="spinner"></div>Renderizando PDF...</div>
  <div id="pages"></div>
  <script>
    pdfjsLib.GlobalWorkerOptions.workerSrc =
      'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';

    const base64 = '$base64Pdf';
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);

    pdfjsLib.getDocument({ data: bytes }).promise.then(function(pdf) {
      document.getElementById('loading').style.display = 'none';
      const container = document.getElementById('pages');
      const scale = window.devicePixelRatio || 1.5;

      for (let pageNum = 1; pageNum <= pdf.numPages; pageNum++) {
        pdf.getPage(pageNum).then(function(page) {
          const viewport = page.getViewport({ scale: (window.innerWidth / page.getViewport({scale:1}).width) * 0.95 });
          const canvas = document.createElement('canvas');
          const ctx = canvas.getContext('2d');
          canvas.width = viewport.width;
          canvas.height = viewport.height;
          container.appendChild(canvas);
          page.render({ canvasContext: ctx, viewport: viewport });
        });
      }
    }).catch(function(err) {
      document.getElementById('loading').innerHTML = 'Error al cargar PDF: ' + err.message;
    });
  </script>
</body>
</html>''';

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFE0E0E0))
        ..loadHtmlString(htmlContent);

      final fileName = path.split('/').last;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => Scaffold(
            backgroundColor: const Color(0xFFE0E0E0),
            appBar: AppBar(
              backgroundColor: kPrimaryColor,
              elevation: 0,
              title: Text(
                fileName.length > 30
                    ? '${fileName.substring(0, 27)}...'
                    : fileName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: fontHeading,
                  fontSize: 16,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  tooltip: 'Compartir',
                  onPressed: () async {
                    try {
                      await Share.shareXFiles([XFile(path)], subject: fileName);
                    } catch (e) {
                      _mostrarMensaje('Error al compartir: $e', esError: true);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.open_in_new_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Abrir con otra app',
                  onPressed: () async {
                    try {
                      await OpenFilex.open(path);
                    } catch (e) {
                      _mostrarMensaje('Error al abrir: $e', esError: true);
                    }
                  },
                ),
              ],
            ),
            body: SafeArea(child: WebViewWidget(controller: controller)),
          ),
        ),
      );
    } catch (e) {
      try {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
      } catch (_) {}
      debugPrint('Error mostrando PDF: $e');
      // Fallback: abrir con app nativa
      try {
        await OpenFilex.open(path);
      } catch (_) {
        _mostrarMensaje('No se pudo mostrar el PDF', esError: true);
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
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
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

                  // Opción 1: Firmar Digitalmente
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

                  // Opción 2: Previsualizar Carta
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

                  // Opción 3: Subir Archivo
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
                    subtitle: const Text(
                      'Sube tu propia carta de prórroga',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndSaveProrroga();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // NUEVA Opción 4: Me titulo la siguiente semana
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kSuccessColor.withOpacity(0.8),
                            kSuccessColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text(
                      '🎓 Me titulo la siguiente semana',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Ya no necesito prórroga',
                      style: TextStyle(fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _markWillGraduateSoon();
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: kSuccessColor.withOpacity(0.05),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Marca que el usuario se titulará pronto y no necesita prórroga
  Future<void> _markWillGraduateSoon() async {
    setState(() => _busyKey = 'will_graduate_soon');
    try {
      final docs =
          await LocalStorageService.getParticipantDocumentsData(
            widget.idPrograma,
          ) ??
          {};
      docs['will_graduate_soon'] = true;
      await LocalStorageService.saveParticipantDocumentsData(
        docs,
        widget.idPrograma,
      );

      if (!mounted) return;
      setState(() {
        _willGraduateSoon = true;
        _hasTitle = false; // Cambiar a modo prórroga
        _prorrogaPath = null; // Limpiar prórroga anterior
        _busyKey = null;
      });

      _mostrarMensaje(
        '✅ Perfecto! Cuando tengas tu título, súbelo en la sección "Título Académico"',
        esError: false,
      );
    } catch (e) {
      debugPrint('Error al marcar graduación próxima: $e');
      _mostrarMensaje('Error al guardar: $e', esError: true);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  /// Subir archivo de prórroga y generar carta automáticamente
  Future<void> _pickAndSaveProrroga() async {
    await _pickAndSave(
      key: 'prorroga_path',
      prefix: 'prorroga_custom',
      onSet: (p) async {
        setState(() => _prorrogaPath = p);
        // Generar automáticamente la carta de prórroga
        await _generateCartaProrroga();
      },
      allowFile: true,
    );
  }

  /// Genera automáticamente la carta de prórroga (similar a carta de inscripción)
  Future<void> _generateCartaProrroga() async {
    if (_prorrogaPath == null) return;

    setState(() => _busyKey = 'carta_prorroga_generation');
    try {
      debugPrint('📄 Generando carta de prórroga automáticamente...');

      final personalData = await LocalStorageService.getPersonalData();
      final name =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final ci = personalData?['numeroCI'] ?? 'NO_CI';

      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final months = [
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
      final month = months[now.month - 1];
      final year = now.year.toString();

      // Obtener programa inscrito
      final sessionData = await LocalStorageService.getSessionData();
      final username = sessionData?['nombreUsuario'] as String? ?? '';
      final userProgramIds = await LocalStorageService.getUserPrograms(
        username,
      );
      String career = 'Programa de Posgrado';
      if (userProgramIds.isNotEmpty) {
        // getUserPrograms retorna Set<String> de IDs, no objetos
        // Usar el primer ID o el nombre guardado en datos personales
        final personalData = await LocalStorageService.getPersonalData();
        career = personalData?['nombreProgramaCarta']?.toString() ?? career;
      }

      // Obtener firma si existe
      String signatureBase64 = '';
      final signaturePath = await LocalStorageService.getSignatureImagePath();
      if (signaturePath != null && signaturePath.isNotEmpty) {
        try {
          final signatureFile = File(signaturePath);
          if (await signatureFile.exists()) {
            final bytes = await signatureFile.readAsBytes();
            signatureBase64 = base64Encode(bytes);
          }
        } catch (e) {
          debugPrint('⚠️ No se pudo cargar la firma: $e');
        }
      }

      // Generar HTML de la carta
      final html = _buildProrrogaHtml(
        name: name,
        ci: ci,
        day: day,
        month: month,
        year: year,
        career: career,
        signatureBase64: signatureBase64,
      );

      // Guardar como archivo HTML
      final dir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${dir.path}/participant_documents');
      if (!await docsDir.exists()) {
        await docsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final htmlPath = '${docsDir.path}/carta_prorroga_$timestamp.html';
      final htmlFile = File(htmlPath);
      await htmlFile.writeAsString(html);

      // Guardar la ruta
      await _saveDocPath('carta_prorroga_path', htmlPath);

      if (!mounted) return;
      setState(() {
        _cartaProrrogaPath = htmlPath;
        _busyKey = null;
      });

      _mostrarMensaje(
        '✅ Carta de prórroga generada automáticamente',
        esError: false,
      );

      debugPrint('✅ Carta de prórroga generada: $htmlPath');
    } catch (e) {
      debugPrint('❌ Error al generar carta de prórroga: $e');
      _mostrarMensaje('Error al generar carta: $e', esError: true);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  /// Construye el HTML de la carta de prórroga
  String _buildProrrogaHtml({
    required String name,
    required String ci,
    required String day,
    required String month,
    required String year,
    required String career,
    required String signatureBase64,
  }) {
    final signatureHtml = signatureBase64.isNotEmpty
        ? '<img src="data:image/png;base64,$signatureBase64" alt="Firma" style="width: 180px; height: 70px; object-fit: contain;" />'
        : '';

    return '''
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
    
    @page {
      size: letter;
      margin: 0;
    }
    
    body {
      font-family: 'Times New Roman', Times, serif;
      background-color: white;
      padding: 50px 40px;
      font-size: 10.5pt;
      line-height: 1.4;
      color: #000;
    }
    
    .date {
      text-align: right;
      margin-bottom: 30px;
    }
    
    .recipient {
      margin-bottom: 20px;
      line-height: 1.3;
    }
    
    .reference {
      margin-bottom: 20px;
      font-weight: bold;
    }
    
    .greeting {
      margin-bottom: 15px;
    }
    
    .body-text {
      text-align: justify;
      margin-bottom: 15px;
    }
    
    .closing {
      margin-top: 30px;
      margin-bottom: 10px;
    }
    
    .signature-section {
      margin-top: 40px;
      text-align: center;
    }
    
    .signature-image {
      margin-bottom: 5px;
    }
    
    .name-line {
      font-weight: bold;
      margin-bottom: 3px;
    }
    
    .ci-line {
      font-size: 10pt;
    }
    
    @media print {
      body {
        padding: 50px 40px;
      }
    }
  </style>
</head>
<body>
  <div class="date">
    La Paz, $day de $month de $year
  </div>
  
  <div class="recipient">
    Señor:<br>
    Dr. Richard Jorge Torrez Juaniquina Ph. D.<br>
    DIRECTOR DE POSGRADO - UPEA<br>
    Presente.-
  </div>
  
  <div class="reference">
    Ref.: SOLICITUD DE PRÓRROGA PARA LA PRESENTACIÓN DE LA FOTOCOPIA LEGALIZADA DEL TÍTULO ACADÉMICO O TÍTULO EN PROVISIÓN NACIONAL
  </div>
  
  <div class="greeting">
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
  
  <div class="signature-section">
    <div class="signature-image">
      $signatureHtml
    </div>
    <div class="name-line">$name</div>
    <div class="ci-line">C.I. $ci</div>
  </div>
</body>
</html>
''';
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
      final String htmlContent =
          '''
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
      final tempDir = Directory(
        '${dir.path}${Platform.pathSeparator}temp_previews',
      );
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }

      final tempFile = File(
        '${tempDir.path}${Platform.pathSeparator}prorroga_preview_${DateTime.now().millisecondsSinceEpoch}.html',
      );
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: kPrimaryColor,
                      ),
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
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
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
                  decoration: BoxDecoration(
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

  /// Detecta el tipo de programa a partir del nombre del programa o del tipo guardado.
  /// Usa el mismo criterio que PantallaValidacionRequisitos._getTipoProgramaEnum().
  TipoPrograma _getTipoProgramaEnum(
    String nombrePrograma, [
    String? tipoGuardado,
  ]) {
    final fuente = (tipoGuardado ?? nombrePrograma).toUpperCase();
    if (fuente.contains('ESPECIALIDAD')) return TipoPrograma.especialidad;
    if (fuente.contains('MAESTR')) return TipoPrograma.maestria;
    if (fuente.contains('DOCTOR')) return TipoPrograma.doctorado;
    return TipoPrograma.diplomado;
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

      // ✅ CORRECCIÓN: Obtener el programa seleccionado desde el último programa inscrito
      // Si no hay programa guardado, mostrar mensaje para que seleccione uno
      final nombrePrograma = (personalData?['nombreProgramaCarta'] ?? '')
          .toString()
          .trim();

      if (nombrePrograma.isEmpty) {
        return;
      }

      final modalidad = (personalData?['modalidadProgramaCarta'] ?? 'Virtual')
          .toString()
          .trim();
      // Obtener la ruta de la firma digital
      final firmaPath = await LocalStorageService.getSignatureImagePath();

      // Guardar valores actuales para detectar cambios futuros
      _lastSignaturePath = firmaPath;
      _lastProgramName = nombrePrograma;

      final tipoGuardado = (personalData?['tipoProgramaCarta'] ?? '')
          .toString()
          .trim();
      final generador = ServicioGeneradorCartaInscripcion();
      final ruta = await generador.generarCarta(
        tipoPrograma: _getTipoProgramaEnum(
          nombrePrograma,
          tipoGuardado.isNotEmpty ? tipoGuardado : null,
        ),
        nombrePrograma: nombrePrograma,
        modalidad: modalidad,
        nombreCompleto: nombreCompleto,
        numeroCI: numeroCI,
        expedidoEn: expedidoEn.isEmpty ? null : expedidoEn,
        montoDeposito: '2400',
        signatureImagePath: firmaPath, // ✅ Pasar la firma
        guardarEnPreferencias: false,
      );
      await _saveDocPath('carta_inscripcion_path', ruta);
      if (!mounted) return;
      setState(() => _cartaInscripcionPath = ruta);
      _mostrarMensaje('Carta de inscripción generada para: $nombrePrograma');
    } catch (e) {
      _mostrarMensaje('Error al generar carta: $e', esError: true);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  /// Genera SOLO una carta de solicitud como EJEMPLO (sin requisitos de inscripción).
  /// - No requiere programa seleccionado.
  /// - No requiere firma: se oculta la firma en la plantilla.
  Future<void> _generarCartaInscripcionEjemplo() async {
    setState(() => _busyKey = 'carta_inscripcion_ejemplo_path');
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

      if (nombreCompleto.isEmpty || numeroCI.isEmpty) {
        _mostrarMensaje(
          'Complete nombre/apellidos y CI para generar la carta de ejemplo.',
          esError: true,
        );
        return;
      }

      final expedidoEn = (personalData?['expedidoEn'] ?? '').toString().trim();
      final modalidad = (personalData?['modalidadProgramaCarta'] ?? 'Virtual')
          .toString()
          .trim();

      // Si no existe programa seleccionado, usamos un texto genérico.
      final rawPrograma = (personalData?['nombreProgramaCarta'] ?? '')
          .toString()
          .trim();
      final nombrePrograma = rawPrograma.isNotEmpty
          ? rawPrograma
          : 'Programa de Posgrado';

      final tipoGuardadoEjemplo = (personalData?['tipoProgramaCarta'] ?? '')
          .toString()
          .trim();
      final generador = ServicioGeneradorCartaInscripcion();
      final ruta = await generador.generarCarta(
        tipoPrograma: _getTipoProgramaEnum(
          nombrePrograma,
          tipoGuardadoEjemplo.isNotEmpty ? tipoGuardadoEjemplo : null,
        ),
        nombrePrograma: nombrePrograma,
        modalidad: modalidad,
        nombreCompleto: nombreCompleto,
        numeroCI: numeroCI,
        expedidoEn: expedidoEn.isEmpty ? null : expedidoEn,
        montoDeposito: '2400',
        // Sin firma para que sea ejemplo.
        signatureImagePath: null,
        guardarEnPreferencias: false,
      );

      await _saveDocPath('carta_inscripcion_ejemplo_path', ruta);
      if (!mounted) return;
      setState(() => _cartaInscripcionEjemploPath = ruta);
      _mostrarMensaje('Carta de solicitud (ejemplo) generada.');
    } catch (e) {
      _mostrarMensaje('Error al generar carta de ejemplo: $e', esError: true);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  /// Detecta cambios en firma o programa y regenera la carta automáticamente
  Future<void> _checkAndRegenerateCartaIfNeeded() async {
    // En esta pantalla SOLO mostramos la carta de EJEMPLO.
    // Evitamos generar/regenerar `carta_inscripcion_path` (carta oficial)
    // para no mostrar avisos y para que la carta oficial se gestione
    // únicamente desde el flujo de inscripción.
    return;
  }

  //Funcion que genera la ficha de inscripcion (con datos reales o de ejemplo)
  Future<void> _generarFichaInscripcion() async {
    setState(() => _busyKey = 'ficha_inscripcion_path');
    try {
      final personalData = await LocalStorageService.getPersonalData();

      // Usar datos reales si existen, o datos de ejemplo si no hay
      final nombreCompleto = (() {
        final n =
            '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
                .trim();
        return n.isNotEmpty ? n : 'JUAN CARLOS PÉREZ MAMANI';
      })();
      final numeroCI =
          (personalData?['numeroCI'] ?? '').toString().trim().isNotEmpty
          ? (personalData?['numeroCI'] ?? '').toString().trim()
          : '5726619';
      final email = (personalData?['email'] ?? '').toString().trim().isNotEmpty
          ? (personalData?['email'] ?? '').toString().trim()
          : 'ejemplo@correo.com';
      final telefono =
          (personalData?['telefono'] ?? '').toString().trim().isNotEmpty
          ? (personalData?['telefono'] ?? '').toString().trim()
          : '70000000';
      final expedidoEn =
          (personalData?['expedidoEn'] ?? '').toString().trim().isNotEmpty
          ? (personalData?['expedidoEn'] ?? '').toString().trim()
          : 'LA PAZ';
      final fechaNacimiento =
          (personalData?['fechaNacimiento'] ?? '').toString().trim().isNotEmpty
          ? (personalData?['fechaNacimiento'] ?? '').toString().trim()
          : '01/01/1990';
      final direccion =
          (personalData?['direccion'] ?? '').toString().trim().isNotEmpty
          ? (personalData?['direccion'] ?? '').toString().trim()
          : 'Av. 6 de Marzo, El Alto';
      final nacionalidad = (personalData?['nacionalidad'] ?? 'BOLIVIANO')
          .toString()
          .trim()
          .toUpperCase();
      final nombrePrograma =
          (personalData?['nombreProgramaCarta'] ??
                  'Formulación y Evaluación de Proyectos')
              .toString()
              .trim();
      final modalidad = (personalData?['modalidadProgramaCarta'] ?? 'Virtual')
          .toString()
          .trim();

      // Obtener foto de perfil en base64
      String fotoPerfilBase64 = '';
      if (_profilePhoto != null && await _profilePhoto!.exists()) {
        try {
          final bytes = await _profilePhoto!.readAsBytes();
          fotoPerfilBase64 = base64Encode(bytes);
        } catch (e) {
          debugPrint('⚠️ Error al cargar foto de perfil: $e');
        }
      }

      // Cargar logo institucional en base64
      String logoBase64 = '';
      try {
        final ByteData logoData = await rootBundle.load(
          'assets/images/logoposgrado.jpg',
        );
        final Uint8List logoBytes = logoData.buffer.asUint8List();
        logoBase64 = base64Encode(logoBytes);
      } catch (e) {
        debugPrint('⚠️ Error al cargar logo: $e');
      }

      final now = DateTime.now();
      final fechaStr =
          '${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      final html =
          '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Ficha de Inscripción</title>
  <style>
    @page {
      size: letter;
      margin: 0;
    }
    
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    
    body {
      font-family: 'Times New Roman', Times, serif;
      font-size: 11pt;
      line-height: 1.5;
      color: #333;
      padding: 50px 40px;
      background: white;
    }
    
    .header-top {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 20px;
      padding-bottom: 15px;
      border-bottom: 3px solid #005BAC;
    }
    
    .logo-container {
      flex: 0 0 150px;
    }
    
    .logo-container img {
      width: 150px;
      height: auto;
      object-fit: contain;
    }
    
    .header-center {
      flex: 1;
      text-align: center;
      padding: 0 20px;
    }
    
    .header-center h1 {
      color: #005BAC;
      font-size: 20pt;
      font-weight: bold;
      margin-bottom: 5px;
      text-transform: uppercase;
    }
    
    .header-center .subtitle {
      color: #666;
      font-size: 11pt;
      font-style: italic;
    }
    
    .photo-container {
      flex: 0 0 120px;
      text-align: right;
    }
    
    .photo-box {
      width: 120px;
      height: 140px;
      border: 2px solid #005BAC;
      border-radius: 8px;
      overflow: hidden;
      background: #f5f5f5;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .photo-box img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
    
    .photo-placeholder {
      color: #999;
      font-size: 9pt;
      text-align: center;
      padding: 10px;
    }
    
    .info-section {
      margin-bottom: 25px;
    }
    
    .info-section h2 {
      color: #005BAC;
      font-size: 14pt;
      font-weight: bold;
      margin-bottom: 12px;
      padding-bottom: 5px;
      border-bottom: 2px solid #E0E4ED;
    }
    
    table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
    }
    
    th, td {
      border: 1px solid #ddd;
      padding: 12px 15px;
      text-align: left;
    }
    
    th {
      background: #F0F4F8;
      font-weight: bold;
      color: #005BAC;
      width: 35%;
    }
    
    td {
      background: white;
    }
    
    .fecha-generacion {
      text-align: right;
      color: #666;
      font-size: 10pt;
      margin-bottom: 20px;
      font-style: italic;
    }
    
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 2px solid #E0E4ED;
      text-align: center;
      font-size: 9pt;
      color: #999;
    }
    
    .firma-section {
      margin-top: 50px;
      display: flex;
      justify-content: space-around;
    }
    
    .firma-box {
      text-align: center;
      width: 40%;
    }
    
    .firma-line {
      border-top: 2px solid #333;
      margin-top: 60px;
      padding-top: 8px;
      font-size: 10pt;
      font-weight: bold;
    }
    
    @media print {
      body {
        padding: 50px 40px;
      }
    }
  </style>
</head>
<body>
  <div class="header-top">
    <div class="logo-container">
      ${logoBase64.isNotEmpty ? '<img src="data:image/jpeg;base64,$logoBase64" alt="Logo UPEA Posgrado">' : '<div style="width:150px;height:60px;background:#f0f0f0;"></div>'}
    </div>
    <div class="header-center">
      <h1>Ficha de Inscripción</h1>
      <div class="subtitle">Universidad Pública de El Alto - Posgrado</div>
    </div>
    <div class="photo-container">
      <div class="photo-box">
        ${fotoPerfilBase64.isNotEmpty ? '<img src="data:image/jpeg;base64,$fotoPerfilBase64" alt="Foto del postulante">' : '<div class="photo-placeholder">Foto del<br>Postulante</div>'}
      </div>
    </div>
  </div>
  
  <div class="fecha-generacion">
    Generada el: $fechaStr
  </div>
  
  <div class="info-section">
    <h2>Datos Personales</h2>
    <table>
      <tr>
        <th>Apellidos y Nombres</th>
        <td>$nombreCompleto</td>
      </tr>
      <tr>
        <th>Cédula de Identidad</th>
        <td>$numeroCI${expedidoEn.isNotEmpty ? ' $expedidoEn' : ''}</td>
      </tr>
      <tr>
        <th>Nacionalidad</th>
        <td>$nacionalidad</td>
      </tr>
      <tr>
        <th>Fecha de Nacimiento</th>
        <td>${fechaNacimiento.isNotEmpty ? fechaNacimiento : 'No especificado'}</td>
      </tr>
      <tr>
        <th>F. Emisión CI</th>
        <td>${(personalData?['fechaEmision'] ?? 'No especificado')}</td>
      </tr>
      <tr>
        <th>F. Expiración CI</th>
        <td>${(personalData?['fechaExpiracion'] ?? 'No especificado')}</td>
      </tr>
      <tr>
        <th>Correo Electrónico</th>
        <td>$email</td>
      </tr>
      <tr>
        <th>Teléfono</th>
        <td>$telefono</td>
      </tr>
      <tr>
        <th>Dirección</th>
        <td>${direccion.isNotEmpty ? direccion : 'No especificado'}</td>
      </tr>
    </table>
  </div>
  
  <div class="info-section">
    <h2>Datos del Programa</h2>
    <table>
      <tr>
        <th>Programa</th>
        <td>$nombrePrograma</td>
      </tr>
      <tr>
        <th>Modalidad</th>
        <td>$modalidad</td>
      </tr>
      <tr>
        <th>Tipo</th>
        <td>Diplomado</td>
      </tr>
    </table>
  </div>
  
  <div class="firma-section">
    <div class="firma-box">
      <div class="firma-line">Firma del Postulante</div>
    </div>
    <div class="firma-box">
      <div class="firma-line">Sello y Firma Institución</div>
    </div>
  </div>
  
  <div class="footer">
    Documento generado automáticamente por el Sistema de Preinscripción - UPEA<br>
    Este documento es válido únicamente con la firma del postulante y el sello institucional
  </div>
</body>
</html>''';
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
      // Abrir directamente en WebView al generar
      await _showHtmlPreview(file.path);
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
            final boundary =
                signatureKey.currentContext?.findRenderObject()
                    as RenderRepaintBoundary?;
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
              decoration: BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
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
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: points.length < 2
                                          ? const Color(0xFFCBD5E1)
                                          : kPrimaryColor.withOpacity(0.6),
                                    ),
                                  ),
                                  child: GestureDetector(
                                    onPanStart: (details) {
                                      final box =
                                          signatureKey.currentContext
                                                  ?.findRenderObject()
                                              as RenderBox?;
                                      if (box == null) return;
                                      final local = box.globalToLocal(
                                        details.globalPosition,
                                      );
                                      setModalState(() {
                                        points = List.of(points)..add(local);
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      final box =
                                          signatureKey.currentContext
                                                  ?.findRenderObject()
                                              as RenderBox?;
                                      if (box == null) return;
                                      final local = box.globalToLocal(
                                        details.globalPosition,
                                      );
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: SafeArea(
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFCBD5E1),
                                  ),
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
                                  final png = await captureSignature();
                                  if (mounted) {
                                    setState(() => _signaturePng = png);
                                  }
                                  onConfirm.call();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
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
    final headerHeight = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 80.0,
      tablet: 86.0,
      largeTablet: 90.0,
      desktop: 94.0,
    );
    final titleFontSize = ResponsiveUtils.subtitleFontSize(context);
    final subtitleFontSize = ResponsiveUtils.bodyFontSize(context) - 1;
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final iconSize = ResponsiveUtils.mediumIconSize(context);
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBodyBehindAppBar: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(headerHeight),
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
                toolbarHeight: headerHeight,
                title: Padding(
                  padding: EdgeInsets.only(
                    top: ResponsiveUtils.scale(context, 8),
                  ),
                  child: Row(
                    children: [
                      // Icono con animación de escala
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, hijo) {
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
                              child: Icon(
                                Icons.folder_special_rounded,
                                color: Colors.white,
                                size: iconSize,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Mis Documentos',
                                style: TextStyle(
                                  fontFamily: fontHeading,
                                  fontWeight: FontWeight.w700,
                                  fontSize: titleFontSize,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(
                                height: ResponsiveUtils.scale(context, 2),
                              ),
                              Text(
                                'Gestiona tus archivos personales',
                                style: TextStyle(
                                  fontFamily: fontBody,
                                  fontWeight: FontWeight.w400,
                                  fontSize: subtitleFontSize,
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
                  Padding(
                    padding: EdgeInsets.only(
                      right: ResponsiveUtils.scale(context, 12),
                      top: ResponsiveUtils.scale(context, 8),
                    ),
                    child: PopupMenuButton<String>(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'smart_scan',
                          child: Text('Escaneo inteligente'),
                        ),
                        PopupMenuItem(
                          value: 'stats',
                          child: Text('Ver estadisticas'),
                        ),
                        PopupMenuItem(value: 'help', child: Text('Ayuda')),
                      ],
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
                          Icons.more_horiz_rounded,
                          size: 20,
                          color: Colors.white,
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
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  ResponsiveUtils.scale(context, 10),
                  horizontalPadding,
                  100, // espacio para el bottom nav
                ),
                children: [
                  // ── Barra de progreso ──────────────────────────────────
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
                  const SizedBox(height: 20),

                  // ── SECCIÓN: Identificación ────────────────────────────
                  FadeInLeft(
                    delay: const Duration(milliseconds: 100),
                    child: _buildSectionTitle('Identificación'),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 120),
                    child: _DocUploadCard(
                      title: 'Cédula (Anverso)',
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
                      onPreview: _ciFrontPath != null
                          ? () => _previewDoc(_ciFrontPath!)
                          : null,
                      onDelete: () async {
                        if (await _confirmDelete('C.I. Anverso')) {
                          await _saveDocPath('ci_front_path', null);
                          setState(() => _ciFrontPath = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 140),
                    child: _DocUploadCard(
                      title: 'Cédula (Reverso)',
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
                      onPreview: _ciBackPath != null
                          ? () => _previewDoc(_ciBackPath!)
                          : null,
                      onDelete: () async {
                        if (await _confirmDelete('C.I. Reverso')) {
                          await _saveDocPath('ci_back_path', null);
                          setState(() => _ciBackPath = null);
                        }
                      },
                    ),
                  ),
                  if ((_ciFrontPath ?? '').isNotEmpty &&
                      (_ciBackPath ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    FadeInUp(
                      delay: const Duration(milliseconds: 160),
                      child: _DocUploadCard(
                        title: 'Fotocopia C.I. (PDF)',
                        description:
                            'Se genera automáticamente desde anverso y reverso',
                        path:
                            (_participantDocs?['ci_photocopy_pdf_path']
                                as String?) ??
                            '',
                        isLoading: _busyKey == 'ci_photocopy_pdf_path',
                        isRequired: false,
                        enabled: !_deferDocuments,
                        canGenerate: true,
                        onUpload: () => _generatePhotocopyFromPaths(),
                        onPreview: () {
                          final p =
                              _participantDocs?['ci_photocopy_pdf_path']
                                  as String?;
                          if (p != null && p.isNotEmpty) _previewDoc(p);
                        },
                        onDelete: () async {
                          if (await _confirmDelete('Fotocopia de C.I.')) {
                            await _saveDocPath('ci_photocopy_pdf_path', null);
                            setState(
                              () => _participantDocs?.remove(
                                'ci_photocopy_pdf_path',
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 180),
                    child: _DocUploadCard(
                      title: 'Hoja Carta C.I. (Fusionado)',
                      description: 'Generada o subida (PDF/Foto)',
                      path: _ciLetterPath,
                      isLoading: _busyKey == 'ci_letter_path',
                      isRequired: false,
                      isAutoGenerated: _ciLetterPath == null,
                      enabled: !_deferDocuments,
                      canGenerate: true,
                      onUpload: _onCiLetterAction,
                      onPreview: _ciLetterPath != null
                          ? () => _previewDoc(_ciLetterPath!)
                          : null,
                      onDelete: () async {
                        if (await _confirmDelete('Hoja Carta')) {
                          await _saveDocPath('ci_letter_path', null);
                          setState(() => _ciLetterPath = null);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── SECCIÓN: Académico ─────────────────────────────────
                  FadeInLeft(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSectionTitle('Académico'),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 220),
                    child: _buildAcademicRequirementSection(),
                  ),

                  const SizedBox(height: 20),

                  // ── SECCIÓN: Preinscripción ────────────────────────────
                  FadeInLeft(
                    delay: const Duration(milliseconds: 240),
                    child: _buildSectionTitle('Preinscripción'),
                  ),
                  const SizedBox(height: 12),
                  FadeInUp(
                    delay: const Duration(milliseconds: 260),
                    child: _DocUploadCard(
                      title: 'Ficha de inscripción',
                      description: 'Se genera automáticamente con sus datos.',
                      path: _fichaInscripcionPath,
                      isLoading: _busyKey == 'ficha_inscripcion_path',
                      isRequired: true,
                      enabled: !_deferDocuments,
                      canGenerate: true,
                      isAutoGenerated: true,
                      onUpload: _fichaInscripcionPath != null
                          ? () => _previewDoc(_fichaInscripcionPath!)
                          : _generarFichaInscripcion,
                      onPreview: _fichaInscripcionPath != null
                          ? () => _previewDoc(_fichaInscripcionPath!)
                          : null,
                      onDelete: () async {
                        if (await _confirmDelete('Ficha de inscripción')) {
                          await _saveDocPath('ficha_inscripcion_path', null);
                          setState(() => _fichaInscripcionPath = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 280),
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
                      onPreview: _hojaVidaPath != null
                          ? () => _previewDoc(_hojaVidaPath!)
                          : null,
                      onDelete: () async {
                        if (await _confirmDelete('Hoja de vida')) {
                          await _saveDocPath('hoja_vida_path', null);
                          setState(() => _hojaVidaPath = null);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 80),
                    child: _DocUploadCard(
                      title: 'Comprobante de pago (matrícula)',
                      description: 'Adjuntar comprobante de pago por matrícula',
                      path: _comprobanteMatriculaPath,
                      isLoading: _busyKey == 'comprobante_matricula_path',
                      isRequired: false,
                      enabled: true,
                      onUpload: () => _pickAndSave(
                        key: 'comprobante_matricula_path',
                        prefix: 'pago_matricula',
                        onSet: (p) => _comprobanteMatriculaPath = p,
                        allowFile: true,
                      ),
                      onPreview: _comprobanteMatriculaPath != null
                          ? () => _previewDoc(_comprobanteMatriculaPath!)
                          : null,
                      onDelete: () async {
                        if (await _confirmDelete('Comprobante matrícula')) {
                          await _saveDocPath(
                            'comprobante_matricula_path',
                            null,
                          );
                          setState(() => _comprobanteMatriculaPath = null);
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Botón guardar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
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
                  const SizedBox(height: 40),
                ],
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
    IconData icon;
    final t = title.toLowerCase();
    if (t.contains('foto')) {
      icon = Icons.person_rounded;
    } else if (t.contains('academ')) {
      icon = Icons.school_rounded;
    } else if (t.contains('preins')) {
      icon = Icons.assignment_rounded;
    } else if (t.contains('ident')) {
      icon = Icons.badge_rounded;
    } else {
      icon = Icons.folder_open_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: kPrimaryColor),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: fontBody,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: kTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicRequirementSection() {
    final hasDoc = _hasTitle ? (_tituloPath != null) : (_prorrogaPath != null);
    final color = hasDoc ? kSuccessColor : kPrimaryColor;
    final isBusy = _hasTitle
        ? (_busyKey == 'titulo_path')
        : (_busyKey == 'prorroga_path');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Control de Selección
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: kPrimaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cuentas con Título?',
                      style: TextStyle(
                        fontFamily: fontHeading,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: kTextColor,
                      ),
                    ),
                    Text(
                      'Título en Provisión Nacional',
                      style: TextStyle(
                        fontFamily: fontBody,
                        fontSize: 11,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _hasTitle,
                activeColor: kPrimaryColor,
                onChanged: _deferDocuments
                    ? null
                    : (val) => _setHasTitleMode(val),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
          ),

          // Row 2: Gestión de Documento Dinámica
          Row(
            children: [
              // Indicador de estado
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasDoc ? kSuccessColor : kWarningText.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _hasTitle ? 'Título Académico' : 'Carta de Prórroga',
                      style: TextStyle(
                        fontFamily: fontHeading,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: hasDoc ? kSuccessColor : kTextColor,
                      ),
                    ),
                    Text(
                      _hasTitle
                          ? (hasDoc
                                ? 'Documento cargado correctamente'
                                : 'Sube una foto o PDF de tu título')
                          : (_willGraduateSoon
                                ? '🎓 Graduación próxima marcada'
                                : (hasDoc
                                      ? 'Carta de prórroga lista'
                                      : 'Genera o sube tu carta de trámite')),
                      style: const TextStyle(
                        fontFamily: fontBody,
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Acciones dinámicas
              if (isBusy)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: kPrimaryColor,
                  ),
                )
              else ...[
                // Botón Acción Principal (Upload/Generate)
                IconButton(
                  onPressed: _deferDocuments
                      ? null
                      : (_hasTitle
                            ? () => _pickAndSave(
                                key: 'titulo_path',
                                prefix: 'titulo_prov_nacional',
                                onSet: (p) => _tituloPath = p,
                                allowFile: true,
                              )
                            : _onProrrogaAction),
                  icon: Icon(
                    _hasTitle
                        ? Icons.cloud_upload_outlined
                        : Icons.auto_awesome_outlined,
                    color: kPrimaryColor,
                  ),
                  tooltip: _hasTitle ? 'Subir Título' : 'Gestionar Prórroga',
                ),

                // Botones de gestión si existe el archivo
                if (hasDoc) ...[
                  IconButton(
                    onPressed: () =>
                        _previewDoc(_hasTitle ? _tituloPath! : _prorrogaPath!),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      color: kTextSecondary,
                    ),
                    tooltip: 'Ver documento',
                  ),
                  IconButton(
                    onPressed: () async {
                      if (await _confirmDelete(
                        _hasTitle ? 'Título' : 'Prórroga',
                      )) {
                        final key = _hasTitle ? 'titulo_path' : 'prorroga_path';
                        await _saveDocPath(key, null);
                        setState(() {
                          if (_hasTitle) {
                            _tituloPath = null;
                          } else {
                            _prorrogaPath = null;
                          }
                        });
                      }
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: kErrorColor,
                    ),
                    tooltip: 'Eliminar',
                  ),
                ],
              ],
            ],
          ),

          // Extra: Botón para ver carta generada de prórroga si existe y no estamos en modo título
          if (!_hasTitle &&
              _cartaProrrogaPath != null &&
              _cartaProrrogaPath!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: InkWell(
                onTap: () => _previewDoc(_cartaProrrogaPath!),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 14,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ver Carta Generada',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 14,
                        color: kPrimaryColor.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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
                ? _MisDocumentosPersonalesPantallaState.kSuccessColor
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
            fontFamily: _MisDocumentosPersonalesPantallaState.fontBody,
            color: Colors.white.withOpacity(isDone ? 1.0 : 0.6),
            fontSize: 13,
            decoration: isDone ? null : null,
          ),
        ),
      ],
    );
  }
}

class _DocUploadCard extends StatefulWidget {
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
  State<_DocUploadCard> createState() => _DocUploadCardState();
}

class _DocUploadCardState extends State<_DocUploadCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _tapController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  IconData _iconForDocument() {
    final t = widget.title.toLowerCase();
    if (t.contains('foto')) return Icons.photo_camera_rounded;
    if (t.contains('ci') || t.contains('ident')) return Icons.badge_rounded;
    if (t.contains('titulo')) return Icons.school_rounded;
    if (t.contains('prórroga') || t.contains('prorroga')) {
      return Icons.schedule_rounded;
    }
    if (t.contains('carta')) return Icons.description_rounded;
    if (t.contains('ficha')) return Icons.fact_check_rounded;
    if (t.contains('hoja de vida') || t.contains('cv')) {
      return Icons.work_history_rounded;
    }
    if (t.contains('comprobante') || t.contains('pago')) {
      return Icons.receipt_long_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    const primary = _MisDocumentosPersonalesPantallaState.kPrimaryColor;
    const success = _MisDocumentosPersonalesPantallaState.kSuccessColor;
    final color = widget.hasFile ? success : primary;

    return Opacity(
      opacity: widget.enabled ? 1.0 : 0.45,
      child: AbsorbPointer(
        absorbing: !widget.enabled,
        child: GestureDetector(
          onTapDown: (_) => _tapController.forward(),
          onTapUp: (_) => _tapController.reverse(),
          onTapCancel: () => _tapController.reverse(),
          child: AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, hijo) =>
                Transform.scale(scale: _scaleAnim.value, child: hijo),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: widget.hasFile
                      ? success.withOpacity(0.35)
                      : primary.withOpacity(0.12),
                  width: widget.hasFile ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(widget.hasFile ? 0.12 : 0.06),
                    blurRadius: widget.hasFile ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // ── Barra de progreso animada en la parte superior ──
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.hasFile
                              ? [success, success.withOpacity(0.6)]
                              : [
                                  primary.withOpacity(0.2),
                                  primary.withOpacity(0.05),
                                ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Header: icono + título + badge ──
                          Row(
                            children: [
                              // Icono animado
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: widget.isLoading
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            color,
                                          ),
                                        ),
                                      )
                                    : AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Icon(
                                          widget.hasFile
                                              ? Icons.check_circle_rounded
                                              : _iconForDocument(),
                                          key: ValueKey(widget.hasFile),
                                          size: 18,
                                          color: color,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.title,
                                      style: const TextStyle(
                                        fontFamily:
                                            _MisDocumentosPersonalesPantallaState
                                                .fontHeading,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color:
                                            _MisDocumentosPersonalesPantallaState
                                                .kTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    AnimatedSwitcher(
                                      duration: const Duration(
                                        milliseconds: 300,
                                      ),
                                      child: Text(
                                        widget.hasFile
                                            ? '✓ Documento listo'
                                            : widget.description,
                                        key: ValueKey(widget.hasFile),
                                        style: TextStyle(
                                          fontFamily:
                                              _MisDocumentosPersonalesPantallaState
                                                  .fontBody,
                                          fontSize: 11.5,
                                          color: widget.hasFile
                                              ? success
                                              : _MisDocumentosPersonalesPantallaState
                                                    .kTextSecondary,
                                          fontWeight: widget.hasFile
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Badge estado
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 350),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.hasFile
                                      ? success.withOpacity(0.1)
                                      : (widget.isRequired
                                            ? const Color(0xFFFFF3E0)
                                            : const Color(0xFFF5F5F5)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: widget.hasFile
                                        ? success.withOpacity(0.3)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  widget.hasFile
                                      ? 'Listo'
                                      : (widget.isRequired
                                            ? 'Requerido'
                                            : 'Opcional'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: widget.hasFile
                                        ? success
                                        : (widget.isRequired
                                              ? const Color(0xFFE65100)
                                              : Colors.grey),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Botones de acción ──
                          Row(
                            children: [
                              // Botón principal (Ver / Generar / Subir)
                              Expanded(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: widget.isLoading
                                        ? null
                                        : widget.hasFile
                                        // Si tiene archivo → Ver (onPreview)
                                        ? widget.onPreview ?? widget.onUpload
                                        // Si no tiene archivo → Subir/Generar (onUpload)
                                        : ((!widget.isAutoGenerated ||
                                                  widget.canGenerate)
                                              ? widget.onUpload
                                              : null),
                                    icon: widget.isLoading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Icon(
                                            widget.hasFile
                                                ? Icons.visibility_rounded
                                                : (widget.isAutoGenerated
                                                      ? Icons
                                                            .auto_awesome_rounded
                                                      : Icons.upload_rounded),
                                            size: 15,
                                          ),
                                    label: Text(
                                      widget.isLoading
                                          ? 'Procesando...'
                                          : (widget.hasFile
                                                ? 'Ver documento'
                                                : (widget.isAutoGenerated
                                                      ? 'Generar'
                                                      : 'Subir')),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: widget.hasFile
                                          ? success
                                          : primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Botones secundarios (solo si hay archivo)
                              if (widget.hasFile) ...[
                                const SizedBox(width: 8),
                                // Regenerar (solo auto-generados)
                                if (widget.isAutoGenerated)
                                  _SmallIconBtn(
                                    icon: Icons.refresh_rounded,
                                    color: primary,
                                    tooltip: 'Regenerar',
                                    onTap: widget.onUpload,
                                  ),
                                const SizedBox(width: 6),
                                // Eliminar
                                _SmallIconBtn(
                                  icon: Icons.delete_outline_rounded,
                                  color: Colors.red,
                                  tooltip: 'Eliminar',
                                  onTap: widget.onDelete,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón icono pequeño para acciones secundarias
class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _SmallIconBtn({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, size: 18, color: color),
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
