import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_biometrico.dart';
import 'package:refactor_template/features/login/presentation/pages/pages.dart';
import 'package:refactor_template/features/sistema/screens/configuracion/configuracion_screen.dart';
import 'package:refactor_template/features/sistema/screens/curriculum/mi_curriculum_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/detalle_programa_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/programas_disponibles_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/programas_vigentes_screen.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:refactor_template/features/sistema/screens/inscripcion/confirmacion_inscripcion_screen.dart';
import 'package:refactor_template/features/sistema/screens/notificaciones/notificaciones_screen.dart';
import 'package:refactor_template/features/sistema/screens/pagos/deposito_matricula_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_datos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_documentos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/pantalla_firma.dart';
import 'package:refactor_template/features/sistema/screens/program_payments_screen.dart';

/// Configuración central de rutas de la aplicación.
/// En desarrollo podemos arrancar directo a una pantalla específica
/// (por ejemplo, Detalle de Programa) para trabajar más rápido.
final goRouter = GoRouter(
  // Flujo normal: iniciar con splash screen animado
  initialLocation: '/splash',
  debugLogDiagnostics: false, // Desactivar logs de debug para mejor rendimiento
  redirect: (context, state) async {
    final path = state.uri.path;

    // Verificar si el usuario ya configuró seguridad (PIN/Biometría)
    // y si YA se autenticó correctamente en esta sesión.
    final biometricService = BiometricService();
    final hasSecurityConfigured = await biometricService.hasSecurityConfigured();
    final session = await LocalStorageService.getSessionData();
    final isAuthenticated = session?['authenticated'] == true;

    // Si tiene PIN/biometría configurado PERO todavía NO se autenticó en esta sesión,
    // proteger todas las rutas del sistema (excepto splash, start-screen y autenticación)
    if (hasSecurityConfigured && !isAuthenticated) {
      // Permitir splash, start-screen y autenticación rápida
      if (path == '/splash' || 
          path == '/start-screen' || 
          path == '/autenticacion-rapida') {
        return null;
      }
      
      // Proteger todas las demás rutas - redirigir a autenticación
      if (path.startsWith('/sistema') || 
          path.startsWith('/perfil') ||
          path.startsWith('/diplomados') ||
          path.startsWith('/programas') ||
          path.startsWith('/detalle-programa') ||
          path.startsWith('/mi-curriculum') ||
          path.startsWith('/mis-datos') ||
          path.startsWith('/mis-documentos') ||
          path.startsWith('/notificaciones') ||
          path.startsWith('/confirmacion') ||
          path.startsWith('/configuracion') ||
          path.startsWith('/deposito') ||
          path.startsWith('/program-payments')) {
        return '/autenticacion-rapida';
      }
    }

    // Si ya está autenticado en esta sesión, permitir acceso a todo
    return null;
  },
  routes: [
    // Splash animado inicial - Sin transición (es la primera pantalla)
    GoRoute(
      path: '/splash',
      name: SplashScreen.name,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const SplashScreen()),
    ),

    // Pantalla de Bienvenida - Fade suave
    GoRoute(
      path: '/start-screen',
      name: StartScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const StartScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ),

    // Pantalla de Registro - Slide desde derecha
    GoRoute(
      path: '/register',
      name: RegisterScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.3, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Pantalla de Autenticación Rápida (PIN) - Fade rápido
    GoRoute(
      path: '/autenticacion-rapida',
      name: PantallaAutenticacionRapida.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PantallaAutenticacionRapida(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    ),

    // Login - Slide desde derecha
    GoRoute(
      path: '/login',
      name: PaginaLogin.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PaginaLogin(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.3, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Pantalla Principal - Slide + Fade
    GoRoute(
      path: '/sistema/pantalla_principal',
      name: PantallaPrincipal.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PantallaPrincipal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    ),

    // Perfil - Slide + Fade
    GoRoute(
      path: '/perfil',
      name: 'perfil',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const PantallaPrincipal(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Mis Programas - Slide + Fade
    GoRoute(
      path: '/diplomados',
      name: 'diplomados',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const DiplomadosScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Programas Vigentes - Slide + Fade
    GoRoute(
      path: '/programas-vigentes',
      name: ProgramasVigentesScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ProgramasVigentesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Detalle de Programa - Scale + Fade (efecto zoom)
    GoRoute(
      path: '/detalle-programa',
      name: 'detalle-programa',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: DetalleProgramaScreen(
            titulo: extra?['titulo'] ?? 'Programa',
            tipo: extra?['tipo'] ?? 'DIPLOMADO',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutCubic));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
        );
      },
    ),

    // Curriculum - Slide + Fade
    GoRoute(
      path: '/mi-curriculum',
      name: MiCurriculumScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MiCurriculumScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Mis Datos Personales - Slide + Fade
    GoRoute(
      path: '/mis-datos-personales',
      name: MisDatosPersonalesScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MisDatosPersonalesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Mis Documentos - Slide + Fade
    GoRoute(
      path: '/mis-documentos-personales',
      name: MisDocumentosPersonalesScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const MisDocumentosPersonalesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.2, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ),

    // Notificaciones - Slide desde abajo
    GoRoute(
      path: '/notificaciones',
      name: NotificacionesScreen.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificacionesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.15);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeOutCubic));
          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
          return FadeTransition(
            opacity: animation.drive(fadeTween),
            child: SlideTransition(
              position: animation.drive(tween),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
      ),
    ),

    // Confirmación de Inscripción - Scale + Fade (celebración)
    GoRoute(
      path: '/confirmacion-inscripcion',
      name: ConfirmacionInscripcionScreen.name,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: ConfirmacionInscripcionScreen(
            nombrePrograma: extra?['nombrePrograma'] as String? ?? 'Programa',
            numeroInscripcion: extra?['numeroInscripcion'] as String? ?? '0',
            mensaje: extra?['mensaje'] as String?,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(
              begin: 0.85,
              end: 1.0,
            ).chain(CurveTween(curve: Curves.easeOutBack));
            final fadeTween = Tween<double>(begin: 0.0, end: 1.0);
            return FadeTransition(
              opacity: animation.drive(fadeTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        );
      },
    ),

    // Rutas con loader - Sin transición personalizada (mantener builder)
    GoRoute(
      path: '/inicial-page',
      name: InicialPage.name,
      builder: (context, state) => const InicialPage(),
    ),
    GoRoute(
      path: '/verification',
      name: VerificationScreen.name,
      builder: (context, state) {
        final target = state.extra as String? ?? 'tu carnet/correo';
        return VerificationScreen(target: target);
      },
    ),
    GoRoute(
      path: '/upload-ci',
      name: IDUploadScreen.name,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialCI = extra?['ci'] as String?;
        return IDUploadScreen(initialCI: initialCI);
      },
    ),
    GoRoute(
      path: '/face-recognition',
      name: FaceRecognitionScreen.name,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return FaceRecognitionScreen(ocrData: data);
      },
    ),
    GoRoute(
      path: '/registration-form',
      name: RegistrationFormScreen.name,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
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
    GoRoute(
      path: '/password-setup',
      name: PasswordSetupScreen.name,
      builder: (context, state) => const PasswordSetupScreen(),
    ),
    GoRoute(
      path: '/terms-conditions',
      name: TermsConditionsScreen.name,
      builder: (context, state) => const TermsConditionsScreen(),
    ),
    GoRoute(
      path: '/biometric-setup',
      name: BiometricSetupScreen.name,
      builder: (context, state) => const BiometricSetupScreen(),
    ),
    GoRoute(
      path: '/programas-disponibles',
      name: ProgramasDisponiblesScreen.name,
      builder: (context, state) => const ProgramasDisponiblesScreen(),
    ),
    GoRoute(
      path: '/configuracion',
      name: ConfiguracionScreen.name,
      builder: (context, state) => const ConfiguracionScreen(),
    ),
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
    GoRoute(
      path: '/program-payments',
      name: ProgramPaymentsScreen.name,
      builder: (context, state) => const ProgramPaymentsScreen(),
    ),
    GoRoute(
      path: '/pantalla_firma',
      name: PantallaFirma.name,
      builder: (context, state) => const PantallaFirma(),
    ),
  ],
);
