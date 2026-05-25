import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String label;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? icon;
  final String? errorMessage;

  const CustomTextFormField({
    super.key,
    required this.label,
    this.onChanged,
    this.obscureText = false,
    this.icon,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3A5C),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          onChanged: onChanged,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: 'Ingresa tu $label',
            prefixIcon: icon,
            errorText: errorMessage,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
