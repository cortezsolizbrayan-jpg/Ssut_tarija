import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';

/// Configuración central de rutas de la aplicación.
///
/// La aplicación inicia ahora en el `SplashScreen` y, al finalizar
/// su animación, navega a la pantalla de inicio de sesión (`PaginaLogin`).
final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Splash animado inicial
    GoRoute(
      path: '/splash',
      name: SplashScreen.name,
      builder: (context, state) => const SplashScreen(),
    ),
    // Pantalla inicial antigua. Se mantiene registrada por si
    // quieres reutilizarla más adelante.
    GoRoute(
      path: '/inicial-page',
      name: InicialPage.name,
      builder: (context, state) => const InicialPage(),
    ),
    // Pantalla principal de inicio de sesión
    GoRoute(
      path: '/login',
      name: PaginaLogin.name,
      builder: (context, state) => const PaginaLogin(),
    ),
  ],
);
