import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PasswordSetupScreen extends StatefulWidget {
  static const name = 'password-setup-screen';
  const PasswordSetupScreen({super.key});

  @override
  State<PasswordSetupScreen> createState() => _PasswordSetupScreenState();
}

class _PasswordSetupScreenState extends State<PasswordSetupScreen> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  bool _isConfirmObscure = true;

  @override
  void dispose() {
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // Validar fortaleza de contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(value)) {
      return 'La contraseña debe contener al menos una letra';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe contener al menos un número';
    }
    return null;
  }

  // Validar confirmación de contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
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
                  'Crea tu contraseña',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInLeft(
                child: Text(
                  'Tu contraseña debe tener al menos 8 caracteres, incluyendo letras y números para mayor seguridad.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ),
              const SizedBox(height: 40),

              _buildPasswordField(
                'Nueva Contraseña',
                _passController,
                _isObscure,
                (value) => setState(() => _isObscure = value),
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),
              _buildPasswordField(
                'Confirmar Contraseña',
                _confirmPassController,
                _isConfirmObscure,
                (value) => setState(() => _isConfirmObscure = value),
                validator: _validateConfirmPassword,
              ),

              const SizedBox(height: 48),

              FadeInUp(
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Navegar a Términos y Condiciones solo si las contraseñas son válidas
                        context.push('/terms-conditions');
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
                      'Continuar',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscure,
    Function(bool) onToggleObscure, {
    String? Function(String?)? validator,
  }) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF1A3A5C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscure,
          validator: validator,
          style: const TextStyle(color: textDark),
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                isObscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: () => onToggleObscure(!isObscure),
            ),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEF2F6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
