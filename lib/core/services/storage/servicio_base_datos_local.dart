import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de base de datos local para desarrollo y testing.
/// Contiene usuarios y datos de ejemplo precargados.
class LocalDatabaseService {
  static const String _localUsersKey = 'local_users_db';

  /// CIs ficticios que van directo al menú principal (sin verificación de identidad).
  /// Solo para pruebas. Usuarios reales (ej. 12865213) pasan por verificación.
  static const Set<String> skipIdentityVerificationCIs = {'12865214'};

  /// Usuarios ficticios para pruebas (no incluye usuarios reales).
  static final Map<String, Map<String, dynamic>> _defaultUsers = {
    '12865214': {
      'ci': '12865214',
      'password': 'payaso123',
      'nombres': 'Participante',
      'apellidos': 'Registrado',
      'email': 'participante@example.com',
      'telefono': '70123457',
      'enrolledPrograms': <String>[], // Sin programas
      'createdAt': DateTime.now().toIso8601String(),
    },
    '87654321': {
      'ci': '87654321',
      'password': 'test123',
      'nombres': 'María José',
      'apellidos': 'Mamani Quispe',
      'email': 'maria@example.com',
      'telefono': '71234567',
      'enrolledPrograms': ['prog-001', 'prog-002'], // Con programas
      'createdAt': DateTime.now().toIso8601String(),
    },
    '54321': {
      'ci': '64214312',
      'password': 'prueba123',
      'nombres': 'María José',
      'apellidos': 'Mamani Quispe',
      'email': 'maria@example.com',
      'telefono': '71234567',
      'enrolledPrograms': ['prog-001', 'prog-002','prog-003'], // Con programas
      'createdAt': DateTime.now().toIso8601String(),
    },
  };

  /// Inicializa la base de datos local con usuarios de ejemplo
  static Future<void> initializeDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_localUsersKey);

    if (existing == null) {
      // Primera vez: cargar usuarios de ejemplo
      await prefs.setString(_localUsersKey, jsonEncode(_defaultUsers));
      if (kDebugMode) {
        print(
          '✅ Base de datos local inicializada con ${_defaultUsers.length} usuarios de ejemplo',
        );
      }
    } else {
      // Fusionar usuarios por defecto para no perder 12865214 si se añadió después
      try {
        final decoded = jsonDecode(existing) as Map<String, dynamic>;
        final merged = Map<String, Map<String, dynamic>>.from(
          decoded.map((k, v) => MapEntry(k, v as Map<String, dynamic>)),
        );
        for (final e in _defaultUsers.entries) {
          if (!merged.containsKey(e.key)) {
            merged[e.key] = e.value;
            if (kDebugMode) {
              print('✅ Usuario de ejemplo añadido: ${e.key}');
            }
          }
        }
        await prefs.setString(_localUsersKey, jsonEncode(merged));
      } catch (_) {
        await prefs.setString(_localUsersKey, jsonEncode(_defaultUsers));
      }
    }
  }

  /// Obtiene todos los usuarios de la BD local
  static Future<Map<String, Map<String, dynamic>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_localUsersKey);

    if (data == null) {
      // Si no existe, inicializar y retornar default
      await initializeDatabase();
      return _defaultUsers;
    }

    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    } catch (e) {
      if (kDebugMode) {
        print('Error parseando usuarios locales: $e');
      }
      return _defaultUsers;
    }
  }

  /// Verifica si un usuario existe y valida su contraseña
  static Future<Map<String, dynamic>?> authenticateUser(
    String ci,
    String password,
  ) async {
    final users = await getAllUsers();
    final user = users[ci];

    if (user == null) {
      if (kDebugMode) {
        print('❌ Usuario con CI $ci no encontrado en BD local');
      }
      return null;
    }

    if (user['password'] != password) {
      if (kDebugMode) {
        print('❌ Contraseña incorrecta para CI $ci');
      }
      return null;
    }

    if (kDebugMode) {
      print('✅ Usuario autenticado: ${user['nombres']} ${user['apellidos']}');
    }

    return user;
  }

  /// Obtiene un usuario por su CI
  static Future<Map<String, dynamic>?> getUserByCi(String ci) async {
    final users = await getAllUsers();
    return users[ci];
  }

  /// Registra un nuevo usuario en la BD local
  static Future<bool> registerUser(Map<String, dynamic> userData) async {
    final ci = userData['ci'] as String?;
    if (ci == null || ci.isEmpty) return false;

    final users = await getAllUsers();

    if (users.containsKey(ci)) {
      if (kDebugMode) {
        print('❌ Usuario con CI $ci ya existe');
      }
      return false;
    }

    users[ci] = {
      ...userData,
      'enrolledPrograms': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localUsersKey, jsonEncode(users));

    if (kDebugMode) {
      print('✅ Usuario registrado: CI $ci');
    }

    return true;
  }

  /// Obtiene los programas inscritos de un usuario
  static Future<Set<String>> getUserEnrolledPrograms(String ci) async {
    final user = await getUserByCi(ci);
    if (user == null) return {};

    final programs = user['enrolledPrograms'];
    if (programs is List) {
      return programs.map((e) => e.toString()).toSet();
    }

    return {};
  }

  /// Inscribe a un usuario en un programa
  static Future<bool> enrollUserInProgram(String ci, String programId) async {
    final users = await getAllUsers();
    final user = users[ci];

    if (user == null) return false;

    final enrolled = (user['enrolledPrograms'] as List?)?.cast<String>() ?? [];
    if (!enrolled.contains(programId)) {
      enrolled.add(programId);
      user['enrolledPrograms'] = enrolled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localUsersKey, jsonEncode(users));

      if (kDebugMode) {
        print('✅ Usuario $ci inscrito en programa $programId');
      }

      return true;
    }

    return false;
  }

  /// Desinscribe a un usuario de un programa
  static Future<bool> unenrollUserFromProgram(
    String ci,
    String programId,
  ) async {
    final users = await getAllUsers();
    final user = users[ci];

    if (user == null) return false;

    final enrolled = (user['enrolledPrograms'] as List?)?.cast<String>() ?? [];
    if (enrolled.contains(programId)) {
      enrolled.remove(programId);
      user['enrolledPrograms'] = enrolled;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localUsersKey, jsonEncode(users));

      if (kDebugMode) {
        print('✅ Usuario $ci desinscrito de programa $programId');
      }

      return true;
    }

    return false;
  }

  /// Reinicia la BD local a los valores por defecto
  static Future<void> resetDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localUsersKey, jsonEncode(_defaultUsers));
    if (kDebugMode) {
      print('🔄 Base de datos local reiniciada');
    }
  }
}
