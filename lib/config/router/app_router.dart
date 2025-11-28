import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';

final goRouter = GoRouter(
  initialLocation: '/inicial-page',
  routes: [
    GoRoute(
      path: '/inicial-page',
      name: InicialPage.name,
      builder: (context, state) => const InicialPage(),
    ),
    // GoRoute(
    //   path: '/login',
    //   name: LoginPage.name,
    //   builder: (context, state) => const LoginPage(),
    // ),
    GoRoute(
      path: '/login',
      name: LoginPage.name,
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          child: const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut, // más suave
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        );
      },
    ),

    // GoRoute(
    //   path: '/persona-ci',
    //   // name: PersonaCi.name,
    //   // builder: (context, state) => const PersonaCi(),
    // ),
  ],
);
