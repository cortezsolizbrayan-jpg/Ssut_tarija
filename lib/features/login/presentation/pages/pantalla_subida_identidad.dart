import 'dart:io';
import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/features/login/presentation/mixins/identity_ocr_mixin.dart';
import 'package:refactor_template/core/services/identity_smart_ocr_service.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';
import 'package:refactor_template/core/services/ci_letter_composer_service.dart';

class IDUploadScreen extends StatefulWidget {
  static const name = 'id-upload-screen';
  final String? initialCI;

  const IDUploadScreen({super.key, this.initialCI});

  @override
  State<IDUploadScreen> createState() => _IDUploadScreenState();
}

class _IDUploadScreenState extends State<IDUploadScreen> with IdentityOcrMixin {
  File? _frontImage;
  File? _backImage;
  Rect? _frontCropRect;
  Rect? _backCropRect;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  static const double _samePhotoSimilarityThreshold = 0.90;

  Future<void> _persistCiSideForDocuments(
    File imgFile, {
    required bool isFront,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final outDir = Directory(
        '${dir.path}${Platform.pathSeparator}participant_documents',
      );
      if (!await outDir.exists()) {
        await outDir.create(recursive: true);
      }

      final fileName = isFront ? 'ci_front_latest.jpg' : 'ci_back_latest.jpg';
      final dest = File('${outDir.path}${Platform.pathSeparator}$fileName');
      await imgFile.copy(dest.path);

      final current =
          await LocalStorageService.getParticipantDocumentsData() ??
          <String, dynamic>{};
      current[isFront ? 'ci_front_path' : 'ci_back_path'] = dest.path;
      await LocalStorageService.saveParticipantDocumentsData(current);

      final frontPath = current['ci_front_path'] as String?;
      final backPath = current['ci_back_path'] as String?;

      if (frontPath != null &&
          frontPath.isNotEmpty &&
          backPath != null &&
          backPath.isNotEmpty) {
        final out = await CiLetterComposerService.composeLetterFromCiImages(
          front: File(frontPath),
          back: File(backPath),
        );
        if (out != null) {
          current['ci_letter_path'] = out.path;
          await LocalStorageService.saveParticipantDocumentsData(current);
        }
      }
    } catch (_) {
      // Best-effort: no bloquear el flujo del usuario
    }
  }

  DateTime? _tryParseDateStrict(String ddMMyyyy) {
    final parts = ddMMyyyy.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;

    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  Future<File> _normalizeForOcr(File input) async {
    try {
      final bytes = await input.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return input;

      img.Image normalized = img.bakeOrientation(decoded);

      // Pre-procesamiento de imagen para mejorar OCR
      // 1. Escala de grises (elimina ruido de color)
      normalized = img.grayscale(normalized);

      // 2. Aumentar contraste (ayuda a separar texto del fondo)
      // Usamos adjustColor para versiones recientes de package:image
      // o manipulamos pixeles si es necesario. Contrast 1.5 = 150%
      normalized = img.contrast(normalized, contrast: 150);

      // 3. Redimensionar si es muy grande (mantiene aspecto)
      const maxDim = 1920;
      final w = normalized.width;
      final h = normalized.height;
      if (w > maxDim || h > maxDim) {
        if (w >= h) {
          normalized = img.copyResize(
            normalized,
            width: maxDim,
            interpolation: img.Interpolation.cubic,
          );
        } else {
          normalized = img.copyResize(
            normalized,
            height: maxDim,
            interpolation: img.Interpolation.cubic,
          );
        }
      }

      final tmpDir = await getTemporaryDirectory();
      final outPath =
          '${tmpDir.path}${Platform.pathSeparator}id_norm_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(normalized, quality: 90));
      return outFile;
    } catch (_) {
      return input;
    }
  }

  Future<int?> _computeDHashFromFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(
        img.bakeOrientation(decoded),
        width: 9,
        height: 8,
        interpolation: img.Interpolation.average,
      );    

      int hash = 0;
      int bitIndex = 0;

      int lum(int x, int y) {
        final p = resized.getPixel(x, y);
        final r = p.r.toInt();
        final g = p.g.toInt();
        final b = p.b.toInt();
        return (0.299 * r + 0.587 * g + 0.114 * b).round();
      }

      for (int y = 0; y < 8; y++) {
        for (int x = 0; x < 8; x++) {
          final left = lum(x, y);
          final right = lum(x + 1, y);
          if (left > right) {
            hash |= (1 << bitIndex);
          }
          bitIndex++;
        }
      }

      return hash;
    } catch (_) {
      return null;
    }
  }

  int _hammingDistance64(int a, int b) {
    int x = a ^ b;
    int count = 0;
    while (x != 0) {
      count += (x & 1);
      x >>= 1;
    }
    return count;
  }

  Future<double?> _photoSimilarity(File a, File b) async {
    final ha = await _computeDHashFromFile(a);
    final hb = await _computeDHashFromFile(b);
    if (ha == null || hb == null) return null;

    final dist = _hammingDistance64(ha, hb);
    return 1.0 - (dist / 64.0);
  }

  Future<File> _cropToRoiIfPossible(File input, Rect roi) async {
    try {
      if (roi == Rect.zero) return input;

      final bytes = await input.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return input;

      final pad = 18.0;
      final left = (roi.left - pad).clamp(0.0, decoded.width.toDouble());
      final top = (roi.top - pad).clamp(0.0, decoded.height.toDouble());
      final right = (roi.right + pad).clamp(0.0, decoded.width.toDouble());
      final bottom = (roi.bottom + pad).clamp(0.0, decoded.height.toDouble());
      final width = (right - left).toInt();
      final height = (bottom - top).toInt();

      if (width < 80 || height < 80) return input;

      final cropped = img.copyCrop(
        decoded,
        x: left.toInt(),
        y: top.toInt(),
        width: width,
        height: height,
      );

      final tmpDir = await getTemporaryDirectory();
      final outPath =
          '${tmpDir.path}${Platform.pathSeparator}id_roi_${DateTime.now().millisecondsSinceEpoch}_${math.Random().nextInt(9999)}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(cropped, quality: 92));
      return outFile;
    } catch (_) {
      return input;
    }
  }

  Future<String?> _createCombinedImage(File front, File back) async {
    try {
      final frontBytes = await front.readAsBytes();
      final backBytes = await back.readAsBytes();
      final frontImg = img.decodeImage(frontBytes);
      final backImg = img.decodeImage(backBytes);

      if (frontImg == null || backImg == null) return null;

      // Letter size at ~150 DPI: 1275 x 1650
      final canvasWidth = 1275;
      final canvasHeight = 1650;
      final canvas = img.Image(width: canvasWidth, height: canvasHeight);

      // Fill with white
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));

      // Resize images to fit width with padding (e.g. 80% of width)
      final targetWidth = (canvasWidth * 0.8).toInt();

      final resizedFront = img.copyResize(
        frontImg,
        width: targetWidth,
        interpolation: img.Interpolation.cubic,
      );
      final resizedBack = img.copyResize(
        backImg,
        width: targetWidth,
        interpolation: img.Interpolation.cubic,
      );

      // Position: Centered horizontally.
      // Front: Top half. Back: Bottom half.
      final xFront = (canvasWidth - resizedFront.width) ~/ 2;
      final yFront = (canvasHeight ~/ 4) - (resizedFront.height ~/ 2);

      final xBack = (canvasWidth - resizedBack.width) ~/ 2;
      final yBack = (canvasHeight * 3 ~/ 4) - (resizedBack.height ~/ 2);

      img.compositeImage(canvas, resizedFront, dstX: xFront, dstY: yFront);
      img.compositeImage(canvas, resizedBack, dstX: xBack, dstY: yBack);

      // Dibujar borde negro sutil alrededor de las fotos para simular "recorte"
      img.drawRect(
        canvas,
        x1: xFront,
        y1: yFront,
        x2: xFront + resizedFront.width,
        y2: yFront + resizedFront.height,
        color: img.ColorRgb8(200, 200, 200),
      );
      img.drawRect(
        canvas,
        x1: xBack,
        y1: yBack,
        x2: xBack + resizedBack.width,
        y2: yBack + resizedBack.height,
        color: img.ColorRgb8(200, 200, 200),
      );

      final tmpDir = await getTemporaryDirectory();
      final outPath =
          '${tmpDir.path}${Platform.pathSeparator}combined_ci_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final outFile = File(outPath);
      await outFile.writeAsBytes(img.encodeJpg(canvas, quality: 90));
      return outPath;
    } catch (e) {
      debugPrint("Error creating combined image: $e");
      return null;
    }
  }

  // Controladores para edición manual
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _fechaEmisionController =
      TextEditingController(); // Nuevo
  final TextEditingController _fechaExpiracionController =
      TextEditingController(); // Nuevo
  bool _showCorrectionForm = false;

  // Colors for premium look
  static const Color primaryBlue = Color(0xFF305BA4);
  static const Color darkBlue = Color(0xFF1A3A5C);
  static const Color bgColor = Color(0xFFF6F8FB);

  @override
  void dispose() {
    _ciController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _fechaEmisionController.dispose(); // Nuevo
    _fechaExpiracionController.dispose(); // Nuevo
    super.dispose();
  }

  Future<void> _processImageWithOCR() async {
    if (_frontImage == null || _backImage == null) {
      _showErrorSnackBar('Por favor sube ambas fotos del carnet.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      try {
        // 1) Normalizar (orientación + tamaño) antes del OCR
        final normalizedFront = await _normalizeForOcr(_frontImage!);
        final normalizedBack = await _normalizeForOcr(_backImage!);

        // 2) OCR 1ra pasada (para encontrar ROI y detectar lado)
        final pass1Front = await textRecognizer.processImage(
          InputImage.fromFilePath(normalizedFront.path),
        );
        final pass1Back = await textRecognizer.processImage(
          InputImage.fromFilePath(normalizedBack.path),
        );

        // 3) Auto-corrección si el usuario subió reverso/anverso invertidos
        File frontForCrop = normalizedFront;
        File backForCrop = normalizedBack;
        RecognizedText frontForRoi = pass1Front;
        RecognizedText backForRoi = pass1Back;

        final sideFront = IdentitySmartOcrService.detectSide(pass1Front);
        final sideBack = IdentitySmartOcrService.detectSide(pass1Back);
        if (sideFront == 'reverso' && sideBack == 'anverso') {
          frontForCrop = normalizedBack;
          backForCrop = normalizedFront;
          frontForRoi = pass1Back;
          backForRoi = pass1Front;
        }

        // 4) Calcular ROI relevante y recortar
        final frontRoi = IdentitySmartOcrService.getRelevantROI(frontForRoi);
        final backRoi = IdentitySmartOcrService.getRelevantROI(backForRoi);

        final croppedFront = await _cropToRoiIfPossible(frontForCrop, frontRoi);
        final croppedBack = await _cropToRoiIfPossible(backForCrop, backRoi);

        // 5) OCR 2da pasada (más precisión al reducir ruido)
        final pass2Front = await textRecognizer.processImage(
          InputImage.fromFilePath(croppedFront.path),
        );
        final pass2Back = await textRecognizer.processImage(
          InputImage.fromFilePath(croppedBack.path),
        );

        // --- EXTRACCIÓN INTELIGENTE (con OCR refinado) ---
        final smartData = IdentitySmartOcrService.extractData(
          pass2Front,
          pass2Back,
        );

        if (!mounted) return;

        setState(() {
          _isProcessing = false;
          _ciController.text = smartData['ci'] ?? "";
          _nombresController.text = smartData['nombres'] ?? "";
          _apellidosController.text = smartData['apellidos'] ?? "";
          _fechaEmisionController.text = formatDate(
            smartData['fechaEmision'] ?? "",
          );
          _fechaExpiracionController.text = formatDate(
            smartData['fechaExpiracion'] ?? "",
          );
          _showCorrectionForm = true;
        });
      } finally {
        await textRecognizer.close();
      }
      if (!mounted) return;
    } catch (e) {
      debugPrint("Error en OCR: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar('Error al procesar: $e');
      }
    }
  }

  void _navigateToFaceRecognition() {
    // Wrapper para ser usado en callbacks (onPressed) sin cambiar firmas.
    // ignore: unawaited_futures
    _navigateToFaceRecognitionAsync();
  }

  Future<void> _navigateToFaceRecognitionAsync() async {
    if (_ciController.text.isEmpty || _nombresController.text.isEmpty) {
      _showErrorSnackBar('El CI y los Nombres son obligatorios.');
      return;
    }

    final emisionRaw = _fechaEmisionController.text.trim();
    final expiracionRaw = _fechaExpiracionController.text.trim();
    if (emisionRaw.isNotEmpty &&
        !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(emisionRaw)) {
      _showErrorSnackBar('Fecha de Emisión inválida (DD/MM/AAAA).');
      return;
    }
    if (expiracionRaw.isNotEmpty &&
        !RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(expiracionRaw)) {
      _showErrorSnackBar('Fecha de Expiración inválida (DD/MM/AAAA).');
      return;
    }
    if (emisionRaw.isNotEmpty) {
      final emision = _tryParseDateStrict(emisionRaw);
      if (emision == null) {
        _showErrorSnackBar('Fecha de Emisión inválida.');
        return;
      }
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      if (emision.isAfter(todayDate)) {
        _showErrorSnackBar('La emisión no puede ser futura.');
        return;
      }
      if (expiracionRaw.isNotEmpty) {
        final expiracion = _tryParseDateStrict(expiracionRaw);
        if (expiracion == null) {
          _showErrorSnackBar('Fecha de Expiración inválida.');
          return;
        }
        if (expiracion.isBefore(emision)) {
          _showErrorSnackBar('La expiración no puede ser antes de la emisión.');
          return;
        }
      }
    }

    // Generate combined image
    String? combinedPath;
    if (_frontImage != null && _backImage != null) {
      await _showBlockingLoader();
      combinedPath = await _createCombinedImage(_frontImage!, _backImage!);
      _dismissBlockingLoaderIfAny(true);
    }

    if (!mounted) return;

    context.push(
      '/face-recognition',
      extra: {
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'ci': cleanCI(_ciController.text),
        'ciFromInitial': (widget.initialCI != null).toString(),
        'fechaEmision': _fechaEmisionController.text.trim(),
        'fechaExpiracion': _fechaExpiracionController.text.trim(),
        'combinedCiPath': combinedPath ?? "",
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orangeAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _showBlockingLoader() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: primaryBlue)),
    );
  }

  void _dismissBlockingLoaderIfAny(bool wasShown) {
    if (!wasShown) return;
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    if (mounted) {
      Navigator.of(context).maybePop();
    }
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (pickedFile != null) {
      await _quickValidateAndSetImage(pickedFile.path, isFront);
    }
  }

  Future<void> _quickValidateAndSetImage(String imagePath, bool isFront) async {
    bool loaderShown = false;
    try {
      loaderShown = true;
      // ignore: unawaited_futures
      _showBlockingLoader();

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      final normalizedFile = await _normalizeForOcr(File(imagePath));
      final inputImage = InputImage.fromFile(normalizedFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      _dismissBlockingLoaderIfAny(loaderShown);
      loaderShown = false;
      if (!mounted) return;

      final smartData = IdentitySmartOcrService.extractData(
        recognizedText,
        null,
      );
      bool isValid =
          smartData['ci'].toString().isNotEmpty ||
          smartData['nombres'].toString().isNotEmpty;

      final detectedSide = IdentitySmartOcrService.detectSide(recognizedText);

      final smartCrop = IdentitySmartOcrService.getRelevantROI(recognizedText);
      final croppedFile = await _cropToRoiIfPossible(normalizedFile, smartCrop);

      String? warning;
      if (isFront && detectedSide == 'reverso') {
        warning =
            'Parece que esta foto es del reverso. Toma el lado frontal (anverso).';
        isValid = false;
      } else if (!isFront && detectedSide == 'anverso') {
        // Solo advertir si la nueva foto es MUY similar a la foto frontal
        // (probablemente se volvió a tomar la misma foto).
        if (_frontImage != null) {
          final similarity = await _photoSimilarity(_frontImage!, croppedFile);
          if (similarity == null ||
              similarity >= _samePhotoSimilarityThreshold) {
            warning =
                'Parece que esta foto es del anverso. Toma el lado posterior (reverso).';
            isValid = false;
          }
        } else {
          warning =
              'Parece que esta foto es del anverso. Toma el lado posterior (reverso).';
          isValid = false;
        }
      }

      final shouldAccept = await _showValidationDialog(isValid, warning);

      if (shouldAccept == true && mounted) {
        setState(() {
          if (isFront) {
            _frontImage = croppedFile;
            _frontCropRect = smartCrop != Rect.zero ? smartCrop : null;
          } else {
            _backImage = croppedFile;
            _backCropRect = smartCrop != Rect.zero ? smartCrop : null;
          }
        });
        // ignore: unawaited_futures
        _persistCiSideForDocuments(croppedFile, isFront: isFront);
        if (isFront) _showFlipAnimation();
      }
    } catch (e) {
      _dismissBlockingLoaderIfAny(loaderShown);
    }
  }

  //Aqui estamos validanddo lo que es la imagen correspondiente
  Future<bool?> _showValidationDialog(bool isValid, String? warningMessage) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              warningMessage != null
                  ? Icons.warning_amber_rounded
                  : (isValid ? Icons.check_circle : Icons.help_outline),
              color: warningMessage != null
                  ? Colors.orange
                  : (isValid ? Colors.green : Colors.grey),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                warningMessage != null
                    ? "¡Atención!"
                    : (isValid ? "Imagen Legible" : "¿Imagen clara?"),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warningMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  warningMessage,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              isValid
                  ? "Hemos detectado datos en el carnet correctamente."
                  : "No pudimos detectar datos claros. Asegúrate de que no haya reflejos.",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Reintentar"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Usar esta foto"),
          ),
        ],
      ),
    );
  }

  void _showFlipAnimation() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _FlipCardAnimation(),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        if (_backImage == null) _showPickerOptions(false);
      }
    });
  }

  void _showPickerOptions(bool isFront) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Seleccionar origen",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerOption(
                  Icons.camera_alt,
                  "Cámara",
                  () => _pickImage(ImageSource.camera, isFront),
                ),
                _pickerOption(
                  Icons.photo_library,
                  "Galería",
                  () => _pickImage(ImageSource.gallery, isFront),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickerOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: primaryBlue.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryBlue, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Identidad',
          style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkBlue),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInDown(child: _buildStepIndicator()),
                const SizedBox(height: 30),
                FadeInLeft(
                  child: const Text(
                    'Captura tu carnet',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInLeft(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Necesitamos verificar tus datos personales.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ),
                const SizedBox(height: 30),
                _buildUploadCard(
                  'Lado Frontal (Anverso)',
                  Icons.credit_card,
                  _frontImage,
                  _frontCropRect,
                  () => _showPickerOptions(true),
                ),
                const SizedBox(height: 20),
                _buildUploadCard(
                  'Lado Posterior (Reverso)',
                  Icons.credit_card_off,
                  _backImage,
                  _backCropRect,
                  () => _showPickerOptions(false),
                ),
                const SizedBox(height: 40),
                _buildContinueButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isProcessing) _buildScanningOverlay(),
          if (_showCorrectionForm) _buildCorrectionForm(),
        ],
      ),
    );
  }

  Widget _buildCorrectionForm() {
    return Container(
      color: Colors.black.withAlpha(153),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: FadeInUp(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(51),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note, size: 50, color: primaryBlue),
                  const SizedBox(height: 10),
                  const Text(
                    "Confirma tus datos",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Toca cualquier campo para corregirlo si hay errores.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  _buildTextField("Número de CI", _ciController, Icons.badge),
                  const SizedBox(height: 15),
                  _buildTextField("Nombres", _nombresController, Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Apellidos",
                    _apellidosController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildDatePickerField(
                    "Fecha de Emisión",
                    _fechaEmisionController,
                    Icons.date_range,
                    lastDate: DateTime.now(),
                  ), // Nuevo
                  const SizedBox(height: 15),
                  _buildDatePickerField(
                    "Fecha de Expiración",
                    _fechaExpiracionController,
                    Icons.event_repeat,
                    firstDate: DateTime.now(),
                  ), // Nuevo
                  const SizedBox(height: 30),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: _navigateToFaceRecognition,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Confirmar e Ir al Siguiente Paso"),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () =>
                            setState(() => _showCorrectionForm = false),
                        child: const Text("Volver a tomar fotos"),
                      ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    IconData icon, {
    DateTime? firstDate,
    DateTime? lastDate,
  }) {
    return TextField(
      controller: controller,
      readOnly: true, // No editable por teclado directo
      onTap: () async {
        DateTime initialDate;
        final raw = controller.text.trim();
        final parsed = _tryParseDateStrict(raw);
        initialDate = parsed ?? DateTime.now();

        final effectiveFirstDate = firstDate ?? DateTime(1900);
        final effectiveLastDate = lastDate ?? DateTime(2101);
        if (initialDate.isBefore(effectiveFirstDate)) {
          initialDate = effectiveFirstDate;
        }
        if (initialDate.isAfter(effectiveLastDate)) {
          initialDate = effectiveLastDate;
        }

        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: effectiveFirstDate,
          lastDate: effectiveLastDate,
          locale: const Locale('es', 'ES'), // Asegúrate de tener conf i18n
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: primaryBlue),
            ),
            child: child!,
          ),
        );
        if (pickedDate != null) {
          // Formato simple DD/MM/YYYY
          String formattedDate =
              "${pickedDate.day.toString().padLeft(2, '0')}/${pickedDate.month.toString().padLeft(2, '0')}/${pickedDate.year}";
          controller.text = formattedDate;
        }
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryBlue),
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
    );
  }

  Widget _buildContinueButton() {
    bool ready = _frontImage != null && _backImage != null && !_isProcessing;
    return FadeInUp(
      delay: const Duration(milliseconds: 400),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: ready
              ? const LinearGradient(colors: [primaryBlue, darkBlue])
              : null,
          boxShadow: ready
              ? [
                  BoxShadow(
                    color: primaryBlue.withAlpha(77),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: ready ? _processImageWithOCR : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Completar Análisis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepItem(1, "Fotos", true),
        _stepLine(true),
        _stepItem(2, "Análisis", _isProcessing),
        _stepLine(false),
        _stepItem(3, "Facial", false),
      ],
    );
  }

  Widget _stepItem(int step, String label, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: active ? primaryBlue : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: active ? primaryBlue : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? primaryBlue : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
        color: active ? primaryBlue : Colors.grey[200],
      ),
    );
  }

  Widget _buildUploadCard(
    String title,
    IconData icon,
    File? file,
    Rect? cropRect,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: file != null ? primaryBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: file != null
                ? Image.file(file, fit: BoxFit.cover, key: ValueKey(file.path))
                : Column(
                    key: const ValueKey('placeholder'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 45, color: primaryBlue.withAlpha(128)),
                      const SizedBox(height: 15),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: darkBlue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Toca para capturar',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black.withAlpha(204),
      child: const Center(child: _ScanningAnimation()),
    );
  }
}

class _FlipCardAnimation extends StatefulWidget {
  const _FlipCardAnimation();
  @override
  State<_FlipCardAnimation> createState() => _FlipCardAnimationState();
}

class _FlipCardAnimationState extends State<_FlipCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (ctx, child) {
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(_controller.value * math.pi),
            child: Container(
              width: 220,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(
                  colors: [Color(0xFF305BA4), Color(0xFF1A3A5C)],
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.blueAccent, blurRadius: 20),
                ],
              ),
              child: const Icon(
                Icons.credit_card,
                color: Colors.white,
                size: 60,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScanningAnimation extends StatefulWidget {
  const _ScanningAnimation();
  @override
  State<_ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<_ScanningAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (ctx, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.contact_page_outlined,
                  size: 120,
                  color: Colors.blueAccent,
                ),
                Positioned(
                  top: 20 + _controller.value * 80,
                  child: Container(
                    width: 150,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withAlpha(128),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Analizando Documento...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        );
      },
    );
  }
}
