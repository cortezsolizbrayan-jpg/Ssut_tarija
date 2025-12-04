import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:refactor_template/features/login/onboding/components/sign_in_form.dart';

class TarjetaAutenticacionWidget extends StatelessWidget {
  const TarjetaAutenticacionWidget({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: width * 0.06,
        right: width * 0.06,
        top: width * 0.08,
        bottom: width * 0.08,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0D0D0D),
            blurRadius: 24,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Iniciar Sesión',
              style: TextStyle(
                color: const Color(0xFF005BAC),
                fontSize: width * 0.05,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(height: width * 0.01),
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 450),
            child: Container(
              width: width * 0.25,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFFFC900),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: width * 0.06),
          // Usamos el formulario funcional con backend y navegación
          const SignInForm(),
          SizedBox(height: width * 0.04),
          FadeIn(
            duration: const Duration(milliseconds: 600),
            delay: const Duration(milliseconds: 900),
            child: Center(
              child: TextButton(
                onPressed: () {},
                child: Text(
                  'Recupera tu contraseña de acceso',
                  style: TextStyle(
                    color: const Color(0xFFFF8A00),
                    fontSize: width * 0.037,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
