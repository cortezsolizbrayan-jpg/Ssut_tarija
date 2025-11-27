import 'package:flutter/material.dart';

import 'components/app_header.dart';
import 'components/diplomado_card.dart';

class DiplomadosScreen extends StatelessWidget {
  const DiplomadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Círculo decorativo con degradado en la parte superior posterior
          Positioned(
            top: -120,
            right: -60,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.2,
                  colors: [
                    const Color(0xFF4A9FD8).withOpacity(0.5),
                    const Color(0xFF2196F3).withOpacity(0.3),
                    const Color(0xFF87CEEB).withOpacity(0.15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 0.7, 1.0],
                ),
              ),
            ),
          ),
          // Contenido principal con header
          Column(
            children: [
              // Header azul oscuro
              const AppHeader(),
              // Contenido scrollable
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // Tarjeta del diplomado
                        const DiplomadoCard(
                          titulo: "DISEÑO, DESARROLLO Y MANTENIMIENTO",
                          saldoPendiente: 600,
                          progresoPago: 75,
                        ),
                        const SizedBox(height: 20),
                        const DiplomadoCard(
                          titulo: "DISEÑO, DESARROLLO Y MANTENIMIENTO",
                          saldoPendiente: 600,
                          progresoPago: 75,
                        ),
                        const SizedBox(height: 20),
                        const DiplomadoCard(
                          titulo: "DISEÑO, DESARROLLO Y MANTENIMIENTO",
                          saldoPendiente: 600,
                          progresoPago: 75,
                        ),
                        const SizedBox(height: 20),
                        const DiplomadoCard(
                          titulo: "DISEÑO, DESARROLLO Y MANTENIMIENTO",
                          saldoPendiente: 600,
                          progresoPago: 75,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
