import 'package:flutter/material.dart';

import 'components/diplomado_card.dart';

class DiplomadosScreen extends StatelessWidget {
  const DiplomadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Mis Diplomados",
                  style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Tarjeta del diplomado
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
    );
  }
}
