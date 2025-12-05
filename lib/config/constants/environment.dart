import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> initEnvironment() async {
    await dotenv.load(fileName: '.env');
  }

  static String apiUrlPsg =
      dotenv.env['THE_API_PSG'] ??
      'No hay comunicación con el servicio rest de Posgrado (UPEA)';
}
