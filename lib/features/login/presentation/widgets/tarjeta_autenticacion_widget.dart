import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import 'widgets.dart';

class TarjetaAutenticacionWidget extends StatelessWidget {
  const TarjetaAutenticacionWidget({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: width * 0.06,
            right: width * 0.06,
            top: width * 0.08,
            bottom: width * 0.16,
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
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    color: const Color(0xFF15223B),
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
                    color: const Color(0xFFE54D52),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: width * 0.06),
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 500),
                child: SessionWidget(
                  label: 'Usuario',
                  width: width,
                  icon: Icons.person_outline,
                ),
              ),
              SizedBox(height: width * 0.05),
              FadeInLeft(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 700),
                child: SessionWidget(
                  label: 'Contraseña',
                  icon: Icons.lock_outline,
                  width: width,
                  obscureText: true,
                  suffix: Icon(
                    Icons.remove_red_eye_outlined,
                    color: const Color(0xFF9AA2B1),
                    size: width * 0.055,
                  ),
                ),
              ),
              SizedBox(height: width * 0.04),
              FadeIn(
                duration: const Duration(milliseconds: 600),
                delay: const Duration(milliseconds: 900),
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Olvidaste Contraseña?',
                    style: TextStyle(
                      color: const Color(0xFFFF8A00),
                      fontSize: width * 0.037,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -width * 0.07,
          left: width * 0.09,
          right: width * 0.09,
          child: BounceInUp(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 1100),
            child: BotonPrimario(width: width),
          ),
        ),
      ],
    );
  }
}
