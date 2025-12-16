import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';
import 'package:refactor_template/features/sistema/screens/configuracion/configuracion_screen.dart';
import 'package:refactor_template/features/sistema/screens/curriculum/mi_curriculum_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/detalle_programa_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:refactor_template/features/sistema/screens/notificaciones/notificaciones_screen.dart';
import 'package:refactor_template/features/sistema/screens/pagos/deposito_matricula_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_datos_personales_screen.dart';

/// Configuración central de rutas de la aplicación.
/// En desarrollo podemos arrancar directo a una pantalla específica
/// (por ejemplo, Detalle de Programa) para trabajar más rápido.
final goRouter = GoRouter(
  // Flujo normal: iniciar en el login (que ya tiene su animación propia)
  initialLocation: '/login',
  debugLogDiagnostics: false, // Desactivar logs de debug para mejor rendimiento
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
    // Pantalla de Notificaciones
    GoRoute(
      path: '/notificaciones',
      name: NotificacionesScreen.name,
      builder: (context, state) => const NotificacionesScreen(),
    ),
    // Pantalla de Configuración
    GoRoute(
      path: '/configuracion',
      name: ConfiguracionScreen.name,
      builder: (context, state) => const ConfiguracionScreen(),
    ),
    // Pantalla de Mis Datos Personales
    GoRoute(
      path: '/mis-datos-personales',
      name: MisDatosPersonalesScreen.name,
      builder: (context, state) => const MisDatosPersonalesScreen(),
    ),
    // Pantalla de Depósito de Matrícula
    GoRoute(
      path: '/deposito-matricula',
      name: DepositoMatriculaScreen.name,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return DepositoMatriculaScreen(
          numeroMatricula: extra?['numeroMatricula'] as String?,
          monto: extra?['monto'] as double?,
        );
      },
    ),
    // Pantalla de Mi Curriculum
    GoRoute(
      path: '/mi-curriculum',
      name: MiCurriculumScreen.name,
      builder: (context, state) => const MiCurriculumScreen(),
    ),
  ],
);
