import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/storage/servicio_base_datos_local.dart';

class RegisterPantalla extends StatefulWidget {
  static const name = 'register-Pantalla';
  const RegisterPantalla({super.key});

  @override
  State<RegisterPantalla> createState() => _RegisterPantallaState();
}

class _RegisterPantallaState extends State<RegisterPantalla> {
  final TextEditingController _inputController = TextEditingController();
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

    if (input.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un CI válido (mínimo 5 dígitos)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // CI de desarrollo — acceso directo sin verificación
    if (LocalDatabaseService.skipIdentityVerificationCIs.contains(input)) {
      if (!mounted) return;
      context.go('/sistema/pantalla_principal');
      return;
    }

    // Guardar progreso: el usuario está en el flujo de registro
    await LocalStorageService.saveRegistroProgreso('/register');

    // API no lista aún — ir directo al escaneo de carnet
    context.push('/upload-ci', extra: {'ci': input});
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color whiteBg = Color(0xFFF6F8FB);
    const Color textDark = Color(0xFF1A3A5C);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textDark),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/start-screen');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            FadeInDown(
              duration: const Duration(milliseconds: 300),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/images/graduation_icon.png',
                  height: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeInLeft(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 50),
              child: const Text(
                'Te damos la bienvenida a Posgrado',
                style: TextStyle(
                  color: textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInLeft(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 80),
              child: const Text(
                'Ingresa tu Cédula de Identidad para comenzar el registro.',
                style: TextStyle(color: Color(0xFF848E9C), fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 100),
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
                    autofocus: true,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Ej: 71234567',
                      hintStyle: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.badge_outlined,
                        color: primaryBlue,
                      ),
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
                    onSubmitted: (_) => _verifyAndContinue(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 120),
              child: const Text.rich(
                TextSpan(
                  text: 'Al continuar, acepto los ',
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
            ),
            const SizedBox(height: 32),
            FadeInUp(
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 150),
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
              duration: const Duration(milliseconds: 300),
              delay: const Duration(milliseconds: 180),
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
