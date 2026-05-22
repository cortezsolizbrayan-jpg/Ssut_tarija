import 'package:flutter/material.dart';

// ── Controlador compartido para todos los skeletons ───────────────────────────
// Un solo AnimationController para toda la pantalla — mucho más eficiente
// que un controller por cada skeleton.

class _SkeletonScope extends InheritedWidget {
  final Animation<double> animation;
  const _SkeletonScope({required this.animation, required super.child});

  static Animation<double>? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SkeletonScope>()?.animation;

  @override
  bool updateShouldNotify(_SkeletonScope old) => false;
}

/// Envuelve una sección con skeletons para compartir un único AnimationController.
/// Úsalo cuando tengas múltiples SkeletonLoader en la misma pantalla.
///
/// ```dart
/// SkeletonScope(
///   child: Column(children: [
///     SkeletonLoader(width: 200, height: 20),
///     SkeletonLoader(width: 150, height: 20),
///   ]),
/// )
/// ```
class SkeletonScope extends StatefulWidget {
  final Widget child;
  const SkeletonScope({super.key, required this.child});

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.35,
      end: 0.75,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonScope(animation: _animation, child: widget.child);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Placeholder animado tipo shimmer para estados de carga.
///
/// Si hay un [SkeletonScope] ancestro, usa su animación compartida.
/// Si no, crea su propio AnimationController (fallback).
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  AnimationController? _ownController;
  Animation<double>? _ownAnimation;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Si no hay SkeletonScope, crear controller propio
    if (_SkeletonScope.of(context) == null && _ownController == null) {
      _ownController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      )..repeat(reverse: true);
      _ownAnimation = Tween<double>(begin: 0.35, end: 0.75).animate(
        CurvedAnimation(parent: _ownController!, curve: Curves.easeInOut),
      );
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = _SkeletonScope.of(context) ?? _ownAnimation!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF1A2E47) : Colors.grey.shade300;

    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          color: base.withOpacity(animation.value),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Card skeleton para listas de programas.
/// Usa SkeletonScope para compartir un único AnimationController.
class ProgramaCardSkeleton extends StatelessWidget {
  const ProgramaCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return SkeletonScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonLoader(
              width: width - 40,
              height: width * 0.35,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(height: 12),
            SkeletonLoader(
              width: width * 0.7,
              height: 18,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            SkeletonLoader(
              width: width * 0.4,
              height: 14,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SkeletonLoader(
                  width: 80,
                  height: 32,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                SkeletonLoader(
                  width: 100,
                  height: 32,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
