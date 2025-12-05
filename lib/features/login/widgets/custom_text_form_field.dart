import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextFormField extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final String? Function(String?)? validator;
  final Icon? icon;
  final String? initialValue;
  final TextEditingController? controller;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    this.label,
    this.hint,
    this.errorMessage,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
    this.icon,
    this.initialValue,
    this.controller,
    this.inputFormatters,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool _isTextHidden = true;

  @override
  void initState() {
    super.initState();
    _isTextHidden = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    return TextFormField(
      inputFormatters: widget.inputFormatters,
      controller: widget.controller,
      initialValue: widget.initialValue,
      onChanged: widget.onChanged,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      obscureText: widget.obscureText ? _isTextHidden : false,
      keyboardType: widget.keyboardType,
      style: const TextStyle(fontSize: 17, color: Colors.black),
      decoration: _inputDecoration(
        size,
        hintText: widget.hint ?? '',
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isTextHidden ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF005BAC),
                ),
                onPressed: () {
                  setState(() {
                    _isTextHidden = !_isTextHidden;
                  });
                },
              )
            : (widget.icon),
      ).copyWith(labelText: widget.label, errorText: widget.errorMessage),
    );
  }

  /// Estilo personalizado solicitado
  InputDecoration _inputDecoration(
    double width, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.035,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF005BAC), width: 1.2),
      ),
    );
  }
}
