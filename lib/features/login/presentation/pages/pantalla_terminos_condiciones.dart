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
    // Definición de colores basados en la imagen
    const Color primaryBlue = Color(
      0xFF005696,
    ); // Azul institucional UPEA aproximado
    const Color darkBlue = Color(0xFF003D6B); // Azul más oscuro para fondo
    const Color goldColor = Color(0xFFFFC107); // Amarillo/Dorado del botón
    const Color whiteText = Colors.white;

    return Scaffold(
      backgroundColor: primaryBlue,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [primaryBlue, darkBlue],
            ),
          ),
          child: Column(
            children: [
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

                          const Text(
                            'Sección 1: Uso de la aplicación Móvil',
                            style: TextStyle(
                              color: whiteText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'Esta aplicación es un sistema institucional destinado a la gestión académica y administrativa de programas de posgrado. Su uso está dirigido a posibles participantes, participantes inscritos y personal autorizado.',
                            whiteText,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'El sistema permite el registro de usuarios para fines de preinscripción, inscripción y seguimiento académico. El registro está disponible para postulantes, estudiantes inscritos y personal autorizado por la Unidad de Posgrado.',
                            whiteText,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'El usuario es responsable de proporcionar información real y verificable durante el proceso de registro y uso del sistema.',
                            whiteText,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'El acceso, uso y consulta de la información académica está restringido a usuarios debidamente habilitados. Cualquier uso indebido, intento de suplantación de identidad o manipulación de datos será sujeto a las acciones administrativas correspondientes.',
                            whiteText,
                          ),

                          const SizedBox(height: 20),
                          const Text(
                            'Sección 2: Protección de datos personales',
                            style: TextStyle(
                              color: whiteText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'Los datos personales proporcionados a través de esta aplicación serán utilizados únicamente para fines académicos, administrativos y de comunicación institucional relacionados con los programas de posgrado.',
                            whiteText,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'La información registrada será tratada conforme a los principios de confidencialidad, seguridad y uso responsable. No será compartida con terceros sin autorización expresa del titular, salvo en los casos exigidos por normativa legal vigente.',
                            whiteText,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'El usuario manifiesta su plena conformidad y autoriza expresamente el uso de sus datos personales para la gestión de trámites académicos, procesos administrativos y cualquier otra gestión necesaria dentro de la institución.',
                            whiteText,
                          ),
                          const SizedBox(height: 40), // Espacio extra al final
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
                  color: darkBlue.withOpacity(0.5),
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
              'Tu cuenta ha sido creada exitosamente. Ya puedes iniciar sesión.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF305BA4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'IR AL LOGIN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
