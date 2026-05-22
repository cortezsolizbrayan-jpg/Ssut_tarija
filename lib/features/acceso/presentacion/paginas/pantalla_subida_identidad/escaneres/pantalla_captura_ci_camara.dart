import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pantalla de cámara con marco tipo BlinkID para capturar anverso/reverso del carnet.
/// Retorna la ruta del archivo capturado al hacer pop.
class IdCaptureCameraPantalla extends StatefulWidget {
  /// true = anverso, false = reverso
  final bool isFront;

  const IdCaptureCameraPantalla({super.key, required this.isFront});

  @override
  State<IdCaptureCameraPantalla> createState() => _IdCaptureCameraPantallaState();
}

class _IdCaptureCameraPantallaState extends State<IdCaptureCameraPantalla> {
  CameraController? _controller;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _errorMessage;

  static const Color _primaryBlue = Color(0xFF305BA4);

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Se necesita permiso de cámara para capturar el carnet.';
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
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      debugPrint('IdCaptureCamera error: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'No se pudo iniciar la cámara. Reintenta.';
        });
      }
    }
  }

  Future<void> _capture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      HapticFeedback.mediumImpact();
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(file.path);
    } catch (e) {
      debugPrint('Capture error: $e');
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al capturar: $e')));
      }
    } finally {
      if (mounted) _isCapturing = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_errorMessage != null)
              Center(
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
                      TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                        label: const Text(
                          'Cerrar',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isInitialized && _controller != null)
              _buildCameraPreview()
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        widget.isFront
                            ? 'Captura el anverso del carnet'
                            : 'Captura el reverso del carnet',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            // Marco tipo BlinkID + instrucción
            if (_isInitialized && _errorMessage == null) _buildOverlay(),
            // Botón capturar
            if (_isInitialized && _errorMessage == null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 32,
                child: Center(
                  child: Material(
                    color: _isCapturing ? Colors.grey : _primaryBlue,
                    shape: const CircleBorder(),
                    elevation: 8,
                    child: InkWell(
                      onTap: _isCapturing ? null : _capture,
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 72,
                        height: 72,
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _controller!.value.previewSize?.height ?? 1,
        height: _controller!.value.previewSize?.width ?? 1,
        child: CameraPreview(_controller!),
      ),
    );
  }

  Widget _buildOverlay() {
    return IgnorePointer(
      child: Column(
        children: [
          const SizedBox(height: 100),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.586, // ID card ratio
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
            child: Text(
              widget.isFront
                  ? 'Coloca el anverso del carnet dentro del marco'
                  : 'Coloca el reverso del carnet dentro del marco',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.7), blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


