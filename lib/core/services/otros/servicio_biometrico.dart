import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar la autenticación biométrica
class BiometricService {
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';
  static const String _pinConfiguredKey = 'pin_configured';
  static const String _savedPinKey = 'saved_pin';

  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Verifica si el dispositivo soporta biometría
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error verificando soporte de biometría: $e');
      return false;
    }
  }

  /// Obtiene los tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Error obteniendo biometrías disponibles: $e');
      return [];
    }
  }

  /// Verifica si la biometría está habilitada por el usuario
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Habilita o deshabilita la biometría
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Guarda las credenciales de forma segura
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedUsernameKey, username);
    await prefs.setString(_savedPasswordKey, password);
  }

  /// Obtiene las credenciales guardadas
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_savedUsernameKey);
    final password = prefs.getString(_savedPasswordKey);
    //final passwordcito = prefs.getString(_savedPasswordKey);
    if (username != null && password != null) {
      return {'username': username, 'password': password};
    }
    return null;
  }

  /// Elimina las credenciales guardadas
  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedUsernameKey);
    await prefs.remove(_savedPasswordKey);
  }

  /// Verifica si el usuario ya configuró PIN o biometría
  Future<bool> hasSecurityConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    final pinConfigured = prefs.getBool(_pinConfiguredKey) ?? false;
    final biometricEnabled = prefs.getBool(_biometricEnabledKey) ?? false;
    
    // También verificar si existe algún PIN guardado (compatibilidad con ambas claves)
    final hasSavedPin = prefs.getString(_savedPinKey) != null;
    final hasSecurityPin = prefs.getString('security_pin') != null;
    
    return pinConfigured || biometricEnabled || hasSavedPin || hasSecurityPin;
  }

  /// Marca que el PIN fue configurado
  Future<void> setPinConfigured(bool configured) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pinConfiguredKey, configured);
  }

  /// Guarda el PIN del usuario
  Future<void> savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPinKey, pin);
    // También guardar con la clave 'security_pin' para compatibilidad con login_page
    await prefs.setString('security_pin', pin);
    await setPinConfigured(true);
  }

  /// Obtiene el PIN guardado
  Future<String?> getSavedPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPinKey);
  }

  /// Verifica si el PIN es correcto
  Future<bool> verifyPin(String pin) async {
    final savedPin = await getSavedPin();
    return savedPin != null && savedPin == pin;
  }

  /// Limpia toda la configuración de seguridad
  Future<void> clearSecurityConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinConfiguredKey);
    await prefs.remove(_savedPinKey);
    await prefs.remove(_biometricEnabledKey);
    await clearSavedCredentials();
  }

  /// Autentica usando biometría
  Future<bool> authenticate({
    String reason = 'Por favor, autentícate para continuar',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool isSetup = false, // Nuevo parámetro para indicar si es configuración inicial
  }) async {
    try {
      // Si NO es configuración inicial, verificar credenciales y estado
      if (!isSetup) {
        // Verificar si hay credenciales guardadas
        final credentials = await getSavedCredentials();
        if (credentials == null) {
          debugPrint('No hay credenciales guardadas para biometría');
          return false;
        }

        // Verificar si la biometría está habilitada
        if (!await isBiometricEnabled()) {
          debugPrint('Biometría no está habilitada');
          return false;
        }
      }

      // Verificar que el dispositivo tenga biometría disponible
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      debugPrint('canCheckBiometrics: $canCheckBiometrics');
      debugPrint('isDeviceSupported: $isDeviceSupported');
      
      if (!canCheckBiometrics && !isDeviceSupported) {
        debugPrint('El dispositivo no soporta biometría');
        return false;
      }

      // Obtener biometrías disponibles
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      debugPrint('Biometrías disponibles: $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        debugPrint('No hay biometrías configuradas en el dispositivo');
        return false;
      }

      // Intentar autenticación biométrica
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
      );

      debugPrint('Resultado de autenticación: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      debugPrint('Error en autenticación biométrica: $e');
      return false;
    }
  }

  /// Obtiene el nombre del tipo de biometría disponible
  String getBiometricTypeName(List<BiometricType> availableTypes) {
    if (availableTypes.isEmpty) return 'Biometría';
    if (availableTypes.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableTypes.contains(BiometricType.fingerprint)) {
      return 'Huella Digital';
    } else if (availableTypes.contains(BiometricType.iris)) {
      return 'Iris';
    } else if (availableTypes.contains(BiometricType.strong)) {
      return 'Autenticación Fuerte';
    } else if (availableTypes.contains(BiometricType.weak)) {
      return 'Autenticación Débil';
    }
    return 'Biometría';
  }

  /// Obtiene el icono apropiado según el tipo de biometría
  IconData getBiometricIcon(List<BiometricType> availableTypes) {
    if (availableTypes.isEmpty) return Icons.fingerprint;
    if (availableTypes.contains(BiometricType.face)) {
      return Icons.face;
    } else if (availableTypes.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    } else if (availableTypes.contains(BiometricType.iris)) {
      return Icons.remove_red_eye;
    }
    return Icons.fingerprint;
  }
}
