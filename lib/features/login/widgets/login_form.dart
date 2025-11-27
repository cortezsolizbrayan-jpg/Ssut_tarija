import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final inputRadius = BorderRadius.circular(24.0);

    return Column(
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: "Correo electrónico o nombre de usuario",
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: width * 0.03, right: width * 0.02),
              child: Icon(Icons.person_outline, size: width * 0.055),
            ),
            filled: true,
            fillColor: const Color(0xFFF0F2F7),
            contentPadding: EdgeInsets.symmetric(
              vertical: width * 0.045,
              horizontal: width * 0.02,
            ),
            border: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
        SizedBox(height: width * 0.04),
        TextField(
          obscureText: true,
          decoration: InputDecoration(
            hintText: "Contraseña",
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: width * 0.03, right: width * 0.02),
              child: Icon(Icons.lock_outline, size: width * 0.055),
            ),
            suffixIcon: Padding(
              padding: EdgeInsets.only(right: width * 0.03),
              child: Icon(Icons.visibility_off, size: width * 0.055),
            ),
            filled: true,
            fillColor: const Color(0xFFF0F2F7),
            contentPadding: EdgeInsets.symmetric(
              vertical: width * 0.045,
              horizontal: width * 0.02,
            ),
            border: OutlineInputBorder(
              borderRadius: inputRadius,
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
