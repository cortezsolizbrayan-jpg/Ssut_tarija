import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/ci_verification_service.dart';

class RegisterScreen extends StatefulWidget {
  static const name = 'register-screen';
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _inputController = TextEditingController();
  final CIVerificationService _ciService = CIVerificationService();
  bool _isVerifying = false;

  Future<void> _verifyAndContinue() async {
    final input = _inputController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu CI'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validar formato de CI (solo números, mínimo 6 dígitos)
    final cleanCI = input.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanCI.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un CI válido (mínimo 6 dígitos)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    // Verificar si el CI existe en la BD
    final result = await _ciService.verifyCI(cleanCI);

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final exists = result['exists'] ?? false;

    if (exists) {
      // Si el CI existe, mostrar mensaje y no permitir registro
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este CI ya está registrado. Por favor inicia sesión.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      // Opcional: redirigir al login
      // context.push('/login');
    } else {
      // Si NO existe, continuar con el flujo de registro
      // Pasar el CI al siguiente paso
      context.push('/upload-ci', extra: {'ci': cleanCI});
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colores de la aplicación (Azul)
    const Color primaryBlue = Color(0xFF305BA4);
    const Color whiteBg = Color(0xFFF6F8FB);
    const Color textDark = Color(0xFF1A3A5C);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/graduation_icon.png',
                  height: 48,
                  // color: primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInLeft(
              duration: const Duration(milliseconds: 600),
              child: const Text(
                'Te damos la bienvenida a Posgrado',
                style: TextStyle(
                  color: textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cédula de Identidad (CI)',
                    style: TextStyle(color: Color(0xFF848E9C), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _inputController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: textDark),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Ej: 71234567',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEF2F6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFEEF2F6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: primaryBlue,
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text.rich(
                    TextSpan(
                      text: 'Al crear una cuenta, acepto los ',
                      style: TextStyle(color: Color(0xFF848E9C), fontSize: 12),
                      children: [
                        TextSpan(
                          text: 'Términos de servicio',
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' y la '),
                        TextSpan(
                          text: 'Política de privacidad',
                          style: TextStyle(
                            color: textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(text: ' de la UPEA.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Siguiente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 600),
              child: Column(
                children: [
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFFEEF2F6))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'o',
                          style: TextStyle(color: Color(0xFF848E9C)),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFFEEF2F6))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SocialButton(
                    icon: FontAwesomeIcons.google,
                    text: 'Continuar con Google',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 12),
                  _SocialButton(
                    icon: FontAwesomeIcons.apple,
                    text: 'Continuar con Apple',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          '¿Ya tienes una cuenta?',
                          style: TextStyle(
                            color: Color(0xFF848E9C),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/login'),
                          child: const Text(
                            'Iniciar sesión',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF1A3A5C), size: 20),
        label: Text(
          text,
          style: const TextStyle(color: Color(0xFF1A3A5C), fontSize: 16),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEEF2F6)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
