import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Widget que anima la transición entre temas claro y oscuro
/// Usa un efecto de fade y scale suave
class AnimatedThemeSwitcher extends StatelessWidget {
  final Widget child;
  final ThemeMode themeMode;

  const AnimatedThemeSwitcher({
    super.key,
    required this.child,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Animación de fade
        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        // Animación de scale sutil
        final scaleAnimation = Tween<double>(
          begin: 0.98,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        ));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(themeMode),
        child: child,
      ),
    );
  }
}

/// Botón toggle para cambiar entre modo claro y oscuro
/// Con animación suave y diseño profesional
class ThemeToggleButton extends StatefulWidget {
  final ThemeMode currentMode;
  final ValueChanged<ThemeMode> onChanged;
  final bool showLabel;

  const ThemeToggleButton({
    super.key,
    required this.currentMode,
    required this.onChanged,
    this.showLabel = false,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    _controller.forward(from: 0.0);
    
    final newMode = widget.currentMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    
    widget.onChanged(newMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.currentMode == ThemeMode.dark;
    final theme = Theme.of(context);

    if (widget.showLabel) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleTheme,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value * 3.14159,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Icon(
                          isDark ? Icons.dark_mode : Icons.light_mode,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDark ? 'Modo Oscuro' : 'Modo Claro',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isDark
                            ? 'Activo - Reduce el brillo'
                            : 'Activo - Mejor visibilidad',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) => _toggleTheme(),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Botón simple sin label
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 3.14159,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: IconButton(
              onPressed: _toggleTheme,
              icon: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode,
                size: 24,
              ),
              tooltip: isDark ? 'Cambiar a modo claro' : 'Cambiar a modo oscuro',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget de transición circular para cambio de tema
/// Efecto visual más dramático (opcional)
class CircularThemeReveal extends StatefulWidget {
  final Widget child;
  final ThemeMode themeMode;
  final Offset? center;

  const CircularThemeReveal({
    super.key,
    required this.child,
    required this.themeMode,
    this.center,
  });

  @override
  State<CircularThemeReveal> createState() => _CircularThemeRevealState();
}

class _CircularThemeRevealState extends State<CircularThemeReveal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(CircularThemeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeMode != widget.themeMode) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ClipPath(
          clipper: _CircularRevealClipper(
            fraction: _animation.value,
            center: widget.center ?? Offset.zero,
          ),
          child: widget.child,
        );
      },
    );
  }
}

class _CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Offset center;

  _CircularRevealClipper({
    required this.fraction,
    required this.center,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final maxRadius = math.sqrt(size.width * size.width + size.height * size.height);
    final radius = maxRadius * fraction;

    path.addOval(Rect.fromCircle(
      center: center,
      radius: radius,
    ));

    return path;
  }

  @override
  bool shouldReclip(_CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
