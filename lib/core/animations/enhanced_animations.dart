import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';

/// Curvas de animación personalizadas para flujos más naturales
class CustomCurves {
  static const Curve smoothEntry = Curves.easeOutCubic;
  static const Curve smoothExit = Curves.easeInCubic;
  static const Curve elastic = Curves.elasticOut;
  static const Curve spring = Curves.easeOutBack;
  static const Curve gentle = Cubic(0.25, 0.1, 0.25, 1.0);
  static const Curve emphasized = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve decelerated = Cubic(0.0, 0.0, 0.2, 1.0);
}

/// Widget de animación de entrada escalonada optimizada con múltiples efectos
class StaggeredFadeSlide extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;
  final bool enableScale;
  final double scaleBegin;

  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 600),
    this.slideOffset = const Offset(0, 0.15),
    this.curve = CustomCurves.emphasized,
    this.enableScale = true,
    this.scaleBegin = 0.92,
  });

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Fade con curva suave
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.65, curve: CustomCurves.smoothEntry),
    ));

    // Slide con curva enfatizada
    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Scale opcional para efecto de profundidad
    _scaleAnimation = Tween<double>(
      begin: widget.enableScale ? widget.scaleBegin : 1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.8, curve: CustomCurves.spring),
    ));

    // Iniciar animación con delay escalonado
    Future.delayed(
      Duration(milliseconds: widget.index * widget.delay.inMilliseconds),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
//asasd
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Widget de animación de pulso suave para elementos de carga
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double minScale;
  final double maxScale;
  final double minOpacity;
  final double maxOpacity;
  final bool enableOpacity;

  const PulseAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1800),
    this.minScale = 0.98,
    this.maxScale = 1.02,
    this.minOpacity = 0.7,
    this.maxOpacity = 1.0,
    this.enableOpacity = false,
  });

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Animación de escala con curva suave
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: CustomCurves.gentle,
    ));

    // Animación de opacidad opcional
    _opacityAnimation = Tween<double>(
      begin: widget.enableOpacity ? widget.minOpacity : 1.0,
      end: widget.enableOpacity ? widget.maxOpacity : 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget de animación de progreso suave con efectos visuales mejorados
class SmoothProgressIndicator extends StatefulWidget {
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;
  final Duration animationDuration;
  final bool showShimmer;
  final Gradient? gradient;

  const SmoothProgressIndicator({
    super.key,
    required this.value,
    this.color = DesignTokens.primaryBlue,
    this.backgroundColor = DesignTokens.mainBackground,
    this.height = 8.0,
    this.borderRadius,
    this.animationDuration = const Duration(milliseconds: 800),
    this.showShimmer = false,
    this.gradient,
  });

  @override
  State<SmoothProgressIndicator> createState() => _SmoothProgressIndicatorState();
}

class _SmoothProgressIndicatorState extends State<SmoothProgressIndicator>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _shimmerController;
  late Animation<double> _progressAnimation;
  late Animation<double> _shimmerAnimation;
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: CustomCurves.emphasized,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    if (widget.showShimmer) {
      _shimmerController.repeat();
    }

    _updateProgress();
  }

  @override
  void didUpdateWidget(SmoothProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateProgress();
    }
    if (oldWidget.showShimmer != widget.showShimmer) {
      if (widget.showShimmer) {
        _shimmerController.repeat();
      } else {
        _shimmerController.stop();
      }
    }
  }

  void _updateProgress() {
    final oldValue = _currentValue;
    _currentValue = widget.value.clamp(0.0, 1.0);
    
    _progressAnimation = Tween<double>(
      begin: oldValue,
      end: _currentValue,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: CustomCurves.emphasized,
    ));

    _progressController.reset();
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
        color: widget.backgroundColor,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(widget.height / 2),
        child: AnimatedBuilder(
          animation: Listenable.merge([_progressAnimation, _shimmerAnimation]),
          builder: (context, child) {
            return Stack(
              children: [
                // Barra de progreso principal
                FractionallySizedBox(
                  widthFactor: _progressAnimation.value,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.gradient ??
                          LinearGradient(
                            colors: [
                              widget.color,
                              widget.color.withOpacity(0.8),
                            ],
                          ),
                    ),
                  ),
                ),
                // Efecto shimmer opcional
                if (widget.showShimmer && _progressAnimation.value > 0)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      widthFactor: _progressAnimation.value,
                      child: Transform.translate(
                        offset: Offset(_shimmerAnimation.value * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withOpacity(0.3),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Widget de animación de botón con efectos táctiles mejorados
class AnimatedButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? splashColor;
  final Color? highlightColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool enabled;
  final Duration animationDuration;
  final double pressedScale;
  final bool enableHaptic;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.splashColor,
    this.highlightColor,
    this.borderRadius,
    this.padding,
    this.enabled = true,
    this.animationDuration = const Duration(milliseconds: 150),
    this.pressedScale = 0.96,
    this.enableHaptic = true,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: CustomCurves.emphasized,
    ));

    _elevationAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = true);
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enabled) {
      setState(() => _isPressed = false);
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: widget.animationDuration,
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: widget.borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08 * _elevationAnimation.value),
                    blurRadius: 8 * _elevationAnimation.value,
                    offset: Offset(0, 4 * _elevationAnimation.value),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04 * _elevationAnimation.value),
                    blurRadius: 4 * _elevationAnimation.value,
                    offset: Offset(0, 2 * _elevationAnimation.value),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// Widget de animación de aparición con rebote suave
class BounceInAnimation extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  const BounceInAnimation({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<BounceInAnimation> createState() => _BounceInAnimationState();
}

class _BounceInAnimationState extends State<BounceInAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(_controller);

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Widget de animación de rotación suave
class RotateAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final bool repeat;
  final double begin;
  final double end;

  const RotateAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
    this.repeat = true,
    this.begin = 0.0,
    this.end = 1.0,
  });

  @override
  State<RotateAnimation> createState() => _RotateAnimationState();
}

class _RotateAnimationState extends State<RotateAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.begin,
      end: widget.end,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    if (widget.repeat) {
      _controller.repeat();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _animation,
      child: widget.child,
    );
  }
}

/// Widget de animación de shimmer para estados de carga
class ShimmerAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
  });

  @override
  State<ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat();
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
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                0.5,
                1.0,
              ],
              transform: GradientRotation(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Extensión para animaciones rápidas en widgets
extension AnimationExtensions on Widget {
  /// Aplica una animación de entrada con fade y slide
  Widget fadeSlideIn({
    int index = 0,
    Duration delay = const Duration(milliseconds: 80),
    Offset slideOffset = const Offset(0, 0.15),
    bool enableScale = true,
  }) {
    return StaggeredFadeSlide(
      index: index,
      delay: delay,
      slideOffset: slideOffset,
      enableScale: enableScale,
      child: this,
    );
  }

  /// Aplica una animación de pulso suave
  Widget pulse({
    Duration duration = const Duration(milliseconds: 1800),
    double minScale = 0.98,
    double maxScale = 1.02,
    bool enableOpacity = false,
  }) 
  {
    return PulseAnimation(
      duration: duration,
      minScale: minScale,
      maxScale: maxScale,
      enableOpacity: enableOpacity,
      child: this,
    );
  }

  /// Aplica una animación de rebote al aparecer
  Widget bounceIn({
    Duration delay = Duration.zero,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return BounceInAnimation(
      delay: delay,
      duration: duration,
      child: this,
    );
  }

  /// Aplica una animación de rotación
  Widget rotate({
    Duration duration = const Duration(seconds: 2),
    bool repeat = true,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return RotateAnimation(
      duration: duration,
      repeat: repeat,
      begin: begin,
      end: end,
      child: this,
    );
  }

  /// Aplica un efecto shimmer para estados de carga
  Widget shimmer({
    Duration duration = const Duration(milliseconds: 1500),
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
  }) {
    return ShimmerAnimation(
      duration: duration,
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: this,
    );
  }

  /// Convierte el widget en un botón animado
  Widget asAnimatedButton({
    VoidCallback? onTap,
    Color? backgroundColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
    bool enabled = true,
    double pressedScale = 0.96,
  }) {
    return AnimatedButton(
      onTap: onTap,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      padding: padding,
      enabled: enabled,
      pressedScale: pressedScale,
      child: this,
    );
  }
}

/// Transiciones de página personalizadas
class CustomPageTransitions {
  /// Transición de deslizamiento desde la derecha
  static Route slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: CustomCurves.emphasized));
        final offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transición de fade con escala
  static Route fadeScale(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

        final scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: CustomCurves.emphasized,
          ),
        );
//retorna 
        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,

          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  /// Transición de deslizamiento hacia arriba
  static Route slideUp(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        final tween = Tween(begin: begin, end: end)
            .chain(CurveTween(curve: CustomCurves.emphasized));
        final offsetAnimation = animation.drive(tween);
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );
//RETORNA UNA TRANSCIIOSN SLIDE PARA EL TEMA DE LA ANIMACION 
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}