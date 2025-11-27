import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';

<<<<<<< HEAD
void main() {
  Environment.initEnvironment();
=======
import 'features/login/pages/login_page.dart';

void main() async {
  await Environment.initEnvironment();
>>>>>>> 57af039d62d7b7ebb146aae37dc1b3c8b2adebd2
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
<<<<<<< HEAD
      home: const DiplomadosScreen(),
=======
      home: const OnbodingScreen(),
      // home: const LoginPage(),
>>>>>>> 57af039d62d7b7ebb146aae37dc1b3c8b2adebd2
    );
  }
}

const defaultInputBorder = OutlineInputBorder(
  borderRadius: BorderRadius.all(Radius.circular(16)),
  borderSide: BorderSide(color: Color(0xFFDEE3F2), width: 1),
);
