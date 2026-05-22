import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:animate_do/animate_do.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

// Servvicios importados - Correcion de clases a utilizar
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/documentos/servicio_fotocopia_carnet.dart';
import 'package:refactor_template/core/services/image_processing/servicio_procesador_imagen_perfil.dart';
import 'package:refactor_template/core/services/documentos/servicio_compositor_cartas_ci.dart';
import 'package:refactor_template/core/services/documentos/servicio_generador_carta_inscripcion.dart';
import 'package:refactor_template/features/sistema/screens/perfil/escaneo/pantalla_escaneo_inteligente.dart';

// Importacion modular
import 'mis_documentos/constants.dart';
import 'mis_documentos/widgets/vertical_timeline_step.dart';
import 'mis_documentos/widgets/timeline_node.dart';
import 'mis_documentos/widgets/doc_upload_card.dart';
import 'mis_documentos/widgets/progress_card.dart';
import 'mis_documentos/widgets/profile_photo_card.dart';
import 'mis_documentos/modals/legal_document_modal.dart';
import 'package:refactor_template/features/sistema/screens/contenedor/menu_lateral_scope.dart';

enum _SourceType { camera, gallery, file }

class MisDocumentosPersonalesScreen extends StatefulWidget {
  static const name = 'mis-documentos-personales-screen';
  final String? idPrograma;

  const MisDocumentosPersonalesScreen({super.key, this.idPrograma});

  @override
  State<MisDocumentosPersonalesScreen> createState() =>
      _MisDocumentosPersonalesScreenState();
}

class _MisDocumentosPersonalesScreenState
    extends State<MisDocumentosPersonalesScreen> {
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

  bool _busyGlobal = false;
  String? _busyKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      _cartaInscripcionPath = data?['carta_inscripcion_path'] as String?;
      _comprobanteMatriculaPath =
          data?['comprobante_matricula_path'] as String?;
      _comprobanteColegiaturaPath =
          data?['comprobante_colegiatura_path'] as String?;
      _fichaInscripcionPath = data?['ficha_inscripcion_path'] as String?;
      _hojaVidaPath = data?['hoja_vida_path'] as String?;
      _profilePhoto = profilePhoto;
      _deferDocuments = data?['defer_documents'] == true;
      _busyGlobal = false;
    });
  }

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

  Future<void> _setDeferDocuments(bool value) async {
    setState(() => _deferDocuments = value);
    final current =
        await LocalStorageService.getParticipantDocumentsData(
          widget.idPrograma,
        ) ??
        <String, dynamic>{};
    current['defer_documents'] = value;
    await LocalStorageService.saveParticipantDocumentsData(
      current,
      widget.idPrograma,
    );
  }

  Future<void> _pickAndSave({
    required String key,
    required String prefix,
    required Function(String) onSet,
    bool allowFile = false,
  }) async {
    if (_deferDocuments) return;

    final source = await _showSourcePicker(allowFile: allowFile);
    if (source == null) return;

    String? pickedPath;
    if (source == _SourceType.file) {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      pickedPath = res?.files.single.path;
    } else {
      final photo = await _picker.pickImage(
        source: source == _SourceType.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 70,
      );
      pickedPath = photo?.path;
    }

    if (pickedPath == null) return;

    setState(() => _busyKey = key);
    try {
      final dir = await getApplicationDocumentsDirectory();
      final extension = pickedPath.contains('.')
          ? pickedPath.substring(pickedPath.lastIndexOf('.'))
          : '.jpg';
      final fileName =
          '${prefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final savedFile = await File(pickedPath).copy('${dir.path}/$fileName');

      await _saveDocPath(key, savedFile.path);
      if (mounted) {
        setState(() {
          onSet(savedFile.path);
          _busyKey = null;
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al guardar: $e', esError: true);
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<_SourceType?> _showSourcePicker({bool allowFile = false}) async {
    return showModalBottomSheet<_SourceType>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: MisDocumentosConstants.kPrimaryColor,
              ),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, _SourceType.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: MisDocumentosConstants.kPrimaryColor,
              ),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, _SourceType.gallery),
            ),
            if (allowFile)
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: MisDocumentosConstants.kPrimaryColor,
                ),
                title: const Text('Archivo / PDF'),
                onTap: () => Navigator.pop(ctx, _SourceType.file),
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarMensaje(String msg, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: esError
            ? MisDocumentosConstants.kErrorColor
            : MisDocumentosConstants.kSuccessColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _previewDoc(String path) async {
    if (path.isEmpty) return;
    try {
      await OpenFilex.open(path);
    } catch (e) {
      _mostrarMensaje('No se pudo abrir el archivo', esError: true);
    }
  }

  Future<bool> _confirmDelete(String label) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar $label'),
        content: const Text('¿Está seguro de eliminar este documento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _updateProfilePhoto() async {
    final source = await _showSourcePicker();
    if (source == null) return;

    final photo = await _picker.pickImage(
      source: source == _SourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    if (photo == null) return;

    setState(() => _busyKey = 'profile_photo');
    try {
      final processed = await ProfileImageProcessorService.processProfileImage(
        File(photo.path),
        isFirstPhoto: true,
      );
      if (processed != null) {
        await LocalStorageService.saveProfileImage(processed);
        if (mounted) {
          setState(() {
            _profilePhoto = processed;
            _busyKey = null;
          });
          _mostrarMensaje('Foto de perfil actualizada');
        }
      } else {
        if (mounted) setState(() => _busyKey = null);
      }
    } catch (e) {
      _mostrarMensaje('Error al procesar imagen', esError: true);
      if (mounted) setState(() => _busyKey = null);
    }
  }

  // --- Actions ---

  Future<void> _generatePhotocopyFromPaths() async {
    if (_ciFrontPath == null || _ciBackPath == null) return;
    setState(() => _busyKey = 'ci_photocopy_pdf_path');
    try {
      final path = await CarnetPhotocopyService.generatePdf(
        frontFile: File(_ciFrontPath!),
        backFile: File(_ciBackPath!),
      );
      if (path != null) {
        await _saveDocPath('ci_photocopy_pdf_path', path);
        if (mounted) {
          setState(() {
            _participantDocs?['ci_photocopy_pdf_path'] = path;
            _busyKey = null;
          });
          _mostrarMensaje('Fotocopia PDF generada');
        }
      } else {
        if (mounted) setState(() => _busyKey = null);
      }
    } catch (e) {
      _mostrarMensaje('Error al generar PDF: $e', esError: true);
      if (mounted) setState(() => _busyKey = null);
    }
  }

  void _onProrrogaAction() {
    _showLegalDocumentReader(
      title: 'Compromiso de Prórroga',
      content:
          'Yo, por la presente me comprometo a presentar mi Título Académico en un plazo no mayor a 90 días...',
      confirmText: 'Firmar Compromiso',
      onConfirm: (sig) {
        if (mounted) setState(() => _signaturePng = sig);
        _generateSignedProrroga();
      },
    );
  }

  Future<void> _generateSignedProrroga() async {
    if (_signaturePng == null) return;
    setState(() => _busyKey = 'prorroga_path');
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final nombreCompleto =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();

      final out = await ServicioCompositorCartasCi.generateProrrogaLetter(
        fullName: nombreCompleto.isEmpty ? 'PARTICIPANTE' : nombreCompleto,
        ci: (personalData?['numeroCI'] ?? '0').toString(),
        signatureBytes: _signaturePng,
      );

      if (out != null) {
        await _saveDocPath('prorroga_path', out.path);
        if (mounted) {
          setState(() {
            _prorrogaPath = out.path;
            _busyKey = null;
          });
          _mostrarMensaje('Carta de prórroga generada');
        }
      } else {
        if (mounted) setState(() => _busyKey = null);
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', esError: true);
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _generarCartaInscripcion() async {
    setState(() => _busyKey = 'carta_inscripcion_path');
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final nombreCompleto =
          '${personalData?['nombre'] ?? ''} ${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
              .trim();
      final numeroCI = (personalData?['numeroCI'] ?? '').toString().trim();

      if (numeroCI.isEmpty || nombreCompleto.isEmpty) {
        _mostrarMensaje(
          'Complete sus datos en Mi Perfil primero',
          esError: true,
        );
        if (mounted) setState(() => _busyKey = null);
        return;
      }

      final firmaPath = await LocalStorageService.getSignatureImagePath();
      final generador = ServicioGeneradorCartaInscripcion();
      final ruta = await generador.generarCarta(
        tipoPrograma: TipoPrograma.diplomado,
        nombrePrograma:
            (personalData?['nombreProgramaCarta'] ?? 'Programa de Posgrado')
                .toString(),
        modalidad: 'Virtual',
        nombreCompleto: nombreCompleto,
        numeroCI: numeroCI,
        signatureImagePath: firmaPath,
        montoDeposito: '2400', // Value from original code
        guardarEnPreferencias: false,
      );

      await _saveDocPath('carta_inscripcion_path', ruta);
      if (mounted) {
        setState(() {
          _cartaInscripcionPath = ruta;
          _busyKey = null;
        });
        _mostrarMensaje('Carta generada');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', esError: true);
      if (mounted) setState(() => _busyKey = null);
    }
  }

  Future<void> _generarFichaInscripcion() async {
    setState(() => _busyKey = 'ficha_inscripcion_path');
    try {
      final personalData = await LocalStorageService.getPersonalData();
      final ci = personalData?['numeroCI'] ?? '0';

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/ficha_$ci.html');
      await file.writeAsString(
        '<h1>Ficha de Inscripción</h1><p>Datos del postulante...</p>',
      );

      await _saveDocPath('ficha_inscripcion_path', file.path);
      if (mounted) {
        setState(() {
          _fichaInscripcionPath = file.path;
          _busyKey = null;
        });
        _mostrarMensaje('Ficha generada');
      }
    } catch (e) {
      _mostrarMensaje('Error: $e', esError: true);
      if (mounted) setState(() => _busyKey = null);
    }
  }

  void _showLegalDocumentReader({
    required String title,
    required String content,
    Function(Uint8List?)? onConfirm,
    String confirmText = "Aceptar",
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LegalDocumentModal(
        title: title,
        content: content,
        confirmText: confirmText,
        onConfirm: onConfirm,
      ),
    );
  }

  void _abrirEscaneoInteligente() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const PantallaEscaneoInteligente()),
    ).then((_) => _load());
  }

  // --- UI Builders ---

  Widget _buildVerticalMap() {
    final ciOk =
        (_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty;
    final photoOk = _profilePhoto != null;
    final tituloOk = _hasTitle
        ? (_tituloPath ?? '').isNotEmpty
        : (_prorrogaPath ?? '').isNotEmpty;
    final preinsOk =
        (_cartaInscripcionPath ?? '').isNotEmpty &&
        (_fichaInscripcionPath ?? '').isNotEmpty &&
        (_hojaVidaPath ?? '').isNotEmpty;
    final pagosOk =
        (_comprobanteMatriculaPath ?? '').isNotEmpty ||
        (_comprobanteColegiaturaPath ?? '').isNotEmpty;

    return Column(
      children: [
        VerticalTimelineStep(
          title: 'Perfil e Identidad',
          subtitle: 'Tu foto y documento de identidad',
          isFirst: true,
          status: (photoOk && ciOk)
              ? MapStepStatus.completed
              : (photoOk || ciOk
                    ? MapStepStatus.inProgress
                    : MapStepStatus.pending),
          children: [
            ProfilePhotoCard(
              profilePhoto: _profilePhoto,
              isBusy: _busyKey == 'profile_photo',
              onUpdate: _updateProfilePhoto,
            ),
            const SizedBox(height: 12),
            DocUploadCard(
              title: 'Cédula (Anverso)',
              description: 'Sube una foto legible del lado frontal de tu CI',
              customIcon: Icons.badge_outlined,
              path: _ciFrontPath,
              isLoading: _busyKey == 'ci_front_path',
              isRequired: true,
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
            const SizedBox(height: 12),
            DocUploadCard(
              title: 'Cédula (Reverso)',
              description: 'Sube una foto del reverso de tu CI',
              customIcon: Icons.badge_outlined,
              path: _ciBackPath,
              isLoading: _busyKey == 'ci_back_path',
              isRequired: true,
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
            if (ciOk) ...[
              const SizedBox(height: 12),
              DocUploadCard(
                title: 'Fotocopia de C.I. (PDF)',
                description: 'Se genera automáticamente',
                path:
                    (_participantDocs?['ci_photocopy_pdf_path'] as String?) ??
                    '',
                isLoading: _busyKey == 'ci_photocopy_pdf_path',
                canGenerate: true,
                onUpload: _generatePhotocopyFromPaths,
                onPreview: () {
                  final p =
                      _participantDocs?['ci_photocopy_pdf_path'] as String?;
                  if (p != null) _previewDoc(p);
                },
                onDelete: () async {
                  if (await _confirmDelete('Fotocopia C.I.')) {
                    await _saveDocPath('ci_photocopy_pdf_path', null);
                    setState(
                      () => _participantDocs?.remove('ci_photocopy_pdf_path'),
                    );
                  }
                },
              ),
            ],
          ],
        ),
        VerticalTimelineStep(
          title: 'Formación Académica',
          subtitle: 'Acredita tu grado académico',
          status: tituloOk ? MapStepStatus.completed : MapStepStatus.pending,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SwitchListTile(
                value: _hasTitle,
                activeColor: MisDocumentosConstants.kPrimaryColor,
                title: const Text(
                  'Tengo Título en Provisión Nacional',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                onChanged: _deferDocuments
                    ? null
                    : (val) => setState(() => _hasTitle = val),
              ),
            ),
            if (_hasTitle)
              DocUploadCard(
                title: 'Título Académico',
                description: 'Foto o escaneo legible de tu Título en Provisión Nacional',
                customIcon: Icons.school_outlined,
                path: _tituloPath,
                isLoading: _busyKey == 'titulo_path',
                isRequired: true,
                enabled: !_deferDocuments,
                onUpload: () => _pickAndSave(
                  key: 'titulo_path',
                  prefix: 'titulo',
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
              )
            else
              DocUploadCard(
                title: 'Carta de Prórroga',
                description: 'Firmar o subir documento',
                path: _prorrogaPath,
                isLoading: _busyKey == 'prorroga_path',
                isRequired: true,
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
          ],
        ),
        VerticalTimelineStep(
          title: 'Solicitudes y CV',
          subtitle: 'Documentación legal requerida',
          status: preinsOk ? MapStepStatus.completed : MapStepStatus.pending,
          children: [
            DocUploadCard(
              title: 'Carta de solicitud',
              description: 'Se genera automáticamente con tus datos',
              customIcon: Icons.edit_document,
              path: _cartaInscripcionPath,
              isLoading: _busyKey == 'carta_inscripcion_path',
              isRequired: true,
              canGenerate: true,
              onUpload: _generarCartaInscripcion,
              onPreview: () => _previewDoc(_cartaInscripcionPath!),
              onDelete: () async {
                if (await _confirmDelete('Carta')) {
                  await _saveDocPath('carta_inscripcion_path', null);
                  setState(() => _cartaInscripcionPath = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DocUploadCard(
              title: 'Hoja de vida (CV)',
              description: 'Subir currículum resumido (PDF recomendado)',
              customIcon: Icons.work_outline_rounded,
              path: _hojaVidaPath,
              isLoading: _busyKey == 'hoja_vida_path',
              isRequired: true,
              onUpload: () => _pickAndSave(
                key: 'hoja_vida_path',
                prefix: 'cv',
                onSet: (p) => _hojaVidaPath = p,
                allowFile: true,
              ),
              onPreview: () => _previewDoc(_hojaVidaPath!),
              onDelete: () async {
                if (await _confirmDelete('CV')) {
                  await _saveDocPath('hoja_vida_path', null);
                  setState(() => _hojaVidaPath = null);
                }
              },
            ),
          ],
        ),
        VerticalTimelineStep(
          title: 'Pagos y Registro',
          subtitle: 'Finaliza tu inscripción',
          isLast: true,
          status: (pagosOk && (_fichaInscripcionPath?.isNotEmpty ?? false))
              ? MapStepStatus.completed
              : MapStepStatus.pending,
          children: [
            DocUploadCard(
              title: 'Comprobante Matrícula',
              description: 'Adjuntar foto o PDF del pago de matrícula',
              customIcon: Icons.receipt_long_rounded,
              path: _comprobanteMatriculaPath,
              isLoading: _busyKey == 'comprobante_matricula_path',
              onUpload: () => _pickAndSave(
                key: 'comprobante_matricula_path',
                prefix: 'pago',
                onSet: (p) => _comprobanteMatriculaPath = p,
                allowFile: true,
              ),
              onPreview: () => _previewDoc(_comprobanteMatriculaPath!),
              onDelete: () async {
                if (await _confirmDelete('Pago')) {
                  await _saveDocPath('comprobante_matricula_path', null);
                  setState(() => _comprobanteMatriculaPath = null);
                }
              },
            ),
            const SizedBox(height: 12),
            DocUploadCard(
              title: 'Ficha de inscripción',
              description: 'Generar la ficha final de inscripción al programa',
              customIcon: Icons.assignment_turned_in_outlined,
              path: _fichaInscripcionPath,
              isLoading: _busyKey == 'ficha_inscripcion_path',
              isRequired: true,
              canGenerate: true,
              onUpload: _generarFichaInscripcion,
              onPreview: () => _previewDoc(_fichaInscripcionPath!),
              onDelete: () async {
                if (await _confirmDelete('Ficha')) {
                  await _saveDocPath('ficha_inscripcion_path', null);
                  setState(() => _fichaInscripcionPath = null);
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ciOk =
        (_ciFrontPath ?? '').isNotEmpty && (_ciBackPath ?? '').isNotEmpty;
    final photoOk = _profilePhoto != null;
    final tituloOk = _hasTitle ? (_tituloPath ?? '').isNotEmpty : true;
    final prorrogaOk = !_hasTitle ? (_prorrogaPath ?? '').isNotEmpty : true;
    final preinsOk =
        (_cartaInscripcionPath ?? '').isNotEmpty &&
        (_fichaInscripcionPath ?? '').isNotEmpty &&
        (_hojaVidaPath ?? '').isNotEmpty;

    const requiredTotal = 4;
    final requiredDone =
        (ciOk && photoOk ? 1 : 0) +
        (tituloOk && prorrogaOk ? 1 : 0) +
        (preinsOk ? 1 : 0) +
        ((_fichaInscripcionPath?.isNotEmpty ?? false) ? 1 : 0);

    final progress = (requiredDone / requiredTotal).clamp(0.0, 1.0);

    return WillPopScope(
      onWillPop: () async {
        if (context.canPop())
          context.pop();
        else
          context.go('/sistema/pantalla_principal');
        return false;
      },
      child: Scaffold(
        backgroundColor: MisDocumentosConstants.kSurfaceColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              elevation: 0,
              backgroundColor: MisDocumentosConstants.kPrimaryColor,
              automaticallyImplyLeading: false,
              leading: const BotonMenuLateral(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        MisDocumentosConstants.kPrimaryColor,
                        MisDocumentosConstants.kPrimaryLight,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -40,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FadeInDown(
                                child: const Text(
                                  'Mis Documentos',
                                  style: TextStyle(
                                    fontFamily:
                                        MisDocumentosConstants.fontHeading,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 26,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FadeInDown(
                                delay: const Duration(milliseconds: 100),
                                child: Text(
                                  'Gestiona tus archivos personales',
                                  style: TextStyle(
                                    fontFamily: MisDocumentosConstants.fontBody,
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
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
              ),
              actions: [
                IconButton(
                  onPressed: _abrirEscaneoInteligente,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MisDocumentosConstants.kSuccessColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.document_scanner_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
          body: _busyGlobal
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      MisDocumentosConstants.kPrimaryColor,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  children: [
                    SlideInUp(
                      child: ProgressCard(
                        progress: progress,
                        done: requiredDone,
                        total: requiredTotal,
                        ciOk: ciOk,
                        tituloOk: tituloOk,
                        prorrogaOk: prorrogaOk,
                      ),
                    ),
                    const SizedBox(height: 32),
                    FadeInUp(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 32),
                        decoration: BoxDecoration(
                          color: _deferDocuments
                              ? MisDocumentosConstants.kPrimaryColor
                                    .withOpacity(0.05)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _deferDocuments
                                ? MisDocumentosConstants.kPrimaryColor
                                      .withOpacity(0.3)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: SwitchListTile(
                          value: _deferDocuments,
                          activeColor: MisDocumentosConstants.kPrimaryColor,
                          secondary: Icon(
                            _deferDocuments
                                ? Icons.history_toggle_off_rounded
                                : Icons.history_rounded,
                            color: _deferDocuments
                                ? MisDocumentosConstants.kPrimaryColor
                                : MisDocumentosConstants.kTextSecondary,
                          ),
                          title: const Text(
                            'Cargaré mis documentos después',
                            style: TextStyle(
                              fontFamily: MisDocumentosConstants.fontBody,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          onChanged: _setDeferDocuments,
                        ),
                      ),
                    ),
                    _buildVerticalMap(),
                  ],
                ),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          decoration: BoxDecoration(
            color: MisDocumentosConstants.kCardColor,
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
              child: ElevatedButton(
                onPressed: (_busyGlobal || _busyKey != null)
                    ? null
                    : () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MisDocumentosConstants.kPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Guardar y Continuar',
                  style: TextStyle(
                    fontFamily: MisDocumentosConstants.fontHeading,
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
}

