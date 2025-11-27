import 'package:flutter/material.dart';

class PerfectCircleBackground extends StatelessWidget {
  const PerfectCircleBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(painter: _PerfectCirclePainter()),
    );
  }
}

class _PerfectCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8EBF3)
      ..style = PaintingStyle.fill;

    // Círculo perfecto en el centro de la pantalla
    final center = Offset(size.width / 2, size.height / 2);
    final radius = 100.0; // radio del círculo, ajusta a tu gusto

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
