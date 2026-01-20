import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/config/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Ejecutar la app
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
      title: 'The Flutter Way',
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
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFEEF1F8),
        primarySwatch: Colors.blue,
        fontFamily: "Intel",
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: Colors.white),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          errorStyle: TextStyle(height: 0),
          border: defaultInputBorder,
          enabledBorder: defaultInputBorder,
          focusedBorder: defaultInputBorder,
          errorBorder: defaultInputBorder,
        ),
      ),
    );
  }
}

//
const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDEE3F2), width: 1),
);
