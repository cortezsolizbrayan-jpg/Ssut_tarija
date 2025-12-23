import 'package:flutter/material.dart';

/// Transiciones de página personalizadas para la aplicación
class PageTransitions {
  /// Transición con slide desde la derecha (como Material)
  static Route slideFromRight(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transición con slide desde abajo (Modal style)
  static Route slideFromBottom(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transición con fade
  static Route fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Transición con scale (zoom in)
  static Route scaleIn(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutQuart;
        var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween(begin: 0.0, end: 1.0);

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: ScaleTransition(
            scale: animation.drive(scaleTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transición combinada: slide + fade
  static Route slideFade(Widget page, {Offset begin = const Offset(0.3, 0.0)}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var slideTween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        var fadeTween = Tween(begin: 0.0, end: 1.0);

        return FadeTransition(
          opacity: animation.drive(fadeTween),
          child: SlideTransition(
            position: animation.drive(slideTween),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 450),
    );
  }

  /// Transición con rotación 3D en el eje Y
  static Route rotate3D(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        var rotateTween = Tween(begin: 0.5, end: 0.0).chain(
          CurveTween(curve: curve),
        );

        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(animation.drive(rotateTween).value * 3.14159),
          alignment: Alignment.center,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  /// Transición con efecto de zoom compartido (Shared Element style)
  static Route sharedAxisHorizontal(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;

        var fadeInTween = Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: const Interval(0.3, 1.0, curve: curve)),
        );

        var slideInTween = Tween(
          begin: const Offset(0.3, 0.0),
          end: Offset.zero,
        ).chain(
          CurveTween(curve: curve),
        );

        var fadeOutTween = Tween(begin: 1.0, end: 0.0).chain(
          CurveTween(curve: const Interval(0.0, 0.3, curve: curve)),
        );

        var slideOutTween = Tween(
          begin: Offset.zero,
          end: const Offset(-0.3, 0.0),
        ).chain(
          CurveTween(curve: curve),
        );

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
      transitionDuration: const Duration(milliseconds: 500),
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
        ).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(slideTween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  /// Transición con blur (desenfoque)
  static Route blurFade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.3),
    );
  }
}

/// Extension para facilitar la navegación con transiciones
extension NavigationExtension on BuildContext {
  /// Navegar con transición desde la derecha
  Future<T?> pushSlideRight<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.slideFromRight(page));
  }

  /// Navegar con transición desde abajo
  Future<T?> pushSlideBottom<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.slideFromBottom(page));
  }

  /// Navegar con fade
  Future<T?> pushFade<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.fade(page));
  }

  /// Navegar con scale
  Future<T?> pushScale<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.scaleIn(page));
  }

  /// Navegar con slide + fade
  Future<T?> pushSlideFade<T>(Widget page) {
    return Navigator.of(this).push<T>(PageTransitions.slideFade(page));
  }
}
