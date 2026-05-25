import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'datos_personales_validators.dart';

class PersonalDataFormField extends StatelessWidget {
  final Key? fieldKey;
  final String label;
  final TextEditingController controller;
  final bool isRequired;
  final double width;
  final bool readOnly;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? Function(String?)? customValidator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const PersonalDataFormField({
    super.key,
    this.fieldKey,
    required this.label,
    required this.controller,
    required this.isRequired,
    required this.width,
    this.readOnly = false,
    this.onTap,
    this.icon,
    this.customValidator,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallPantalla = width < 400;
    final bool isFilled = controller.text.isNotEmpty;

    return Container(
      key: fieldKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmallPantalla ? 13 : 14,
                      fontWeight: isFilled ? FontWeight.w800 : FontWeight.w700,
                      color: isFilled
                          ? DatosPersonalesConstants.primaryBlue
                          : DatosPersonalesConstants.primaryBlue.withOpacity(
                              0.9,
                            ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isRequired)
                  const Text(
                    ' *',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontSize: isSmallPantalla ? 14 : 15,
              color: DatosPersonalesConstants.primaryBlue,
              fontWeight: isFilled ? FontWeight.bold : FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: isFilled
                  ? const Color(0xFFE8F0FE)
                  : (readOnly ? Colors.grey[50] : Colors.white),
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: isFilled
                          ? DatosPersonalesConstants.primaryBlue
                          : DatosPersonalesConstants.primaryBlue.withOpacity(
                              0.5,
                            ),
                      size: 20,
                    )
                  : null,
              hintText: 'Ingrese ${label.toLowerCase()}',
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.4),
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isFilled
                      ? DatosPersonalesConstants.primaryBlue.withOpacity(0.3)
                      : const Color(0xFFE8EEF7),
                  width: isFilled ? 1.5 : 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF005BAC),
                  width: 1.8,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 1),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            validator: (value) {
              if (isRequired && (value == null || value.isEmpty)) {
                return 'Campo requerido';
              }
              return customValidator?.call(value);
            },
            onChanged: (value) {
              if (onChanged != null) onChanged!(value);
            },
          ),
        ],
      ),
    );
  }
}

