import 'package:flutter/material.dart';
import 'datos_personales_validators.dart';

class PersonalDataDropdownField extends StatelessWidget {
  final Key? fieldKey;
  final String label;
  final String? value;
  final List<String> items;
  final bool isRequired;
  final double width;
  final Function(String?) onChanged;
  final IconData? icon;

  const PersonalDataDropdownField({
    super.key,
    this.fieldKey,
    required this.label,
    required this.value,
    required this.items,
    required this.isRequired,
    required this.width,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallPantalla = width < 400;

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
                      fontWeight: FontWeight.w700,
                      color: DatosPersonalesConstants.primaryBlue.withOpacity(
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
          DropdownButtonFormField<String>(
            value: value != null && items.contains(value) ? value : null,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF005BAC),
            ),
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: isSmallPantalla ? 14 : 15,
              color: DatosPersonalesConstants.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: icon != null
                  ? Icon(
                      icon,
                      color: DatosPersonalesConstants.primaryBlue.withOpacity(
                        0.5,
                      ),
                      size: 20,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFE8EEF7),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF005BAC),
                  width: 1.8,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: isSmallPantalla ? 14 : 15,
                    fontWeight: FontWeight.bold,
                    color: DatosPersonalesConstants.primaryBlue,
                  ),
                ),
              );
            }).toList(),
            onChanged: onChanged,
            validator: isRequired
                ? (v) => (v == null || v.isEmpty) ? 'Requerido' : null
                : null,
          ),
        ],
      ),
    );
  }
}

