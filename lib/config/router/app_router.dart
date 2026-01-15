import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';
import 'package:refactor_template/features/sistema/screens/configuracion/configuracion_screen.dart';
import 'package:refactor_template/features/sistema/screens/curriculum/mi_curriculum_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/detalle_programa_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/programas_disponibles_screen.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:refactor_template/features/sistema/screens/notificaciones/notificaciones_screen.dart';
import 'package:refactor_template/features/sistema/screens/pagos/deposito_matricula_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_datos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_documentos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/program_payments_screen.dart';

/// Configuración central de rutas de la aplicación.
/// En desarrollo podemos arrancar directo a una pantalla específica
/// (por ejemplo, Detalle de Programa) para trabajar más rápido.
final goRouter = GoRouter(
  // Flujo normal: iniciar en la pantalla de bienvenida
  initialLocation: '/start-screen',
  debugLogDiagnostics: false, // Desactivar logs de debug para mejor rendimiento
  redirect: (context, state) async {
    final session = await LocalStorageService.getSessionData();
    final hasSession = session != null;

    final path = state.uri.path;

    final isPublicRoute =
        path == '/splash' ||
        path == '/start-screen' ||
        path == '/register' ||
        path == '/verification' ||
        path == '/upload-ci' ||
        path == '/face-recognition' ||
        path == '/registration-form' ||
        path == '/password-setup' ||
        path == '/terms-conditions' ||
        path == '/login' ||
        path == '/programas-disponibles';

    if (!hasSession && !isPublicRoute) {
      return '/login';
    }

    if (hasSession && path == '/login') {
      return PantallaPrincipal.name;
    }

    return null;
  },
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
    // Nueva Pantalla de Inicio (Bienvenida)
    GoRoute(
      path: '/start-screen',
      name: StartScreen.name,
      builder: (context, state) => const StartScreen(),
    ),
    // Pantalla de Registro (Binance style)
    GoRoute(
      path: '/register',
      name: RegisterScreen.name,
      builder: (context, state) => const RegisterScreen(),
    ),
    // Pantalla de Verificación (SMS/Email)
    GoRoute(
      path: '/verification',
      name: VerificationScreen.name,
      builder: (context, state) {
        final target = state.extra as String? ?? 'tu carnet/correo';
        return VerificationScreen(target: target);
      },
    ),
    // Pantalla de Carga de Carnet (ID)
    GoRoute(
      path: '/upload-ci',
      name: IDUploadScreen.name,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialCI = extra?['ci'] as String?;
        return IDUploadScreen(initialCI: initialCI);
      },
    ),
    // Pantalla de Reconocimiento Facial
    GoRoute(
      path: '/face-recognition',
      name: FaceRecognitionScreen.name,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return FaceRecognitionScreen(ocrData: data);
      },
    ),
    // Pantalla de Formulario de Registro (Pre-llenado por OCR)
    GoRoute(
      path: '/registration-form',
      name: RegistrationFormScreen.name,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        // Si el CI viene del flujo inicial (no del OCR), bloquearlo
        final isCIBlocked = data?['ciFromInitial'] == 'true';
        return RegistrationFormScreen(
          initialNombres: data?['nombres'],
          initialApellidos: data?['apellidos'],
          initialCI: data?['ci'],
          initialFechaEmision: data?['fechaEmision'],
          initialFechaExpiracion: data?['fechaExpiracion'],
          initialCombinedCiPath: data?['combinedCiPath'],
          isCIBlocked: isCIBlocked,
        );
      },
    ),
    // Pantalla de Creación de Contraseña
    GoRoute(
      path: '/password-setup',
      name: PasswordSetupScreen.name,
      builder: (context, state) => const PasswordSetupScreen(),
    ),
    // Pantalla de Términos y Condiciones
    GoRoute(
      path: '/terms-conditions',
      name: TermsConditionsScreen.name,
      builder: (context, state) => const TermsConditionsScreen(),
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
    // Pantalla de Programas Disponibles (Para invitados)
    GoRoute(
      path: '/programas-disponibles',
      name: ProgramasDisponiblesScreen.name,
      builder: (context, state) => const ProgramasDisponiblesScreen(),
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
    // Pantalla de Mis Documentos Personales
    GoRoute(
      path: '/mis-documentos-personales',
      name: MisDocumentosPersonalesScreen.name,
      builder: (context, state) => const MisDocumentosPersonalesScreen(),
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
    // Pantalla de Pagos del Programa (Demo de tarjetas)
    GoRoute(
      path: '/program-payments',
      name: ProgramPaymentsScreen.name,
      builder: (context, state) => const ProgramPaymentsScreen(),
    ),
  ],
);
