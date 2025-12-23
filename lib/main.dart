import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  // Ejecutar la app primero para mostrar el splash inmediatamente
  runApp(const ProviderScope(child: MyApp()));

  // Inicializar environment en background con delay para no interferir con el inicio
  Future.delayed(const Duration(milliseconds: 500), () async {
    try {
      await Environment.initEnvironment().timeout(
        const Duration(milliseconds: 1000), // Reducido a 1 segundo
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
  });
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
