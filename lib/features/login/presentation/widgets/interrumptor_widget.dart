// Widget para la ilustración del edificio en blanco
// Animación de carga
import 'package:flutter/material.dart';

class InterruptorWidget extends StatefulWidget {
  const InterruptorWidget({super.key, required this.width});

  final double width;

  @override
  State<InterruptorWidget> createState() => _InterruptorWidgetState();
}

class _InterruptorWidgetState extends State<InterruptorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switchWidth = widget.width * 0.30;
    final switchHeight = widget.width * 0.1;
    final padding = 3.0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: switchWidth,
          height: switchHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF113A82),
            borderRadius: BorderRadius.circular(switchHeight / 2),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                (switchHeight - padding * 2) / 2,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: (switchWidth - padding * 2) * _animation.value,
                  height: switchHeight - padding * 2,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      (switchHeight - padding * 2) / 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
