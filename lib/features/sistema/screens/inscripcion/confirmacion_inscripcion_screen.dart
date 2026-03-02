import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/widgets/optimized_fade_in.dart';

/// Pantalla de confirmación después de inscribirse exitosamente
class ConfirmacionInscripcionScreen extends StatefulWidget {
  static const String name = 'confirmacion-inscripcion';

  final String nombrePrograma;
  final String numeroInscripcion;
  final String? mensaje;

  const ConfirmacionInscripcionScreen({
    super.key,
    required this.nombrePrograma,
    required this.numeroInscripcion,
    this.mensaje,
  });

  @override
  State<ConfirmacionInscripcionScreen> createState() =>
      _ConfirmacionInscripcionScreenState();
}

class _ConfirmacionInscripcionScreenState
    extends State<ConfirmacionInscripcionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _masterController;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _pulseAnimation;

  static const Color kPrimaryColor = Color(0xFF005BAC);
  static const Color kSuccessColor = Color(0xFF4CAF50);
  static const Color kSurfaceColor = Color(0xFFF6F8FB);
  static const String fontHeading = 'Poppins';
  static const String fontBody = 'Intel';

  @override
  void initState() {
    super.initState();
    
    // Un solo controller para todas las animaciones de entrada
    _masterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animación de escala del icono con rebote
    _iconScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 40,
      ),
    ]).animate(_masterController);

    // Rotación del check
    _iconRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // Pulso suave continuo
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _masterController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    // Iniciar animación
    _masterController.forward().then((_) {
      // Repetir solo el pulso
      _masterController.repeat(
        min: 0.6,
        max: 1.0,
        reverse: true,
        period: const Duration(milliseconds: 1500),
      );
    });
  }

  @override
  void dispose() {
    _masterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        _irAlInicio();
        return false;
      },
      child: Scaffold(
        backgroundColor: kSurfaceColor,
        body: Stack(
          children: [
            // Gradiente de fondo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    kPrimaryColor.withOpacity(0.1),
                    kSurfaceColor,
                  ],
                ),
              ),
            ),

            // Contenido principal
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.05),

                    // Icono de éxito optimizado
                    AnimatedBuilder(
                      animation: _masterController,
                      builder: (context, child) {
                        final scale = _iconScaleAnimation.value;
                        final pulse = _pulseAnimation.value;
                        
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: kSuccessColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: kSuccessColor.withOpacity(0.2 + (pulse * 0.15)),
                                  blurRadius: 20 + (pulse * 10),
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Transform.rotate(
                              angle: _iconRotationAnimation.value * 6.28319, // 2π
                              child: const Icon(
                                Icons.check_rounded,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Título optimizado
                    FadeInDown(
                      from: 20,
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 200),
                      child: const Text(
                        '¡Inscripción Exitosa!',
                        style: TextStyle(
                          fontFamily: fontHeading,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: kSuccessColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Mensaje optimizado
                    FadeInUp(
                      from: 15,
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 300),
                      child: Text(
                        widget.mensaje ?? 
                        'Tu inscripción ha sido registrada correctamente',
                        style: const TextStyle(
                          fontFamily: fontBody,
                          fontSize: 16,
                          color: Color(0xFF666666),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Tarjeta optimizada
                    FadeInUp(
                      from: 30,
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 400),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Número de inscripción destacado
                            _buildDetailRow(
                              icon: Icons.confirmation_number_outlined,
                              label: 'Número de Inscripción',
                              value: widget.numeroInscripcion,
                              isHighlighted: true,
                            ),

                            const Divider(height: 32),

                            // Programa
                            _buildDetailRow(
                              icon: Icons.school_outlined,
                              label: 'Programa',
                              value: widget.nombrePrograma,
                            ),

                            const Divider(height: 32),

                            // Fecha
                            _buildDetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Fecha de Inscripción',
                              value: _formatearFecha(DateTime.now()),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Información adicional optimizada
                    FadeInUp(
                      from: 20,
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: kPrimaryColor.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  Icons.info_outline,
                                  color: kPrimaryColor,
                                  size: 24,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Próximos pasos',
                                    style: TextStyle(
                                      fontFamily: fontHeading,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildInfoItem(
                              '1. Revisa tu correo electrónico para más detalles',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoItem(
                              '2. Completa el pago de matrícula si aún no lo has hecho',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoItem(
                              '3. Sube los comprobantes de pago en "Mis Documentos"',
                            ),
                            const SizedBox(height: 8),
                            _buildInfoItem(
                              '4. Espera la confirmación del coordinador',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Botones optimizados
                    FadeInUp(
                      from: 15,
                      duration: const Duration(milliseconds: 400),
                      delay: const Duration(milliseconds: 600),
                      child: Column(
                        children: [
                          // Botón principal
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: _irAMisDocumentos,
                              icon: const Icon(Icons.upload_file, size: 22),
                              label: const Text(
                                'Subir Comprobantes de Pago',
                                style: TextStyle(
                                  fontFamily: fontHeading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: kPrimaryColor.withOpacity(0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Botón secundario
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: _irAMisProgramas,
                              icon: const Icon(Icons.school, size: 22),
                              label: const Text(
                                'Ver Mis Programas',
                                style: TextStyle(
                                  fontFamily: fontHeading,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kPrimaryColor,
                                side: const BorderSide(
                                  color: kPrimaryColor,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Botón terciario
                          TextButton.icon(
                            onPressed: _irAlInicio,
                            icon: const Icon(Icons.home_outlined, size: 20),
                            label: const Text(
                              'Volver al Inicio',
                              style: TextStyle(
                                fontFamily: fontBody,
                                fontSize: 15,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isHighlighted = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHighlighted
                ? kSuccessColor.withOpacity(0.1)
                : kPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isHighlighted ? kSuccessColor : kPrimaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: fontBody,
                  fontSize: 13,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontFamily: fontHeading,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isHighlighted ? kSuccessColor : const Color(0xFF333333),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: kPrimaryColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: fontBody,
              fontSize: 14,
              color: Color(0xFF333333),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
//formatear fechas 
  String _formatearFecha(DateTime fecha) {
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${fecha.day} de ${meses[fecha.month - 1]} de ${fecha.year}';
  }

  void _irAMisDocumentos() {
    context.go('/mis-documentos-personales');
  }
//aqui es uan funcion de ruta para ver los diplomados 
  void _irAMisProgramas() {
    context.go('/diplomados');
  }

  void _irAlInicio() {
    context.go('/sistema/pantalla_principal');
  }
}
