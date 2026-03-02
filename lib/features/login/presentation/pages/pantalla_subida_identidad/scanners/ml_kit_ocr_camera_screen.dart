import 'dart:async';
import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pantalla de cámara mejorada para ML Kit OCR con captura automática
/// cuando el carnet está bien posicionado en el marco.
class MlKitOcrCameraScreen extends StatefulWidget {
  /// true = anverso, false = reverso
  final bool isFront;
  /// Si true (reverso), muestra botón "Omitir reverso"
  final bool showSkipButton;

  const MlKitOcrCameraScreen({
    super.key,
    required this.isFront,
    this.showSkipButton = false,
  });

  @override
  State<MlKitOcrCameraScreen> createState() => _MlKitOcrCameraScreenState();
}

class _MlKitOcrCameraScreenState extends State<MlKitOcrCameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  // Detección automática
  bool _isDocumentDetected = false;
  int _stableFrames = 0;
  Timer? _autoCapturTimer;
  bool _hasAutoCapture = false;
  bool _isCurrentlyStable = false;
  bool _isUnstable = false;
  int _unstableTicks = 0;
  Uint8List? _lastYPlane;
  bool _showShutter = false;

  // Animaciones
  late AnimationController _frameAnimController;
  late AnimationController _pulseAnimController;
  late AnimationController _instructionAnimController;
  late AnimationController _scanLineAnimController;
  late AnimationController _shimmerAnimController;
  late AnimationController _successOverlayController;
  late Animation<double> _frameScaleAnim;
  late Animation<double> _pulseAnim;
  late Animation<double> _instructionOpacityAnim;
  late Animation<double> _scanLineOffsetAnim;
  late Animation<double> _shimmerAnim;
  late Animation<double> _successScaleAnim;
  late Animation<double> _successOpacityAnim;

  // Colores
  static const Color _primaryBlue = Color(0xFF305BA4);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _warningOrange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
  }

  /// Frames necesarios para considerar "documento detectado" (más = más tiempo para acomodar)
  /// Bajamos a 2 para detectar más rápido cuando el carnet ya está bien colocado.
  static const int _framesToDetect = 2;
  /// Frames necesarios para captura automática (más = más tiempo para el usuario)
  /// Bajamos a 5 para que la captura llegue en ~2.5s si está estable.
  static const int _framesToCapture = 5;
  /// Intervalo del timer (ms) — más lento = más tiempo entre cada "tick"
  /// Reducido para que el progreso avance más rápido.
  static const int _timerIntervalMs = 500;
  /// Ticks inestables antes de marcar el estado en rojo
  /// Aumentado para no castigar tanto pequeños movimientos.
  static const int _unstableTicksThreshold = 8;
  /// Umbral de movimiento promedio entre frames (0-255) para considerar estable
  /// Aumentado para tolerar micro-movimientos del usuario.
  static const int _motionThreshold = 12;

  void _initAnimations() {
    // Animación del marco (más lenta para que el usuario acomode bien)
    _frameAnimController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    );
    _frameScaleAnim = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _frameAnimController, curve: Curves.easeInOut),
    );
    _frameAnimController.repeat(reverse: true);

    // Animación de pulso cuando detecta documento (más lenta)
    _pulseAnimController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseAnimController, curve: Curves.easeInOut),
    );

    // Animación de instrucciones (fade in más lento)
    _instructionAnimController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _instructionOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _instructionAnimController,
        curve: Curves.easeInOut,
      ),
    );
    _instructionAnimController.forward();

    // Línea de escaneo que recorre el marco (ida y vuelta, más fluida)
    _scanLineAnimController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _scanLineOffsetAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanLineAnimController,
        curve: Curves.easeInOut,
      ),
    );
    _scanLineAnimController.repeat(reverse: true);

    // Shimmer en el borde cuando se detecta documento
    _shimmerAnimController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shimmerAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shimmerAnimController,
        curve: Curves.easeInOut,
      ),
    );

    // Overlay de éxito (escala + opacidad)
    _successOverlayController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _successScaleAnim = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _successOverlayController,
        curve: Curves.elasticOut,
      ),
    );
    _successOpacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _successOverlayController,
        curve: Curves.easeOut,
      ),
    );
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Se necesita permiso de cámara para escanear el carnet.';
        });
      }
      return;
    }

    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      
      if (!mounted) return;

      // Iniciar stream de imágenes para medir estabilidad (movimiento)
      try {
        await _controller!.startImageStream(_onImageAvailable);
      } catch (e) {
        debugPrint('No se pudo iniciar imageStream: $e');
      }
      
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });

      _scanLineAnimController.repeat();
      // Iniciar detección automática
      _startAutoDetection();
    } catch (e) {
      debugPrint('MlKitOcrCamera error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la cámara. Reintenta.';
        });
      }
    }
  }

  void _startAutoDetection() {
    _autoCapturTimer = Timer.periodic(
      const Duration(milliseconds: _timerIntervalMs),
      (timer) {
        if (!mounted || _isCapturing || _hasAutoCapture) {
          timer.cancel();
          return;
        }

        if (_controller != null && _controller!.value.isInitialized) {
          setState(() {
            // Si el frame actual es estable (poco movimiento), acumulamos "frames estables"
            if (_isCurrentlyStable && !_isCapturing) {
              _stableFrames++;
              _unstableTicks = 0;
            } else {
              // Si hay movimiento, en lugar de resetear a 0, vamos descontando poco a poco.
              // Así no se pierde todo el progreso por un pequeño temblor de mano.
              if (_stableFrames > 0) {
                _stableFrames =
                    (_stableFrames - 1).clamp(0, _framesToCapture);
              }
              _unstableTicks++;
            }

            // Si hay demasiados ticks inestables sin captura, marcamos estado rojo
            _isUnstable = !_isCurrentlyStable &&
                !_hasAutoCapture &&
                _unstableTicks >= _unstableTicksThreshold;
            
            // Documento "detectado" después de más frames (más tiempo para acomodar)
            if (_stableFrames >= _framesToDetect &&
                !_isDocumentDetected &&
                !_isUnstable) {
              _isDocumentDetected = true;
              _isUnstable = false;
              _unstableTicks = 0;
              _pulseAnimController.repeat(reverse: true);
              _shimmerAnimController.repeat(reverse: true);
              HapticFeedback.lightImpact();
            }
            
            // Captura automática después de más frames (~8 s para que acomode bien)
            if (_stableFrames >= _framesToCapture && !_hasAutoCapture) {
              _hasAutoCapture = true;
              _autoCapture();
            }
          });
        }
      },
    );
  }

  /// Procesa cada frame de la cámara para estimar si el carnet se mantiene
  /// relativamente quieto (estable) o se está moviendo demasiado.
  void _onImageAvailable(CameraImage image) {
    if (!mounted || _isCapturing) return;
    try {
      final plane = image.planes.first;
      final bytes = plane.bytes;

      if (_lastYPlane != null && _lastYPlane!.length == bytes.length) {
        // Muestreamos una fracción de píxeles para estimar el movimiento
        final length = bytes.length;
        int step = (length / 800).floor(); // ~800 muestras máx
        if (step < 1) step = 1;

        int diffSum = 0;
        int samples = 0;

        for (int i = 0; i < length; i += step) {
          final current = bytes[i];
          final previous = _lastYPlane![i];
          diffSum += (current - previous).abs();
          samples++;
        }

        final avgDiff = samples == 0 ? 0.0 : diffSum / samples;
        final nowStable = avgDiff < _motionThreshold;

        if (nowStable != _isCurrentlyStable) {
          setState(() {
            _isCurrentlyStable = nowStable;
          });
        }
      }

      _lastYPlane = Uint8List.fromList(bytes);
    } catch (e) {
      debugPrint('MlKitOcrCamera motion error: $e');
    }
  }

  Future<void> _autoCapture() async {
    if (_isCapturing) return;
    
    setState(() {
      _isCapturing = true;
      _showShutter = true;
    });
    
    // Feedback visual y háptico
    HapticFeedback.mediumImpact();
    
    // Quitar shutter tras 100ms
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showShutter = false);
    });

    _pulseAnimController.stop();
    _frameAnimController.stop();
    
    try {
      // Detener stream de imágenes antes de tomar la foto
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      await Future.delayed(const Duration(milliseconds: 300));
      final XFile file = await _controller!.takePicture();
      
      if (!mounted) return;
      
      // Animación de éxito antes de cerrar
      await _showSuccessAnimation();
      
      if (mounted) {
        Navigator.of(context).pop(file.path);
      }
    } catch (e) {
      debugPrint('Auto capture error: $e');
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _hasAutoCapture = false;
          _isDocumentDetected = false;
          _stableFrames = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al capturar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _showSuccessAnimation() async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    await _successOverlayController.forward().orCancel;
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 350));
  }

  Future<void> _manualCapture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _showShutter = true;
    });
    
    try {
      HapticFeedback.mediumImpact();
      // Quitar shutter tras 100ms
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _showShutter = false);
      });
      // Detener stream de imágenes antes de tomar la foto
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      final XFile file = await _controller!.takePicture();
      
      if (!mounted) return;
      
      await _showSuccessAnimation();
      
      if (mounted) {
        Navigator.of(context).pop(file.path);
      }
    } catch (e) {
      debugPrint('Manual capture error: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al capturar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _autoCapturTimer?.cancel();
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        _controller!.stopImageStream();
      }
    } catch (_) {}
    _frameAnimController.dispose();
    _pulseAnimController.dispose();
    _instructionAnimController.dispose();
    _scanLineAnimController.dispose();
    _shimmerAnimController.dispose();
    _successOverlayController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameWidth = size.width * 0.85;
    final frameHeight = frameWidth * 0.63; // Proporción estándar de tarjeta ID

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Vista previa de cámara
            if (_isInitialized && _controller != null)
              Center(
                child: CameraPreview(_controller!),
              )
            else if (_errorMessage != null)
              _buildErrorView()
            else
              _buildLoadingView(),

            // Overlay oscuro con recorte para el marco
            if (_isInitialized)
              CustomPaint(
                painter: _FrameOverlayPainter(
                  frameWidth: frameWidth,
                  frameHeight: frameHeight,
                  isDetected: _isDocumentDetected,
                ),
                child: Container(),
              ),

            // Marco animado del documento con entrada suave
            if (_isInitialized)
              FadeInDown(
                duration: const Duration(milliseconds: 700),
                child: Center(
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _isDocumentDetected ? _pulseAnim : _frameScaleAnim,
                      if (_isDocumentDetected) ...[_shimmerAnim],
                    ]),
                    builder: (context, child) {
                      final scale = _isDocumentDetected
                          ? _pulseAnim.value
                          : _frameScaleAnim.value;
                      final shimmerOpacity = _isDocumentDetected
                          ? 0.3 + 0.4 * _shimmerAnim.value
                          : 0.0;
                      final frameColor = _isUnstable
                          ? Colors.redAccent
                          : (_isDocumentDetected
                              ? _successGreen
                              : _warningOrange);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: frameWidth,
                          height: frameHeight,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: frameColor,
                              width: _isDocumentDetected ? 4 : 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: frameColor.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                              if (_isDocumentDetected)
                                BoxShadow(
                                  color: _successGreen.withOpacity(shimmerOpacity),
                                  blurRadius: 16,
                                  spreadRadius: 0,
                                ),
                            ],
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: Stack(
                            children: [
                              // Relleno verde progresivo dentro del marco mientras se mantiene estable
                              if (_isDocumentDetected && !_isCapturing)
                                _buildFrameFillProgress(),
                              _buildCornerMarkers(frameColor),
                              // Línea de escaneo animada
                              if (!_isCapturing)
                                AnimatedBuilder(
                                  animation: _scanLineOffsetAnim,
                                  builder: (context, child) {
                                    final t = _scanLineOffsetAnim.value;
                                    return Positioned(
                                      left: 6,
                                      right: 6,
                                      top: 6 + (frameHeight - 28) * t,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.transparent,
                                              _primaryBlue.withOpacity(0.3),
                                              Colors.white,
                                              _primaryBlue.withOpacity(0.3),
                                              Colors.transparent,
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryBlue.withOpacity(0.7),
                                              blurRadius: 10,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Instrucciones animadas
            if (_isInitialized) _buildInstructions(frameHeight),

            // Indicador de progreso
            if (_isDocumentDetected && !_isCapturing)
              _buildProgressIndicator(),

            // Cuenta regresiva visual en los últimos segundos antes de la captura automática
            if (_isDocumentDetected && !_isCapturing)
              _buildCountdownOverlay(),

            // Botones de control
            if (_isInitialized) _buildControls(),

            // Overlay de captura
            if (_isCapturing) _buildCapturingOverlay(),

            // Efecto Shutter (Flash blanco)
            if (_showShutter)
              Container(
                color: Colors.white,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              label: const Text('Cerrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _frameScaleAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.9 + 0.15 * _frameScaleAnim.value,
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 3,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Iniciando cámara...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMarkers(Color color) {
    const length = 30.0;
    const thickness = 4.0;

    return Stack(
      children: [
        // Esquina superior izquierda
        Positioned(
          top: 0,
          left: 0,
          child: _CornerMarker(
            color: color,
            length: length,
            thickness: thickness,
            isTopLeft: true,
          ),
        ),
        // Esquina superior derecha
        Positioned(
          top: 0,
          right: 0,
          child: _CornerMarker(
            color: color,
            length: length,
            thickness: thickness,
            isTopRight: true,
          ),
        ),
        // Esquina inferior izquierda
        Positioned(
          bottom: 0,
          left: 0,
          child: _CornerMarker(
            color: color,
            length: length,
            thickness: thickness,
            isBottomLeft: true,
          ),
        ),
        // Esquina inferior derecha
        Positioned(
          bottom: 0,
          right: 0,
          child: _CornerMarker(
            color: color,
            length: length,
            thickness: thickness,
            isBottomRight: true,
          ),
        ),
      ],
    );
  }

  /// Relleno verde que va ocupando el marco a medida que se completa
  /// el tiempo de escaneo antes de la captura automática.
  Widget _buildFrameFillProgress() {
    // Progreso solo entre "detectado" y "captura"
    final totalFramesForFill =
        (_framesToCapture - _framesToDetect).clamp(1, 1000).toDouble();
    final framesAfterDetect = (_stableFrames - _framesToDetect).toDouble();
    final progress =
        (framesAfterDetect / totalFramesForFill).clamp(0.0, 1.0);

    return Positioned.fill(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: progress,
          widthFactor: 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  _successGreen.withOpacity(0.45),
                  _successGreen.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(double frameHeight) {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: FadeTransition(
        opacity: _instructionOpacityAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _isDocumentDetected
                        ? Icons.check_circle
                        : _isUnstable
                            ? Icons.warning_amber_rounded
                            : Icons.info,
                    color: _isDocumentDetected
                        ? _successGreen
                        : _isUnstable
                            ? Colors.redAccent
                            : _warningOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Text(
                        _isDocumentDetected
                            ? '¡Bien! Mantén el carnet estable un momento…'
                            : _isUnstable
                                ? 'Hay movimiento. Centra el carnet en el recuadro.'
                                : widget.isFront
                                    ? 'Coloca el ANVERSO del carnet en el marco'
                                    : 'Coloca el REVERSO del carnet en el marco',
                        key: ValueKey('$_isDocumentDetected-$_isUnstable'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isDocumentDetected && !_isUnstable) ...[
                const SizedBox(height: 8),
                Text(
                  'La foto se tomará sola cuando esté bien enfocado. También puedes usar "Capturar".',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ] else if (_isUnstable) ...[
                const SizedBox(height: 8),
                Text(
                  'Intenta sostener el celular y el carnet más estables.',
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.95),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalFramesForFill =
        (_framesToCapture - _framesToDetect).clamp(1, 1000).toDouble();
    final framesAfterDetect = (_stableFrames - _framesToDetect).toDouble();
    final progress =
        (framesAfterDetect / totalFramesForFill).clamp(0.0, 1.0);

    return Positioned(
      top: 140,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 220,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth * progress;
              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    width: w,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _successGreen,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: _successGreen.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Cuenta regresiva flotante (3, 2, 1) justo antes de la captura automática.
  Widget _buildCountdownOverlay() {
    // Solo considerar el tramo entre "detectado" y "captura"
    final totalFramesForFill =
        (_framesToCapture - _framesToDetect).clamp(1, 1000).toDouble();
    final framesAfterDetect = (_stableFrames - _framesToDetect).toDouble();
    final remainingFrames =
        (totalFramesForFill - framesAfterDetect).clamp(0.0, totalFramesForFill);

    final remainingSeconds =
        (remainingFrames * _timerIntervalMs / 1000).ceil();

    // Solo mostramos cuenta atrás en los últimos 3 segundos
    if (remainingSeconds <= 0 || remainingSeconds > 3) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 180,
      right: 24,
      child: ZoomIn(
        key: ValueKey('countdown_$remainingSeconds'),
        duration: const Duration(milliseconds: 400),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.7),
            border: Border.all(
              color: _successGreen,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _successGreen.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$remainingSeconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Cerrar
            Flexible(
              child: _ControlButton(
                icon: Icons.close,
                label: 'Cerrar',
                onTap: () => Navigator.of(context).pop(),
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            
            // Omitir reverso (solo en pantalla reverso)
            if (widget.showSkipButton && !_isCapturing) ...[
              const SizedBox(width: 8),
              Flexible(
                child: _ControlButton(
                  icon: Icons.skip_next,
                  label: 'Omitir',
                  onTap: () => Navigator.of(context).pop(),
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
            
            const SizedBox(width: 8),
            // Captura manual (botón principal con animación de pulso suave)
            if (!_isCapturing)
              Flexible(
                flex: 2,
                child: Pulse(
                  infinite: true,
                  duration: const Duration(milliseconds: 1800),
                  child: _ControlButton(
                    icon: Icons.camera,
                    label: 'Capturar',
                    onTap: _manualCapture,
                    color: _primaryBlue,
                    isPrimary: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapturingOverlay() {
    return AnimatedBuilder(
      animation: _successOverlayController,
      builder: (context, child) {
        final opacity = _successOpacityAnim.value;
        final scale = _successScaleAnim.value;
        return Container(
          color: Colors.black.withOpacity(0.4 * opacity),
          child: Center(
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _successGreen,
                      size: 88,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.isFront ? 'Anverso Capturado' : 'Reverso Capturado',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Procesando imagen...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
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

// CustomPainter para el overlay oscuro con recorte
class _FrameOverlayPainter extends CustomPainter {
  final double frameWidth;
  final double frameHeight;
  final bool isDetected;

  _FrameOverlayPainter({
    required this.frameWidth,
    required this.frameHeight,
    required this.isDetected,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final framePaint = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;

    // Dibujar overlay oscuro
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Recortar área del marco
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY),
        width: frameWidth,
        height: frameHeight,
      ),
      const Radius.circular(16),
    );
    canvas.drawRRect(frameRect, framePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FrameOverlayPainter oldDelegate) {
    return oldDelegate.isDetected != isDetected;
  }
}

// Widget para las marcas de las esquinas
class _CornerMarker extends StatelessWidget {
  final Color color;
  final double length;
  final double thickness;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  const _CornerMarker({
    required this.color,
    required this.length,
    required this.thickness,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thickness,
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.isTopLeft,
    required this.isTopRight,
    required this.isBottomLeft,
    required this.isBottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isTopLeft) {
      canvas.drawLine(Offset(0, thickness / 2), Offset(size.width, thickness / 2), paint);
      canvas.drawLine(Offset(thickness / 2, 0), Offset(thickness / 2, size.height), paint);
    } else if (isTopRight) {
      canvas.drawLine(Offset(0, thickness / 2), Offset(size.width, thickness / 2), paint);
      canvas.drawLine(
        Offset(size.width - thickness / 2, 0),
        Offset(size.width - thickness / 2, size.height),
        paint,
      );
    } else if (isBottomLeft) {
      canvas.drawLine(
        Offset(0, size.height - thickness / 2),
        Offset(size.width, size.height - thickness / 2),
        paint,
      );
      canvas.drawLine(Offset(thickness / 2, 0), Offset(thickness / 2, size.height), paint);
    } else if (isBottomRight) {
      canvas.drawLine(
        Offset(0, size.height - thickness / 2),
        Offset(size.width, size.height - thickness / 2),
        paint,
      );
      canvas.drawLine(
        Offset(size.width - thickness / 2, 0),
        Offset(size.width - thickness / 2, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}

// Widget para botones de control
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isPrimary ? 32 : 24,
          vertical: isPrimary ? 16 : 12,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isPrimary ? Colors.white : Colors.black87,
              size: isPrimary ? 24 : 20, // Reducir un poco el tamaño de iconos
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: isPrimary ? Colors.white : Colors.black87,
                  fontSize: isPrimary ? 16 : 13, // Reducir un poco el tamaño de fuente
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
