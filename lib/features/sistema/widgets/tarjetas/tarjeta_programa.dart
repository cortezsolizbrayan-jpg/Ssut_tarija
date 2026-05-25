import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Tarjeta de programa con indicador de progreso circular
class ProgramCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0.0 a 1.0
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? selectedColor;

  const ProgramCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    this.isSelected = false,
    this.onTap,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005BAC);
    const lightBlue = Color(0xFF3D8FE0);
    
    // Validar progress para evitar Infinity/NaN
    final validProgress = progress.isFinite && !progress.isNaN 
        ? progress.clamp(0.0, 1.0) 
        : 0.0;
    
    final bgColor = isSelected 
        ? (selectedColor ?? lightBlue)
        : (backgroundColor ?? Colors.white);
    
    final textColor = isSelected ? Colors.white : const Color(0xFF333333);
    final subtitleColor = isSelected 
        ? Colors.white.withOpacity(0.9) 
        : const Color(0xFF666666);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? primaryBlue.withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 16 : 12,
              offset: Offset(0, isSelected ? 8 : 4),
            ),
          ],
          border: Border.all(
            color: isSelected 
                ? Colors.transparent 
                : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            
            // Indicador de progreso y subtítulo
            Row(
              children: [
                // Progreso circular
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo de fondo
                      CustomPaint(
                        size: const Size(50, 50),
                        painter: _CircularProgressPainter(
                          progress: 1.0,
                          color: isSelected 
                              ? Colors.white.withOpacity(0.3)
                              : const Color(0xFFE8E8E8),
                          strokeWidth: 4,
                        ),
                      ),
                      // Círculo de progreso
                      CustomPaint(
                        size: const Size(50, 50),
                        painter: _CircularProgressPainter(
                          progress: validProgress,
                          color: isSelected 
                              ? Colors.white
                              : primaryBlue,
                          strokeWidth: 4,
                        ),
                      ),
                      // Porcentaje
                      Text(
                        '${(validProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // Subtítulo
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter para el indicador circular de progreso
class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    
    const startAngle = -math.pi / 2; // Comenzar desde arriba
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

