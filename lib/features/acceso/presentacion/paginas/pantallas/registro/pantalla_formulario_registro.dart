import 'dart:math' as math;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/core/widgets/ios_date_picker.dart';

class RegistrationFormPantalla extends StatefulWidget {
  static const name = 'registration-form-Pantalla';
  final String? initialNombres;
  final String? initialApellidos;
  final String? initialCI;
  final String? initialEmail;
  final String? initialFechaEmision;
  final String? initialFechaExpiracion;
  final String? initialCombinedCiPath;
  final bool isCIBlocked;

  const RegistrationFormPantalla({
    super.key,
    this.initialNombres,
    this.initialApellidos,
    this.initialCI,
    this.initialEmail,
    this.initialFechaEmision,
    this.initialFechaExpiracion,
    this.initialCombinedCiPath,
    this.isCIBlocked = false,
  });

  @override
  State<RegistrationFormPantalla> createState() =>
      _RegistrationFormPantallaState();
}

class _RegistrationFormPantallaState extends State<RegistrationFormPantalla> {
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _ciController;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fechaNacimientoController =
      TextEditingController();
  late TextEditingController _fechaEmisionController;
  late TextEditingController _fechaExpiracionController;
  final _formKey = GlobalKey<FormState>();

  DateTime? _tryParseDateStrict(String ddMMyyyy) {
    final parts = ddMMyyyy.split('/');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    final dt = DateTime(year, month, day);
    if (dt.year != year || dt.month != month || dt.day != day) return null;
    return dt;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .toLowerCase()
        .split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _nombresController = TextEditingController(text: widget.initialNombres);
    _apellidosController = TextEditingController(text: widget.initialApellidos);
    _ciController = TextEditingController(text: widget.initialCI);
    _emailController.text = widget.initialEmail ?? '';
    _fechaEmisionController = TextEditingController(text: widget.initialFechaEmision);
    _fechaExpiracionController = TextEditingController(text: widget.initialFechaExpiracion);
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _ciController.dispose();
    _emailController.dispose();
    _fechaNacimientoController.dispose();
    _fechaEmisionController.dispose();
    _fechaExpiracionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller, {
    DateTime? firstDate,
    DateTime? lastDate,
    bool esNacimiento = false,
  }) async {
    DateTime initialDate;
    if (controller.text.isNotEmpty) {
      final iso = _convertToIso(controller.text);
      initialDate = DateTime.tryParse(iso) ?? DateTime.now();
    } else {
      initialDate = DateTime.now();
    }
    final effectiveFirstDate = firstDate ?? DateTime(1900);
    final effectiveLastDate = lastDate ?? DateTime(2100);
    if (initialDate.isBefore(effectiveFirstDate)) initialDate = effectiveFirstDate;
    if (initialDate.isAfter(effectiveLastDate)) initialDate = effectiveLastDate;

    final picked = await mostrarIosFechaPicker(
      context: context,
      initialDate: initialDate,
      titulo: 'Seleccionar Fecha',
      esFechaNacimiento: esNacimiento,
      minimumYear: esNacimiento ? null : effectiveFirstDate.year,
      maximumYear: esNacimiento ? null : effectiveLastDate.year,
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      controller.text = formatted;
      setState(() {});
    }
  }

  bool _isAdult(String dateString) {
    if (dateString.isEmpty) return false;
    final iso = _convertToIso(dateString);
    final birthDate = DateTime.tryParse(iso);
    if (birthDate == null) return false;
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    final monthDiff = today.month - birthDate.month;
    final dayDiff = today.day - birthDate.day;
    if (monthDiff < 0 || (monthDiff == 0 && dayDiff < 0)) return age - 1 >= 18;
    return age >= 18;
  }

  String _convertToIso(String date) {
    final parts = date.split('/');
    if (parts.length != 3) return date;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required BuildContext context,
    DateTime? firstDate,
    DateTime? lastDate,
    bool esNacimiento = false,
    String? Function(String?)? validator,
  }) {
    final bool isFilled = controller.text.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isFilled ? const Color(0xFF1A3A5C) : const Color(0xFF848E9C),
            fontSize: 13,
            fontWeight: isFilled ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickDate(context, controller,
              firstDate: firstDate, lastDate: lastDate, esNacimiento: esNacimiento),
          child: AbsorbPointer(
            child: TextFormField(
              controller: controller,
              validator: validator,
              style: TextStyle(
                color: const Color(0xFF1A3A5C),
                fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  icon,
                  color: isFilled
                      ? const Color(0xFF305BA4)
                      : const Color(0xFF305BA4).withAlpha(179),
                  size: 20,
                ),
                filled: true,
                fillColor: isFilled ? const Color(0xFFE8F0FE) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isFilled
                        ? const Color(0xFF305BA4).withOpacity(0.3)
                        : const Color(0xFFEEF2F6),
                    width: isFilled ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF305BA4), width: 1.8),
                ),
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: isFilled ? const Color(0xFF305BA4) : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Formulario completo reutilizado en portrait y landscape ────────────────
  Widget _buildForm(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField('Nombre', _nombresController, Icons.person_outline,
              validator: (value) {
            if (value == null || value.isEmpty) return 'Ingresa tu nombre';
            if (RegExp(r'\d').hasMatch(value)) return 'El nombre no debe contener números';
            return null;
          }),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          _buildField('Apellidos', _apellidosController, Icons.person_outline,
              validator: (value) {
            if (value == null || value.isEmpty) return 'Ingresa tus apellidos';
            if (RegExp(r'\d').hasMatch(value)) return 'Los apellidos no deben contener números';
            return null;
          }),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          _buildField(
            'Cédula de Identidad',
            _ciController,
            Icons.badge_outlined,
            isBlocked: widget.isCIBlocked,
            keyboardType: TextInputType.visiblePassword,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Ingresa tu CI';
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          _buildDateField(
            'Fecha de Nacimiento*',
            _fechaNacimientoController,
            Icons.calendar_today_outlined,
            context: context,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            esNacimiento: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu fecha de nacimiento';
              if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Formato inválido (DD/MM/AAAA)';
              final parsed = _tryParseDateStrict(value);
              if (parsed == null) return 'Fecha inválida';
              if (!_isAdult(value)) return 'Debes ser mayor de 18 años para registrarte';
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          _buildDateField(
            'Fecha de Emisión',
            _fechaEmisionController,
            Icons.calendar_today_outlined,
            context: context,
            firstDate: DateTime(1920),
            lastDate: DateTime.now(),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa la fecha';
              if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Formato inválido (DD/MM/AAAA)';
              final emision = _tryParseDateStrict(value);
              if (emision == null) return 'Fecha inválida';
              final expiracionRaw = _fechaExpiracionController.text.trim();
              if (expiracionRaw.isNotEmpty) {
                final expiracion = _tryParseDateStrict(expiracionRaw);
                if (expiracion != null && emision.isAfter(expiracion)) {
                  return 'La emisión no puede ser después de la expiración';
                }
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          _buildDateField(
            'Fecha de Expiración',
            _fechaExpiracionController,
            Icons.event_outlined,
            context: context,
            firstDate: DateTime(1950),
            lastDate: DateTime(DateTime.now().year + 20),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa la fecha';
              if (!RegExp(r'^\d{2}/\d{2}/\d{4}$').hasMatch(value)) return 'Formato inválido (DD/MM/AAAA)';
              final expiracion = _tryParseDateStrict(value);
              if (expiracion == null) return 'Fecha inválida';
              final emisionRaw = _fechaEmisionController.text.trim();
              if (emisionRaw.isNotEmpty) {
                final emision = _tryParseDateStrict(emisionRaw);
                if (emision != null && expiracion.isBefore(emision)) {
                  return 'La expiración no puede ser antes de la emisión';
                }
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          _buildField(
            'Correo Electrónico',
            _emailController,
            Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ingresa tu correo';
              if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context) * 2.5),
          FadeInUp(
            child: SizedBox(
              width: double.infinity,
              height: ResponsiveUtils.buttonHeight(context),
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final parts = _apellidosController.text.trim().split(RegExp(r'\s+'));
                    final apPaterno = parts.isNotEmpty ? parts.first : '';
                    final apMaterno = parts.length > 1 ? parts.skip(1).join(' ') : '';
                    // ignore: unawaited_futures
                    LocalStorageService.savePersonalData({
                      'nombre': _nombresController.text.trim(),
                      'apPaterno': apPaterno,
                      'apMaterno': apMaterno,
                      'fechaNacimiento': _fechaNacimientoController.text.trim(),
                      'numeroCI': _ciController.text.trim(),
                      'correo': _emailController.text.trim(),
                      'fechaEmision': _fechaEmisionController.text.trim(),
                      'fechaExpiracion': _fechaExpiracionController.text.trim(),
                    });
                    context.push('/password-setup');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Confirmar y Registrar',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color textDark = Color(0xFF1A3A5C);
    const Color whiteBg = Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: whiteBg,
      appBar: AppBar(
        backgroundColor: whiteBg,
        elevation: 0,
        title: const Text(
          'Confirmar Datos',
          style: TextStyle(color: textDark, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark),
          onPressed: () => context.pop(),
        ),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            // ── Layout landscape: dos columnas ──────────────────────────────
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Columna izquierda: título + ícono decorativo
                Expanded(
                  flex: 4,
                  child: Container(
                    color: whiteBg,
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.horizontalPadding(context),
                      vertical: 24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeInDown(
                          child: const Text(
                            'Verifica tu información',
                            style: TextStyle(
                              color: textDark,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeInLeft(
                          child: Text(
                            'Hemos extraído estos datos de tu carnet. Por favor, corrígelos si es necesario.',
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Center(
                          child: FadeInUp(
                            child: Icon(
                              Icons.verified_user_outlined,
                              size: 96,
                              color: const Color(0xFF305BA4).withOpacity(0.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Divisor visual
                Container(width: 1, color: const Color(0xFFEEF2F6)),
                // Columna derecha: formulario scrollable
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.horizontalPadding(context),
                      vertical: 16,
                    ),
                    child: _buildForm(context),
                  ),
                ),
              ],
            );
          }

          // ── Layout portrait ─────────────────────────────────────────────
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ResponsiveUtils.cardSpacing(context)),
                FadeInDown(
                  child: const Text(
                    'Verifica tu información',
                    style: TextStyle(color: textDark, fontSize: 24, fontWeight: FontWeight.bold),
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
                _buildForm(context),
              ],
            ),
          );
        },
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
    final bool isFilled = controller.text.isNotEmpty && !isBlocked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isFilled ? textDark : const Color(0xFF848E9C),
            fontSize: 13,
            fontWeight: isFilled ? FontWeight.bold : FontWeight.w500,
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
            fontWeight: isFilled || isBlocked ? FontWeight.bold : FontWeight.w600,
          ),
          onChanged: (value) {
            setState(() {});
            if (label == 'Nombre' || label == 'Apellidos') {
              final position = controller.selection;
              final formatted = _toTitleCase(value);
              if (formatted != value) {
                controller.text = formatted;
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
              color: isFilled ? primaryBlue : primaryBlue.withAlpha(179),
              size: 20,
            ),
            filled: true,
            fillColor: isBlocked
                ? Colors.grey[100]
                : (isFilled ? const Color(0xFFE8F0FE) : Colors.white),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isFilled ? primaryBlue.withOpacity(0.3) : const Color(0xFFEEF2F6),
                width: isFilled ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryBlue, width: 1.8),
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
