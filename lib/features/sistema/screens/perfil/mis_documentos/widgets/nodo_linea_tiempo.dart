import 'package:flutter/material.dart';
import '../constantes.dart';

enum EstadoNodoMapa { pendiente, enProgreso, completado }

class NodoLineaTiempo extends StatelessWidget {
  final EstadoNodoMapa estado;
  final bool esUltimo;

  const NodoLineaTiempo({
    super.key,
    required this.estado,
    this.esUltimo = false,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icono;

    switch (estado) {
      case EstadoNodoMapa.completado:
        color = ConstantesMisDocumentos.kSuccessColor;
        icono = Icons.check_circle_rounded;
        break;
      case EstadoNodoMapa.enProgreso:
        color = ConstantesMisDocumentos.kPrimaryColor;
        icono = Icons.radio_button_checked_rounded;
        break;
      case EstadoNodoMapa.pendiente:
        color = Colors.grey.shade300;
        icono = Icons.circle_outlined;
        break;
    }

    return Column(
      children: [
        Icon(icono, color: color, size: 28),
        if (!esUltimo)
          Container(
            width: 2,
            height: 40,
            color: color.withOpacity(0.3),
          ),
      ],
    );
  }
}
