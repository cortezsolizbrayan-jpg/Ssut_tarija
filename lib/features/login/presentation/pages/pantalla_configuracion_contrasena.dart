import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_biometrico.dart';

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
  bool _isProcessing = false;
  final BiometricService _biometricService = BiometricService();

  // Estado de cada regla de validación (para mostrar checkmarks)
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;
  bool _hasNoSpaces = true;
  bool _hasMaxLength = true;

  @override
  void initState() {
    super.initState();
    _passController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passController.removeListener(_onPasswordChanged);
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
//metodo que se ejecuta cuando cambia la contraseña
  void _onPasswordChanged() {
    final v = _passController.text;
    setState(() {
      _hasMinLength = v.length >= 8;
      _hasMaxLength = v.length <= 64;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(v);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(v);
      _hasNumber = RegExp(r'[0-9]').hasMatch(v);
      _hasSpecial = RegExp(r'[@$!%*?&.#_\-]').hasMatch(v);
      _hasNoSpaces = !v.contains(' ');
    });
  }

  /// Calcula el nivel de fortaleza: 0=ninguna, 1=débil, 2=media, 3=fuerte, 4=muy fuerte
  int _strengthLevel() {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase && _hasLowercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecial) score++;
    return score;
  }

  // ── Validadores ─────────────────────────────────────────────────────────────

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.contains(' ')) {
      return 'La contraseña no puede contener espacios en blanco';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (value.length > 64) {
      return 'La contraseña no puede superar los 64 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe incluir al menos una letra MAYÚSCULA';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Debe incluir al menos una letra minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe incluir al menos un número';
    }
    if (!RegExp(r'[@$!%*?&.#_\-]').hasMatch(value)) {
      return 'Debe incluir al menos un carácter especial (@\$!%*?&.#_-)';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != _passController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

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
          autovalidateMode: AutovalidateMode.onUserInteraction,
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
                  'Tu contraseña debe cumplir todos los requisitos indicados '
                  'a continuación para garantizar tu seguridad.',
                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                ),
              ),
              const SizedBox(height: 32),

              // ── Campo nueva contraseña
              _buildPasswordField(
                'Nueva Contraseña',
                _passController,
                _isObscure,
                (value) => setState(() => _isObscure = value),
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),

              // ── Barra de fortaleza
              _buildStrengthBar(),
              const SizedBox(height: 16),

              // ── Lista de requisitos
              _buildRequirements(),

              const SizedBox(height: 24),

              // ── Campo confirmar contraseña
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
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => _isProcessing = true);
                              
                              try {
                                // Obtener el CI del almacenamiento local (guardado en el paso anterior)
                                final personalData = await LocalStorageService.getPersonalData();
                                final ci = personalData?['numeroCI']?.toString() ?? '';
                                final password = _passController.text;

                                // Guardar credenciales silenciosamente para el paso biométrico posterior
                                await _biometricService.saveCredentials(username: ci, password: password);

                                if (context.mounted) {
                                  context.push('/terms-conditions');
                                }
                              } finally {
                                if (mounted) setState(() => _isProcessing = false);
                              }
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
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── Barra de fortaleza visual ───────────────────────────────────────────────
  Widget _buildStrengthBar() {
    final level = _strengthLevel();
    final bool isEmpty = _passController.text.isEmpty;

    final List<Color> colors = [
      const Color(0xFFEEEEEE), // vacío
      const Color(0xFFEF5350), // débil  (1)
      const Color(0xFFFFA726), // media  (2)
      const Color(0xFF66BB6A), // fuerte (3)
      const Color(0xFF1E88E5), // muy fuerte (4)
    ];

    final List<String> labels = ['', 'Débil', 'Media', 'Fuerte', 'Muy fuerte'];

    Color barColor = isEmpty ? colors[0] : colors[level];
    String label = isEmpty ? '' : labels[level];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            final filled = !isEmpty && i < level;
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                height: 6,
                decoration: BoxDecoration(
                  color: filled ? barColor : const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              'Seguridad: $label',
              key: ValueKey(label),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: barColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── Lista de requisitos con checkmarks ─────────────────────────────────────
  Widget _buildRequirements() {
    final rules = [
      _Rule('Mínimo 8 caracteres', _hasMinLength),
      _Rule('Máximo 64 caracteres', _hasMaxLength),
      _Rule('Al menos una letra MAYÚSCULA', _hasUppercase),
      _Rule('Al menos una letra minúscula', _hasLowercase),
      _Rule('Al menos un número', _hasNumber),
      _Rule('Al menos un carácter especial (@\$!%*?&.#_-)', _hasSpecial),
      _Rule('Sin espacios en blanco', _hasNoSpaces),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEF2F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requisitos de la contraseña',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A3A5C),
            ),
          ),
          const SizedBox(height: 10),
          ...rules.map((r) => _buildRuleRow(r)),
        ],
      ),
    );
  }

  Widget _buildRuleRow(_Rule rule) {
    final bool isEmpty = _passController.text.isEmpty;
    final Color iconColor = isEmpty
        ? Colors.grey.shade400
        : rule.passed
            ? const Color(0xFF43A047)
            : const Color(0xFFEF5350);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isEmpty
                  ? Icons.radio_button_unchecked
                  : rule.passed
                      ? Icons.check_circle
                      : Icons.cancel,
              key: ValueKey('${rule.label}_${rule.passed}_$isEmpty'),
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule.label,
              style: TextStyle(
                fontSize: 13,
                color: isEmpty
                    ? Colors.grey.shade600
                    : rule.passed
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Campo de contraseña reutilizable ───────────────────────────────────────
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
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

}

// ── Modelo de regla ─────────────────────────────────────────────────────────
class _Rule {
  final String label;
  final bool passed;
  const _Rule(this.label, this.passed);
}
