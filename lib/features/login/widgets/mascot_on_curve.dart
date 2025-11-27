import 'package:flutter/material.dart';

class MascotOnCurve extends StatelessWidget {
  final double height;
  final Color primaryYellow;
  final Color deepBlue;

  const MascotOnCurve({
    super.key,
    required this.height,
    required this.primaryYellow,
    required this.deepBlue,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // El widget ocupa toda la anchura y la 'height' que le pases.
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Curva / panel inferior oscuro
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: height * 0.72,
              // hacemos una curva con BorderRadius grande en la parte superior
              decoration: BoxDecoration(
                color: deepBlue,
                borderRadius: BorderRadius.vertical(
                  top: Radius.elliptical(w * 0.6, height * 0.6),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: height * 0.18,
                  left: w * 0.06,
                  right: w * 0.06,
                ),
                child: Column(
                  children: [
                    // Espacio donde luego se ubica el botón grande
                    SizedBox(height: height * 0.02),
                    // Botón principal
                    SizedBox(
                      width: double.infinity,
                      height: height * 0.18,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: height * 0.03,
                          ),
                        ),
                        onPressed: () {},
                        child: Text(
                          "INICIAR SESIÓN",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: w * 0.045,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    // Texto de soporte
                    Text(
                      "No tienes acceso? Comunícate con soporte!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: w * 0.034,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Mascota posicionada encima de la curva (superpuesta)
          Positioned(
            bottom: height * 0.52,
            left: (w / 2) - (w * 0.12),
            child: SizedBox(
              width: w * 0.24,
              height: w * 0.24,
              child: Image.asset(
                "assets/images/mascot.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
