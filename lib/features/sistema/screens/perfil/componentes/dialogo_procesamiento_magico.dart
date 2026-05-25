import 'package:flutter/material.dart';
import 'datos_personales_validators.dart';

class DialogoProcesamientoMagico extends StatefulWidget {
  const DialogoProcesamientoMagico({super.key});

  @override
  State<DialogoProcesamientoMagico> createState() =>
      _DialogoProcesamientoMagicoState();
}

class _DialogoProcesamientoMagicoState extends State<DialogoProcesamientoMagico>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  int _currentStep = 0;
  final List<String> _steps = [
    '✨ Analizando imagen...',
    '🎨 Removiendo fondo...',
    '🖼️ Aplicando fondo institucional...',
    '✂️ Recortando y centrando...',
    '✅ Finalizando...',
  ];

  @override
  void initState() {
    super.initState();

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _sparkleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotateController);

    _animateSteps();
  }

  void _animateSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(Duration(milliseconds: i == 0 ? 500 : 1200));
      if (mounted) {
        setState(() => _currentStep = i);
      }
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_sparkleAnimation, _pulseAnimation]),
          builder: (context, hijo) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Opacity(
                opacity: 0.95,
                child: Card(
                  margin: const EdgeInsets.all(32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 20,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          DatosPersonalesConstants.primaryBlue.withOpacity(
                            0.05,
                          ),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _rotateAnimation,
                              builder: (context, hijo) {
                                return Transform.rotate(
                                  angle: _rotateAnimation.value * 2 * 3.14159,
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: SweepGradient(
                                        colors: [
                                          DatosPersonalesConstants.primaryBlue
                                              .withOpacity(0.1),
                                          DatosPersonalesConstants.primaryBlue,
                                          const Color(0xFF4CAF50),
                                          DatosPersonalesConstants.primaryBlue
                                              .withOpacity(0.1),
                                        ],
                                        stops: const [0.0, 0.3, 0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: DatosPersonalesConstants.primaryBlue
                                        .withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.auto_fix_high,
                                size: 32,
                                color: Color.lerp(
                                  DatosPersonalesConstants.primaryBlue,
                                  const Color(0xFF4CAF50),
                                  _sparkleAnimation.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        AnimatedBuilder(
                          animation: _sparkleAnimation,
                          builder: (context, hijo) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: [
                                    DatosPersonalesConstants.primaryBlue,
                                    Color.lerp(
                                      DatosPersonalesConstants.primaryBlue,
                                      const Color(0xFF4CAF50),
                                      _sparkleAnimation.value,
                                    )!,
                                    DatosPersonalesConstants.primaryBlue,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ).createShader(bounds);
                              },
                              child: const Text(
                                '✨ Procesando tu foto ✨',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.3),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            key: ValueKey<int>(_currentStep),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: DatosPersonalesConstants.primaryBlue
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: DatosPersonalesConstants.primaryBlue
                                    .withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _steps[_currentStep],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: DatosPersonalesConstants.primaryBlue,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (_currentStep + 1) / _steps.length,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              DatosPersonalesConstants.primaryBlue,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          '${((_currentStep + 1) / _steps.length * 100).toInt()}% completado',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

