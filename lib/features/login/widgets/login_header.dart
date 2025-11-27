import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      children: [
        // Imagen circular grande de fondo (opcional)
        SizedBox(
          width: w * 0.46,
          height: w * 0.46,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // círculo de fondo tenue
              Container(
                width: w * 0.46,
                height: w * 0.46,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              // icono de graduación
              Image.asset(
                "assets/images/graduation_icon.png",
                width: w * 0.28,
                height: w * 0.28,
                fit: BoxFit.contain,
                color: const Color(0xFFEEF3FB).withOpacity(0.95),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        const Text(
          "BIENVENIDO DE NUEVO",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.6,
            color: Color(0xFF0E0A3A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "INICIAR SESIÓN",
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
