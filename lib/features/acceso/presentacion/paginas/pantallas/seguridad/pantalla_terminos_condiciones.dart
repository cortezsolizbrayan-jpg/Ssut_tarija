import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/storage/servicio_base_datos_local.dart';

class TermsConditionsPantalla extends StatefulWidget {
  static const name = 'terms-conditions-Pantalla';

  const TermsConditionsPantalla({super.key});

  @override
  State<TermsConditionsPantalla> createState() =>
      _TermsConditionsPantallaState();
}

class _TermsConditionsPantallaState extends State<TermsConditionsPantalla> {
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
    const Color primaryBlue = Color(0xFF005BAC);

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de progreso de lectura
            AnimatedBuilder(
              animation: _scrollController,
              builder: (context, _) {
                double progress = 0.0;
                if (_scrollController.hasClients &&
                    _scrollController.position.maxScrollExtent > 0) {
                  progress =
                      (_scrollController.offset /
                              _scrollController.position.maxScrollExtent)
                          .clamp(0.0, 1.0);
                }
                return LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(primaryBlue),
                  minHeight: 4,
                );
              },
            ),
            // Encabezado institucional
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: FadeInDown(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TÉRMINOS Y CONDICIONES',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lea detenidamente antes de continuar.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Contenido Scrollable
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeInLeft(
                            delay: const Duration(milliseconds: 200),
                            child: const Text(
                              'Actualizamos nuestras Condiciones de Uso y Avisos de Privacidad',
                              style: TextStyle(
                                color: Color(0xFF333333),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildParagraph(
                            'A partir de Diciembre de 2025 entrarán en vigor nuestras políticas actualizadas Términos de Uso y Aviso de Privacidad.',
                          ),
                          const SizedBox(height: 16),
                          const SectionTitle(
                            title: 'Sección 1: Uso de la aplicación Móvil',
                            icon: Icons.phone_android_rounded,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'Esta aplicación es un sistema institucional destinado a la gestión académica y administrativa de programas de posgrado. Su uso está dirigido a posibles participantes, participantes inscritos y personal autorizado.',
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'El sistema permite el registro de usuarios para fines de preinscripción, inscripción y seguimiento académico. El registro está disponible para postulantes, estudiantes inscritos y personal autorizado por la Unidad de Posgrado.',
                          ),
                          const SizedBox(height: 20),
                          const SectionTitle(
                            title: 'Sección 2: Protección de datos personales',
                            icon: Icons.security_rounded,
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'Los datos personales proporcionados a través de esta aplicación serán utilizados únicamente para fines académicos, administrativos y de comunicación institucional relacionados con los programas de posgrado.',
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'La información registrada será tratada conforme a los principios de confidencialidad, seguridad y uso responsable. No será compartida con terceros sin autorización expresa del titular, salvo en los casos exigidos por normativa legal vigente.',
                          ),
                          const SizedBox(height: 10),
                          _buildParagraph(
                            'El usuario manifiesta su plena conformidad y autoriza expresamente el uso de sus datos personales para la gestión de trámites académicos, procesos administrativos y cualquier otra gestión necesaria dentro de la institución.',
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Checkbox y Botón
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  if (!_canAccept)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_downward_rounded,
                            size: 14,
                            color: primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Desplázate hasta el final para aceptar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  FadeInUp(
                    child: Row(
                      children: [
                        Checkbox(
                          value: _accepted,
                          activeColor: primaryBlue,
                          checkColor: Colors.white,
                          side: BorderSide(
                            color: _canAccept ? primaryBlue : Colors.grey,
                            width: 2,
                          ),
                          onChanged: _canAccept
                              ? (val) =>
                                    setState(() => _accepted = val ?? false)
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            'He leído los términos y condiciones',
                            style: TextStyle(
                              color: _canAccept
                                  ? const Color(0xFF333333)
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _accepted
                            ? () => _showSuccessDialog(context)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBlue,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: _accepted ? 3 : 0,
                        ),
                        child: Text(
                          'ACEPTAR Y CONTINUAR',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: _accepted ? Colors.white : Colors.grey,
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
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      textAlign: TextAlign.justify,
      style: const TextStyle(
        color: Color(0xFF444444),
        fontSize: 14,
        height: 1.6,
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
                  // 1. Obtener datos acumulados del registro
                  final personalData =
                      await LocalStorageService.getPersonalData();
                  final nombre = personalData?['nombre'] ?? 'Usuario';
                  final apellidos =
                      '${personalData?['apPaterno'] ?? ''} ${personalData?['apMaterno'] ?? ''}'
                          .trim();
                  final ci = personalData?['numeroCI'] ?? '';

                  // 2. REGISTRO EFECTIVO: Guardar en BD local para poder iniciar sesión después
                  await LocalDatabaseService.registerUser({
                    'ci': ci,
                    'nombres': nombre,
                    'apellidos': apellidos,
                    'password':
                        'Upea123*', // Password temporal o guardada en paso previo
                    'email': personalData?['correo'] ?? '',
                    'telefono': personalData?['celular'] ?? '',
                  });

                  // 3. AUTO-LOGIN: Guardamos datos de sesión
                  await LocalStorageService.saveSessionData({
                    'nombreUsuario': ci,
                    'nombreCompleto': '$nombre $apellidos',
                    'rol': 'participante',
                    'loginDate': DateTime.now().toIso8601String(),
                  });

                  // 4. Solicitar firma al concluir registro (requisito para cartas)
                  final firmaPath =
                      await LocalStorageService.getSignatureImagePath();
                  if ((firmaPath ?? '').trim().isEmpty) {
                    if (!context.mounted) return;
                    final firmaGenerada = await context.push<String?>(
                      '/pantalla_firma',
                    );
                    if ((firmaGenerada ?? '').trim().isEmpty) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Para generar cartas oficiales, primero debes registrar tu firma.',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }
                  }

                  if (context.mounted) {
                    // Registro completado — limpiar progreso guardado
                    await LocalStorageService.clearRegistroProgreso();
                    context.go('/biometric-setup');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF305BA4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'INGRESAR AL SISTEMA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
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
        Icon(icon, color: const Color(0xFF005BAC), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF005BAC),
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}
