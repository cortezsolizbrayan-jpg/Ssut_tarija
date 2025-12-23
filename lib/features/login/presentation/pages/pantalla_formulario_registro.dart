import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RegistrationFormScreen extends StatefulWidget {
  static const name = 'registration-form-screen';
  final String? initialNombres;
  final String? initialApellidos;
  final String? initialCI;
  final String? initialFechaEmision;
  final String? initialFechaExpiracion;
  final bool isCIBlocked; // Si el CI debe estar bloqueado

  const RegistrationFormScreen({
    super.key,
    this.initialNombres,
    this.initialApellidos,
    this.initialCI,
    this.initialFechaEmision,
    this.initialFechaExpiracion,
    this.isCIBlocked = false, // Por defecto no bloqueado
  });

  @override
  State<RegistrationFormScreen> createState() => _RegistrationFormScreenState();
}

class _RegistrationFormScreenState extends State<RegistrationFormScreen> {
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _ciController;
  final TextEditingController _emailController = TextEditingController();
  late TextEditingController _fechaEmisionController;
  late TextEditingController _fechaExpiracionController;
  final _formKey = GlobalKey<FormState>();

  String _toTitleCase(String text) {
    if (text.isEmpty) return "";
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return "";
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.initialNombres);
    _apellidosController = TextEditingController(text: widget.initialApellidos);
    _ciController = TextEditingController(text: widget.initialCI);
    _fechaEmisionController = TextEditingController(
      text: widget.initialFechaEmision,
    );
    _fechaExpiracionController = TextEditingController(
      text: widget.initialFechaExpiracion,
    );
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _ciController.dispose();
    _emailController.dispose();
    _fechaEmisionController.dispose();
    _fechaExpiracionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF1A3A5C);
    const Color whiteBg = Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        title: const Text(
          'Confirmar Datos',
          style: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              FadeInDown(
                child: const Text(
                  'Verifica tu información',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeInLeft(
                child: Text(
                  'Hemos extraído estos datos de tu carnet. Por favor, corrígelos si es necesario.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),

              _buildField(
                'Nombre',
                _nombresController,
                Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu nombre';
                  if (RegExp(r'\d').hasMatch(value)) {
                    return 'El nombre no debe contener números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Apellidos',
                _apellidosController,
                Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingresa tus apellidos';
                  }
                  if (RegExp(r'\d').hasMatch(value)) {
                    return 'Los apellidos no deben contener números';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Cédula de Identidad',
                _ciController,
                Icons.badge_outlined,
                isBlocked: widget.isCIBlocked,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu CI';
                  // Permitir números seguidos opcionalmente por una extensión (ej: 1234567 LP)
                  if (!RegExp(r'^\d+(\s+[A-Z]{2})?$').hasMatch(value.toUpperCase())) {
                    return 'CI inválido (ej: 1234567 o 1234567 LP)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Fecha de Emisión',
                _fechaEmisionController,
                Icons.calendar_today_outlined,
                validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa la fecha';
                    // Validación básica de formato DD/MM/AAAA
                    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Formato inválido (DD/MM/AAAA)';
                    return null;
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Fecha de Expiración',
                _fechaExpiracionController,
                Icons.event_outlined,
                validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa la fecha';
                    if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Formato inválido (DD/MM/AAAA)';
                    return null;
                },
              ),
              const SizedBox(height: 20),
              _buildField(
                'Correo Electrónico',
                _emailController,
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Ingresa tu correo';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Ingresa un correo válido';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 48),

              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Siguiente: Crear contraseña
                        context.push('/password-setup');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Confirmar y Registrar',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isBlocked = false,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF1A3A5C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF848E9C),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: !isBlocked,
          readOnly: isBlocked,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isBlocked ? Colors.grey[600] : textDark,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (value) {
            if (label == 'Nombre' || label == 'Apellidos') {
              final position = controller.selection;
              final formatted = _toTitleCase(value);
              if (formatted != value) {
                controller.text = formatted;
                // Mantener la posición del cursor si es posible
                try {
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: math.min(position.baseOffset, formatted.length)),
                  );
                } catch (_) {}
              }
            }
          },
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              color: primaryBlue.withOpacity(0.7),
              size: 20,
            ),
            filled: true,
            fillColor: isBlocked ? Colors.grey[100] : Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFEEF2F6),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primaryBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            suffixIcon: isBlocked
                ? const Icon(Icons.lock_outline, color: Colors.grey, size: 18)
                : null,
            hintText: isBlocked ? 'Este campo no se puede modificar' : null,
          ),
        ),
      ],
    );
  }
}
