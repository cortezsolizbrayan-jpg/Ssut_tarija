import 'package:flutter/material.dart';

/// Transiciones de página personalizadas para la aplicación
/// Optimizadas para rendimiento y experiencia de usuario
class PageTransitions {
  // Duración estándar de transiciones
  static const Duration _defaultDuration = Duration(milliseconds: 280);
  static const Duration _fastDuration = Duration(milliseconds: 220);
  static const Curve _primaryCurve = Curves.easeInOutCubic;
  static const Curve _secondaryCurve = Curves.easeOutCubic;

  /// Transición con slide desde la derecha (como Material)
  /// Optimizada para navegación principal
  static Route slideFromRight(Widget page, {Duration? duration, Curve? curve}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: effectiveCurve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
    );
  }

  /// Transición con slide desde abajo (Modal style)
  /// Ideal para modales y bottom sheets
  static Route slideFromBottom(
    Widget page, {
    Duration? duration,
    Curve? curve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _secondaryCurve;
        final tween = Tween<Offset>(
          begin: const Offset(0.0, 1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: effectiveCurve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: duration ?? const Duration(milliseconds: 320),
      reverseTransitionDuration: duration ?? _fastDuration,
      opaque: false,
      barrierColor: Colors.black54,
    );
  }

  /// Transición con slide desde arriba
  /// Útil para dropdowns y menús superiores
  static Route slideFromTop(Widget page, {Duration? duration, Curve? curve}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _secondaryCurve;
        final tween = Tween<Offset>(
          begin: const Offset(0.0, -1.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: effectiveCurve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: duration ?? _fastDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
    );
  }

  /// Transición con slide desde la izquierda
  /// Para navegación hacia atrás o lateral
  static Route slideFromLeft(Widget page, {Duration? duration, Curve? curve}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final tween = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: effectiveCurve));

        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
    );
  }

  /// Transición con fade (desvanecimiento)
  /// Suave y rápida, ideal para overlays
  static Route fade(Widget page, {Duration? duration, Curve? curve}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final opacityTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));

        return FadeTransition(
          opacity: animation.drive(opacityTween),
          child: child,
        );
      },
      transitionDuration: duration ?? _fastDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
      opaque: false,
    );
  }

  /// Transición con scale (zoom in)
  /// Efecto de acercamiento, ideal para detalles y modales
  static Route scaleIn(
    Widget page, {
    Duration? duration,
    Curve? curve,
    double beginScale = 0.8,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final scaleTween = Tween<double>(
          begin: beginScale,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));
        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
      opaque: false,
      barrierColor: Colors.black54,
    );
  }

  /// Transición combinada: slide + fade
  /// La más usada, combina deslizamiento y desvanecimiento
  static Route slideFade(
    Widget page, {
    Offset? begin,
    Duration? duration,
    Curve? curve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final effectiveBegin = begin ?? const Offset(0.24, 0.0);

        final slideTween = Tween<Offset>(
          begin: effectiveBegin,
          end: Offset.zero,
        ).chain(CurveTween(curve: effectiveCurve));

        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
    );
  }

  /// Transición con rotación 3D en el eje Y
  /// Efecto de página que gira, para casos especiales
  static Route rotate3D(Widget page, {Duration? duration, Curve? curve}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final rotateTween = Tween<double>(
          begin: 0.5,
          end: 0.0,
        ).chain(CurveTween(curve: effectiveCurve));

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(animation.drive(rotateTween).value * 3.14159),
              alignment: Alignment.center,
              child: child,
            );
          },
          child: child,
        );
      },
      transitionDuration: duration ?? const Duration(milliseconds: 520),
      reverseTransitionDuration: duration ?? const Duration(milliseconds: 520),
    );
  }

  /// Transición con efecto de zoom compartido (Shared Element style)
  static Route sharedAxisHorizontal(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var fadeInTween = Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: const Interval(0.3, 1.0, curve: curve)));

        var slideInTween = Tween(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        var fadeOutTween = Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: const Interval(0.0, 0.3, curve: curve)));

        var slideOutTween = Tween(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).chain(CurveTween(curve: curve));

        return Stack(
          children: [
            FadeTransition(
              opacity: secondaryAnimation.drive(fadeOutTween),
              child: SlideTransition(
                position: secondaryAnimation.drive(slideOutTween),
                child: Container(), // Página anterior
              ),
            ),
            FadeTransition(
              opacity: animation.drive(fadeInTween),
              child: SlideTransition(
                position: animation.drive(slideInTween),
                child: child,
              ),
            ),
          ],
        );
      },
      transitionDuration: const Duration(milliseconds: 420),
    );
  }

  /// Transición estilo iOS (Cupertino)
  static Route cupertinoStyle(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.linearToEaseOut;

        var slideTween = Tween(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

      return SlideTransition(
        position: animation.drive(slideTween),
        child: child,
      );
    },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }

  /// Transición con blur (desenfoque)
  /// Nota: Requiere importar dart:ui para ImageFilter
  static Route blurFade(
    Widget page, {
    Duration? duration,
    double blurAmount = 5.0,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

        return FadeTransition(
          opacity: animation.drive(opacityTween),
          child: child,
        );
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.3),
    );
  }

  /// Transición con efecto de expansión desde un punto
  /// Útil para elementos que se expanden desde un botón o icono
  static Route expandFrom(
    Widget page, {
    Alignment alignment = Alignment.center,
    Duration? duration,
    Curve? curve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final scaleTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));
        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            alignment: alignment,
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
      opaque: false,
      barrierColor: Colors.black54,
    );
  }

  /// Transición con efecto de deslizamiento diagonal
  /// Útil para transiciones dinámicas
  static Route diagonalSlide(
    Widget page, {
    Offset? begin,
    Duration? duration,
    Curve? curve,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final effectiveCurve = curve ?? _primaryCurve;
        final effectiveBegin = begin ?? const Offset(1.0, -1.0);

        final slideTween = Tween<Offset>(
          begin: effectiveBegin,
          end: Offset.zero,
        ).chain(CurveTween(curve: effectiveCurve));

        final fadeTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: effectiveCurve));

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: duration ?? _defaultDuration,
      reverseTransitionDuration: duration ?? _fastDuration,
    );
  }
}

/// Extension para facilitar la navegación con transiciones
/// Compatible con Navigator tradicional
extension NavigationExtension on BuildContext {
  /// Navegar con transición desde la derecha
  Future<T?> pushSlideRight<T>(
    Widget page, {
    Duration? duration,
    Curve? curve,
  }) {
    return Navigator.of(this).push<T>(
      PageTransitions.slideFromRight(page, duration: duration, curve: curve)
          as Route<T>,
    );
  }

  /// Navegar con transición desde abajo
  Future<T?> pushSlideBottom<T>(
    Widget page, {
    Duration? duration,
    Curve? curve,
  }) {
    return Navigator.of(this).push<T>(
      PageTransitions.slideFromBottom(page, duration: duration, curve: curve)
          as Route<T>,
    );
  }

  /// Navegar con transición desde arriba
  Future<T?> pushSlideTop<T>(Widget page, {Duration? duration, Curve? curve}) {
    return Navigator.of(this).push<T>(
      PageTransitions.slideFromTop(page, duration: duration, curve: curve)
          as Route<T>,
    );
  }

  /// Navegar con transición desde la izquierda
  Future<T?> pushSlideLeft<T>(Widget page, {Duration? duration, Curve? curve}) {
    return Navigator.of(this).push<T>(
      PageTransitions.slideFromLeft(page, duration: duration, curve: curve)
          as Route<T>,
    );
  }

  /// Navegar con fade
  Future<T?> pushFade<T>(Widget page, {Duration? duration, Curve? curve}) {
    return Navigator.of(this).push<T>(
      PageTransitions.fade(page, duration: duration, curve: curve) as Route<T>,
    );
  }

  /// Navegar con scale
  Future<T?> pushScale<T>(
    Widget page, {
    Duration? duration,
    Curve? curve,
    double beginScale = 0.8,
  }) {
    return Navigator.of(this).push<T>(
      PageTransitions.scaleIn(
            page,
            duration: duration,
            curve: curve,
            beginScale: beginScale,
          )
          as Route<T>,
    );
  }

  /// Navegar con slide + fade
  Future<T?> pushSlideFade<T>(
    Widget page, {
    Offset? begin,
    Duration? duration,
    Curve? curve,
  }) {
    return Navigator.of(this).push<T>(
      PageTransitions.slideFade(
            page,
            begin: begin,
            duration: duration,
            curve: curve,
          )
          as Route<T>,
    );
  }

  /// Navegar con rotación 3D
  Future<T?> pushRotate3D<T>(Widget page, {Duration? duration, Curve? curve}) {
    return Navigator.of(this).push<T>(
      PageTransitions.rotate3D(page, duration: duration, curve: curve)
          as Route<T>,
    );
  }

  /// Navegar con expansión desde un punto
  Future<T?> pushExpandFrom<T>(
    Widget page, {
    Alignment alignment = Alignment.center,
    Duration? duration,
    Curve? curve,
  }) {
    return Navigator.of(this).push<T>(
      PageTransitions.expandFrom(
            page,
            alignment: alignment,
            duration: duration,
            curve: curve,
          )
          as Route<T>,
    );
  }

  /// Navegar con deslizamiento diagonal
  Future<T?> pushDiagonal<T>(
    Widget page, {
    Offset? begin,
    Duration? duration,
    Curve? curve,
  }) {
    return Navigator.of(this).push<T>(
      PageTransitions.diagonalSlide(
            page,
            begin: begin,
            duration: duration,
            curve: curve,
          )
          as Route<T>,
    );
  }
}

// Extension para GoRouter comentada - requiere configuración adicional
// Para usar transiciones con GoRouter, configura en app_router.dart:
//
// GoRoute(
//   path: '/detalle',
//   pageBuilder: (context, state) => CustomTransitionPage(
//     key: state.pageKey,
//     child: DetallePage(),
//     transitionsBuilder: PageTransitions.slideFade,
//   ),
// )
