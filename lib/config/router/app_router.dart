import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/detalle_programa_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';

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
    // Pantalla de perfil con menú 3D y medallas
    GoRoute(
      path: '/perfil',
      name: 'perfil',
      builder: (context, state) => const PantallaPrincipal(),
    ),
    // Pantalla de Diplomados (Mis Programas)
    GoRoute(
      path: '/diplomados',
      name: 'diplomados',
      builder: (context, state) => const DiplomadosScreen(),
    ),

    GoRoute(
      path: '/sistema/pantalla_principal',
      name: PantallaPrincipal.name,
      builder: (context, state) => const PantallaPrincipal(),
    ),
    // Pantalla de Detalle del Programa
    GoRoute(
      path: '/detalle-programa',
      name: 'detalle-programa',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return DetalleProgramaScreen(
          titulo: extra?['titulo'] ?? 'Programa',
          tipo: extra?['tipo'] ?? 'DIPLOMADO',
        );
      },
    ),
  ],
);
