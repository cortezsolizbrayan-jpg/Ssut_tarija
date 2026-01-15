import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:animate_do/animate_do.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;

enum FaceStep { center, completed }

class FaceRecognitionScreen extends StatefulWidget {
  static const name = 'face-recognition-screen';
  final Map<String, String>? ocrData;

  const FaceRecognitionScreen({super.key, this.ocrData});

  @override
  State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isBusy = false;
  int _frameCount = 0;
  // _ocrData removido - se usa widget.ocrData directamente
  FaceStep _currentStep = FaceStep.center;
  double _progress = 0.0;
  double _stepProgress = 0.0; // Progreso del paso actual (0.0 a 1.0)
  String _instruction = "Centra tu rostro en el círculo";
  Timer? _stepTimer;
  bool _isConditionMet = false; // Para feedback visual
  bool _isFaceDetected = false; // Debug: ¿Hay un rostro?
  String _errorMessage =
      ""; // Mensaje de error de validación (ej: "Acércate más")
  bool _isInitialDelayComplete = false; // Delay inicial de 2 segundos
  int _consecutiveTimeouts = 0; // Contador de timeouts consecutivos
  bool _isProcessingPaused =
      false; // Si el procesamiento está pausado por timeouts

  // Para animaciones y captura de fotos
  final List<XFile> _capturedPhotos = [];
  bool _isCapturing = false;
  bool _showFlash = false;
  bool _showSuccessAnimation = false;
  RiveAnimationController? _checkAnimationController;
  RiveAnimationController? _confettiController;
  RiveAnimationController? _shapesController;
  late AnimationController _pulseController;
  late AnimationController _successController;
  late AnimationController _flashController;
  late AnimationController _headRotationController;
  late AnimationController _arrowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _successScaleAnimation;
  late Animation<double> _headRotationAnimation;
  late Animation<double> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCamera();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableLandmarks: false,
        enableClassification: true, // Para mejor detección de rostro
        performanceMode: FaceDetectorMode.fast,
      ),
    );
  }

  void _initializeAnimations() {
    // Animación de pulso para el borde
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animación de éxito mejorada (más dinámica)
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _successScaleAnimation = Tween<double>(begin: 0.0, end: 1.2).animate(
      CurvedAnimation(parent: _successController, curve: Curves.elasticOut),
    );

    // Animación de flash
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Animación de rotación de cabeza
    _headRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _headRotationAnimation = Tween<double>(begin: -0.3, end: 0.3).animate(
      CurvedAnimation(parent: _headRotationController, curve: Curves.easeInOut),
    );

    // Animación de flechas
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _arrowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut),
    );

    // Controlador para animación Rive de check
    _checkAnimationController = SimpleAnimation('Check', autoplay: false);
    _confettiController = SimpleAnimation('Trigger victory', autoplay: false);
    _shapesController = SimpleAnimation('Animation 1', autoplay: true);
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) return;

    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset
          .low, // Cambiamos a LOW para máxima estabilidad en Android y evitar IllegalArgumentException por memoria
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      // Actualizar estado para mostrar el preview de la cámara inmediatamente
      setState(() {});
      debugPrint("✓ Cámara inicializada. Mostrando preview...");

      // Esperar 2 segundos antes de empezar a procesar imágenes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isInitialDelayComplete = true;
            _instruction = "Centra tu rostro en el círculo";
          });
          debugPrint(
            "✓ Delay inicial completado. Iniciando detección facial...",
          );
        }
      });

      _cameraController!.startImageStream((image) {
        if (_isBusy) return;
        // Solo procesar después del delay inicial
        if (_isInitialDelayComplete) {
          _processCameraImage(image);
        }
      });
    } catch (e) {
      debugPrint("Camera Error: $e");
      if (mounted) {
        setState(() {
          _isInitialDelayComplete =
              true; // Permitir continuar aunque haya error
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_cameraController == null || _faceDetector == null) return;
    if (_isBusy) return;
    if (!_isInitialDelayComplete) return;

    // OPTIMIZACIÓN: Procesar solo cada 8vo frame para reducir carga
    _frameCount++;
    if (_frameCount % 8 != 0) return;

    // OPTIMIZACIÓN: Pausar procesamiento si hay demasiados timeouts consecutivos
    if (_isProcessingPaused) {
      debugPrint(
        "⚠️ Procesamiento pausado por $_consecutiveTimeouts timeouts consecutivos",
      );
      return;
    }

    _isBusy = true;

    try {
      // OPTIMIZACIÓN: Procesar con timeout de 2 segundos
      await _processImageWithTimeout(image, const Duration(seconds: 2));
    } catch (e) {
      _consecutiveTimeouts++;
      debugPrint(
        "❌ Timeout #$_consecutiveTimeouts en procesamiento de imagen: $e",
      );

      // OPTIMIZACIÓN: Pausar procesamiento después de 3 timeouts consecutivos
      if (_consecutiveTimeouts >= 3) {
        _isProcessingPaused = true;
        debugPrint("⏸️ Procesamiento pausado por 3 timeouts consecutivos");

        // Reanudar automáticamente después de 5 segundos
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _consecutiveTimeouts = 0;
            _isProcessingPaused = false;
            debugPrint("▶️ Procesamiento reanudado");
          }
        });
      }

      // OPTIMIZACIÓN: Detener stream de cámara después de 10 timeouts
      if (_consecutiveTimeouts >= 10) {
        debugPrint("🚫 Demasiados timeouts. Deteniendo stream de cámara.");
        _stopCameraStream();
      }
    } finally {
      _isBusy = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final rotation = InputImageRotationValue.fromRawValue(
      _cameraController!.description.sensorOrientation,
    );
    if (rotation == null) return null;

    if (Platform.isAndroid) {
      // Construir formato NV21 correctamente desde YUV420
      // NV21 = Y plano + UV intercalado (VU orden)
      if (image.format.group == ImageFormatGroup.yuv420) {
        final yPlane = image.planes[0];

        // Verificar si tenemos 2 o 3 planos
        if (image.planes.length == 2) {
          // Ya está en formato semi-planar (Y + UV)
          final uvPlane = image.planes[1];
          final ySize = yPlane.bytes.length;
          final uvSize = uvPlane.bytes.length;
          final totalSize = ySize + uvSize;

          final nv21Buffer = Uint8List(totalSize);
          nv21Buffer.setRange(0, ySize, yPlane.bytes);
          nv21Buffer.setRange(ySize, totalSize, uvPlane.bytes);

          return InputImage.fromBytes(
            bytes: nv21Buffer,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: rotation,
              format: InputImageFormat.nv21,
              bytesPerRow: yPlane.bytesPerRow,
            ),
          );
        } else if (image.planes.length == 3) {
          // YUV_420_888: necesitamos intercalar U y V
          final uPlane = image.planes[1];
          final vPlane = image.planes[2];

          final ySize = yPlane.bytes.length;
          // Calcular tamaño UV basado en los bytes reales (intercalado VU)
          final minLength = uPlane.bytes.length < vPlane.bytes.length
              ? uPlane.bytes.length
              : vPlane.bytes.length;
          final uvSize = minLength * 2; // Cada par es V+U
          final totalSize = ySize + uvSize;

          final nv21Buffer = Uint8List(totalSize);

          // Copiar plano Y
          nv21Buffer.setRange(0, ySize, yPlane.bytes);

          // Intercalar U y V en orden VU para NV21
          int uvIndex = ySize;
          for (int i = 0; i < minLength; i++) {
            nv21Buffer[uvIndex++] = vPlane.bytes[i];
            nv21Buffer[uvIndex++] = uPlane.bytes[i];
          }

          return InputImage.fromBytes(
            bytes: nv21Buffer,
            metadata: InputImageMetadata(
              size: Size(image.width.toDouble(), image.height.toDouble()),
              rotation: rotation,
              format: InputImageFormat.nv21,
              bytesPerRow: yPlane.bytesPerRow,
            ),
          );
        }
      }

      // Fallback: intentar usar el formato nativo
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format != null) {
        final allBytes = WriteBuffer();
        for (final plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: format,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }

      return null;
    }

    // iOS y otros
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Future<void> _processImageWithTimeout(
    CameraImage image,
    Duration timeout,
  ) async {
    if (image.planes.isEmpty) return;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final faces = await _faceDetector!.processImage(inputImage);

    // Resetear contador de timeouts en procesamiento exitoso
    _consecutiveTimeouts = 0;

    // --- OPTIMIZACIÓN DE REDIBUJADO ---
    // Solo hacer setState si algo cambió para evitar "ciclado" excesivo en logs
    bool newFaceDetected = faces.isNotEmpty;
    String newError = "";

    if (faces.length > 1) {
      newError = "Solo una persona permitida";
    } else if (faces.isEmpty) {
      newError = "Buscando rostro...";
    } else {
      newError = "";
    }

    // Detectar cambios antes de redibujar
    if (mounted &&
        (_isFaceDetected != newFaceDetected || _errorMessage != newError)) {
      setState(() {
        _isFaceDetected = newFaceDetected;
        _errorMessage = newError;

        // Si hay más de una cara, resetear condición aquí
        if (faces.length > 1) _isConditionMet = false;
      });
      if (faces.length > 1) _resetStepTimer();
    }

    if (faces.length == 1) {
      _analyzeFace(faces.first, image.width.toDouble());
    }
  }

  void _resetStepTimer() {
    if (_stepTimer != null) {
      _stepTimer!.cancel();
      _stepTimer = null;
    }
    if (mounted) {
      setState(() {
        _stepProgress = 0.0;
        _isConditionMet = false;
      });
    }
  }

  void _startStepTimer(VoidCallback onComplete) {
    if (_stepTimer != null) return;

    const duration = Duration(milliseconds: 50);
    int elapsed = 0;
    const total = 2000; // 2 segundos para dar tiempo prudente de detección

    _stepTimer = Timer.periodic(duration, (timer) {
      elapsed += 50;
      if (mounted) {
        setState(() {
          _stepProgress = elapsed / total;
        });
      }

      if (elapsed >= total) {
        timer.cancel();
        _stepTimer = null;
        // Capturar foto antes de cambiar de paso
        _capturePhoto().then((_) {
          onComplete();
        });
      }
    });
  }

  Future<void> _capturePhoto() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isCapturing) return;
    _isCapturing = true;

    try {
      // Efecto de flash
      setState(() {
        _showFlash = true;
      });
      _flashController.forward().then((_) {
        _flashController.reverse();
      });

      // Capturar foto solo si no hemos alcanzado el límite (1 foto de frente)
      if (_capturedPhotos.length < 1) {
        final photo = await _cameraController!.takePicture();
        _capturedPhotos.add(photo);
        debugPrint("✅ Foto de frente capturada");
      } else {
        // Ya tenemos la foto, no capturar más
        debugPrint("Límite de 1 foto alcanzado");
        return;
      }

      // Animación de éxito mejorada con Rive
      setState(() {
        _showSuccessAnimation = true;
      });

      // Iniciar animación Rive
      if (_checkAnimationController != null) {
        _checkAnimationController!.isActive = true;
      }

      // Iniciar animación de escala mejorada
      _successController.forward().then((_) {
        // Mantener la animación visible por más tiempo
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _successController.reverse().then((_) {
              if (mounted) {
                setState(() {
                  _showSuccessAnimation = false;
                });
                _successController.reset();
                if (_checkAnimationController != null) {
                  _checkAnimationController!.isActive = false;
                }
              }
            });
          }
        });
      });

      // Vibración de feedback
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("Error capturando foto: $e");
    } finally {
      _isCapturing = false;
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showFlash = false;
          });
        }
      });
    }
  }

  void _analyzeFace(Face face, double frameWidth) {
    if (_currentStep == FaceStep.completed) return;

    // OPTIMIZACIÓN: Solo validar frente (sin rotación lateral)
    final double? rotZ = face.headEulerAngleZ; // Inclinación

    // Validación de Distancia (basada en el ancho del rostro relativo al frame)
    final faceWidthRatio = face.boundingBox.width / frameWidth;
    bool isDistanceOk = faceWidthRatio > 0.35 && faceWidthRatio < 0.75;

    // Validación de Inclinación: Cabeza recta
    bool isHeadStraight = rotZ != null && rotZ.abs() < 15;

    bool currentCondition = false;
    String validationError = "";

    if (!isDistanceOk) {
      validationError = faceWidthRatio < 0.35
          ? "Acércate más a la cámara"
          : "Aléjate un poco";
    } else if (!isHeadStraight) {
      validationError = "Mantén tu cabeza derecha";
    } else {
      // Solo validar que esté centrado y recto (sin validar rotación lateral)
      switch (_currentStep) {
        case FaceStep.center:
          currentCondition = true; // Solo frente, sin validar rotY
          break;
        default:
          break;
      }
    }

    if (mounted) {
      setState(() {
        _errorMessage = validationError;
      });
    }

    if (currentCondition && validationError.isEmpty) {
      if (!_isConditionMet) {
        setState(() => _isConditionMet = true);
      }
      _startStepTimer(() {
        // La foto ya se capturó en _startStepTimer
        setState(() {
          switch (_currentStep) {
            case FaceStep.center:
              _progress = 1.0;
              _currentStep = FaceStep.completed;
              _instruction = "¡Verificación Completada!";
              _finishVerification();
              break;
            default:
              break;
          }
          _stepProgress = 0.0;
          _isConditionMet = false;
        });
      });
    } else {
      if (_isConditionMet) {
        setState(() => _isConditionMet = false);
      }
      _resetStepTimer();
    }
  }

  void _finishVerification() {
    // Capturar la última foto solo si no hemos alcanzado el límite (1 foto de frente)
    if (_capturedPhotos.length < 1) {
      _capturePhoto();
    }

    // Animación de éxito final con Confeti Rive
    if (_confettiController != null) {
      _confettiController!.isActive = true;
    }

    HapticFeedback.heavyImpact();

    // Esperar un poco para mostrar la animación de éxito
    Timer(const Duration(milliseconds: 2500), () async {
      if (!mounted) return;

      // Obtener datos OCR (de widget o de localStorage)
      Map<String, String>? data;
      if (widget.ocrData != null) {
        data = Map<String, String>.from(widget.ocrData!);
      } else {
        // Intentar obtener de localStorage si no vienen en widget
        final pendingData = await getPendingOcrData();
        if (pendingData != null) {
          data = Map<String, String>.from(
            pendingData.map((key, value) => MapEntry(key, value.toString())),
          );
        }
      }

      // Validación final: mostrar advertencia si faltan datos críticos pero permitir continuar
      if (data != null) {
        final ci = data['ci'] ?? '';
        final nombres = data['nombres'] ?? '';

        if (ci.isEmpty || nombres.isEmpty) {
          debugPrint('⚠️ Advertencia: Algunos datos del OCR están vacíos');
          debugPrint('   CI: ${ci.isEmpty ? "FALTA" : "OK"}');
          debugPrint('   Nombres: ${nombres.isEmpty ? "FALTA" : "OK"}');
          // Mostrar mensaje informativo pero permitir continuar
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  ci.isEmpty && nombres.isEmpty
                      ? 'Algunos datos no se detectaron. Podrás completarlos en el formulario.'
                      : ci.isEmpty
                      ? 'El CI no se detectó. Podrás ingresarlo manualmente.'
                      : 'Los nombres no se detectaron. Podrás ingresarlos manualmente.',
                ),
                backgroundColor: Colors.orangeAccent,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }

        // Pasar todos los datos al formulario de registro (aunque estén vacíos)
        if (mounted) {
          context.push('/registration-form', extra: data);
        }
      } else {
        // Si no hay datos, crear estructura vacía y continuar
        debugPrint(
          '⚠️ No se encontraron datos OCR, continuando con datos vacíos',
        );
        if (mounted) {
          context.push(
            '/registration-form',
            extra: {
              'nombres': '',
              'apellidos': '',
              'ci': '',
              'ciFromInitial': 'false',
              'fechaEmision': '',
              'fechaExpiracion': '',
              'combinedCiPath': '',
            },
          );
        }
      }
    });
  }

  void _stopCameraStream() {
    debugPrint("🛑 Deteniendo stream de cámara por timeouts excesivos");
    _cameraController?.stopImageStream();
    _isProcessingPaused = true;
    _consecutiveTimeouts = 0; // Reset para posible reinicio manual
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    _flashController.dispose();
    _headRotationController.dispose();
    _arrowController.dispose();
    _checkAnimationController?.dispose();
    _confettiController?.dispose();
    _shapesController?.dispose();
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color whiteBg = Color(0xFFF6F8FB);
    const Color textDark = Color(0xFF1A3A5C);

    // Hacer el layout responsive
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenHeight < 700;

    // Tamaños responsive
    final previewWidth = (screenWidth * 0.7).clamp(200.0, 280.0);
    final previewHeight = (previewWidth * 1.3).clamp(260.0, 360.0);
    final fontSize = isSmallScreen ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: whiteBg,
      body: Stack(
        children: [
          // Fondo Rive Animado (Ambiental)
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: RiveAnimation.asset(
                'assets/RiveAssets/shapes.riv',
                fit: BoxFit.cover,
                controllers: [_shapesController!],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  whiteBg.withOpacity(0.8),
                  whiteBg.withOpacity(0.9),
                  primaryBlue.withOpacity(0.1),
                  primaryBlue.withOpacity(0.15),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Color(0xFF1A3A5C),
                          ),
                          onPressed: () => context.pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Verificación de Identidad',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A3A5C),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Mensaje de preparación durante el delay inicial
                  if (!_isInitialDelayComplete)
                    FadeInDown(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: primaryBlue.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primaryBlue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Preparando cámara...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Cabeza animada arriba que indica la dirección
                  if (_isInitialDelayComplete)
                    FadeInDown(
                      child: _AnimatedHeadIndicatorWidget(
                        currentStep: _currentStep,
                        headRotationAnimation: _headRotationAnimation,
                        size: isSmallScreen ? 50.0 : 60.0,
                      ),
                    ),

                  SizedBox(height: _isInitialDelayComplete ? 20 : 10),

                  FadeInDown(
                    child: Column(
                      children: [
                        // Instrucción con animación
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                          child: Text(
                            _instruction,
                            key: ValueKey(_instruction),
                            style: TextStyle(
                              fontSize: fontSize + 2,
                              fontWeight: FontWeight.w800,
                              color: _isConditionMet
                                  ? Colors.green
                                  : const Color(0xFF1A3A5C),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Contador de fotos capturadas
                        if (_capturedPhotos.isNotEmpty)
                          FadeIn(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.camera_alt,
                                    size: 14,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_capturedPhotos.length}/1 foto',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        // Indicador de Rostro Detectado con animación
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Row(
                            key: ValueKey(_isFaceDetected),
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  _isFaceDetected
                                      ? Icons.face
                                      : Icons.face_outlined,
                                  size: 16,
                                  color: _isFaceDetected
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _errorMessage.isNotEmpty
                                    ? _errorMessage
                                    : (_isFaceDetected
                                          ? "Rostro detectado"
                                          : "Buscando rostro..."),
                                style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      _errorMessage.contains("Solo") ||
                                          _errorMessage.contains("Acércate") ||
                                          _errorMessage.contains("Aléjate") ||
                                          _errorMessage.contains("Mantén")
                                      ? Colors.orangeAccent
                                      : (_isFaceDetected
                                            ? Colors.green
                                            : Colors.grey),
                                  fontWeight: _errorMessage.isNotEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Barra de progreso del paso actual
                        if (_isConditionMet && _stepProgress > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            width: 200,
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(2),
                              color: Colors.grey[200],
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _stepProgress,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [Colors.green, Colors.greenAccent],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 40),

                  // Radar / Camera Preview (FORMA DE CARA HUMANA)
                  Expanded(
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Efecto de flash cuando se captura
                          AnimatedBuilder(
                            animation: _flashController,
                            builder: (context, child) {
                              return _showFlash
                                  ? Container(
                                      width: previewWidth + 20,
                                      height: previewHeight + 20,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(
                                          _flashController.value * 0.8,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),

                          // Animación de éxito mejorada con Rive
                          AnimatedBuilder(
                            animation: _successScaleAnimation,
                            builder: (context, child) {
                              return _showSuccessAnimation
                                  ? Transform.scale(
                                      scale: _successScaleAnimation.value,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            colors: [
                                              Colors.green.withOpacity(0.9),
                                              Colors.greenAccent.withOpacity(
                                                0.7,
                                              ),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.green.withOpacity(
                                                0.5,
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            // Animación Rive de check
                                            SizedBox(
                                              width: 80,
                                              height: 80,
                                              child: RiveAnimation.asset(
                                                'assets/RiveAssets/check.riv',
                                                controllers: [
                                                  if (_checkAnimationController !=
                                                      null)
                                                    _checkAnimationController!,
                                                ],
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            // Fallback con icono si Rive no carga
                                            if (_checkAnimationController ==
                                                null)
                                              const Icon(
                                                Icons.check_circle,
                                                color: Colors.white,
                                                size: 70,
                                              ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            },
                          ),

                          // Radar Oval Background con efecto Glassmorphism
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _isConditionMet
                                    ? _pulseAnimation.value
                                    : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: previewWidth,
                                  height: previewHeight,
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(
                                      Radius.elliptical(130, 170),
                                    ),
                                    border: Border.all(
                                      color: _isConditionMet
                                          ? Colors.green.withOpacity(0.8)
                                          : primaryBlue.withOpacity(0.15),
                                      width: _isConditionMet ? 8 : 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isConditionMet
                                                    ? Colors.green
                                                    : primaryBlue)
                                                .withOpacity(0.1),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          // Progress Indicators (OVALADOS con CustomPainter)
                          SizedBox(
                            width: previewWidth + 10,
                            height: previewHeight + 10,
                            child: CustomPaint(
                              painter: _OvalProgressPainter(
                                progress: _progress,
                                stepProgress: _stepProgress,
                                color: primaryBlue,
                                accentColor: _isConditionMet
                                    ? Colors.greenAccent
                                    : primaryBlue,
                              ),
                            ),
                          ),

                          // Camera Preview (CLIP OVALADO) con animación mejorada
                          ClipPath(
                            clipper: _FaceClipper(),
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _isConditionMet
                                      ? 1.0 +
                                            (_pulseAnimation.value - 1.0) * 0.05
                                      : 1.0,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: previewWidth - 10,
                                    height: previewHeight - 10,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: _isConditionMet
                                          ? [
                                              BoxShadow(
                                                color: Colors.green.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 15,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child:
                                        (_cameraController != null &&
                                            _cameraController!
                                                .value
                                                .isInitialized)
                                        ? Center(
                                            child: AspectRatio(
                                              aspectRatio:
                                                  1 / 1.32, // Ratio ovoidal
                                              child: FittedBox(
                                                fit: BoxFit.cover,
                                                child: SizedBox(
                                                  width:
                                                      _cameraController!
                                                          .value
                                                          .previewSize
                                                          ?.height ??
                                                      1,
                                                  height:
                                                      _cameraController!
                                                          .value
                                                          .previewSize
                                                          ?.width ??
                                                      1,
                                                  child: CameraPreview(
                                                    _cameraController!,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(color: Colors.black12),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Efecto de partículas cuando se completa un paso
                          if (_showSuccessAnimation)
                            ...List.generate(8, (index) {
                              return _ParticleWidget(
                                index: index,
                                controller: _successController,
                              );
                            }),

                          // Overlay con transparencia cuando no se cumple la condición
                          if (!_isConditionMet &&
                              _currentStep != FaceStep.completed)
                            ClipPath(
                              clipper: _FaceClipper(),
                              child: Container(
                                width: previewWidth - 10,
                                height: previewHeight - 10,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),

                          // Scanning Effect (Scanner line)
                          if (_currentStep != FaceStep.completed &&
                              !_isConditionMet)
                            _ScannerLineAnimation(
                              width: previewWidth - 10,
                              height: previewHeight - 10,
                            ),

                          // Flechas dinámicas que indican la dirección
                          if (_currentStep != FaceStep.completed &&
                              !_isConditionMet)
                            _DirectionalArrowsWidget(
                              currentStep: _currentStep,
                              arrowAnimation: _arrowAnimation,
                              isConditionMet: _isConditionMet,
                              previewWidth: previewWidth,
                              previewHeight: previewHeight,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Passos
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                      vertical: isSmallScreen ? 20 : 40,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StepIndicator(
                          active: _currentStep == FaceStep.center,
                          done: _currentStep == FaceStep.completed,
                          label: "Frente",
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 10 : 20),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: _currentStep == FaceStep.completed
                  ? RiveAnimation.asset(
                      'assets/RiveAssets/confetti.riv',
                      fit: BoxFit.cover,
                      controllers: [_confettiController!],
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatefulWidget {
  final bool active;
  final bool done;
  final String label;

  const _StepIndicator({
    required this.active,
    required this.done,
    required this.label,
  });

  @override
  State<_StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<_StepIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _wasDone = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _wasDone = widget.done;
  }

  @override
  void didUpdateWidget(_StepIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.done && !_wasDone) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      _wasDone = true;
    } else if (!widget.done) {
      _wasDone = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    return Column(
      children: [
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.done && widget.active ? _scaleAnimation.value : 1.0,
              child: Container(
                decoration: widget.done
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  widget.done ? Icons.check_circle : Icons.circle_outlined,
                  color: widget.done
                      ? Colors.green
                      : (widget.active ? primaryBlue : Colors.grey),
                  size: 28,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 12,
            fontWeight: widget.active ? FontWeight.bold : FontWeight.normal,
            color: widget.active
                ? (widget.done ? Colors.green : primaryBlue)
                : Colors.grey,
          ),
          child: Text(widget.label),
        ),
      ],
    );
  }
}

class _FaceClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _getHeadPath(size);
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _OvalProgressPainter extends CustomPainter {
  final double progress;
  final double stepProgress;
  final Color color;
  final Color accentColor;

  _OvalProgressPainter({
    required this.progress,
    required this.stepProgress,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Usamos la misma ruta para el contorno
    Path path = _getHeadPath(size);

    // 1. Sombras y brillos externos (Efecto cristal)
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.05)
        ..style = PaintingStyle.fill,
    );

    // 2. Borde base (Gris elegante)
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // 3. Guía visual "Dashed" para indicar dónde poner el rostro (Visible si no hay progreso de paso)
    if (stepProgress == 0 && progress < 1.0) {
      _drawDashedPath(
        canvas,
        path,
        Paint()
          ..color = Colors.white.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    //Fondo aazul parametrizado
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      // 4. Progreso General (Azul suave)
      final extractGeneral = metric.extractPath(0, metric.length * progress);
      canvas.drawPath(
        extractGeneral,
        Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );

      // 5. Progreso de Estabilidad (Verde neón/Azul brillante)
      if (stepProgress > 0) {
        final extractStep = metric.extractPath(0, metric.length * stepProgress);
        canvas.drawPath(
          extractStep,
          Paint()
            ..color = accentColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..strokeCap = StrokeCap.round
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.solid,
              4,
            ), // Efecto de brillo
        );
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    Path dashPath = Path();
    double dashWidth = 10.0;
    double dashSpace = 5.0;
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_OvalProgressPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.stepProgress != stepProgress;
}

// ... _ParticleWidget ...
class _ParticleWidget extends StatelessWidget {
  final int index;
  final AnimationController controller;

  const _ParticleWidget({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    final colors = [
      Colors.green,
      Colors.greenAccent,
      Colors.lightGreen,
      Colors.white,
    ];

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final angle = (index * 45.0) * (math.pi / 180.0);
        final distance = 120.0 * controller.value;
        final x = distance * math.cos(angle);
        final y = distance * math.sin(angle);
        final opacity = 1.0 - controller.value;
        final scale = 1.2 - controller.value * 1.0;

        return Positioned(
          left: 140 + x - 5,
          top: 180 + y - 5,
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ... _ScannerLineAnimation ...
class _ScannerLineAnimation extends StatefulWidget {
  final double width;
  final double height;

  const _ScannerLineAnimation({required this.width, required this.height});

  @override
  State<_ScannerLineAnimation> createState() => _ScannerLineAnimationState();
}

class _ScannerLineAnimationState extends State<_ScannerLineAnimation>
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
      builder: (context, child) {
        return Positioned(
          top: widget.height * _controller.value,
          child: Opacity(
            opacity: 0.8,
            child: Container(
              width: widget.width,
              height: 4,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4FC3F7).withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF4FC3F7),
                    const Color(0xFF305BA4),
                    const Color(0xFF4FC3F7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ... _AnimatedHeadIndicatorWidget ...
class _AnimatedHeadIndicatorWidget extends StatelessWidget {
  final FaceStep currentStep;
  final Animation<double> headRotationAnimation;
  final double size;

  const _AnimatedHeadIndicatorWidget({
    required this.currentStep,
    required this.headRotationAnimation,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    double baseRotation = 0.0;
    IconData icon = Icons.face;
    Color color = const Color(0xFF305BA4);
    Widget? arrowWidget;

    switch (currentStep) {
      case FaceStep.center:
        baseRotation = 0.0;
        icon = Icons.face_retouching_natural;
        color = const Color(0xFF305BA4);
        break;
      case FaceStep.completed:
        baseRotation = 0.0;
        icon = Icons.verified_user_rounded;
        color = Colors.green;
        break;
    }

    return AnimatedBuilder(
      animation: headRotationAnimation,
      builder: (context, child) {
        final dynamicRotation =
            baseRotation + (headRotationAnimation.value * 0.4);

        return Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: dynamicRotation,
              child: Container(
                padding: EdgeInsets.all(size * 0.25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(icon, size: size, color: color),
              ),
            ),
            if (arrowWidget != null) arrowWidget,
          ],
        );
      },
    );
  }
}

// ... _DirectionalArrowsWidget ...
class _DirectionalArrowsWidget extends StatelessWidget {
  final FaceStep currentStep;
  final Animation<double> arrowAnimation;
  final bool isConditionMet;
  final double previewWidth;
  final double previewHeight;

  const _DirectionalArrowsWidget({
    required this.currentStep,
    required this.arrowAnimation,
    required this.isConditionMet,
    required this.previewWidth,
    required this.previewHeight,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStep == FaceStep.completed || isConditionMet) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: arrowAnimation,
      builder: (context, child) {
        final offset = arrowAnimation.value * 15;
        final centerY = previewHeight / 2;

        switch (currentStep) {
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

//SECCION DE FUNCIONES DE LA CARA AUXILIARES
Path _getHeadPath(Size size) {
  Path path = Path();
  double w = size.width;
  double h = size.height;

  // Silueta de rostro más definida (Hombros + Cabeza mejorada)
  path.moveTo(w * 0.5, h * 0.05); // Frente (Top)

  // Lado Derecho
  path.cubicTo(
    w * 0.9,
    h * 0.05, // P1: Esquina superior derecha curva
    w * 0.95,
    h * 0.3, // P2: Lado derecho de la cara
    w * 0.92,
    h * 0.55, // Destino: Mandíbula/Mejilla derecha
  );
  path.quadraticBezierTo(
    w * 0.9,
    h * 0.75, // Control: Inclinación hacia cuello
    w * 0.7,
    h * 0.85, // Destino: Inicio cuello derecho
  );

  // Hombro Derecho (apertura)
  path.quadraticBezierTo(w * 0.85, h * 0.95, w * 0.9, h * 1.0);

  // Base (cortada por el frame)
  path.lineTo(w * 0.1, h * 1.0);

  // Hombro Izquierdo (cierre)
  path.quadraticBezierTo(
    w * 0.15,
    h * 0.95,
    w * 0.3,
    h * 0.85, // Inicio cuello izquierdo
  );

  // Lado Izquierdo
  path.quadraticBezierTo(
    w * 0.1,
    h * 0.75, // Control
    w * 0.08,
    h * 0.55, // Destino: Mandíbula/Mejilla izquierda
  );

  path.cubicTo(
    w * 0.05,
    h * 0.3, // P1
    w * 0.1,
    h * 0.05, // P2
    w * 0.5,
    h * 0.05, // Cierre en Frente
  );

  path.close();
  return path;
}
