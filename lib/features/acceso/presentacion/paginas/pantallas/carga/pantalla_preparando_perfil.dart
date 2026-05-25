import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/image_processing/servicio_remover_fondo.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';

/// Pantalla de transición que inicializa ONNX y prepara el perfil del usuario
/// antes de entrar a la pantalla principal por primera vez.
class PantallaPreparandoPerfil extends StatefulWidget {
  static const name = 'preparando-perfil';
  const PantallaPreparandoPerfil({super.key});

  @override
  State<PantallaPreparandoPerfil> createState() =>
      _PantallaPreparandoPerfilState();
}

class _PantallaPreparandoPerfilState extends State<PantallaPreparandoPerfil>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _mensaje = 'Preparando tu perfil...';
  double _progreso = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _iniciarPreparacion();
  }

  Future<void> _iniciarPreparacion() async {
    // Paso 1 — Configuración inicial
    await Future.delayed(const Duration(milliseconds: 400));
    _actualizar('Configurando tu cuenta...', 0.2);

    // Paso 2 — Inicializar ONNX para remoción de fondo
    await Future.delayed(const Duration(milliseconds: 300));
    _actualizar('Cargando herramientas de imagen...', 0.4);

    try {
      await ServicioRemoverFondo.inicializar().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ ONNX timeout — continuando sin remoción de fondo');
        },
      );
    } catch (e) {
      debugPrint('⚠️ ONNX no disponible: $e');
    }

    _actualizar('Personalizando tu experiencia...', 0.7);
    await Future.delayed(const Duration(milliseconds: 400));

    // Paso 3 — Marcar que ya pasó por esta pantalla
    await LocalStorageService.saveSessionData({
      ...?await LocalStorageService.getSessionData(),
      'perfilPreparado': true,
    });

    _actualizar('¡Todo listo!', 1.0);
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      context.go('/sistema/pantalla_principal');
    }
  }

  void _actualizar(String mensaje, double progreso) {
    if (!mounted) return;
    setState(() {
      _mensaje = mensaje;
      _progreso = progreso;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005BAC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo
                  Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryBlue.withOpacity(0.15),
                        width: 2,
                      ),
                    ),
                    child: Image.asset(
                      'assets/images/logoposgrado.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    'Posgrado UPEA',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _mensaje,
                      key: ValueKey(_mensaje),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Barra de progreso
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      child: LinearProgressIndicator(
                        value: _progreso,
                        minHeight: 6,
                        backgroundColor: primaryBlue.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          primaryBlue,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '${(_progreso * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
