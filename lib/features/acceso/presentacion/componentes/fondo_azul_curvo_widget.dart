import 'package:flutter/material.dart';

/// Fondo azul curvo que se usa como encabezado en la pantalla de login.
/// Dibuja la forma curva usando un [CustomPainter].
class FondoAzulCurvoWidget extends StatelessWidget {
  const FondoAzulCurvoWidget({
    super.key,
    required this.child,
    this.color = const Color(0xFF005BAC),
    this.height,
  });

  /// Contenido que se muestra encima del fondo azul.
  final Widget child;

  /// Color del fondo azul.
  final Color color;

  /// Altura del header azul. Si es null, se adapta al contenido.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(painter: _FondoAzulCurvoPainter(color), child: child),
    );
  }
}

class _FondoAzulCurvoPainter extends CustomPainter {
  _FondoAzulCurvoPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      // Bajamos solo un poco más los laterales del fondo azul
      ..lineTo(0, size.height * 1.15)
      ..quadraticBezierTo(
        size.width * 0.50, // punto medio en X
        size.height * 1.55, // "panza" ligeramente más profunda
        size.width, // extremo derecho
        size.height * 1.15,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FondoAzulCurvoPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

