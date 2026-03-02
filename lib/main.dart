import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/config/providers/theme_mode_provider.dart';
import 'package:refactor_template/config/router/app_router.dart';
import 'package:refactor_template/config/theme/app_theme.dart';
import 'package:refactor_template/core/services/servicio_base_datos_local.dart';
import 'package:refactor_template/core/services/servicio_notificaciones.dart';
import 'package:refactor_template/core/services/servicio_remover_fondo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar el status bar globalmente para evitar fondo negro
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Desactivamos la visualización de zonas táctiles para evitar
  // interferencias al hacer clic, especialmente en web.
  debugPaintPointersEnabled = false;

  // Ejecutar la app con manejo de errores
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Error Flutter: ${details.exception}');
    }
  };

  // Cargar variables de entorno antes de arrancar la app (necesarias para Vision/Gemini)
  try {
    await Environment.initEnvironment().timeout(
      const Duration(milliseconds: 1000),
      onTimeout: () {
        if (kDebugMode) {
          print('Timeout cargando .env, usando valores por defecto');
        }
      },
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error inicializando environment: $e');
    }
  }

  // Inicializar base de datos local con usuarios de ejemplo
  try {
    await LocalDatabaseService.initializeDatabase();
  } catch (e) {
    if (kDebugMode) {
      print('Error inicializando BD local: $e');
    }
  }

  // Inicializar servicio de notificaciones
  try {
    final servicioNotificaciones = ServicioNotificaciones();
    await servicioNotificaciones.initialize();
    await servicioNotificaciones.requestPermissions();
  } catch (e) {
    if (kDebugMode) {
      print('Error inicializando notificaciones: $e');
    }
  }

  // Inicializar modelo ONNX para remoción de fondo (una sola vez)
  try {
    await ServicioRemoverFondo.inicializar();
  } catch (e) {
    if (kDebugMode) {
      print('Error inicializando ONNX para remoción de fondo: $e');
    }
  }

  // No inicializar Scanbot aquí: se carga solo cuando el usuario usa
  // "Scanbot Scanner", para reducir peso y uso de memoria al inicio.

  // Limitar caché de imágenes para evitar que la app supere cientos de MB
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MiB

  runApp(const ProviderScope(child: MyApp()));
}

/// Observador del ciclo de vida para liberar memoria cuando la app va a segundo plano.
class _ObservadorCicloVidaApp with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _liberarMemoriaEnSegundoPlano();
    }
  }

  void _liberarMemoriaEnSegundoPlano() {
    try {
      // Liberar caché de imágenes (principal fuente de peso en muchas apps)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _observadorCicloVida = _ObservadorCicloVidaApp();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_observadorCicloVida);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_observadorCicloVida);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    
    // Actualizar el status bar según el tema actual
    final isDark = themeMode == ThemeMode.dark || 
                   (themeMode == ThemeMode.system && 
                    MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.light,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.dark,
        systemNavigationBarColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      title: 'Posgrado UPEA',
      locale: const Locale('es'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('es', 'ES'),
        Locale('es', 'BO'),
        Locale('en'),
      ],
      // Usar temas profesionales con colores institucionales
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
