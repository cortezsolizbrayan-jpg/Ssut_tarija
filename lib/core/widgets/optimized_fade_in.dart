import 'package:flutter/material.dart';

/// Reemplazo optimizado de animate_do FadeIn
/// Usa widgets nativos de Flutter para mejor rendimiento
class OptimizedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Curve curve;
  final double from;

  const OptimizedFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.curve = Curves.easeOut,
    this.from = 0.0,
  });

  @override
  State<OptimizedFadeIn> createState() => _OptimizedFadeInState();
}

class _OptimizedFadeInState extends State<OptimizedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.from / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Iniciar con delay
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.from == 0.0) {
      // Solo fade, sin slide
      return FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      );
    }

    // Fade + slide
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Variante optimizada de FadeInDown
class OptimizedFadeInDown extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double from;

  const OptimizedFadeInDown({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.from = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedFadeIn(
      duration: duration,
      delay: delay,
      from: -from, // Negativo para bajar
      child: child,
    );
  }
}

/// Variante optimizada de FadeInUp
class OptimizedFadeInUp extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final double from;

  const OptimizedFadeInUp({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.delay = Duration.zero,
    this.from = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return OptimizedFadeIn(
      duration: duration,
      delay: delay,
      from: from, // Positivo para subir
      child: child,
    );
  }
}

// Aliases para compatibilidad con código existente
typedef FadeInDown = OptimizedFadeInDown;
typedef FadeInUp = OptimizedFadeInUp;
