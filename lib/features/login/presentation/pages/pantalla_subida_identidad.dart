import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/cloud_vision_ocr_service.dart';
import 'package:refactor_template/core/services/carnet_photocopy_service.dart';
import 'package:refactor_template/core/services/gemini_structured_ocr_service.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';
import 'package:refactor_template/core/services/profile_image_processor_service.dart';
import 'package:refactor_template/core/services/servicio_ocr_inteligente_identidad.dart';

class IDUploadScreen extends StatefulWidget {
  static const name = 'id-upload-screen';
  final String? initialCI; // CI ingresado previamente

  const IDUploadScreen({super.key, this.initialCI});

  @override
  State<IDUploadScreen> createState() => _IDUploadScreenState();
}

class _IDUploadScreenState extends State<IDUploadScreen>
    with SingleTickerProviderStateMixin {
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  double _progress = 0.0;
  DateTime? _processStart;
  bool _isFlipDialogOpen = false;
  late final AnimationController _hintController;
  late final Animation<double> _hintOpacity;
  late final Animation<Offset> _hintSlide;

  @override
  void initState() {
    super.initState();
    _hintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _hintOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
    _hintSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: const Offset(0, -0.05),
    ).animate(
      CurvedAnimation(parent: _hintController, curve: Curves.easeInOut),
    );
  }

  void _setProgress(double value) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0.0, 1.0);
    });
  }

  void _logStep(String message) {
    final elapsed = _processStart != null
        ? DateTime.now().difference(_processStart!).inMilliseconds
        : 0;
    debugPrint("[OCR ${elapsed}ms] $message");
  }

  String _pickBestCIFromTexts(String? front, String? back, String current) {
    final texts = <String>[
      if (front != null) front,
      if (back != null) back,
      if (current.isNotEmpty) current,
    ];
    final regex = RegExp(r'(?:NO\.?|NRO\.?|N°|N)\s*\.?\s*:?[\s\-]*([0-9]{5,12})',
        caseSensitive: false);
    final regexDigits = RegExp(r'\b([0-9]{7,12})\b');

    String best = current;
    int bestScore = current.length >= 7 ? current.length : 0;

    for (final text in texts) {
      for (final m in regex.allMatches(text)) {
        final ci = m.group(1) ?? '';
        final score = ci.length;
        if (score > bestScore) {
          best = ci;
          bestScore = score;
        }
      }
      if (bestScore < 8) {
        for (final m in regexDigits.allMatches(text)) {
          final ci = m.group(1) ?? '';
          final score = ci.length;
          if (score > bestScore) {
            best = ci;
            bestScore = score;
          }
        }
      }
    }
    return best;
  }

  bool _isFamilyMemberLine(String line) {
    final upper = line.toUpperCase();
    return upper.contains('MADRE') ||
        upper.contains('PADRE') ||
        upper.contains('MADRES') ||
        upper.contains('PADRES');
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _processImageWithOCR() async {
    if (_frontImage == null || _backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor sube ambas fotos del carnet (frontal y posterior).',
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _progress = 0.05;
      _processStart = DateTime.now();
    });
    _logStep("Iniciando OCR");

    try {
      // Usar TextRecognizer con mejor configuración para OCR más preciso
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      String extractedCI = "";
      String extractedNombres = "";
      String extractedApellidos = "";
      String extractedFechaNacimiento = "";
      String extractedLugarNacimiento = "";
      String extractedProfesion = "";
      String extractedEstadoCivil = "";
      String extractedDomicilio = "";
      String extractedGrupoSanguineo = "";
      String extractedFechaEmision = "";
      String extractedFechaExpiracion = "";
      bool usedRemote = false;
      bool usedVision = false;
      String? rawVisionFrontText;
      String? rawVisionBackText;

      // Archivos preparados para OCR (preprocesados y persistentes)
      final frontOcrFile = await _prepareFileForOcr(_frontImage!);
      final backOcrFile = await _prepareFileForOcr(_backImage!);
      _setProgress(0.15);
      _logStep("Archivos preparados para OCR");

      // Intentar Google Vision primero si está habilitado
      if (CloudVisionOcrService.isEnabled) {
        try {
          _logStep("Llamando a Google Vision (frente y reverso)");
          rawVisionFrontText = await CloudVisionOcrService.extractText(frontOcrFile);
          rawVisionBackText = backOcrFile.path.isNotEmpty ? await CloudVisionOcrService.extractText(backOcrFile) : null;
          if (rawVisionFrontText != null) {
            final visionData = ServicioOcrInteligenteIdentidad.extractDataFromText(
              rawVisionFrontText!,
              rawVisionBackText,
            );
            extractedCI = _pickFirstNonEmpty([visionData['ci']?.toString() ?? '', extractedCI]);
            extractedNombres = _pickFirstNonEmpty([visionData['nombres']?.toString() ?? '', extractedNombres]);
            extractedApellidos = _pickFirstNonEmpty([visionData['apellidos']?.toString() ?? '', extractedApellidos]);
            extractedFechaEmision = _pickFirstNonEmpty(
              [visionData['fechaEmision']?.toString() ?? '', extractedFechaEmision],
            );
            extractedFechaExpiracion = _pickFirstNonEmpty(
              [visionData['fechaExpiracion']?.toString() ?? '', extractedFechaExpiracion],
            );
            extractedFechaNacimiento = _pickFirstNonEmpty(
              [visionData['fechaNacimiento']?.toString() ?? '', extractedFechaNacimiento],
            );
            extractedLugarNacimiento = _pickFirstNonEmpty(
              [visionData['lugarNacimiento']?.toString() ?? '', extractedLugarNacimiento],
            );
            extractedProfesion = _pickFirstNonEmpty(
              [visionData['profesion']?.toString() ?? '', extractedProfesion],
            );
            extractedEstadoCivil = _pickFirstNonEmpty(
              [visionData['estadoCivil']?.toString() ?? '', extractedEstadoCivil],
            );
            extractedDomicilio = _pickFirstNonEmpty(
              [visionData['domicilio']?.toString() ?? '', extractedDomicilio],
            );
            extractedGrupoSanguineo = _pickFirstNonEmpty(
              [visionData['grupoSanguineo']?.toString() ?? '', extractedGrupoSanguineo],
            );
            usedRemote = true; // Considerar Vision como OCR remoto principal siempre que responda
            usedVision = true;
            debugPrint("OCR Google Vision aplicado con éxito");
            _setProgress(0.45);
            _logStep("Vision OK, extrayendo campos");

            // Refinar con Gemini si está habilitado (mejor clasificación de campos).
            if (GeminiStructuredOcrService.isEnabled) {
              _logStep("Llamando a Gemini structuring");
              final gemini = await GeminiStructuredOcrService.structureOcr(
                frontText: rawVisionFrontText!,
                backText: rawVisionBackText,
              );
              if (gemini != null && gemini.isNotEmpty) {
                extractedCI = _pickFirstNonEmpty([gemini['ci'] ?? '', extractedCI]);
                extractedNombres = _pickFirstNonEmpty([gemini['nombres'] ?? '', extractedNombres]);
                extractedApellidos = _pickFirstNonEmpty([gemini['apellidos'] ?? '', extractedApellidos]);
                extractedFechaNacimiento =
                    _pickFirstNonEmpty([gemini['fechaNacimiento'] ?? '', extractedFechaNacimiento]);
                extractedFechaEmision = _pickFirstNonEmpty([gemini['fechaEmision'] ?? '', extractedFechaEmision]);
                extractedFechaExpiracion =
                    _pickFirstNonEmpty([gemini['fechaExpiracion'] ?? '', extractedFechaExpiracion]);
              }
              _setProgress(0.6);
            }
          }
        } catch (e) {
          debugPrint("Error Google Vision: $e");
        }
      }

      // Reintentar Vision con preprocesado agresivo si faltan campos clave
      if (CloudVisionOcrService.isEnabled &&
          (extractedCI.isEmpty ||
              extractedNombres.isEmpty ||
              extractedApellidos.isEmpty ||
              extractedFechaEmision.isEmpty ||
              extractedFechaExpiracion.isEmpty ||
              extractedFechaNacimiento.isEmpty)) {
        try {
          _logStep("Reintento Vision con preprocesado mejorado");
          final enhancedFront = await _preprocessForOcrEnhanced(frontOcrFile);
          final enhancedBack = await _preprocessForOcrEnhanced(backOcrFile);
          final visionFrontText = await CloudVisionOcrService.extractText(enhancedFront);
          final visionBackText = await CloudVisionOcrService.extractText(enhancedBack);
          if (visionFrontText != null) {
            rawVisionFrontText ??= visionFrontText;
            rawVisionBackText ??= visionBackText;
            final visionData = ServicioOcrInteligenteIdentidad.extractDataFromText(
              visionFrontText,
              visionBackText,
            );
            extractedCI = _pickFirstNonEmpty([extractedCI, visionData['ci']?.toString() ?? '']);
            extractedNombres = _pickFirstNonEmpty([extractedNombres, visionData['nombres']?.toString() ?? '']);
            extractedApellidos =
                _pickFirstNonEmpty([extractedApellidos, visionData['apellidos']?.toString() ?? '']);
            extractedFechaEmision =
                _pickFirstNonEmpty([extractedFechaEmision, visionData['fechaEmision']?.toString() ?? '']);
            extractedFechaExpiracion =
                _pickFirstNonEmpty([extractedFechaExpiracion, visionData['fechaExpiracion']?.toString() ?? '']);
            extractedFechaNacimiento =
                _pickFirstNonEmpty([extractedFechaNacimiento, visionData['fechaNacimiento']?.toString() ?? '']);
            extractedLugarNacimiento =
                _pickFirstNonEmpty([extractedLugarNacimiento, visionData['lugarNacimiento']?.toString() ?? '']);
            extractedProfesion =
                _pickFirstNonEmpty([extractedProfesion, visionData['profesion']?.toString() ?? '']);
            extractedEstadoCivil =
                _pickFirstNonEmpty([extractedEstadoCivil, visionData['estadoCivil']?.toString() ?? '']);
            extractedDomicilio =
                _pickFirstNonEmpty([extractedDomicilio, visionData['domicilio']?.toString() ?? '']);
            extractedGrupoSanguineo =
                _pickFirstNonEmpty([extractedGrupoSanguineo, visionData['grupoSanguineo']?.toString() ?? '']);
            usedRemote = true;
            usedVision = true;
            debugPrint("OCR Vision (mejorado) aplicado");
            _setProgress(0.75);
            _logStep("Vision mejorado OK, extrayendo campos");

            if (GeminiStructuredOcrService.isEnabled) {
              _logStep("Llamando a Gemini structuring (mejorado)");
              final gemini = await GeminiStructuredOcrService.structureOcr(
                frontText: visionFrontText,
                backText: visionBackText,
              );
              if (gemini != null && gemini.isNotEmpty) {
                extractedCI = _pickFirstNonEmpty([gemini['ci'] ?? '', extractedCI]);
                extractedNombres = _pickFirstNonEmpty([gemini['nombres'] ?? '', extractedNombres]);
                extractedApellidos = _pickFirstNonEmpty([gemini['apellidos'] ?? '', extractedApellidos]);
                extractedFechaNacimiento =
                    _pickFirstNonEmpty([gemini['fechaNacimiento'] ?? '', extractedFechaNacimiento]);
                extractedFechaEmision = _pickFirstNonEmpty([gemini['fechaEmision'] ?? '', extractedFechaEmision]);
                extractedFechaExpiracion =
                    _pickFirstNonEmpty([gemini['fechaExpiracion'] ?? '', extractedFechaExpiracion]);
              }
              _setProgress(0.85);
            }
          }
        } catch (e) {
          debugPrint("Error Vision (mejorado): $e");
        }
      }

      // ML Kit desactivado: no usamos OCR local, solo Vision/backend
      // Mantener backend remoto si en el futuro se requiere

      // Procesar imagen FRONTAL para extraer CI
      RecognizedText? frontRecognizedText;
      RecognizedText? backRecognizedText;
      String detectedModel = "desconocido";

      // Si Vision/back no entregaron datos suficientes, usar ML Kit local como refuerzo
      final needsLocalData = extractedNombres.isEmpty ||
          extractedApellidos.isEmpty ||
          extractedFechaNacimiento.isEmpty ||
          extractedFechaEmision.isEmpty ||
          extractedFechaExpiracion.isEmpty;

      if ((!usedRemote && !usedVision) || needsLocalData) {
        if (_frontImage != null) {
        debugPrint("=== PROCESANDO IMAGEN FRONTAL ===");
        debugPrint("Ruta de imagen: ${frontOcrFile.path}");

        // Crear InputImage con mejor configuración
        final frontInputImage = InputImage.fromFilePath(frontOcrFile.path);

        debugPrint("Iniciando OCR del frontal...");
        frontRecognizedText = await textRecognizer.processImage(
          frontInputImage,
        );

        debugPrint(
          "OCR completado. Texto reconocido (${frontRecognizedText.text.length} caracteres)",
        );
        extractedCI = _extractCIFromText(frontRecognizedText);
        detectedModel = _detectCIModel(frontRecognizedText);
        debugPrint("CI extraído del frontal: $extractedCI");
        debugPrint("Modelo detectado: $detectedModel");
        debugPrint("Texto frontal completo:\n${frontRecognizedText.text}");

        // Para modelo NUEVO: buscar nombres y apellidos por separado en el frontal
        if (detectedModel == "nuevo") {
          final nameData = _extractNamesAndSurnames(frontRecognizedText);
          extractedNombres = nameData['nombres'] ?? "";
          extractedApellidos = nameData['apellidos'] ?? "";
          debugPrint(
            "Nombres extraídos del frontal: $extractedNombres, Apellidos: $extractedApellidos",
          );

          // Si no se encontraron nombres en el frontal, puede ser que el OCR esté corrupto
          // o que sea un carnet antiguo mal detectado. Intentar detectar desde el reverso también.
          if (extractedNombres.isEmpty) {
            debugPrint(
              "⚠ No se encontraron nombres en el frontal. Verificando si es modelo antiguo...",
            );
          }
        }

        // Extraer fechas del frontal (tanto modelo nuevo como antiguo pueden tenerlas)
        extractedFechaEmision = _extractFechaEmision(
          frontRecognizedText,
          detectedModel,
        );
        extractedFechaExpiracion = _extractFechaExpiracion(
          frontRecognizedText,
          detectedModel,
        );
        if (extractedFechaEmision.isNotEmpty) {
          debugPrint("Fecha de emisión extraída: $extractedFechaEmision");
        }
        if (extractedFechaExpiracion.isNotEmpty) {
          debugPrint("Fecha de expiración extraída: $extractedFechaExpiracion");
        }
      }

      // Procesar imagen POSTERIOR para extraer nombre completo
      // Para modelo ANTIGUO: buscar en el reverso
      // Para modelo NUEVO: solo buscar si no se encontraron nombres en el frontal (fallback)
      if (_backImage != null && extractedNombres.isEmpty) {
        debugPrint("=== PROCESANDO REVERSO ===");
        debugPrint("Modelo detectado en frontal: $detectedModel");
        debugPrint("Nombres encontrados en frontal: '$extractedNombres'");
        debugPrint("Ruta de imagen reverso: ${backOcrFile.path}");

        // Crear InputImage con mejor configuración
        final backInputImage = InputImage.fromFilePath(backOcrFile.path);

        debugPrint("Iniciando OCR del reverso...");
        backRecognizedText = await textRecognizer.processImage(
          backInputImage,
        );

        debugPrint(
          "OCR reverso completado. Texto reconocido (${backRecognizedText.text.length} caracteres)",
        );

        debugPrint("Texto reverso completo:\n${backRecognizedText.text}");

        // Si el modelo no se detectó en el frontal, o si no se encontraron nombres,
        // intentar detectarlo desde el reverso
        String finalModel = detectedModel;
        final backText = backRecognizedText.text.toUpperCase();

        debugPrint(
          "Texto reverso (mayúsculas, primeros 500 caracteres):\n${backText.substring(0, backText.length.clamp(0, 500))}",
        );

        // Buscar indicadores del modelo antiguo en el reverso
        final hasPerteneceA = RegExp(
          r'PERTENECE\s+A|CERTIFICA|FOTOGRAF[ÍI]A\s+E\s+IMPRESI[ÓO]N|QUE\s+LA\s+FIRMA',
          caseSensitive: false,
        ).hasMatch(backText);

        // Buscar indicadores del modelo nuevo en el reverso
        final hasNewModelFields = RegExp(
          r'LUGAR|DOMICILIO|OCUPACION|OCUPACIÓN|ESTADO CIVIL',
          caseSensitive: false,
        ).hasMatch(backText);

        debugPrint("¿Tiene 'PERTENECE A' o 'CERTIFICA'? $hasPerteneceA");
        debugPrint("¿Tiene campos del modelo nuevo? $hasNewModelFields");

        // Si el modelo es "desconocido" o si no se encontraron nombres en el frontal,
        // usar el reverso para determinar el modelo
        if (detectedModel == "desconocido" ||
            (detectedModel == "nuevo" && extractedNombres.isEmpty)) {
          if (hasPerteneceA && !hasNewModelFields) {
            finalModel = "antiguo";
            debugPrint(
              "✓ Modelo ANTIGUO detectado desde el reverso (tiene 'PERTENECE A' o 'CERTIFICA')",
            );
          } else if (hasNewModelFields && !hasPerteneceA) {
            finalModel = "nuevo";
            debugPrint("✓ Modelo NUEVO confirmado desde el reverso");
          } else if (hasPerteneceA) {
            // Si tiene ambos indicadores, priorizar "PERTENECE A" (modelo antiguo)
            finalModel = "antiguo";
            debugPrint(
              "✓ Modelo ANTIGUO detectado desde el reverso (prioridad sobre campos nuevos)",
            );
          }
        }

        debugPrint("Modelo final después de analizar reverso: $finalModel");

        // Solo buscar nombres si es modelo antiguo
        if (finalModel == "antiguo") {
          debugPrint("Buscando nombre en el reverso (modelo antiguo)...");
          final nameFromBack = _extractNameFromText(
            backRecognizedText,
            isFrontal: false,
            model: finalModel,
          );
          if (nameFromBack.isNotEmpty) {
            // Para modelo antiguo, el nombre completo viene junto, intentar separarlo
            final words = nameFromBack.trim().split(RegExp(r'\s+'));
            if (words.length >= 2) {
              // Asumir que las primeras palabras son nombres y las últimas son apellidos
              final mitad = (words.length / 2).ceil();
              extractedNombres = words.sublist(0, mitad).join(' ');
              extractedApellidos = words.sublist(mitad).join(' ');
            } else {
              extractedNombres = nameFromBack;
            }
            debugPrint(
              "Nombre extraído del reverso (modelo antiguo): Nombres=$extractedNombres, Apellidos=$extractedApellidos",
            );
            debugPrint("Texto reverso completo:\n${backRecognizedText.text}");
          } else {
            debugPrint(
              " No se encontró nombre en el reverso del modelo antiguo",
            );
            debugPrint("Texto reverso completo:\n${backRecognizedText.text}");
          }
        } else if (finalModel == "nuevo") {
          debugPrint("Modelo nuevo detectado: NO buscar nombres en el reverso");
        }
      }
      }

      if (frontRecognizedText != null) {
        final smartData = ServicioOcrInteligenteIdentidad.extractData(
          frontRecognizedText,
          _backImage != null ? backRecognizedText : null,
        );
        extractedCI = _pickFirstNonEmpty([
          extractedCI,
          smartData['ci']?.toString() ?? '',
        ]);
        extractedNombres = _pickFirstNonEmpty([
          extractedNombres,
          smartData['nombres']?.toString() ?? '',
        ]);
        extractedApellidos = _pickFirstNonEmpty([
          extractedApellidos,
          smartData['apellidos']?.toString() ?? '',
        ]);
        extractedFechaNacimiento = _pickFirstNonEmpty([
          extractedFechaNacimiento,
          smartData['fechaNacimiento']?.toString() ?? '',
        ]);
        extractedLugarNacimiento = _pickFirstNonEmpty([
          extractedLugarNacimiento,
          smartData['lugarNacimiento']?.toString() ?? '',
        ]);
        extractedProfesion = _pickFirstNonEmpty([
          extractedProfesion,
          smartData['profesion']?.toString() ?? '',
        ]);
        extractedEstadoCivil = _pickFirstNonEmpty([
          extractedEstadoCivil,
          smartData['estadoCivil']?.toString() ?? '',
        ]);
        extractedDomicilio = _pickFirstNonEmpty([
          extractedDomicilio,
          smartData['domicilio']?.toString() ?? '',
        ]);
        extractedGrupoSanguineo = _pickFirstNonEmpty([
          extractedGrupoSanguineo,
          smartData['grupoSanguineo']?.toString() ?? '',
        ]);
        extractedFechaEmision = _pickFirstNonEmpty([
          extractedFechaEmision,
          smartData['fechaEmision']?.toString() ?? '',
        ]);
        extractedFechaExpiracion = _pickFirstNonEmpty([
          extractedFechaExpiracion,
          smartData['fechaExpiracion']?.toString() ?? '',
        ]);
      }

      await textRecognizer.close();

      // Ajuste final de CI: priorizar números largos detectados en el OCR de Vision
      extractedCI = _pickBestCIFromTexts(rawVisionFrontText, rawVisionBackText, extractedCI);

      if (mounted) {
        // Validación menos estricta - solo verificar que haya algo
        if (extractedCI.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se detectó un CI en el carnet frontal. Por favor intenta nuevamente.',
              ),
              backgroundColor: Colors.orangeAccent,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }

        // Validación básica del nombre (menos estricta)
        if (extractedNombres.isEmpty) {
          final modelMessage = detectedModel == "antiguo"
              ? "Asegúrate de que el reverso del carnet esté bien visible y que aparezca 'PERTENECE A:' seguido del nombre completo."
              : "Asegúrate de que el frontal del carnet esté bien visible y que aparezcan los campos 'NOMBRES' y 'APELLIDOS'.";

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No se detectó el nombre completo.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(modelMessage, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  const Text(
                    'Por favor intenta nuevamente con mejor iluminación.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              backgroundColor: Colors.orangeAccent,
              duration: const Duration(seconds: 5),
            ),
          );
          debugPrint(" Validación fallida: Nombre vacío");
          debugPrint("Modelo detectado: $detectedModel");
          debugPrint("CI extraído: $extractedCI");
          return;
        }

        // Si todo es válido, continuar al reconocimiento facial
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Datos validados correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _setProgress(1.0);
        _logStep("Validación completa, navegando a reconocimiento facial");

        // Cerrar cualquier diálogo o modal abierto antes de navegar
        if (mounted) {
          // Cerrar todos los diálogos
          while (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          // Esperar un momento para que se cierren los diálogos
          await Future.delayed(const Duration(milliseconds: 100));
        }

        // Usar siempre el CI detectado si existe; de lo contrario, el ingresado
        final finalCI = extractedCI.isNotEmpty
            ? extractedCI
            : (widget.initialCI ?? '');
        final ciFromInitial =
            widget.initialCI != null && widget.initialCI == finalCI;

        // Ir al siguiente paso: RECONOCIMIENTO FACIAL
        if (mounted) {
          context.push(
            '/face-recognition',
            extra: {
              'nombres': extractedNombres,
              'apellidos': extractedApellidos,
              'ci': finalCI, // Usar el CI inicial si existe
              'ciFromInitial': ciFromInitial
                  .toString(), // Indicar si viene del flujo inicial
              'fechaEmision': extractedFechaEmision,
              'fechaExpiracion': extractedFechaExpiracion,
              'fechaNacimiento': extractedFechaNacimiento,
              'lugarNacimiento': extractedLugarNacimiento,
              'profesion': extractedProfesion,
              'estadoCivil': extractedEstadoCivil,
              'domicilio': extractedDomicilio,
              'grupoSanguineo': extractedGrupoSanguineo,
            },
          );
        }
      }
    } catch (e) {
      debugPrint("Error en OCR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar las imágenes: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
      _logStep("Proceso finalizado");
    }
  }

  /// Detecta el modelo del CI (nuevo o antiguo) basándose en el texto reconocido
  String _detectCIModel(RecognizedText recognizedText) {
    final fullText = recognizedText.text.toUpperCase();
    debugPrint("=== DETECCIÓN DE MODELO ===");
    debugPrint(
      "Texto completo (primeros 500 caracteres):\n${fullText.substring(0, fullText.length.clamp(0, 500))}",
    );

    // Modelo NUEVO: tiene "CÉDULA DE IDENTIDAD" en el frontal
    final hasCedulaIdentidad = RegExp(
      r'C[ÉE]DULA\s+DE\s+IDENTIDAD',
      caseSensitive: false,
    ).hasMatch(fullText);
    if (hasCedulaIdentidad) {
      debugPrint("✓ Modelo detectado: NUEVO (tiene 'CÉDULA DE IDENTIDAD')");
      return "nuevo";
    }

    // Modelo ANTIGUO: tiene "N°", "Nº", "N.", "NUMERO", "N°", etc.
    // Buscar múltiples variaciones más flexibles
    final nPatterns = [
      RegExp(r'N\s*[°º]', caseSensitive: false), // N° o Nº
      RegExp(r'N\s*\.', caseSensitive: false), // N.
      RegExp(r'NUMERO\s*[°º]?', caseSensitive: false), // NUMERO o NUMERO°
      RegExp(r'N\s*:\s*\d', caseSensitive: false), // N: seguido de número
      RegExp(r'N\s+[°º]?\s*\d', caseSensitive: false), // N seguido de número
    ];

    bool hasN = false;
    for (final pattern in nPatterns) {
      if (pattern.hasMatch(fullText)) {
        hasN = true;
        debugPrint("✓ Patrón N encontrado: ${pattern.pattern}");
        break;
      }
    }

    // También buscar en bloques individuales (más preciso)
    if (!hasN) {
      for (final block in recognizedText.blocks) {
        final blockText = block.text.toUpperCase();
        for (final pattern in nPatterns) {
          if (pattern.hasMatch(blockText)) {
            hasN = true;
            debugPrint("✓ Patrón N encontrado en bloque: ${pattern.pattern}");
            debugPrint(
              "Bloque: ${blockText.substring(0, blockText.length.clamp(0, 100))}",
            );
            break;
          }
        }
        if (hasN) break;
      }
    }

    if (hasN) {
      // Verificar si hay indicios de códigos de barras/QR (patrones comunes)
      final hasBarcodePattern =
          RegExp(r'[|]{2,}|[█]{2,}|[▄]{2,}|[■]{2,}').hasMatch(fullText) ||
          fullText.contains('QR') ||
          fullText.contains('CODIGO') ||
          fullText.contains('CÓDIGO') ||
          fullText.contains('BARRA') ||
          fullText.contains('BARRAS');

      // También buscar patrones de códigos de barras en los bloques
      bool hasBarcodeInBlocks = false;
      for (final block in recognizedText.blocks) {
        final blockText = block.text;
        if (RegExp(r'[|]{3,}|[█]{3,}|[▄]{3,}|[■]{3,}').hasMatch(blockText) ||
            (blockText.length > 50 &&
                RegExp(r'[|█▄■]{10,}').hasMatch(blockText))) {
          hasBarcodeInBlocks = true;
          break;
        }
      }

      if (hasBarcodePattern || hasBarcodeInBlocks) {
        debugPrint(
          "✓ Modelo detectado: ANTIGUO (tiene 'N°' y códigos de barras/QR)",
        );
        return "antiguo";
      }
      // Si tiene N° pero no tiene "CÉDULA DE IDENTIDAD", probablemente es antiguo
      debugPrint(
        "✓ Modelo detectado: ANTIGUO (tiene 'N°' sin 'CÉDULA DE IDENTIDAD')",
      );
      return "antiguo";
    }

    // Por defecto, intentar detectar por presencia de nombres en el frontal
    // Si hay nombres/apellidos en el frontal, probablemente es modelo nuevo
    final hasNames = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);
    if (hasNames && !hasN) {
      debugPrint(
        "Modelo detectado: NUEVO (tiene nombres/apellidos en frontal)",
      );
      return "nuevo";
    }

    debugPrint("Modelo detectado: DESCONOCIDO");
    return "desconocido";
  }

  /// Extrae el CI del texto reconocido del frontal del carnet
  String _extractCIFromText(RecognizedText recognizedText) {
    // Patrones para CI en carnets bolivianos
    // Modelo NUEVO: "CÉDULA DE IDENTIDAD" seguido de números
    // Modelo ANTIGUO: "N°" o "Nº" seguido de números
    // También: "CI:", "C.I.:", "CEDULA:", etc.

    final List<String> candidateCIs = [];
    final fullText = recognizedText.text.toUpperCase();
    final model = _detectCIModel(recognizedText);

    debugPrint("=== BÚSQUEDA DE CI ===");
    debugPrint("Modelo detectado: $model");
    debugPrint("Texto completo reconocido:\n$fullText");

    // Buscar en bloques de texto (más confiable que líneas)
    for (final block in recognizedText.blocks) {
      final blockText = block.text;

      // PATRÓN 1: "CÉDULA DE IDENTIDAD" o "CEDULA DE IDENTIDAD" (Modelo nuevo) - MÁS PRIORITARIO
      // Buscar con diferentes variaciones de espacios y caracteres
      final nuevoModeloPatterns = [
        RegExp(
          r'C[ÉE]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})',
          caseSensitive: false,
        ),
        RegExp(
          r'C[ÉE]DULA\s+DE\s+IDENTIDAD\s+(\d{5,11})',
          caseSensitive: false,
        ),
        RegExp(
          r'C[ÉE]DULA\s+DE\s+IDENTIDAD\s*(\d{5,11})',
          caseSensitive: false,
        ),
        RegExp(
          r'C[ÉE]DULA\s+DE\s+IDENTIDAD[^\d]*(\d{5,11})',
          caseSensitive: false,
        ),
      ];
      //aqui se estable si es viable tener el ci
      for (final pattern in nuevoModeloPatterns) {
        final matchNuevo = pattern.firstMatch(blockText);
        if (matchNuevo != null) {
          final ci = matchNuevo.group(1)!.trim();
          if (_isValidCI(ci)) {
            debugPrint(
              "✓ CI detectado (modelo nuevo - CÉDULA DE IDENTIDAD): $ci",
            );
            return ci;
          }
          candidateCIs.add(ci);
        }
      }

      // PATRÓN 2: "N°" o "Nº" seguido de números (Modelo antiguo) - MÁS PRIORITARIO
      // Buscar con diferentes variaciones más flexibles
      final antiguoModeloPatterns = [
        RegExp(r'N[°º]\s*:?\s*(\d{5,11})', caseSensitive: false),
        RegExp(r'N[°º]\s+(\d{5,11})', caseSensitive: false),
        RegExp(r'N[°º]\s*(\d{5,11})', caseSensitive: false),
        RegExp(r'N\s*[°º]\s*:?\s*(\d{5,11})', caseSensitive: false),
        RegExp(
          r'N\s*\.\s*:?\s*(\d{5,11})',
          caseSensitive: false,
        ), // N. seguido de número
        RegExp(r'NUMERO\s*[°º]?\s*:?\s*(\d{5,11})', caseSensitive: false),
        RegExp(
          r'N\s*:\s*(\d{5,11})',
          caseSensitive: false,
        ), // N: seguido de número
        RegExp(
          r'N\s+(\d{5,11})',
          caseSensitive: false,
        ), // N seguido de número (sin símbolo)
        // También buscar "CÉDULA DE IDENTIDAD" en modelo antiguo (algunos tienen ambos)
        RegExp(
          r'C[ÉE]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})',
          caseSensitive: false,
        ),
      ];

      for (final pattern in antiguoModeloPatterns) {
        final matchAntiguo = pattern.firstMatch(blockText);
        if (matchAntiguo != null) {
          final ci = matchAntiguo.group(1)!.trim();
          if (_isValidCI(ci)) {
            debugPrint("✓ CI detectado (modelo antiguo - N°): $ci");
            debugPrint("Patrón usado: ${pattern.pattern}");
            debugPrint(
              "Bloque: ${blockText.substring(0, blockText.length.clamp(0, 150))}",
            );
            return ci;
          }
          candidateCIs.add(ci);
        }
      }

      // PATRÓN 3: "CI:", "C.I.:", "CEDULA:", "CÉDULA:" seguido de números
      final ciPattern3 = RegExp(
        r'(?:CI|C\.I\.|CEDULA|CÉDULA)[\s:]*(\d{5,11})',
        caseSensitive: false,
      );
      final match3 = ciPattern3.firstMatch(blockText);
      if (match3 != null) {
        final ci = match3.group(1)!.trim();
        if (_isValidCI(ci)) {
          debugPrint("CI detectado (patrón CI:): $ci");
          return ci;
        }
        candidateCIs.add(ci);
      }

      // PATRÓN 4: Buscar números de 5-11 dígitos cerca de palabras clave
      final keywordsPattern = RegExp(
        r'(?:CÉDULA|CEDULA|IDENTIDAD|CI|C\.I\.|N[°º])\s*:?\s*(\d{5,11})',
        caseSensitive: false,
      );
      final matches4 = keywordsPattern.allMatches(blockText);
      for (final match in matches4) {
        final ci = match.group(1)!;
        if (_isValidCI(ci) &&
            !_isLikelyDate(ci) &&
            !_isLikelyOtherNumber(blockText, match.start)) {
          candidateCIs.add(ci);
        }
      }

      // PATRÓN 5: Solo números de 5-11 dígitos (fallback)
      final ciPattern5 = RegExp(r'\b(\d{5,11})\b');
      final matches5 = ciPattern5.allMatches(blockText);
      for (final match in matches5) {
        final ci = match.group(1)!;
        // Validar que no sea parte de una fecha u otro número
        if (_isValidCI(ci) &&
            !_isLikelyDate(ci) &&
            !_isLikelyOtherNumber(blockText, match.start)) {
          candidateCIs.add(ci);
        }
      }
    }

    // Buscar también en el texto completo (por si las palabras están en líneas diferentes)
    // Buscar "CÉDULA DE IDENTIDAD" y luego el número más cercano
    final cedulaMatch = RegExp(
      r'C[ÉE]DULA\s+DE\s+IDENTIDAD',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (cedulaMatch != null) {
      // Buscar números después de "CÉDULA DE IDENTIDAD" (hasta 50 caracteres después)
      final afterCedula = fullText.substring(cedulaMatch.end);
      final numberAfterCedula = RegExp(
        r'(\d{5,11})',
      ).firstMatch(afterCedula.substring(0, afterCedula.length.clamp(0, 50)));
      if (numberAfterCedula != null) {
        final ci = numberAfterCedula.group(1)!.trim();
        if (_isValidCI(ci)) {
          debugPrint("✓ CI detectado (después de CÉDULA DE IDENTIDAD): $ci");
          return ci;
        }
        if (!candidateCIs.contains(ci)) {
          candidateCIs.add(ci);
        }
      }
    }

    // Buscar "N°", "Nº", "N.", "N:" y luego el número más cercano (más flexible)
    final nPatterns = [
      RegExp(r'N\s*[°º]', caseSensitive: false), // N° o Nº
      RegExp(r'N\s*\.', caseSensitive: false), // N.
      RegExp(r'N\s*:', caseSensitive: false), // N:
      RegExp(r'NUMERO\s*[°º]?', caseSensitive: false), // NUMERO o NUMERO°
    ];

    for (final pattern in nPatterns) {
      final nMatch = pattern.firstMatch(fullText);
      if (nMatch != null) {
        // Buscar números después de "N°" (hasta 50 caracteres después, más espacio)
        final afterN = fullText.substring(nMatch.end);
        final numberAfterN = RegExp(
          r'(\d{5,11})',
        ).firstMatch(afterN.substring(0, afterN.length.clamp(0, 50)));
        if (numberAfterN != null) {
          final ci = numberAfterN.group(1)!.trim();
          if (_isValidCI(ci)) {
            debugPrint("✓ CI detectado (después de N°): $ci");
            debugPrint("Patrón usado: ${pattern.pattern}");
            return ci;
          }
          if (!candidateCIs.contains(ci)) {
            candidateCIs.add(ci);
          }
        }
      }
    }

    // Fallback: buscar en líneas si no se encontró en bloques
    if (candidateCIs.isEmpty) {
      final lines = recognizedText.text.split('\n');
      for (var line in lines) {
        // Modelo nuevo - múltiples variaciones
        final nuevoPatterns = [
          RegExp(
            r'C[ÉE]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})',
            caseSensitive: false,
          ),
          RegExp(
            r'C[ÉE]DULA\s+DE\s+IDENTIDAD\s+(\d{5,11})',
            caseSensitive: false,
          ),
        ];

        for (final pattern in nuevoPatterns) {
          final matchNuevo = pattern.firstMatch(line);
          if (matchNuevo != null) {
            final ci = matchNuevo.group(1)!.trim();
            if (_isValidCI(ci)) {
              debugPrint("✓ CI detectado (línea - modelo nuevo): $ci");
              return ci;
            }
            candidateCIs.add(ci);
          }
        }

        // Modelo antiguo - múltiples variaciones
        final antiguoPatterns = [
          RegExp(r'N[°º]\s*:?\s*(\d{5,11})', caseSensitive: false),
          RegExp(r'N[°º]\s+(\d{5,11})', caseSensitive: false),
          RegExp(r'N\s*[°º]\s*(\d{5,11})', caseSensitive: false),
        ];

        for (final pattern in antiguoPatterns) {
          final matchAntiguo = pattern.firstMatch(line);
          if (matchAntiguo != null) {
            final ci = matchAntiguo.group(1)!.trim();
            if (_isValidCI(ci)) {
              debugPrint("✓ CI detectado (línea - modelo antiguo): $ci");
              return ci;
            }
            candidateCIs.add(ci);
          }
        }

        // Otros patrones
        final ciPattern = RegExp(
          r'(?:CI|C\.I\.|CEDULA|CÉDULA)[\s:]*(\d{5,11})',
          caseSensitive: false,
        );
        final match = ciPattern.firstMatch(line);
        if (match != null) {
          final ci = match.group(1)!.trim();
          if (_isValidCI(ci)) {
            return ci;
          }
          candidateCIs.add(ci);
        }

        // Buscar solo números largos
        final numberMatch = RegExp(r'\b(\d{5,11})\b').firstMatch(line);
        if (numberMatch != null) {
          final ci = numberMatch.group(1)!;
          if (_isValidCI(ci) && !_isLikelyDate(ci)) {
            candidateCIs.add(ci);
          }
        }
      }
    }

    // Retornar el primer CI válido encontrado
    for (final ci in candidateCIs) {
      if (_isValidCI(ci)) {
        debugPrint("CI detectado (fallback): $ci");
        return ci;
      }
    }

    debugPrint("No se encontró CI válido en el texto");
    return "";
  }

  /// Valida que un CI sea válido (validación menos estricta)
  bool _isValidCI(String ci) {
    // Validación básica: debe tener entre 5 y 11 dígitos (más flexible)
    if (ci.length < 5 || ci.length > 11) {
      return false;
    }

    // Debe contener solo dígitos
    if (!RegExp(r'^\d+$').hasMatch(ci)) {
      return false;
    }

    // No debe ser solo ceros
    if (int.tryParse(ci) == 0) {
      return false;
    }

    return true;
  }

  /// Extrae el nombre completo del texto reconocido
  /// Para modelo NUEVO: SOLO está en el frontal (reverso tiene lugar de nacimiento, domicilio, etc.)
  /// Para modelo ANTIGUO: SOLO está en el reverso (frontal solo tiene CI y códigos)
  String _extractNameFromText(
    RecognizedText recognizedText, {
    bool isFrontal = false,
    String model = "desconocido",
  }) {
    // Patrones comunes para nombres en carnets bolivianos
    // El nombre suele estar en líneas con solo letras y espacios
    // DEBE tener mínimo nombre y apellido (2 palabras)

    // Validar según modelo y posición
    if (isFrontal) {
      // En el frontal: solo modelo nuevo tiene nombres
      if (model != "nuevo") {
        debugPrint("No buscar nombres en frontal (modelo antiguo)");
        return "";
      }
      debugPrint("Buscando nombres en frontal (modelo nuevo)");
    } else {
      // En el reverso: solo modelo antiguo tiene nombres
      if (model != "antiguo") {
        debugPrint(
          "No buscar nombres en reverso (modelo nuevo - reverso tiene otros datos)",
        );
        return "";
      }
      debugPrint("Buscando nombres en reverso (modelo antiguo)");
    }

    // Buscar nombres cerca de palabras clave como "NOMBRES", "APELLIDOS"
    final fullText = recognizedText.text.toUpperCase();
    final hasNameKeywords = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);

    if (hasNameKeywords) {
      // Buscar líneas después de "NOMBRES" o "APELLIDOS"
      final lines = recognizedText.text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toUpperCase();
        if (RegExp(
          r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
          caseSensitive: false,
        ).hasMatch(line)) {
          // Buscar en las siguientes 2-3 líneas después de la palabra clave
          for (int j = i + 1; j < (i + 4).clamp(0, lines.length); j++) {
            final candidateLine = lines[j].trim();
            final words = _extractValidWords(candidateLine);

            // Validar que no sea un lugar o dirección
            if (words.length >= 2 &&
                !_isCommonNonNameWord(candidateLine) &&
                !_isLocationOrAddress(candidateLine)) {
              final namePattern = RegExp(
                r'^[A-Za-zÁÉÍÓÚÑÜáéíóúñü\s\.\-\x27]+$',
                caseSensitive: false,
              );
              if (namePattern.hasMatch(candidateLine) &&
                  candidateLine.length >= 6 &&
                  candidateLine.length <= 60) {
                debugPrint(
                  "Nombre encontrado cerca de palabra clave: $candidateLine",
                );
                return candidateLine;
              }
            }
          }
        }
      }
    }

    final List<String> candidateNames = [];

    // MODELO ANTIGUO (reverso): Buscar después de "PERTENECE A:"
    if (model == "antiguo" && !isFrontal) {
      final result = _extractNameFromOldModel(recognizedText);
      if (result.isNotEmpty) return result;
    }

    // Buscar en bloques de texto (método general)
    // Priorizar líneas que estén cerca de palabras clave
    for (final block in recognizedText.blocks) {
      final blockText = block.text.trim();
      final lines = blockText.split('\n');

      // Buscar líneas que estén cerca de "NOMBRES" o "APELLIDOS" (modelo nuevo)
      // o cerca de "A:" (modelo antiguo)
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final lineUpper = line.toUpperCase();

        // Si la línea contiene palabras clave, buscar en las siguientes líneas
        bool isNearKeyword = false;
        if (lineUpper.contains('NOMBRES') ||
            lineUpper.contains('APELLIDOS') ||
            (model == "antiguo" && lineUpper.contains('A:'))) {
          isNearKeyword = true;
        }

        // Si no está cerca de palabra clave, verificar líneas anteriores
        if (!isNearKeyword && i > 0) {
          final prevLine = lines[i - 1].toUpperCase();
          if (prevLine.contains('NOMBRES') ||
              prevLine.contains('APELLIDOS') ||
              (model == "antiguo" && prevLine.contains('A:'))) {
            isNearKeyword = true;
          }
        }

        // Filtrar líneas que parezcan nombres
        final namePattern = RegExp(
          r'^[A-Za-zÁÉÍÓÚÑÜáéíóúñü\s\.\-\x27]+$',
          caseSensitive: false,
        );
        final hasLetter = RegExp(r'[A-Za-zÁÉÍÓÚÑÜáéíóúñü]').hasMatch(line);

        // Excluir profesiones y campos del carnet
        final hasProfession =
            lineUpper.contains('ABG') ||
            lineUpper.contains('ABOGADO') ||
            lineUpper.contains('ING') ||
            lineUpper.contains('INGENIERO') ||
            lineUpper.contains('DR') ||
            lineUpper.contains('DOCTOR') ||
            lineUpper.contains('LIC') ||
            lineUpper.contains('LICENCIADO') ||
            lineUpper.contains('SERIE') ||
            lineUpper.contains('SECCIÓN') ||
            lineUpper.contains('SECCION') ||
            lineUpper.contains('FECHA') ||
            lineUpper.contains('BIO');

        if (line.length >= 6 &&
            line.length <= 60 &&
            namePattern.hasMatch(line) &&
            hasLetter &&
            !hasProfession) {
          // Excluir palabras comunes que no son nombres y lugares/direcciones
          if (!_isCommonNonNameWord(line) && !_isLocationOrAddress(line)) {
            // VALIDACIÓN: Debe tener al menos 2 palabras (nombre y apellido)
            final words = _extractValidWords(line);
            if (words.length >= 2) {
              // Priorizar líneas cerca de palabras clave
              if (isNearKeyword) {
                candidateNames.insert(0, line); // Insertar al inicio
              } else {
                candidateNames.add(line);
              }
            }
          }
        }
      }
    }

    // Si no se encontró en bloques, buscar en líneas directas
    if (candidateNames.isEmpty) {
      final lines = recognizedText.text.split('\n');
      final namePattern2 = RegExp(
        r'^[A-Za-zÁÉÍÓÚÑÜáéíóúñü\s\.\-\x27]+$',
        caseSensitive: false,
      );
      for (var line in lines) {
        line = line.trim();
        final hasLetter2 = RegExp(r'[A-Za-zÁÉÍÓÚÑÜáéíóúñü]').hasMatch(line);
        final isValidLength = line.length >= 6 && line.length <= 60;
        final matchesPattern = namePattern2.hasMatch(line);
        final isNotCommonWord = !_isCommonNonNameWord(line);

        if (isValidLength &&
            matchesPattern &&
            hasLetter2 &&
            isNotCommonWord &&
            !_isLocationOrAddress(line)) {
          final words = _extractValidWords(line);
          if (words.length >= 2) {
            candidateNames.add(line);
          }
        }
      }
    }

    // Seleccionar el mejor candidato
    if (candidateNames.isNotEmpty) {
      // Priorizar nombres con más palabras (nombre + apellido paterno + apellido materno)
      candidateNames.sort((a, b) {
        final wordsA = _extractValidWords(a);
        final wordsB = _extractValidWords(b);

        // Primero por cantidad de palabras (más es mejor)
        if (wordsB.length != wordsA.length) {
          return wordsB.length.compareTo(wordsA.length);
        }
        // Luego por longitud total
        return b.length.compareTo(a.length);
      });

      // Retornar el primero que tenga estructura válida
      return candidateNames.first.trim();
    }

    return "";
  }

  /// Extrae nombres y apellidos por separado del modelo NUEVO (frontal)
  Map<String, String> _extractNamesAndSurnames(RecognizedText recognizedText) {
    final lines = recognizedText.text.split('\n');
    String? nombres;
    String? apellidos;
    int? nombresLineIndex; // Guardar el índice donde se encontraron los nombres

    // PRIMERO: Buscar "NOMBRES" y la siguiente línea con texto válido
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();
      if (line == 'NOMBRES' ||
          (line.contains('NOMBRES') && !line.contains('APELLIDOS'))) {
        for (int j = i + 1; j < lines.length && j < i + 4; j++) {
          final next = lines[j].trim();
          if (next.isNotEmpty && _isValidNameLine(next)) {
            nombres = next;
            nombresLineIndex = j; // Guardar el índice de la línea de nombres
            debugPrint("✓ Nombres encontrados en línea $j: $nombres");
            break;
          }
        }
        if (nombres != null) break; // Si encontramos nombres, salir del bucle
      }
    }

    // SEGUNDO: Buscar "APELLIDOS" explícitamente
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim().toUpperCase();
      if (line == 'APELLIDOS' || line.contains('APELLIDOS')) {
        for (int j = i + 1; j < lines.length && j < i + 4; j++) {
          final next = lines[j].trim();
          if (next.isNotEmpty && _isValidNameLine(next)) {
            apellidos = next;
            debugPrint(
              "✓ Apellidos encontrados (explícito) en línea $j: $apellidos",
            );
            break;
          }
        }
        if (apellidos != null) break;
      }
    }

    // TERCERO: Si no encontramos "APELLIDOS" explícitamente pero sí encontramos nombres,
    // buscar en las líneas siguientes a donde están los nombres
    if (nombres != null && nombresLineIndex != null && apellidos == null) {
      debugPrint(
        "🔍 No se encontró 'APELLIDOS' explícito, buscando después de nombres...",
      );
      for (
        int j = nombresLineIndex + 1;
        j < lines.length && j < nombresLineIndex + 5;
        j++
      ) {
        final next = lines[j].trim();
        final nextUpper = next.toUpperCase();

        // Excluir líneas que sean campos del carnet
        if (next.isNotEmpty &&
            !nextUpper.contains('SERIE') &&
            !nextUpper.contains('SECCIÓN') &&
            !nextUpper.contains('SECCION') &&
            !nextUpper.contains('FECHA') &&
            !nextUpper.contains('BIO') &&
            !nextUpper.contains('PLURINAC') &&
            !nextUpper.contains('ESTADO') &&
            !nextUpper.contains('BOLIVIA') &&
            !_isCommonNonNameWord(next) &&
            !_isLocationOrAddress(next) &&
            !_containsProfession(next)) {
          // Verificar que parezca un apellido (solo letras, sin números)
          final namePattern = RegExp(
            r'^[A-Za-zÁÉÍÓÚÑÜáéíóúñü\s\.\-\x27]+$',
            caseSensitive: false,
          );

          if (namePattern.hasMatch(next) && next.length >= 3) {
            final words = _extractValidWords(next);
            if (words.isNotEmpty) {
              apellidos = next;
              debugPrint(
                "✓ Apellidos encontrados (después de nombres) en línea $j: $apellidos",
              );
              break;
            }
          }
        }
      }
    }

    // Limpiar y devolver nombres y apellidos por separado
    final nombresClean = nombres != null
        ? _removeProfessions(nombres.trim())
        : "";
    final apellidosClean = apellidos != null
        ? _removeProfessions(apellidos.trim())
        : "";

    // Validar que no contengan profesiones ni lugares
    if (nombresClean.isNotEmpty && _containsProfession(nombresClean)) {
      return {'nombres': '', 'apellidos': apellidosClean};
    }
    if (apellidosClean.isNotEmpty && _containsProfession(apellidosClean)) {
      return {'nombres': nombresClean, 'apellidos': ''};
    }
    // Filtrar nombres que son ruido ("ESTADO PLURINACIONAL", etc.)
    if (nombresClean.toUpperCase().contains('PLURINAC') ||
        nombresClean.toUpperCase().contains('ESTADO') ||
        nombresClean.toUpperCase().contains('BOLIVIA')) {
      return {'nombres': '', 'apellidos': apellidosClean};
    }
    if (apellidosClean.toUpperCase().contains('PLURINAC') ||
        apellidosClean.toUpperCase().contains('ESTADO') ||
        apellidosClean.toUpperCase().contains('BOLIVIA')) {
      return {'nombres': nombresClean, 'apellidos': ''};
    }

    debugPrint(
      "✓ RESULTADO FINAL - Nombres: '$nombresClean', Apellidos: '$apellidosClean'",
    );
    return {'nombres': nombresClean, 'apellidos': apellidosClean};
  }

  /// Extrae nombre del modelo ANTIGUO (reverso): busca después de "PERTENECE A:"
  /// El nombre completo (incluyendo apellidos) siempre está después de "PERTENECE A:"
  String _extractNameFromOldModel(RecognizedText recognizedText) {
    final fullText = recognizedText.text;
    final fullTextUpper = fullText.toUpperCase();
    final lines = fullText.split('\n');

    debugPrint("=== EXTRACCIÓN DE NOMBRE (MODELO ANTIGUO) ===");
    debugPrint("Total de líneas: ${lines.length}");
    debugPrint("Texto completo:\n$fullText");
    debugPrint("Texto completo (mayúsculas):\n$fullTextUpper");

    // Heurística previa: si ya hay una línea que parece nombre completo en mayúsculas (2-4 palabras)
    final strongNamePattern = RegExp(r'^[A-ZÁÉÍÓÚÜÑ]{2,}(?: [A-ZÁÉÍÓÚÜÑ]{2,}){1,3}$');
    for (final line in lines.map((e) => e.trim()).where((e) => e.isNotEmpty)) {
      if (strongNamePattern.hasMatch(line) &&
          !_isCarnetText(line) &&
          !_containsProfession(line) &&
          !_isLocationOrAddress(line) &&
          !_isFamilyMemberLine(line)) {
        debugPrint("✓ Nombre detectado por patrón fuerte: $line");
        return _removeProfessions(line);
      }
    }

    // VALIDACIÓN CRÍTICA: El nombre SIEMPRE está después de "PERTENECE A:"
    // Buscar primero "PERTENECE A:" en el texto completo (más confiable)
    final perteneceAPatterns = [
      RegExp(r'PERTENECE\s+A\s*:', caseSensitive: false),
      RegExp(r'PERTENECE\s+A\s+', caseSensitive: false),
      RegExp(
        r'FOTOGRAF[ÍI]A\s+E\s+IMPRESI[ÓO]N\s+PERTENECE\s+A\s*:',
        caseSensitive: false,
      ),
      RegExp(r'QUE\s+LA\s+FIRMA.*PERTENECE\s+A\s*:', caseSensitive: false),
      RegExp(r'CERTIFICA.*PERTENECE\s+A\s*:', caseSensitive: false),
    ];

    int perteneceAIndex = -1;

    for (final pattern in perteneceAPatterns) {
      final match = pattern.firstMatch(fullTextUpper);
      if (match != null) {
        perteneceAIndex = match.end;
        debugPrint(
          "✓ Encontrado 'PERTENECE A:' en posición $perteneceAIndex con patrón: ${pattern.pattern}",
        );
        break;
      }
    }

    if (perteneceAIndex == -1) {
      debugPrint(
        "❌ NO se encontró 'PERTENECE A:' en el texto. Buscando variaciones...",
      );
    } else {
      // Extraer el texto después de "PERTENECE A:"
      final textAfterPertenece = fullText.substring(perteneceAIndex).trim();
      debugPrint(
        "Texto después de 'PERTENECE A:' (primeros 200 caracteres):\n${textAfterPertenece.substring(0, textAfterPertenece.length.clamp(0, 200))}",
      );

      // Buscar el nombre en las primeras líneas después de "PERTENECE A:"
      // El nombre completo (nombres + apellidos) siempre está después de "PERTENECE A:"
      final linesAfterPertenece = textAfterPertenece.split('\n');

      // ESTRATEGIA: Buscar la primera línea que contenga principalmente letras y sea un nombre válido
      for (int i = 0; i < linesAfterPertenece.length && i < 8; i++) {
        final line = linesAfterPertenece[i].trim();
        if (line.isEmpty) continue;
        if (_isFamilyMemberLine(line)) continue;

        // Remover "A:" si está al inicio
        final cleanLine = line
            .replaceFirst(RegExp(r'^A\s*:\s*', caseSensitive: false), '')
            .trim();

        if (cleanLine.isEmpty) continue;

        debugPrint(
          "Analizando línea $i después de 'PERTENECE A:': '$cleanLine'",
        );

        // Clasificar palabras: verificar que sean principalmente letras
        final words = cleanLine.split(RegExp(r'\s+'));
        final validWords = words.where((w) {
          final cleaned = w.replaceAll(RegExp(r'[\.\-\x27]'), '');
          return cleaned.length >= 2 &&
              RegExp(r'^[A-Za-zÁÉÍÓÚÑÜáéíóúñü]+$').hasMatch(cleaned);
        }).toList();

        debugPrint(
          "Palabras válidas encontradas: ${validWords.length} - $validWords",
        );

        // Debe tener al menos 2 palabras válidas (nombre + apellido mínimo)
        if (validWords.length >= 2 && validWords.length <= 8) {
          // Verificar que la línea tenga principalmente letras (no números ni caracteres especiales)
          final letterCount = cleanLine
              .split('')
              .where((c) => RegExp(r'[A-Za-zÁÉÍÓÚÑÜáéíóúñü]').hasMatch(c))
              .length;
          final totalChars = cleanLine.replaceAll(RegExp(r'\s'), '').length;
          final letterRatio = totalChars > 0 ? letterCount / totalChars : 0;

          debugPrint(
            "Ratio de letras: $letterRatio (letras: $letterCount, total: $totalChars)",
          );

          if (letterRatio >= 0.8 &&
              cleanLine.length >= 6 &&
              cleanLine.length <= 100) {
            final clean = _removeProfessions(cleanLine);

            // Validar que NO sea texto del carnet
            if (!_isCarnetText(clean) &&
                !_isLocationOrAddress(clean) &&
                !_containsProfession(clean)) {
              // Verificar que las palabras no sean todas muy cortas (evitar "ar cer" etc.)
              final avgWordLength =
                  validWords.map((w) => w.length).reduce((a, b) => a + b) /
                  validWords.length;

              if (avgWordLength >= 3.0) {
                debugPrint(
                  "✓ Nombre válido encontrado después de 'PERTENECE A:' (línea $i): $clean",
                );
                debugPrint(
                  "Palabras: $validWords, Longitud promedio: $avgWordLength",
                );
                return clean;
              } else {
                debugPrint(
                  "⚠ Rechazado: palabras muy cortas (promedio: $avgWordLength)",
                );
              }
            } else {
              debugPrint(
                "⚠ Línea rechazada (texto del carnet/lugar/profesión): $clean",
              );
            }
          } else {
            debugPrint(
              "⚠ Rechazado: ratio de letras insuficiente ($letterRatio) o longitud inválida",
            );
          }
        } else {
          debugPrint(
            "⚠ Rechazado: número de palabras inválido (${validWords.length})",
          );
        }
      }
    }

    // ESTRATEGIA 1: Buscar "pertenece" o "PERTENECE" y luego "A:" en líneas siguientes
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineUpper = line.toUpperCase();

      // Buscar líneas que contengan "pertenece" o "CERTIFICA" o "fotografía e impresión"
      final perteneceKeywords = [
        'PERTENECE',
        'PERtenece',
        'pertenece',
        'CERTIFICA',
        'FOTOGRAFÍA E IMPRESIÓN',
        'FOTOGRAFIA E IMPRESION',
        'IMPRESIÓN PERTENECE',
        'IMPRESION PERTENECE',
      ];

      bool foundPerteneceKeyword = false;
      for (final keyword in perteneceKeywords) {
        if (lineUpper.contains(keyword.toUpperCase())) {
          foundPerteneceKeyword = true;
          debugPrint(
            "✓ Palabra clave '$keyword' encontrada en línea $i: $line",
          );
          break;
        }
      }

      if (foundPerteneceKeyword) {
        // Buscar "A:" en las siguientes 8 líneas (más espacio para OCR corrupto)
        for (int j = i + 1; j < lines.length && j < i + 9; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          final fechaNext = _findDateInLine(nextLine);
          if (fechaNext.isNotEmpty) {
            debugPrint(
              " Fecha encontrada en l?nea $j (despu?s de $i): $fechaNext",
            );
            return fechaNext;
          }


          final nextLineUpper = nextLine.toUpperCase();

          // Buscar "A:" seguido de texto (más flexible)
          if (nextLineUpper.contains('A:') ||
              nextLineUpper.startsWith('A') ||
              RegExp(
                r'^A\s*:\s*[A-Z]',
                caseSensitive: false,
              ).hasMatch(nextLineUpper)) {
            // Extraer el nombre después de "A:"
            final aMatch = RegExp(
              r'A\s*:\s*(.+)',
              caseSensitive: false,
            ).firstMatch(nextLine);
            if (aMatch != null) {
              final name = aMatch.group(1)?.trim();
              if (name != null && name.isNotEmpty && name.length >= 6) {
                final clean = _removeProfessions(name);
                // Validación más flexible: solo verificar que tenga al menos 2 palabras
                final words = clean
                    .split(RegExp(r'\s+'))
                    .where((w) => w.length > 1)
                    .toList();
                if (words.length >= 2 &&
                    !_isLocationOrAddress(clean) &&
                    !_containsProfession(clean)) {
                  debugPrint(
                    "✓ Nombre encontrado después de 'A:' (línea $j): $clean",
                  );
                  return clean;
                }
              }
            }

            // Si "A:" está solo o casi solo, buscar en las siguientes 2 líneas
            if (nextLineUpper.trim() == 'A:' ||
                nextLineUpper.trim().startsWith('A:') ||
                (nextLineUpper.length <= 3 && nextLineUpper.contains('A'))) {
              for (int k = j + 1; k < lines.length && k < j + 3; k++) {
                final nameLine = lines[k].trim();
                if (nameLine.isEmpty) continue;

                final clean = _removeProfessions(nameLine);
                final words = clean
                    .split(RegExp(r'\s+'))
                    .where((w) => w.length > 1)
                    .toList();

                // Validación más flexible
                if (words.length >= 2 &&
                    nameLine.length >= 6 &&
                    nameLine.length <= 80 &&
                    !_isLocationOrAddress(clean) &&
                    !_containsProfession(clean) &&
                    !_isCarnetText(clean)) {
                  debugPrint(
                    "✓ Nombre encontrado después de 'A:' (línea $k): $clean",
                  );
                  return clean;
                }
              }
            }
          }
        }

        // ESTRATEGIA ALTERNATIVA: Si encontramos "pertenece" pero no "A:", buscar nombres en las siguientes líneas
        debugPrint(
          "Buscando nombre después de 'pertenece' sin 'A:' explícito...",
        );
        for (int j = i + 1; j < lines.length && j < i + 6; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          final fechaNext = _findDateInLine(nextLine);
          if (fechaNext.isNotEmpty) {
            debugPrint(
              " Fecha encontrada en l?nea $j (despu?s de $i): $fechaNext",
            );
            return fechaNext;
          }


          // Buscar líneas que parezcan nombres (mínimo 2 palabras, solo letras y espacios)
          final namePattern = RegExp(
            r'^[A-Za-zÁÉÍÓÚÑÜáéíóúñü\s\.\-\x27]+$',
            caseSensitive: false,
          );
          if (namePattern.hasMatch(nextLine) &&
              nextLine.length >= 6 &&
              nextLine.length <= 80) {
            final words = nextLine
                .split(RegExp(r'\s+'))
                .where((w) => w.length > 1)
                .toList();
            if (words.length >= 2 && words.length <= 6) {
              final clean = _removeProfessions(nextLine);
              // Validación más flexible: verificar que no sea un lugar, profesión o texto del carnet
              if (!_isLocationOrAddress(clean) &&
                  !_containsProfession(clean) &&
                  !_isCarnetText(clean) &&
                  !_isFamilyMemberLine(clean)) {
                // Excluir líneas que son claramente campos del carnet
                final lineUpper = nextLine.toUpperCase();
                if (!lineUpper.contains('SERIE') &&
                    !lineUpper.contains('SECCI') &&
                    !lineUpper.contains('FECHA') &&
                    !lineUpper.contains('BIO') &&
                    !lineUpper.contains('NACIDO') &&
                    !lineUpper.contains('ESTADO CIVIL') &&
                    !lineUpper.contains('PROFESION') &&
                    !lineUpper.contains('OCUPACION') &&
                    !lineUpper.contains('DOMICILIO') &&
                    !lineUpper.contains('IMPRES') &&
                    !lineUpper.contains('FOTOGRAF') &&
                    !lineUpper.contains('PERTENECE')) {
                  debugPrint(
                    "✓ Nombre encontrado después de 'pertenece' (línea $j): $clean",
                  );
                  return clean;
                }
              }
            }
          }
        }
      }
    }

    // ESTRATEGIA 2: Buscar "A:" directamente seguido de nombre
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineUpper = line.toUpperCase();

      // Buscar "PERTENECE A:" o variaciones en la misma línea
      final pertenecePatterns = [
        RegExp(r'PERTENECE\s+A\s*:', caseSensitive: false),
        RegExp(r'PERTENECE\s+A\s+', caseSensitive: false),
        RegExp(
          r'FOTOGRAF[ÍI]A\s+E\s+IMPRESI[ÓO]N\s+PERTENECE\s+A\s*:',
          caseSensitive: false,
        ),
        RegExp(
          r'FOTOGRAF[ÍI]A\s+E\s+IMPRESI[ÓO]N\s+PERTENECE\s+A\s+',
          caseSensitive: false,
        ),
        RegExp(r'PERTENECE\s+A', caseSensitive: false),
        RegExp(
          r'A\s*:\s*[A-Z]',
          caseSensitive: false,
        ), // A: seguido de letra mayúscula
      ];

      bool foundPertenece = false;
      for (final pattern in pertenecePatterns) {
        if (pattern.hasMatch(lineUpper)) {
          foundPertenece = true;
          debugPrint(
            "✓ Patrón 'PERTENECE A' encontrado en línea $i: ${pattern.pattern}",
          );
          debugPrint("Línea: $line");
          break;
        }
      }

      if (foundPertenece ||
          lineUpper.contains('PERTENECE') ||
          (lineUpper.contains('A:') &&
              lineUpper.contains(RegExp(r'[A-Z]{3,}')))) {
        // Buscar en la misma línea después de "PERTENECE A:"
        final matchPatterns = [
          RegExp(
            r'(?:FOTOGRAF[ÍI]A\s+E\s+IMPRESI[ÓO]N\s+)?PERTENECE\s+A\s*:\s*(.+)',
            caseSensitive: false,
          ),
          RegExp(r'PERTENECE\s+A\s*:\s*(.+)', caseSensitive: false),
          RegExp(r'PERTENECE\s+A\s+(.+)', caseSensitive: false),
          RegExp(r'A\s*:\s*(.+)', caseSensitive: false),
        ];

        for (final pattern in matchPatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final name = match.group(1)?.trim();
            if (name != null && name.isNotEmpty) {
              final clean = _removeProfessions(name);
              if (_isValidName(clean) &&
                  !_containsProfession(clean) &&
                  !_isLocationOrAddress(clean)) {
                debugPrint(
                  "✓ Nombre encontrado (PERTENECE A - misma línea): $clean",
                );
                return clean;
              }
            }
          }
        }

        // Buscar en las siguientes 5 líneas (más espacio)
        for (int j = i + 1; j < lines.length && j < i + 6; j++) {
          final next = lines[j].trim();
          if (next.isNotEmpty && _isValidNameLine(next)) {
            final clean = _removeProfessions(next);
            if (_isValidName(clean) &&
                !_containsProfession(clean) &&
                !_isLocationOrAddress(clean) &&
                !_isCarnetText(clean)) {
              debugPrint("✓ Nombre encontrado (siguiente línea $j): $clean");
              return clean;
            }
          }
        }
      }
    }

    // Búsqueda alternativa: buscar cualquier línea que parezca un nombre completo
    // (mínimo 2 palabras, solo letras, no campos del carnet)
    debugPrint("Búsqueda alternativa: líneas que parezcan nombres...");
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Buscar líneas que tengan principalmente letras
      final letterCount = line
          .split('')
          .where((c) => RegExp(r'[A-Za-zÁÉÍÓÚÑÜáéíóúñü]').hasMatch(c))
          .length;
      final totalChars = line.replaceAll(RegExp(r'\s'), '').length;

      if (totalChars > 0 && (letterCount / totalChars) > 0.7) {
        // Al menos 70% letras
        final words = line
            .split(RegExp(r'\s+'))
            .where((w) => w.length > 1)
            .toList();
        if (words.length >= 2 &&
            words.length <= 6 &&
            line.length >= 6 &&
            line.length <= 80) {
          final clean = _removeProfessions(line);
          // Validación más flexible: solo verificar que no sea un lugar, profesión o texto del carnet
          if (!_isLocationOrAddress(clean) &&
              !_containsProfession(clean) &&
              !_isCarnetText(clean)) {
            // Excluir líneas que son claramente campos del carnet
            final lineUpper = line.toUpperCase();
            if (!lineUpper.contains('SERIE') &&
                !lineUpper.contains('SECCI') &&
                !lineUpper.contains('FECHA') &&
                !lineUpper.contains('BIO') &&
                !lineUpper.contains('NACIDO') &&
                !lineUpper.contains('ESTADO CIVIL') &&
                !lineUpper.contains('PROFESION') &&
                !lineUpper.contains('OCUPACION') &&
                !lineUpper.contains('DOMICILIO')) {
              debugPrint(
                "✓ Nombre encontrado (búsqueda alternativa línea $i): $clean",
              );
              return clean;
            }
          }
        }
      }
    }

    debugPrint("❌ No se encontró nombre en el reverso");
    return "";
  }

  /// Verifica si una línea es válida para contener un nombre (no campos del carnet)
  bool _isValidNameLine(String line) {
    final upper = line.toUpperCase();
    // Excluir campos del carnet y profesiones
    final invalidKeywords = [
      'SERIE',
      'SECCIÓN',
      'SECCION',
      'FECHA',
      'BIO',
      'NOMBRES',
      'APELLIDOS',
      'ABG',
      'ABOGADO',
      'ING',
      'INGENIERO',
      'DR',
      'DOCTOR',
      'LIC',
      'LICENCIADO',
      'EN:',
      'PROFESION',
      'OCUPACION',
      'DOMICILIO',
      'ESTADO CIVIL',
    ];

    for (final keyword in invalidKeywords) {
      if (upper.contains(keyword)) return false;
    }

    return !_isCommonNonNameWord(line) && !_isLocationOrAddress(line);
  }

  /// Extrae la fecha de emisión del texto reconocido
  String _extractFechaEmision(RecognizedText recognizedText, String model) {
    final fullText = recognizedText.text;
    final lines = fullText.split('\n');

    debugPrint(" Buscando FECHA DE EMISIÓN en ${lines.length} líneas");

    // Patrones más amplios para buscar fecha de emisión
    final emisionKeywords = [
      'FECHA DE EMISIÓN',
      'FECHA EMISIÓN',
      'FECHA DE EMISION',
      'FECHA EMISION',
      'EMISIÓN',
      'EMISION',
      'EMITIDO',
      'EXPEDIDO',
      'EXPEDICIÓN',
      'EXPEDICION',
    ];

    // Buscar en cada línea
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineUpper = line.toUpperCase();

      // Verificar si la línea contiene alguna palabra clave
      bool hasKeyword = false;
      for (final keyword in emisionKeywords) {
        if (lineUpper.contains(keyword)) {
          hasKeyword = true;
          debugPrint(" Palabra clave '$keyword' encontrada en línea $i: $line");
          break;
        }
      }

      if (hasKeyword) {

        final fechaLinea = _findDateInLine(line);
        if (fechaLinea.isNotEmpty) {
          debugPrint(" Fecha encontrada en l?nea $i: $fechaLinea");
          return fechaLinea;
        }
        // Buscar fecha en la misma línea
        // Patrones de fecha: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD MM YYYY
        final datePatterns = [
          RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'), // DD/MM/YYYY o DD-MM-YYYY
          RegExp(r'(\d{1,2}\.\d{1,2}\.\d{2,4})'), // DD.MM.YYYY
          RegExp(r'(\d{1,2}\s+\d{1,2}\s+\d{2,4})'), // DD MM YYYY
        ];

        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final fecha = match.group(1)!.trim();
            // Validar que parezca una fecha (tiene formato de fecha)
            if (fecha.length < 6) continue;
            debugPrint(" Fecha de emisión encontrada en línea $i: $fecha");
            return fecha;
          }
        }

        // Si no se encontró en la misma línea, buscar en las siguientes (hasta 5 líneas)
        for (int j = i + 1; j < lines.length && j < i + 6; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          // Evitar líneas que sean claramente otra cosa
          final nextUpper = nextLine.toUpperCase();
          if (nextUpper.contains('FECHA DE EXPIR') ||
              nextUpper.contains('VALIDA HASTA') ||
              nextUpper.contains('NOMBRES') ||
              nextUpper.contains('APELLIDOS') ||
              nextUpper.contains('CI') ||
              nextUpper.contains('CEDULA')) {
            continue;
          }

          for (final pattern in datePatterns) {
            final match = pattern.firstMatch(nextLine);
            if (match != null) {
              final fecha = match.group(1)!.trim();
              if (fecha.length < 6) continue;
              debugPrint(
                " Fecha de emisión encontrada en línea $j (después de $i): $fecha",
              );
              return fecha;
            }
          }
        }
      }
    }

    // Búsqueda alternativa: buscar cualquier fecha cerca de palabras relacionadas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineUpper = line.toUpperCase();

      if (lineUpper.contains('EMISI') ||
          lineUpper.contains('EMITIDO') ||
          lineUpper.contains('EXPEDIDO') ||
          lineUpper.contains('EXPEDICI')) {
        // Buscar fecha en un rango más amplio (línea actual y siguientes 5)
        for (int j = i; j < lines.length && j < i + 6; j++) {
          final searchLine = lines[j].trim();
          if (searchLine.isEmpty) continue;

          final dateMatch = RegExp(
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
          ).firstMatch(searchLine);
          if (dateMatch != null) {
            final fecha = dateMatch.group(1)!.trim();
            if (fecha.length < 6) continue;
            debugPrint(
              "✅ Fecha de emisión encontrada (búsqueda alternativa línea $j): $fecha",
            );
            return fecha;
          }
        }
      }
    }
    // Si no se encontró ninguna fecha, retornar vacío de retronar un valor vacio
    debugPrint(" No se encontró fecha de emisión");
    return "";
  }

  /// Extrae la fecha de expiración del texto reconocido
  String _extractFechaExpiracion(RecognizedText recognizedText, String model) {
    final fullText = recognizedText.text;
    final lines = fullText.split('\n');

    debugPrint(" Buscando FECHA DE EXPIRACIÓN en ${lines.length} líneas");

    // Patrones más amplios para buscar fecha de expiración
    final expiracionKeywords = [
      'FECHA DE EXPIRACIÓN',
      'FECHA EXPIRACIÓN',
      'FECHA DE EXPIRACION',
      'FECHA EXPIRACION',
      'EXPIRACIÓN',
      'EXPIRACION',
      'VÁLIDA HASTA',
      'VALIDA HASTA',
      'VIGENCIA',
      'VENCE',
      'VENCIMIENTO',
      'EXPIRA',
      'EXPIRA EL',
      'EXPIRATION',
    ];

    // Buscar en cada línea
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final lineUpper = line.toUpperCase();

      // Verificar si la línea contiene alguna palabra clave
      bool hasKeyword = false;
      for (final keyword in expiracionKeywords) {
        if (lineUpper.contains(keyword)) {
          hasKeyword = true;
          debugPrint(
            "🔍 Palabra clave '$keyword' encontrada en línea $i: $line",
          );
          break;
        }
      }

      if (hasKeyword) {

        final fechaLinea = _findDateInLine(line);
        if (fechaLinea.isNotEmpty) {
          debugPrint(" Fecha encontrada en l?nea $i: $fechaLinea");
          return fechaLinea;
        }
        // Buscar fecha en la misma línea
        // Patrones de fecha: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, DD MM YYYY
        final datePatterns = [
          RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'), // DD/MM/YYYY o DD-MM-YYYY
          RegExp(r'(\d{1,2}\.\d{1,2}\.\d{2,4})'), // DD.MM.YYYY
          RegExp(r'(\d{1,2}\s+\d{1,2}\s+\d{2,4})'), // DD MM YYYY
        ];

        for (final pattern in datePatterns) {
          final match = pattern.firstMatch(line);
          if (match != null) {
            final fecha = match.group(1)!.trim();
            // Validar que parezca una fecha (tiene formato de fecha)
            if (fecha.length < 6) continue;
            debugPrint(" Fecha de expiración encontrada en línea $i: $fecha");
            return fecha;
          }
        }

        // Si no se encontró en la misma línea, buscar en las siguientes (hasta 5 líneas)
        for (int j = i + 1; j < lines.length && j < i + 6; j++) {
          final nextLine = lines[j].trim();
          if (nextLine.isEmpty) continue;

          // Evitar líneas que sean claramente otra cosa
          final nextUpper = nextLine.toUpperCase();
          if (nextUpper.contains('FECHA DE EMISI') ||
              nextUpper.contains('EMITIDO') ||
              nextUpper.contains('NOMBRES') ||
              nextUpper.contains('APELLIDOS') ||
              nextUpper.contains('CI') ||
              nextUpper.contains('CEDULA')) {
            continue;
          }

          for (final pattern in datePatterns) {
            final match = pattern.firstMatch(nextLine);
            if (match != null) {
              final fecha = match.group(1)!.trim();
              if (fecha.length < 6) continue;
              debugPrint(
                " Fecha de expiración encontrada en línea $j (después de $i): $fecha",
              );
              return fecha;
            }
          }
        }
      }
    }

    // Búsqueda alternativa: buscar cualquier fecha cerca de palabras relacionadas
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      final lineUpper = line.toUpperCase();

      if (lineUpper.contains('EXPIRACI') ||
          lineUpper.contains('VALIDA HASTA') ||
          lineUpper.contains('VIGENCIA') ||
          lineUpper.contains('VENCE') ||
          lineUpper.contains('VENCIMIENTO') ||
          lineUpper.contains('EXPIRA') ||
          lineUpper.contains('EXPIRA EL') ||
          lineUpper.contains('EXPIRATION')) {
        // Buscar fecha en un rango más amplio (línea actual y siguientes 5)
        for (int j = i; j < lines.length && j < i + 6; j++) {
          final searchLine = lines[j].trim();
          if (searchLine.isEmpty) continue;

          final dateMatch = RegExp(
            r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})',
          ).firstMatch(searchLine);
          if (dateMatch != null) {
            final fecha = dateMatch.group(1)!.trim();
            if (fecha.length < 6) continue;
            debugPrint(
              " Fecha de expiración encontrada (búsqueda alternativa línea $j): $fecha",
            );
            return fecha;
          }
        }
      }
    }

    debugPrint(" No se encontró fecha de expiración");
    return "";
  }

  /// Extrae palabras válidas de una línea (filtra palabras muy cortas y clasifica)
  List<String> _extractValidWords(String text) {
    final words = text.split(RegExp(r'\s+'));
    return words.where((word) {
      // Remover puntuación y caracteres especiales para validar
      final cleanWord = word.replaceAll(RegExp(r'[\.\-\x27]'), '').trim();

      // Debe tener al menos 2 caracteres
      if (cleanWord.length < 2) return false;

      // Debe contener principalmente letras (al menos 70% letras)
      final letterCount = cleanWord
          .split('')
          .where((c) => RegExp(r'[A-Za-zÁÉÍÓÚÑÜáéíóúñü]').hasMatch(c))
          .length;
      final letterRatio = cleanWord.isNotEmpty
          ? letterCount / cleanWord.length
          : 0;
      //clasificacion debe ser principal letras y no ser solo numeritos
      // Clasificar: debe ser principalmente letras y no ser solo números
      return letterRatio >= 0.7 && !RegExp(r'^\d+$').hasMatch(cleanWord);
    }).toList();
  }

  /// Remueve profesiones y títulos del texto
  String _removeProfessions(String text) {
    final professions = [
      'ABG',
      'ABOGADO',
      'ABOGADA',
      'ING',
      'INGENIERO',
      'INGENIERA',
      'DR',
      'DOCTOR',
      'DOCTORA',
      'LIC',
      'LICENCIADO',
      'LICENCIADA',
      'SR',
      'SEÑOR',
      'SRA',
      'SEÑORA',
      'SRTA',
      'SEÑORITA',
      'MSC',
      'MASTER',
      'MAGISTER',
      'PH.D',
      'PHD',
    ];

    String cleaned = text.trim();

    for (final profession in professions) {
      // Remover profesión si está al inicio
      final startPattern = RegExp('^$profession\\s+', caseSensitive: false);
      if (startPattern.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(startPattern, '').trim();
      }

      // Remover profesión si está al final
      final endPattern = RegExp('\\s+$profession\$', caseSensitive: false);
      if (endPattern.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(endPattern, '').trim();
      }

      // Remover si está en medio con espacios (solo si no es parte de una palabra)
      final middlePattern = RegExp('\\s+$profession\\s+', caseSensitive: false);
      cleaned = cleaned.replaceAll(middlePattern, ' ').trim();

      // Remover si está seguido de punto (ej: "DR.")
      final dotPattern = RegExp('\\s+$profession\\.', caseSensitive: false);
      cleaned = cleaned.replaceAll(dotPattern, '').trim();
    }

    // Limpiar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    return cleaned;
  }

  /// Valida si un texto es un nombre válido (no fragmentos como "ar cer")
  bool _isValidName(String text) {
    final words = _extractValidWords(text);

    // Debe tener al menos 2 palabras
    if (words.length < 2) {
      return false;
    }

    // Cada palabra debe tener al menos 3 caracteres (evitar "ar", "cer", etc.)
    for (final word in words) {
      if (word.length < 3) {
        return false;
      }
    }

    // El nombre completo debe tener al menos 8 caracteres
    if (text.trim().length < 8) {
      return false;
    }

    // No debe contener solo letras muy cortas repetidas
    final shortWords = words.where((w) => w.length < 3).length;
    if (shortWords > 0) {
      return false;
    }

    return true;
  }

  /// Verifica si el texto contiene profesiones
  bool _containsProfession(String text) {
    final upperText = text.toUpperCase();
    final professions = [
      'ABG',
      'ABOGADO',
      'ABOGADA',
      'ING',
      'INGENIERO',
      'INGENIERA',
      'DR',
      'DOCTOR',
      'DOCTORA',
      'LIC',
      'LICENCIADO',
      'LICENCIADA',
    ];

    for (final profession in professions) {
      if (upperText.contains(profession)) {
        return true;
      }
    }
    return false;
  }

  /// Verifica si un número es probablemente una fecha
  bool _isLikelyDate(String number) {
    // Fechas comunes: 8 dígitos (DDMMYYYY o YYYYMMDD)
    if (number.length == 8) {
      final day = int.tryParse(number.substring(0, 2));
      final month = int.tryParse(number.substring(2, 4));
      if (day != null && month != null) {
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return true;
        }
      }
    }
    return false;
  }

  /// Verifica si un número es probablemente otra cosa (no CI)
  bool _isLikelyOtherNumber(String context, int position) {
    // Verificar si está cerca de palabras como "FECHA", "NAC", "EXP", etc.
    final nearbyText = context
        .substring(
          (position - 20).clamp(0, context.length),
          (position + 30).clamp(0, context.length),
        )
        .toUpperCase();

    final dateKeywords = [
      'FECHA',
      'NAC',
      'NACIMIENTO',
      'EXP',
      'EXPEDICION',
      'DD',
      'MM',
      'YYYY',
    ];
    for (final keyword in dateKeywords) {
      if (nearbyText.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  /// Verifica si el texto es parte del carnet (no es un nombre)
  bool _isCarnetText(String text) {
    final upperText = text.toUpperCase();
    final carnetPhrases = [
      'SERVICIO GENERAL DE IDENTIFICACIÓN PERSONAL',
      'SERVICIO GENERAL DE IDENTIFICACION PERSONAL',
      'SERVICIO GENERAL',
      'IDENTIFICACIÓN PERSONAL',
      'IDENTIFICACION PERSONAL',
      'CÉDULA DE IDENTIDAD',
      'CEDULA DE IDENTIDAD',
      'CERTIFICA',
      'QUE LA FIRMA',
      'FOTOGRAFÍA E IMPRESIÓN',
      'FOTOGRAFIA E IMPRESION',
      'PERTENECE A',
      'ESTADO PLURINACIONAL DE BOLIVIA',
      'ESTADO PLURINACIONAL',
      'PLURINACIONAL DE BOLIVIA',
    ];

    for (final phrase in carnetPhrases) {
      if (upperText.contains(phrase)) {
        debugPrint("⚠ Texto rechazado (frase del carnet): $phrase");
        return true;
      }
    }
    return false;
  }

  /// Verifica si una palabra es común y no es un nombre
  bool _isCommonNonNameWord(String text) {
    final upperText = text.toUpperCase();

    // Primero verificar si es texto del carnet
    if (_isCarnetText(text)) {
      return true;
    }

    final commonWords = [
      'BOLIVIA',
      'BOLIVIANO',
      'REPUBLICA',
      'REPÚBLICA',
      'ESTADO',
      'PLURINACIONAL',
      'PLURINACIONAL DE BOLIVIA',
      'IDENTIDAD',
      'CEDULA',
      'CÉDULA',
      'CIUDADANIA',
      'CIUDADANÍA',
      'NACIONALIDAD',
      'FECHA',
      'NACIMIENTO',
      'EXPEDICION',
      'EXPEDICIÓN',
      'VIGENCIA',
      'SEXO',
      'ESTADO CIVIL',
      'PROFESION',
      'PROFESIÓN',
      'OCUPACION',
      'OCUPACIÓN',
      'DOMICILIO',
      'LUGAR',
      'LUGAR DE NACIMIENTO',
      'NACIDO EN',
      'DEPARTAMENTO',
      'PROVINCIA',
      'MUNICIPIO',
      'SEGMENTO',
      'CODIGO',
      'CÓDIGO',
      'SERVICIO GENERAL',
      'IDENTIFICACION PERSONAL',
      'IDENTIFICACIÓN PERSONAL',
      // Profesiones comunes (excluir de nombres)
      'ABG',
      'ABOGADO',
      'ABOGADA',
      'ING',
      'INGENIERO',
      'INGENIERA',
      'DR',
      'DOCTOR',
      'DOCTORA',
      'LIC',
      'LICENCIADO',
      'LICENCIADA',
      'SR',
      'SEÑOR',
      'SRA',
      'SEÑORA',
      'SRTA',
      'SEÑORITA',
      // Lugares comunes en Bolivia (excluir de nombres)
      'LA PAZ',
      'SANTA CRUZ',
      'COCHABAMBA',
      'ORURO',
      'POTOSI',
      'POTOSÍ',
      'SUCRE',
      'TARIJA',
      'BENI',
      'PANDO',
      'MURILLO',
      'EL ALTO',
      'CIUDAD',
      'ZONA',
      'CALLE',
      'AVENIDA',
      'BARRIO',
      // Campos del carnet (excluir)
      'SERIE',
      'SECCIÓN',
      'SECCION',
      'BIO',
      'VALIDA HASTA',
      'VÁLIDA HASTA',
    ];

    // Verificar si contiene nombres de lugares comunes
    final placePatterns = [
      RegExp(
        r'\b(LA PAZ|SANTA CRUZ|COCHABAMBA|ORURO|POTOSI|POTOSÍ|SUCRE|TARIJA|BENI|PANDO)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(MURILLO|EL ALTO|CIUDAD|ZONA|CALLE|AVENIDA|BARRIO)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(ALTO|BAJO|NORTE|SUR|ESTE|OESTE|CENTRO)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in placePatterns) {
      if (pattern.hasMatch(upperText)) {
        return true;
      }
    }

    for (final word in commonWords) {
      if (upperText.contains(word)) {
        return true;
      }
    }

    return false;
  }

  /// Verifica si un texto es un lugar o dirección (no un nombre)
  bool _isLocationOrAddress(String text) {
    final upperText = text.toUpperCase();

    // Patrones de lugares comunes
    final locationPatterns = [
      // Ciudades y departamentos
      RegExp(
        r'\b(LA PAZ|SANTA CRUZ|COCHABAMBA|ORURO|POTOSI|POTOSÍ|SUCRE|TARIJA|BENI|PANDO)\b',
        caseSensitive: false,
      ),
      // Provincias y municipios comunes
      RegExp(
        r'\b(MURILLO|EL ALTO|CIUDAD|ZONA|CALLE|AVENIDA|BARRIO|URBANIZACION|URBANIZACIÓN)\b',
        caseSensitive: false,
      ),
      // Direcciones
      RegExp(
        r'\b(ALTO|BAJO|NORTE|SUR|ESTE|OESTE|CENTRO|PLAZA|MERCADO)\b',
        caseSensitive: false,
      ),
      // Números en direcciones (ej: "CALLE 10", "AVENIDA 6 DE AGOSTO")
      RegExp(r'\b(.*\d+.*)\b', caseSensitive: false),
    ];

    // Si contiene palabras de lugar, probablemente es una dirección
    for (final pattern in locationPatterns) {
      if (pattern.hasMatch(upperText)) {
        // Verificar que no sea un nombre que contenga estas palabras por casualidad
        // Si tiene más de 3 palabras y contiene números, probablemente es dirección
        final words = upperText.split(RegExp(r'\s+'));
        if (words.length > 3 || RegExp(r'\d').hasMatch(upperText)) {
          return true;
        }
      }
    }

    // Si contiene "EL ALTO", "LA PAZ", "MURILLO" como palabras completas, es lugar
    if (upperText.contains('EL ALTO') ||
        upperText.contains('LA PAZ') ||
        upperText.contains('MURILLO')) {
      return true;
    }

    return false;
  }

  /// Detecta si una imagen es el anverso o el reverso del carnet
  /// Retorna: "front" si es anverso, "back" si es reverso, "unknown" si no se puede determinar
  String _detectCardSide(RecognizedText recognizedText) {
    final fullText = recognizedText.text.toUpperCase();

    // Características del ANVERSO:
    // - Tiene "CÉDULA DE IDENTIDAD" o "N°"
    // - Tiene CI (número de 5-11 dígitos)
    final hasCedulaIdentidad = RegExp(
      r'C[ÉE]DULA\s+DE\s+IDENTIDAD',
      caseSensitive: false,
    ).hasMatch(fullText);
    final hasN = RegExp(r'N\s*[°º]', caseSensitive: false).hasMatch(fullText);
    final hasCI = _extractCIFromText(recognizedText).isNotEmpty;

    // Características del REVERSO:
    // - Modelo nuevo: tiene "LUGAR", "DOMICILIO", "OCUPACIÓN", "ESTADO CIVIL"
    // - Modelo antiguo: tiene "NOMBRES", "APELLIDOS"
    final hasBackData = RegExp(
      r'(LUGAR|DOMICILIO|OCUPACION|OCUPACIÓN|ESTADO CIVIL|NACIMIENTO|NACIDO EN)',
      caseSensitive: false,
    ).hasMatch(fullText);
    final hasNames = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);

    // Si tiene características del anverso
    if ((hasCedulaIdentidad || hasN) && hasCI) {
      debugPrint(
        "📄 Detectado: ANVERSO (tiene CI y 'CÉDULA DE IDENTIDAD' o 'N°')",
      );
      return "front";
    }

    // Si tiene características del reverso
    if (hasBackData || hasNames) {
      debugPrint(" Detectado: REVERSO (tiene datos del reverso)");
      return "back";
    }

    debugPrint(" Detectado: DESCONOCIDO");
    return "unknown";
  }

  /// Calcula la similitud entre dos textos (0.0 a 1.0)
  double _calculateTextSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    // Normalizar textos (eliminar espacios extra, convertir a mayúsculas)
    final normalized1 = text1.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized2 = text2.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Contar palabras comunes
    final words1 = normalized1.split(' ').where((w) => w.length > 2).toSet();
    final words2 = normalized2.split(' ').where((w) => w.length > 2).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final commonWords = words1.intersection(words2);
    final totalWords = words1.union(words2);

    if (totalWords.isEmpty) return 0.0;

    return commonWords.length / totalWords.length;
  }

  Future<File> _preprocessForOcr(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageFile;

    // Recortar bordes blancos o ruido externo para evitar texto fuera del carnet
    img.Image processed = _autoCropBorders(decoded);

    const int minShortSide = 1200;
    const int maxLongSide = 2000;
    int width = processed.width;
    int height = processed.height;
    int shortSide = width < height ? width : height;
    int longSide = width > height ? width : height;

    if (shortSide < minShortSide) {
      final scale = minShortSide / shortSide;
      processed = img.copyResize(
        processed,
        width: (width * scale).round(),
        height: (height * scale).round(),
        interpolation: img.Interpolation.average,
      );
      width = processed.width;
      height = processed.height;
      longSide = width > height ? width : height;
    }

    if (longSide > maxLongSide) {
      final scale = maxLongSide / longSide;
      processed = img.copyResize(
        processed,
        width: (width * scale).round(),
        height: (height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    processed = img.normalize(processed, min: 0, max: 255);
    processed = img.adjustColor(
      processed,
      contrast: 1.1,
      brightness: 1.05,
    );

    return _writeOcrImage(processed, suffix: 'ocr');
  }

  Future<File> _prepareFileForOcr(File original) async {
    if (!original.existsSync()) return original;
    // Si ya está en la carpeta persistente de OCR, úsalo directamente
    if (p.basename(p.dirname(original.path)) == 'ocr_cache') {
      return original;
    }
    final processed = await _preprocessForOcr(original);
    return processed.existsSync() ? processed : original;
  }

  Future<File> _persistImage(File file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(appDir.path, 'ocr_cache'));
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final newPath = p.join(
      outDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_${p.basename(file.path)}',
    );
    return file.copy(newPath);
  }

  Future<File> _writeOcrImage(img.Image image, {required String suffix}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final outDir = Directory(p.join(appDir.path, 'ocr_cache'));
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
    final newPath = p.join(
      outDir.path,
      '${DateTime.now().microsecondsSinceEpoch}_$suffix.jpg',
    );
    final outBytes = img.encodeJpg(image, quality: 92);
    final outFile = await File(newPath).writeAsBytes(outBytes, flush: true);
    return outFile.existsSync() ? outFile : File(newPath);
  }

  String _pickFirstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  Future<File> _preprocessForOcrEnhanced(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return imageFile;

    final cropped = _autoCropBorders(decoded);

    var processed = img.grayscale(cropped);
    processed = img.adjustColor(
      processed,
      contrast: 1.35,
      brightness: 1.1,
    );

    return _writeOcrImage(processed, suffix: 'ocr_enhanced');
  }

  img.Image _autoCropBorders(img.Image src) {
    const threshold = 245; // casi blanco
    int minX = src.width, minY = src.height, maxX = 0, maxY = 0;
    bool found = false;

    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final l = img.getLuminance(src.getPixel(x, y));
        if (l < threshold) {
          found = true;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    if (!found) return src;

    const pad = 8;
    final cropX = (minX - pad).clamp(0, src.width - 1);
    final cropY = (minY - pad).clamp(0, src.height - 1);
    final cropW = (maxX - cropX + 1 + pad * 2).clamp(1, src.width - cropX);
    final cropH = (maxY - cropY + 1 + pad * 2).clamp(1, src.height - cropY);

    return img.copyCrop(
      src,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );
  }

  Future<double> _estimateSharpness(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return 1.0;

    img.Image sample = decoded;
    final longSide =
        sample.width > sample.height ? sample.width : sample.height;
    if (longSide > 600) {
      final scale = 600 / longSide;
      sample = img.copyResize(
        sample,
        width: (sample.width * scale).round(),
        height: (sample.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    sample = img.grayscale(sample);
    final edges = img.sobel(sample, amount: 1);
    double sum = 0.0;
    int count = 0;
    for (final pixel in edges) {
      sum += pixel.luminance.toDouble();
      count++;
    }

    if (count == 0) return 1.0;
    return (sum / count) / 255.0;
  }

  Future<File> _cropCardImage(
    File imageFile,
    RecognizedText recognizedText,
  ) async {
    if (recognizedText.blocks.isEmpty) return imageFile;

    final imageBytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageFile;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = 0;
    double maxY = 0;

    for (final block in recognizedText.blocks) {
      if (block.boundingBox.left < minX) minX = block.boundingBox.left;
      if (block.boundingBox.top < minY) minY = block.boundingBox.top;
      if (block.boundingBox.right > maxX) maxX = block.boundingBox.right;
      if (block.boundingBox.bottom > maxY) maxY = block.boundingBox.bottom;
    }

    final boxWidth = (maxX - minX).clamp(1, decoded.width.toDouble());
    final boxHeight = (maxY - minY).clamp(1, decoded.height.toDouble());
    final paddingX = boxWidth * 0.18;
    final paddingY = boxHeight * 0.25;

    int clampInt(num value, int min, int max) {
      if (value < min) return min;
      if (value > max) return max;
      return value.toInt();
    }

    final left = clampInt(minX - paddingX, 0, decoded.width - 1);
    final top = clampInt(minY - paddingY, 0, decoded.height - 1);
    final right = clampInt(maxX + paddingX, 1, decoded.width);
    final bottom = clampInt(maxY + paddingY, 1, decoded.height);
    final cropWidth = right - left;
    final cropHeight = bottom - top;

    if (cropWidth <= 0 || cropHeight <= 0) return imageFile;

    final cropped = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: cropWidth,
      height: cropHeight,
    );

    final newPath = imageFile.path.replaceFirst(
      RegExp(r'\.[^./\\]+$'),
      '_cropped.jpg',
    );
    final outBytes = img.encodeJpg(cropped, quality: 90);
    final outFile = await File(newPath).writeAsBytes(outBytes, flush: true);
    return outFile;
  }

  Future<void> _pickImage(ImageSource source, bool isFront) async {
    // Cerrar el bottom sheet primero
    if (mounted) Navigator.pop(context);

    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      // Validar rápidamente la imagen
      await _quickValidateAndSetImage(pickedFile.path, isFront);
    }
  }

  // Método para validar rápidamente la imagen con OCR
  Future<void> _quickValidateAndSetImage(String imagePath, bool isFront) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      File sourceFile = File(imagePath);
      try {
        sourceFile = await _preprocessForOcr(sourceFile);
      } catch (e) {
        debugPrint("Error preprocesando imagen: $e");
      }

      final sharpness = await _estimateSharpness(sourceFile);

      // Validar con OCR
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final inputImage = InputImage.fromFile(sourceFile);
      final recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      bool isValid = false;
      bool isSharpEnough = sharpness >= 0.035;
      String message = "";
      String extractedValue = "";

      if (!isSharpEnough) {
        isValid = false;
        message =
            "Imagen borrosa. Acerca el carnet, mejora la luz y evita movimiento.";
      }

      if (isFront && isSharpEnough) {
        // Validar que sea realmente el ANVERSO (no el reverso)
        final detectedSide = _detectCardSide(recognizedText);

        if (detectedSide == "back") {
          // El usuario está tomando el reverso cuando debería tomar el anverso
          isValid = false;
          message =
              "⚠ Error: Parece que estás tomando el reverso. Por favor, toma el anverso del carnet (lado con el CI).";
        } else if (_backImage != null && detectedSide == "front") {
          // Si ya tiene el reverso cargado, verificar que el anverso no sea el mismo
          try {
            final backTextRecognizer = TextRecognizer(
              script: TextRecognitionScript.latin,
            );
            final backInputImage = InputImage.fromFile(_backImage!);
            final backRecognizedText = await backTextRecognizer.processImage(
              backInputImage,
            );

            final backText = backRecognizedText.text.toUpperCase().trim();
            final currentText = recognizedText.text.toUpperCase().trim();

            if (backText == currentText ||
                _calculateTextSimilarity(backText, currentText) > 0.95) {
              isValid = false;
              message =
                  "⚠ Error: Parece que estás tomando el mismo reverso otra vez. Por favor, voltea el carnet y toma el anverso (lado con el CI).";
            } else {
              // Es el anverso válido, continuar con validación normal
              extractedValue = _extractCIFromText(recognizedText);
              final model = _detectCIModel(recognizedText);

              if (extractedValue.isNotEmpty) {
                isValid = true;
                final modelInfo = model == "nuevo"
                    ? " (Modelo nuevo)"
                    : model == "antiguo"
                        ? " (Modelo antiguo)"
                        : "";
                message = "✓ Foto frontal válida$modelInfo";
              } else {
                isValid = false;
                message = "⚠ No se detectó un CI. ¿Deseas continuar?";
              }
            }

            await backTextRecognizer.close();
          } catch (e) {
            debugPrint("Error al comparar con reverso existente: $e");
            // Si hay error, continuar con validación normal
            extractedValue = _extractCIFromText(recognizedText);
            final model = _detectCIModel(recognizedText);

          if (extractedValue.isNotEmpty) {
            isValid = true;
            final modelInfo = model == "nuevo"
                ? " (Modelo nuevo)"
                : model == "antiguo"
                    ? " (Modelo antiguo)"
                    : "";
            message = "✓ Foto frontal válida$modelInfo";
          } else {
            isValid = false;
            message = "⚠ No se detectó un CI. ¿Deseas continuar?";
          }
          }
        } else {
          // Validar CI (menos estricto) - caso normal (anverso primero)
          extractedValue = _extractCIFromText(recognizedText);
          final model = _detectCIModel(recognizedText);

          if (extractedValue.isNotEmpty) {
            isValid = true;
            final modelInfo = model == "nuevo"
                ? " (Modelo nuevo)"
                : model == "antiguo"
                ? " (Modelo antiguo)"
                : "";
            message = "✓ Foto frontal válida$modelInfo";
          } else {
            isValid = false;
            message = "⚠ No se detectó un CI. ¿Deseas continuar?";
          }
        }
      } else if (isSharpEnough) {
        // Validar nombre (menos estricto)
        // Para el reverso: solo buscar nombres si es modelo antiguo
        // (En modelo nuevo, el reverso tiene lugar de nacimiento, domicilio, etc., NO nombres)

        // Primero, detectar el modelo del frontal (si ya se cargó)
        String frontModel = "desconocido";
        RecognizedText? frontRecognizedText;
        if (_frontImage != null) {
          try {
            final frontTextRecognizer = TextRecognizer(
              script: TextRecognitionScript.latin,
            );
            final frontInputImage = InputImage.fromFile(_frontImage!);
            frontRecognizedText = await frontTextRecognizer.processImage(
              frontInputImage,
            );
            frontModel = _detectCIModel(frontRecognizedText);
            await frontTextRecognizer.close();
          } catch (e) {
            debugPrint("Error al detectar modelo del frontal: $e");
          }
        }

        // Si ya tenemos el anverso cargado, solo validar que el reverso sea diferente
        if (_frontImage != null && frontRecognizedText != null) {
          final frontText = frontRecognizedText.text.toUpperCase().trim();
          final backText = recognizedText.text.toUpperCase().trim();

          // Si el texto es idéntico, es el anverso otra vez
          if (frontText == backText) {
            isValid = false;
            message =
                "⚠ Error: Parece que estás tomando el anverso otra vez. Por favor, voltea el carnet y toma el reverso.";
          } else {
            // Calcular similitud
            final similarity = _calculateTextSimilarity(frontText, backText);
            debugPrint(
              "📊 Similitud entre anverso y reverso: ${(similarity * 100).toStringAsFixed(0)}%",
            );

            // Si la similitud es muy alta (>95%), es probablemente el anverso
            if (similarity > 0.95) {
              isValid = false;
              message =
                  "⚠ Error: Parece que estás tomando el anverso otra vez. Por favor, voltea el carnet y toma el reverso.";
            } else {
              // Es diferente, es válido
              isValid = true;

              // Intentar extraer nombre si es modelo antiguo
              final fullText = recognizedText.text.toUpperCase();
              final hasNameKeywords = RegExp(
                r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
                caseSensitive: false,
              ).hasMatch(fullText);

              if (hasNameKeywords && frontModel == "antiguo") {
                extractedValue = _extractNameFromText(
                  recognizedText,
                  isFrontal: false,
                  model: "antiguo",
                );
                final words = _extractValidWords(extractedValue);
                if (extractedValue.isNotEmpty && words.length >= 2) {
                  message = "✓ Nombre detectado: $extractedValue";
                } else {
                  message = "✓ Reverso del carnet detectado";
                }
              } else {
                message = "✓ Reverso del carnet detectado";
              }
            }
          }
        } else {
          // Si no hay anverso cargado, permitir continuar (caso: reverso primero)
          isValid = true;
          message = "✓ Reverso del carnet detectado";
        }
      }

      // Mostrar alert
      if (!mounted) return;
      final shouldAccept = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                isValid ? Icons.check_circle : Icons.warning,
                color: isValid ? Colors.green : Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isValid ? "✓ Validación exitosa" : "⚠ Advertencia",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isValid ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            if (!isValid)
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text("Tomar otra"),
              ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF305BA4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Aceptar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldAccept == true && mounted) {
        File finalImage = sourceFile;
        try {
          finalImage = await _cropCardImage(finalImage, recognizedText);
        } catch (e) {
          debugPrint("Error recortando imagen del carnet: $e");
        }

        // Persistir la imagen en un path estable para evitar que se borre del cache
        try {
          finalImage = await _persistImage(finalImage);
        } catch (e) {
          debugPrint("Error persistiendo imagen: $e");
        }

        setState(() {
          if (isFront) {
            _frontImage = finalImage;
          } else {
            _backImage = finalImage;
          }
        });

        // Guardar ruta en documentos del participante
        try {
          final key = isFront ? 'ci_front_path' : 'ci_back_path';
          final current = await LocalStorageService.getParticipantDocumentsData() ?? <String, dynamic>{};
          current[key] = finalImage.path;
          await LocalStorageService.saveParticipantDocumentsData(current);

          // Si ya tenemos ambos lados, generar fotocopia en PDF
          final front = isFront ? finalImage.path : current['ci_front_path'] as String?;
          final back = !isFront ? finalImage.path : current['ci_back_path'] as String?;
          if (front != null && back != null) {
            final profilePath = current['profile_photo_path'] as String?;
            final pdfPath = await CarnetPhotocopyService.generatePdf(
              frontFile: File(front),
              backFile: File(back),
              profilePhoto: profilePath != null ? File(profilePath) : null,
            );
            if (pdfPath != null) {
              current['ci_photocopy_pdf_path'] = pdfPath;
              await LocalStorageService.saveParticipantDocumentsData(current);
            }
          }
        } catch (e) {
          debugPrint("Error guardando ruta de CI: $e");
        }

        // Nota: la foto 4x4 ahora se genera desde el escaneo facial.

        // Mostrar animación de volteo si es frontal (después de actualizar el estado)
        if (isFront) {
          // Esperar un poco para que el estado se actualice
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _showFlipAnimation();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading si hay error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al validar imagen: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showFlipAnimation() {
    // Animación de volteo del carnet
    if (!mounted || _isFlipDialogOpen) return;
    _isFlipDialogOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) => const _FlipCardAnimation(),
    );

    // Cerrar después de la animación y abrir la cámara para el reverso
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar animación
        _isFlipDialogOpen = false;

        // Esperar un poco y abrir la cámara para tomar el reverso
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _backImage == null) {
            _showPickerOptions(false); // Abrir opciones para tomar el reverso
          }
        });
      } else {
        _isFlipDialogOpen = false;
      }
    });
  }

  void _showPickerOptions(bool isFront) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF305BA4)),
                title: const Text('Cámara'),
                onTap: () => _pickImage(ImageSource.camera, isFront),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF305BA4),
                ),
                title: const Text('Galería'),
                onTap: () => _pickImage(ImageSource.gallery, isFront),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF1A3A5C);
    const Color whiteBg = Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        title: const Text(
          'Verificación de Identidad',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            FadeInDown(
              child: const Text(
                'Sube una foto de tu Carnet',
                style: TextStyle(
                  color: textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInLeft(
              child: Text(
                'Para verificar tu cuenta, necesitamos una foto clara de tu documento de identidad (CI).',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ),
            const SizedBox(height: 32),

            _buildUploadCard(
              title: 'Lado Frontal',
              icon: Icons.credit_card,
              delay: 200,
              imageFile: _frontImage,
              isScanning: _isProcessing,
              isValidating: false,
              isFrontCard: true,
              onTap: () => _showPickerOptions(true),
            ),

            const SizedBox(height: 20),

            _buildUploadCard(
              title: 'Lado Posterior',
              icon: Icons.credit_card_off_outlined,
              delay: 400,
              imageFile: _backImage,
              isScanning: _isProcessing,
              isValidating: false,
              isFrontCard: false,
              onTap: () => _showPickerOptions(false),
            ),

            const SizedBox(height: 40),

            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryBlue.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: primaryBlue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Asegúrate de que todos los datos sean legibles y la foto no tenga reflejos.',
                        style: TextStyle(
                          color: textDark.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 48),

            FadeInUp(
              delay: const Duration(milliseconds: 800),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed:
                      (_frontImage != null &&
                          _backImage != null &&
                          !_isProcessing)
                      ? _processImageWithOCR
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.white24,
                              color: Colors.white,
                              minHeight: 6,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Procesando... ${(_progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Subir y Continuar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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

  Widget _buildUploadCard({
    required String title,
    required IconData icon,
    required int delay,
    File? imageFile,
    required VoidCallback onTap,
    bool isScanning = false,
    bool isValidating = false,
    required bool isFrontCard,
  }) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF1A3A5C);

    return FadeInUp(
      delay: Duration(milliseconds: delay),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: imageFile != null ? primaryBlue : const Color(0xFFEEF2F6),
              width: imageFile != null ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: textDark.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageFile != null)
                  Image.file(imageFile, fit: BoxFit.cover)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryBlue.withOpacity(0.08),
                          primaryBlue.withOpacity(0.14),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                if (imageFile != null) Container(color: Colors.black26),
                if (imageFile != null)
                  const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                if (imageFile != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.8),
                      radius: 16,
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                if (imageFile == null)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 40, color: primaryBlue.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: const TextStyle(
                          color: textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pulsa para tomar foto o subir',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                if (isScanning)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FadeTransition(
                        opacity: _hintOpacity,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.15),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (isValidating)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: AnimatedOpacity(
                      opacity: isValidating ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(primaryBlue),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (imageFile == null)
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: SlideTransition(
                      position: _hintSlide,
                      child: FadeTransition(
                        opacity: _hintOpacity,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isFrontCard ? Icons.credit_card : Icons.flip_camera_android,
                              color: primaryBlue.withOpacity(0.7),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFrontCard
                                  ? 'Toca para cargar el anverso'
                                  : 'Toca para cargar el reverso',
                              style: TextStyle(
                                color: primaryBlue.withOpacity(0.8),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
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

  String _normalizeDateLine(String line) {
    final buffer = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      final prev = i > 0 ? line[i - 1] : '';
      final next = i + 1 < line.length ? line[i + 1] : '';
      final hasDigitNearby =
          RegExp(r'\d').hasMatch(prev) || RegExp(r'\d').hasMatch(next);
      if (hasDigitNearby) {
        if (char == 'O' || char == 'o') {
          buffer.write('0');
          continue;
        }
        if (char == 'I' || char == 'l' || char == '|' || char == '!') {
          buffer.write('1');
          continue;
        }
        if (char == 'S' || char == 's') {
          buffer.write('5');
          continue;
        }
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  DateTime? _parseDateString(String raw) {
    final cleaned =
        raw.replaceAll(RegExp(r'[.\-\s]+'), '/').replaceAll('//', '/');
    final parts = cleaned.split('/');
    if (parts.length < 3) return null;

    int? day;
    int? month;
    int? year;

    if (parts[0].length == 4) {
      year = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      day = int.tryParse(parts[2]);
    } else {
      day = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      year = int.tryParse(parts[2]);
    }

    if (day == null || month == null || year == null) return null;
    if (year < 100) year = year > 30 ? 1900 + year : 2000 + year;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yyyy';
  }

  String _findDateInLine(String line) {
    final normalized = _normalizeDateLine(line);
    final datePatterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})'),
      RegExp(r'(\d{1,2}\.\d{1,2}\.\d{2,4})'),
      RegExp(r'(\d{4}\.\d{1,2}\.\d{1,2})'),
      RegExp(r'(\d{1,2}\s+\d{1,2}\s+\d{2,4})'),
      RegExp(r'(\d{4}\s+\d{1,2}\s+\d{1,2})'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final raw = match.group(1)!.trim();
        if (raw.length < 6) continue;
        final parsed = _parseDateString(raw);
        if (parsed != null) return _formatDate(parsed);
      }
    }
    return '';
  }

}

// Animación de volteo del carnet

class _FlipCardAnimation extends StatefulWidget {
  const _FlipCardAnimation();

  @override
  State<_FlipCardAnimation> createState() => _FlipCardAnimationState();
}

class _FlipCardAnimationState extends State<_FlipCardAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }
//AQUI SE AQUI ES LA ANIMACION DE VOLTEAR EL CARNET
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _flipAnimation,
      builder: (context, child) {
        // Corregir el ángulo para que gire correctamente (no al revés)
        final angle = _flipAnimation.value * math.pi;
        final scale = _flipAnimation.value < 0.5
            ? 1.0 - _flipAnimation.value * 0.2
            : 0.8 + (_flipAnimation.value - 0.5) * 0.2;

        // Determinar qué mostrar según el progreso de la animación
        final showFront = _flipAnimation.value < 0.5;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle)
            ..scale(scale),
          child: Container(
            color: Colors.transparent,
            child: Center(
              child: Container(
                width: 200,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(
                        0xFF305BA4,
                      ).withOpacity(showFront ? 1.0 : 0.7),
                      const Color(0xFF305BA4).withOpacity(0.7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF305BA4).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: showFront
                    ? const Center(
                        child: Icon(
                          Icons.credit_card,
                          size: 80,
                          color: Colors.white,
                        ),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.credit_card_off_outlined,
                              size: 80,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Voltea el carnet",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.arrow_downward,
                              color: Colors.white.withOpacity(0.8),
                              size: 32,
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
