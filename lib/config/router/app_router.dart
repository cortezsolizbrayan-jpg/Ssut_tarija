import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/otros/servicio_biometrico.dart';
import 'package:refactor_template/features/acceso/presentacion/bloques/identity/identity_bloc.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/autenticacion/pantalla_autenticacion_rapida.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/autenticacion/pantalla_login.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/identidad/pantalla_reconocimiento_facial.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/autenticacion/pantalla_verificacion.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/bienvenida/pagina_inicial.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/bienvenida/pantalla_registro.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/carga/pantalla_carga.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/carga/pantalla_preparando_perfil.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/identidad/pantalla_subida_identidad.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/registro/pantalla_formulario_registro.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/seguridad/pantalla_configuracion_contrasena.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/seguridad/pantalla_seguridad_biometrica.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/seguridad/pantalla_terminos_condiciones.dart';
import 'package:refactor_template/features/sistema/screens/configuracion/configuracion_screen.dart';
import 'package:refactor_template/features/sistema/screens/contenedor/pantalla_contenedor_principal.dart';
import 'package:refactor_template/features/sistema/screens/curriculum/mi_curriculum_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/pantalla_detalle_programa.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/pantalla_programas_disponibles.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/programas_vigentes_screen.dart';
import 'package:refactor_template/features/sistema/screens/inscripcion/confirmacion_inscripcion_screen.dart';
import 'package:refactor_template/features/sistema/screens/notificaciones/pantalla_notificaciones.dart';
import 'package:refactor_template/features/sistema/screens/pagos/deposito_matricula_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_datos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_documentos_personales_screen.dart';
import 'package:refactor_template/features/sistema/screens/perfil/pantalla_perfil.dart';
import 'package:refactor_template/features/sistema/screens/perfil/pantalla_firma.dart';
import 'package:refactor_template/features/sistema/screens/pantalla_pagos_programa.dart';

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
    final hasSecurityConfigured = await biometricService
        .hasSecurityConfigured();
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
      name: SplashPantalla.name,
      pageBuilder: (context, state) =>
          NoTransitionPage(key: state.pageKey, child: const SplashPantalla()),
    ),

    // Pantalla de Bienvenida - Fade suave
    GoRoute(
      path: '/start-screen',
      name: InicialPage.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const InicialPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 220),
      ),
    ),

    // Pantalla de Registro - Slide desde derecha
    GoRoute(
      path: '/register',
      name: RegisterPantalla.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const RegisterPantalla(),
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
        transitionDuration: const Duration(milliseconds: 200),
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
        transitionDuration: const Duration(milliseconds: 180),
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
        transitionDuration: const Duration(milliseconds: 200),
      ),
    ),

    // Shell principal con navegación persistente (sidebar + bottom nav)
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/diplomados',
              name: 'diplomados',
              builder: (context, state) => const DiplomadosScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/programas-vigentes',
              name: ProgramasVigentesScreen.name,
              builder: (context, state) => const ProgramasVigentesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/sistema/pantalla_principal',
              name: 'perfil',
              builder: (context, state) => const PerfilPantalla(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mi-curriculum',
              name: MiCurriculumScreen.name,
              builder: (context, state) => const MiCurriculumScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mis-documentos-personales',
              name: MisDocumentosPersonalesScreen.name,
              builder: (context, state) =>
                  const MisDocumentosPersonalesScreen(),
            ),
          ],
        ),
      ],
    ),

    // Alias legacy para abrir la pestaña de inicio dentro del shell
    GoRoute(
      path: '/perfil',
      redirect: (context, state) => '/sistema/pantalla_principal',
    ),

    // Detalle de Programa - Scale + Fade (efecto zoom)
    GoRoute(
      path: '/detalle-programa',
      name: 'detalle-programa',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        return CustomTransitionPage(
          key: state.pageKey,
          child: DetalleProgramaPantalla(
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
          transitionDuration: const Duration(milliseconds: 200),
        );
      },
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
        transitionDuration: const Duration(milliseconds: 200),
      ),
    ),

    // Notificaciones - Slide desde abajo
    GoRoute(
      path: '/notificaciones',
      name: NotificacionesPantalla.name,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const NotificacionesPantalla(),
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
        transitionDuration: const Duration(milliseconds: 180),
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
          transitionDuration: const Duration(milliseconds: 180),
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
      name: VerificationPantalla.name,
      builder: (context, state) {
        final target = state.extra as String? ?? 'tu carnet/correo';
        return VerificationPantalla(target: target);
      },
    ),
    GoRoute(
      path: '/upload-ci',
      name: IDUploadPantalla.name,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final initialCI = extra?['ci'] as String?;
        return BlocProvider(
          create: (_) => IdentityBloc(),
          child: IDUploadPantalla(initialCI: initialCI),
        );
      },
    ),
    GoRoute(
      path: '/face-recognition',
      name: FaceRecognitionPantalla.name,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        return FaceRecognitionPantalla(ocrData: data);
      },
    ),
    GoRoute(
      path: '/registration-form',
      name: RegistrationFormPantalla.name,
      builder: (context, state) {
        final data = state.extra as Map<String, String>?;
        final isCIBlocked = data?['ciFromInitial'] == 'true';
        return RegistrationFormPantalla(
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
      name: PasswordSetupPantalla.name,
      builder: (context, state) => const PasswordSetupPantalla(),
    ),
    GoRoute(
      path: '/terms-conditions',
      name: TermsConditionsPantalla.name,
      builder: (context, state) => const TermsConditionsPantalla(),
    ),
    GoRoute(
      path: '/biometric-setup',
      name: BiometricSetupPantalla.name,
      builder: (context, state) => const BiometricSetupPantalla(),
    ),
    GoRoute(
      path: '/preparando-perfil',
      name: PantallaPreparandoPerfil.name,
      builder: (context, state) => const PantallaPreparandoPerfil(),
    ),
    GoRoute(
      path: '/programas-disponibles',
      name: ProgramasDisponiblesPantalla.name,
      builder: (context, state) => const ProgramasDisponiblesPantalla(),
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
      name: ProgramPaymentsPantalla.name,
      builder: (context, state) => const ProgramPaymentsPantalla(),
    ),
    GoRoute(
      path: '/pantalla_firma',
      name: PantallaFirma.name,
      builder: (context, state) => const PantallaFirma(),
    ),
  ],
);

