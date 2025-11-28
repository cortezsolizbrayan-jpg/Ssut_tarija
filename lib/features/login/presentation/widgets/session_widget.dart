import 'package:flutter/material.dart';

class SessionWidget extends StatelessWidget {
  const SessionWidget({
    super.key,
    required this.label,
    required this.width,
    this.icon,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final IconData? icon;
  final double width;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE6E9EF);

    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: const Color(0xFF9AA2B1),
          fontSize: width * 0.04,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: width * 0.06, color: const Color(0xFF9AA2B1)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: EdgeInsets.symmetric(vertical: width * 0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF1A4C9C)),
        ),
      ),
    );
  }
}
