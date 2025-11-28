import 'package:flutter/material.dart';

class IlustracionWidget extends StatelessWidget {
  const IlustracionWidget({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    // Intentar cargar como SVG primero, si no existe usar Image con ColorFilter
    return ColorFiltered(
      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      child: Image.asset(
        'assets/svg/edificio.webp',
        width: width * 0.8,
        height: width * 1.0,
        fit: BoxFit.contain,
      ),
    );
  }
}
