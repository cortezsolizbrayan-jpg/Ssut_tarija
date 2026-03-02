import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsScreen extends StatefulWidget {
  static const name = 'terms-conditions-screen';

  const TermsConditionsScreen({super.key});

  @override
  State<TermsConditionsScreen> createState() => _TermsConditionsScreenState();
}

class _TermsConditionsScreenState extends State<TermsConditionsScreen> {
  bool _accepted = false;
  bool _canAccept = false; // Controla si ya leyó todo
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Si ya puede aceptar, no necesitamos seguir revisando
    if (_canAccept) return;

    // Verificar si llegó al final del scroll (con un pequeño margen de error)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 50) {
      setState(() {
        _canAccept = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Definición de colores basados en el design system
    const Color primaryBlue = Color(0xFF005BAC); // Azul institucional UPEA
    const Color lightBlue = Color(0xFF3D8FE0); // Azul claro institucional
    const Color goldColor = Color(0xFFFFC107); // Amarillo/Dorado del botón
    const Color whiteText = Colors.white;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Fondo decorativo con gradiente institucional
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue, // Azul institucional
                    primaryBlue.withOpacity(0.9),
                    lightBlue.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Barra de progreso de lectura
                ValueListenableBuilder<double>(
                  valueListenable: ValueNotifier(_scrollController.hasClients ? _scrollController.offset : 0.0),
                  builder: (context, offset, child) {
                    double progress = 0.0;
                    if (_scrollController.hasClients) {
                      progress = (_scrollController.offset / _scrollController.position.maxScrollExtent).clamp(0.0, 1.0);
                    }
                    return LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(goldColor),
                      minHeight: 4,
                    );
                  },
                ),
                // Encabezado
                Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Icono o Logo (placeholder basado en la P del ícono)
                    FadeInDown(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.school,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TERMINOS Y CONDICIONES',
                                  style: TextStyle(
                                    color: whiteText,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Lea detenidamente los Términos y Condiciones antes de continuar.',
                                  style: TextStyle(
                                    color: whiteText.withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido Scrollable
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.only(
                    right: 5,
                  ), // Espacio para scrollbar
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller:
                        _scrollController, // Asociar también al scrollbar
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(right: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInLeft(
                            delay: const Duration(milliseconds: 200),
                            child: const Text(
                              'Actualizamos nuestras Condiciones de Uso y Avisos de Privacidad',
                              style: TextStyle(
                                color: whiteText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildParagraph(
                            'A partir de Diciembre de 2025 entrarán en vigor nuestras políticas actualizadas Términos de Uso y Aviso de Privacidad.',
                            whiteText,
                          ),
                          const SizedBox(height: 15),

                          const SectionTitle(title: 'Sección 1: Uso de la aplicación Móvil', icon: Icons.phone_android_rounded),
                          const SizedBox(height: 12),
                          _buildParagraph(
                            'Esta aplicación es un sistema institucional destinado a la gestión académica y administrativa de programas de posgrado. Su uso está dirigido a posibles participantes, participantes inscritos y personal autorizado.',
                            whiteText,
                          ),
                          const SizedBox(height: 12),
                          _buildParagraph(
                            'El sistema permite el registro de usuarios para fines de preinscripción, inscripción y seguimiento académico. El registro está disponible para postulantes, estudiantes inscritos y personal autorizado por la Unidad de Posgrado.',
                            whiteText,
                          ),
                          
                          const SizedBox(height: 24),
                          const SectionTitle(title: 'Sección 2: Protección de datos personales', icon: Icons.security_rounded),
                          const SizedBox(height: 12),
                          _buildParagraph(
                            'Los datos personales proporcionados a través de esta aplicación serán utilizados únicamente para fines académicos, administrativos y de comunicación institucional relacionados con los programas de posgrado.',
                            whiteText,
                          ),
                          const SizedBox(height: 12),
                          _buildParagraph(
                            'La información registrada será tratada conforme a los principios de confidencialidad, seguridad y uso responsable. No será compartida con terceros sin autorización expresa del titular, salvo en los casos exigidos por normativa legal vigente.',
                            whiteText,
                          ),
                          const SizedBox(height: 12),
                          _buildParagraph(
                            'El usuario manifiesta su plena conformidad y autoriza expresamente el uso de sus datos personales para la gestión de trámites académicos, procesos administrativos y cualquier otra gestión necesaria dentro de la institución.',
                            whiteText,
                          ),
                          const SizedBox(height: 60),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Checkbox y Botón
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.5),
                  border: Border(
                    top: BorderSide(color: whiteText.withOpacity(0.1)),
                  ),
                ),
                child: Column(
                  children: [
                    FadeInUp(
                      child: Row(
                        children: [
                          Theme(
                            data: ThemeData(
                              unselectedWidgetColor: _canAccept
                                  ? whiteText
                                  : Colors.grey, // Retroalimentación visual
                            ),
                            child: Checkbox(
                              value: _accepted,
                              activeColor: Colors.white,
                              checkColor: primaryBlue,
                              side: const BorderSide(color: Colors.white, width: 2),
                              // Solo permitir habilitar si ya se leyó todo
                              onChanged: _canAccept
                                  ? (bool? value) {
                                      setState(() {
                                        _accepted = value ?? false;
                                      });
                                    }
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'He leído los términos y condiciones',
                              style: TextStyle(
                                color: _canAccept
                                    ? whiteText
                                    : Colors.grey, // Retroalimentación visual
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _accepted
                              ? () {
                                  // Mostrar éxito y navegar al login (lógica movida desde la pantalla anterior)
                                  _showSuccessDialog(context);
                                }
                              : null, // Deshabilitado si no acepta
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldColor,
                            foregroundColor:
                                Colors.black, // Color del texto al presionar
                            disabledBackgroundColor: Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 5,
                          ),
                          child: const Text(
                            'ACEPTAR Y CONTINUAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildParagraph(String text, Color color) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: TextStyle(
        color: color.withOpacity(0.9),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text(
              '¡Registro Completado!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu cuenta ha sido creada exitosamente. Ya puedes acceder a todas las funciones.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Cerrar el diálogo primero
                  Navigator.of(context).pop();
                  
                  // NO guardamos la sesión todavía, solo navegamos a biometric-setup
                  // La sesión se guardará después de configurar la biometría
                  if (context.mounted) {
                    // Navegar a la configuración biométrica
                    context.go('/biometric-setup');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005BAC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'INGRESAR AL SISTEMA',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitle({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFFC107), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
