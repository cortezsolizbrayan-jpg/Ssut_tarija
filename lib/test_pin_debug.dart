import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script de prueba para verificar el estado del PIN
/// Ejecuta esto desde cualquier pantalla para ver el estado actual
Future<void> testPinStatus(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  
  final pinConfigured = prefs.getBool('pin_configured') ?? false;
  final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
  final savedPin = prefs.getString('saved_pin');
  final securityPin = prefs.getString('security_pin');
  
  final message = '''
🔐 ESTADO DE SEGURIDAD:
━━━━━━━━━━━━━━━━━━━━━━
PIN Configurado: $pinConfigured
Biometría Habilitada: $biometricEnabled
PIN Guardado (saved_pin): ${savedPin != null ? '✅ Existe' : '❌ No existe'}
PIN Seguridad (security_pin): ${securityPin != null ? '✅ Existe' : '❌ No existe'}
━━━━━━━━━━━━━━━━━━━━━━

Todas las claves en SharedPreferences:
${prefs.getKeys().join('\n')}
  ''';
  
  debugPrint(message);
  
  if (context.mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estado de Seguridad'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
