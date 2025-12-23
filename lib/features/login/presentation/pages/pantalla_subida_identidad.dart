import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/features/login/presentation/mixins/identity_ocr_mixin.dart';
import 'package:refactor_template/core/services/identity_smart_ocr_service.dart';

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

  // Controladores para edición manual
  final TextEditingController _ciController = TextEditingController();
  final TextEditingController _nombresController = TextEditingController();
  final TextEditingController _apellidosController = TextEditingController();
  final TextEditingController _fechaEmisionController = TextEditingController(); // Nuevo
  final TextEditingController _fechaExpiracionController = TextEditingController(); // Nuevo
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
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      
      final frontInputImage = InputImage.fromFilePath(_frontImage!.path);
      final frontRecognizedText = await textRecognizer.processImage(frontInputImage);

      final backInputImage = InputImage.fromFilePath(_backImage!.path);
      final backRecognizedText = await textRecognizer.processImage(backInputImage);

      // --- EXTRACCIÓN INTELIGENTE ---
      final smartData = IdentitySmartOcrService.extractData(frontRecognizedText, backRecognizedText);

      await textRecognizer.close();
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _ciController.text = smartData['ci'] ?? "";
        _nombresController.text = smartData['nombres'] ?? "";
        _apellidosController.text = smartData['apellidos'] ?? "";
        _fechaEmisionController.text = smartData['fechaEmision'] ?? ""; // Nuevo
        _fechaExpiracionController.text = smartData['fechaExpiracion'] ?? ""; // Nuevo
        _showCorrectionForm = true; 
      });

    } catch (e) {
      debugPrint("Error en OCR: $e");
      if (mounted) {
        setState(() => _isProcessing = false);
        _showErrorSnackBar('Error al procesar: $e');
      }
    }
  }

  void _navigateToFaceRecognition() {
    if (_ciController.text.isEmpty || _nombresController.text.isEmpty) {
      _showErrorSnackBar('El CI y los Nombres son obligatorios.');
      return;
    }

    context.push(
      '/face-recognition',
      extra: {
        'nombres': _nombresController.text.trim(),
        'apellidos': _apellidosController.text.trim(),
        'ci': cleanCI(_ciController.text),
        'ciFromInitial': (widget.initialCI != null).toString(),
        'fechaEmision': _fechaEmisionController.text.trim(), // Nuevo
        'fechaExpiracion': _fechaExpiracionController.text.trim(), // Nuevo
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

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    if (mounted) Navigator.pop(context);
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 90);
    if (pickedFile != null) {
      await _quickValidateAndSetImage(pickedFile.path, isFront);
    }
  }

  Future<void> _quickValidateAndSetImage(String imagePath, bool isFront) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(color: primaryBlue)),
      );

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (!mounted) return;
      Navigator.pop(context);

      final smartData = IdentitySmartOcrService.extractData(recognizedText, null);
      bool isValid = smartData['ci'].toString().isNotEmpty || smartData['nombres'].toString().isNotEmpty;

      final smartCrop = IdentitySmartOcrService.getRelevantROI(recognizedText);

      final shouldAccept = await _showValidationDialog(isValid, null);

      if (shouldAccept == true && mounted) {
        setState(() {
          if (isFront) {
            _frontImage = File(imagePath);
            _frontCropRect = smartCrop != Rect.zero ? smartCrop : null;
          } else {
            _backImage = File(imagePath);
            _backCropRect = smartCrop != Rect.zero ? smartCrop : null;
          }
        });
        if (isFront) _showFlipAnimation();
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
              warningMessage != null ? Icons.warning_amber_rounded : (isValid ? Icons.check_circle : Icons.help_outline),
              color: warningMessage != null ? Colors.orange : (isValid ? Colors.green : Colors.grey)
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(warningMessage != null ? "¡Atención!" : (isValid ? "Imagen Legible" : "¿Imagen clara?"), style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (warningMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(warningMessage, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ),
            Text(isValid 
              ? "Hemos detectado datos en el carnet correctamente." 
              : "No pudimos detectar datos claros. Asegúrate de que no haya reflejos."),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Reintentar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue, foregroundColor: Colors.white),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Seleccionar origen", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _pickerOption(Icons.camera_alt, "Cámara", () => _pickImage(ImageSource.camera, isFront)),
                _pickerOption(Icons.photo_library, "Galería", () => _pickImage(ImageSource.gallery, isFront)),
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
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
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
        title: const Text('Identidad', style: TextStyle(color: darkBlue, fontWeight: FontWeight.bold)),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: darkBlue), onPressed: () => context.pop()),
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
                FadeInLeft(child: const Text('Captura tu carnet', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkBlue))),
                const SizedBox(height: 8),
                FadeInLeft(delay: const Duration(milliseconds: 200), child: Text('Necesitamos verificar tus datos personales.', style: TextStyle(color: Colors.grey[600], fontSize: 15))),
                const SizedBox(height: 30),
                _buildUploadCard('Lado Frontal (Anverso)', Icons.credit_card, _frontImage, _frontCropRect, () => _showPickerOptions(true)),
                const SizedBox(height: 20),
                _buildUploadCard('Lado Posterior (Reverso)', Icons.credit_card_off, _backImage, _backCropRect, () => _showPickerOptions(false)),
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
      color: Colors.black.withOpacity(0.6),
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
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
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
                  _buildTextField("Apellidos", _apellidosController, Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildDatePickerField("Fecha de Emisión", _fechaEmisionController, Icons.date_range), // Nuevo
                  const SizedBox(height: 15),
                  _buildDatePickerField("Fecha de Expiración", _fechaExpiracionController, Icons.event_repeat), // Nuevo
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
                        onPressed: () => setState(() => _showCorrectionForm = false),
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

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
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

  Widget _buildDatePickerField(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      readOnly: true, // No editable por teclado directo
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900),
          lastDate: DateTime(2101),
          locale: const Locale('es', 'ES'), // Asegúrate de tener conf i18n
          builder: (context, child) => Theme(
             data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: primaryBlue)),
             child: child!,
          ),
        );
        if (pickedDate != null) {
          // Formato simple DD/MM/YYYY
          String formattedDate = "${pickedDate.day.toString().padLeft(2,'0')}/${pickedDate.month.toString().padLeft(2,'0')}/${pickedDate.year}";
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
          gradient: ready ? const LinearGradient(colors: [primaryBlue, darkBlue]) : null,
          boxShadow: ready ? [BoxShadow(color: primaryBlue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))] : [],
        ),
        child: ElevatedButton(
          onPressed: ready ? _processImageWithOCR : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: _isProcessing 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Completar Análisis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
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
          width: 35, height: 35,
          decoration: BoxDecoration(
            color: active ? primaryBlue : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: active ? primaryBlue : Colors.grey[300]!, width: 2),
          ),
          child: Center(child: Text(step.toString(), style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: active ? primaryBlue : Colors.grey)),
      ],
    );
  }

  Widget _stepLine(bool active) {
    return Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 20, left: 10, right: 10), color: active ? primaryBlue : Colors.grey[200]));
  }

  Widget _buildUploadCard(String title, IconData icon, File? file, Rect? cropRect, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: file != null ? primaryBlue : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: file != null 
            ? Image.file(file, fit: BoxFit.cover)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 45, color: primaryBlue.withOpacity(0.5)),
                  const SizedBox(height: 15),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: darkBlue)),
                  const SizedBox(height: 5),
                  Text('Toca para capturar', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
        ),
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(child: _ScanningAnimation()),
    );
  }
}

class _FlipCardAnimation extends StatefulWidget {
  const _FlipCardAnimation();
  @override
  State<_FlipCardAnimation> createState() => _FlipCardAnimationState();
}

class _FlipCardAnimationState extends State<_FlipCardAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..forward();
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
            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(_controller.value * math.pi),
            child: Container(
              width: 220, height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: const LinearGradient(colors: [Color(0xFF305BA4), Color(0xFF1A3A5C)]),
                boxShadow: const [BoxShadow(color: Colors.blueAccent, blurRadius: 20)],
              ),
              child: const Icon(Icons.credit_card, color: Colors.white, size: 60),
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

class _ScanningAnimationState extends State<_ScanningAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
                const Icon(Icons.contact_page_outlined, size: 120, color: Colors.blueAccent),
                Positioned(top: 20 + _controller.value * 80, child: Container(width: 150, height: 3, decoration: BoxDecoration(color: Colors.cyanAccent, boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)]))),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Analizando Documento...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        );
      },
    );
  }
}
