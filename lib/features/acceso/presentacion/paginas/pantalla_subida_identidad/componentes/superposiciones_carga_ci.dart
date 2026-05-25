import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

class FlipCardAnimation extends StatefulWidget {
  const FlipCardAnimation({super.key});

  @override
  State<FlipCardAnimation> createState() => _FlipCardAnimationState();
}

class _FlipCardAnimationState extends State<FlipCardAnimation>
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
        builder: (ctx, hijo) {
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

class ScanningAnimation extends StatefulWidget {
  const ScanningAnimation({super.key});

  @override
  State<ScanningAnimation> createState() => _ScanningAnimationState();
}

class _ScanningAnimationState extends State<ScanningAnimation>
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
      builder: (ctx, hijo) {
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

class PremiumOcrLoader extends StatefulWidget {
  final String? message;

  const PremiumOcrLoader({super.key, this.message});

  @override
  State<PremiumOcrLoader> createState() => _PremiumOcrLoaderState();
}

class _PremiumOcrLoaderState extends State<PremiumOcrLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  String _currentDynamicStatus = 'Analizando datos...';
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _opacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    final statuses = [
      'Detectando bordes...',
      'Localizando datos...',
      'Leyendo OCR...',
      'Extrayendo nombres...',
      'Verificando validez...',
    ];
    int index = 0;
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _currentDynamicStatus = statuses[index % statuses.length];
          index++;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF005BAC).withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, hijo) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Opacity(
                        opacity: _opacityAnimation.value,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF005BAC), Color(0xFF3D8FE0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF005BAC).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.document_scanner_rounded,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF005BAC),
                  ),
                  backgroundColor: const Color(0xFF005BAC).withOpacity(0.1),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.message ?? 'Procesando...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _currentDynamicStatus,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF005BAC).withOpacity(0.8),
                  fontFamily: 'Intel',
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, hijo) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final delay = index * 0.2;
                      final value = (_controller.value - delay) % 1.0;
                      final opacity = (value < 0.5)
                          ? (value * 2)
                          : (2 - value * 2);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF005BAC,
                          ).withOpacity(opacity.clamp(0.2, 1.0)),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IDUploadOverlays {
  static Widget pickerOptions({
    required BuildContext context,
    required bool isFront,
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color darkBlue = Color(0xFF1A3A5C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isFront ? 'Subir Anverso' : 'Subir Reverso',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Incluso si el sistema falla, podrás editar los datos manualmente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _pickerItem(
                  icon: Icons.camera_alt_rounded,
                  label: 'Cámara',
                  color: primaryBlue,
                  onTap: onCamera,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _pickerItem(
                  icon: Icons.photo_library_rounded,
                  label: 'Galería',
                  color: Colors.orange,
                  onTap: onGallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  static Widget _pickerItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

