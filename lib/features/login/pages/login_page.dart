import 'package:flutter/material.dart';
import 'package:refactor_template/features/login/widgets/login_top_background.dart';
import '../widgets/login_header.dart';
import '../widgets/login_form.dart';
import '../widgets/mascot_on_curve.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    const bgColor = Color(0xFFEDF7FF);
    const primaryYellow = Color(0xFFFFC727);
    const deepBlue = Color(0xFF0E0A3A);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo plomito orgánico aquí (DEBAJO de todo)
            const PerfectCircleBackground(),
            SingleChildScrollView(
              child: SizedBox(
                width: width,
                height: height,
                child: Column(
                  children: [
                    SizedBox(height: height * 0.02),

                    // header encima del fondo
                    const LoginHeader(),

                    SizedBox(height: height * 0.02),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
                      child: Column(
                        children: [
                          const LoginForm(),
                          SizedBox(height: height * 0.03),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                "Olvidé mi contraseña",
                                style: TextStyle(
                                  color: deepBlue,
                                  fontWeight: FontWeight.w600,
                                  fontSize: width * 0.035,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mascota sobre curva
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MascotOnCurve(
                height: height * 0.32,
                primaryYellow: primaryYellow,
                deepBlue: deepBlue,
              ),
            ),

            // Botón amarillo arriba
            Positioned(
              top: height * 0.02,
              left: width * 0.04,
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: width * 0.11,
                  height: width * 0.11,
                  decoration: BoxDecoration(
                    color: primaryYellow,
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black12,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black,
                    size: width * 0.06,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
