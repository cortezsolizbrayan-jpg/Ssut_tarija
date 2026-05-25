import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

// Importaciones del proyecto
import 'package:refactor_template/features/acceso/presentacion/bloques/identity/identity_state.dart';

class CorrectionFormOverlay extends StatelessWidget {
  final IdentityState state;
  final TextEditingController ciController;
  final TextEditingController nombresController;
  final TextEditingController apellidosController;
  final TextEditingController emisionController;
  final TextEditingController expiracionController;
  final VoidCallback onConfirm;
  final VoidCallback onSaveAndSkip;
  final VoidCallback onBack;
  final Future<DateTime?> Function(
    String label,
    TextEditingController controller,
  )
  onDatePickerTap;

  const CorrectionFormOverlay({
    super.key,
    required this.state,
    required this.ciController,
    required this.nombresController,
    required this.apellidosController,
    required this.emisionController,
    required this.expiracionController,
    required this.onConfirm,
    required this.onSaveAndSkip,
    required this.onBack,
    required this.onDatePickerTap,
  });

  static const Color primaryBlue = Color(0xFF305BA4);
  static const Color darkBlue = Color(0xFF1A3A5C);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withAlpha(153),
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: FadeInUp(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_note, size: 50, color: primaryBlue),
                  const SizedBox(height: 10),
                  const Text(
                    "Confirma tus datos",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: darkBlue,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "Toca cualquier campo para corregirlo si hay errores.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 25),
                  _buildTextField("Número de CI", ciController, Icons.badge),
                  const SizedBox(height: 15),
                  _buildTextField("Nombres", nombresController, Icons.person),
                  const SizedBox(height: 15),
                  _buildTextField(
                    "Apellidos",
                    apellidosController,
                    Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildDatePickerField(
                    "Fecha de Emisión",
                    emisionController,
                    Icons.date_range,
                  ),
                  const SizedBox(height: 15),
                  _buildDatePickerField(
                    "Fecha de Expiración",
                    expiracionController,
                    Icons.event_repeat,
                  ),
                  const SizedBox(height: 30),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text("Confirmar e Ir al Siguiente Paso"),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryBlue,
            side: const BorderSide(color: primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onSaveAndSkip,
          icon: const Icon(Icons.forward_to_inbox_rounded, size: 20),
          label: const Text("Registrar CI y subir foto después"),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBack,
          child: Text(
            state.isPdfMode
                ? "Cambiar a fotos separadas"
                : "Volver a tomar fotos",
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(label, icon),
    );
  }

  Widget _buildDatePickerField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    final bool isExp =
        label.toLowerCase().contains('expiración') ||
        label.toLowerCase().contains('expiracion');
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => onDatePickerTap(label, controller),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(label, icon).copyWith(
        suffixIcon: isExp
            ? IconButton(
                icon: const Icon(
                  Icons.all_inclusive_rounded,
                  color: primaryBlue,
                ),
                onPressed: () => controller.text = 'INDEFINIDO',
              )
            : const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
      prefixIcon: Icon(icon, color: primaryBlue, size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}

