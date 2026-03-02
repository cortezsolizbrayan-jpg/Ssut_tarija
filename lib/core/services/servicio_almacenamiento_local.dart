import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para manejar el almacenamiento local de datos personales y foto de perfil
class LocalStorageService {
  static const String _profileImagePathKey = 'profile_image_path';

  /// Key para guardar los datos personales
  static const String _personalDataKey = 'personal_data';
  // Key para guardar los datos del curriculum
  static const String _curriculumDataKey = 'curriculum_data';

  /// Key para guardar los datos de sesión
  static const String _sessionDataKey = 'session_data';

  static const String _participantDocumentsKey = 'participant_documents';
  static const String _userProgramsKey = 'user_programs';

  /// Nombre del archivo de la imagen de perfil
  static const String _profileImageFileName = 'profile_image.jpg';

  /// NUEVO: Key para guardar resultados de OCR en segundo plano
  static const String _pendingOcrDataKey = 'pending_ocr_data';

  /// Guarda la ruta de la imagen de perfil
  static Future<void> saveProfileImagePath(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImagePathKey, imagePath);
  }

  /// Obtiene la ruta de la imagen de perfil guardada
  static Future<String?> getProfileImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImagePathKey);
  }

  /// Guarda la ruta de la firma digital
  static Future<void> saveSignatureImage(String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('signature_image_path', imagePath);
  }

  /// Obtiene la ruta de la firma digital guardada
  static Future<String?> getSignatureImagePath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('signature_image_path');
  }

  /// Guarda la imagen de perfil
  /// Copia la imagen seleccionada a un directorio permanente y guarda la ruta
  static Future<String?> saveProfileImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageDir = Directory('${directory.path}/profile_images');

      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      // Crear el archivo de la imagen
      final savedImage = File('${imageDir.path}/$_profileImageFileName');
      await imageFile.copy(savedImage.path);

      await saveProfileImagePath(savedImage.path);

      // NUEVO: Sincronizar con los documentos del participante para la validación de requisitos
      final docs = await getParticipantDocumentsData() ?? {};
      docs['profile_photo_path'] = savedImage.path;
      await saveParticipantDocumentsData(docs);

      return savedImage.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error guardando imagen: $e');
      }
      // Si hay error, retornar null
      return null;
    }
  }

  /// Obtiene el archivo de la imagen de perfil guardada (prefs o participant_documents)
  static Future<File?> getProfileImageFile() async {
    var path = await getProfileImagePath();
    if (path != null) {
      final file = File(path);
      if (await file.exists()) return file;
    }
    // Fallback: foto guardada en documentos del participante (ej. desde reconocimiento facial)
    final docs = await getParticipantDocumentsData();
    final docPath = docs?['profile_photo_path'] as String?;
    if (docPath != null && docPath.toString().trim().isNotEmpty) {
      final file = File(docPath.trim());
      if (await file.exists()) {
        await saveProfileImagePath(docPath.trim());
        return file;
      }
    }
    return null;
  }

  /// Guarda los datos personales
  static Future<void> savePersonalData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(data);
    final ok = await prefs.setString(_personalDataKey, encoded);
    if (!ok) {
      throw Exception('No se pudo persistir los datos personales en el dispositivo');
    }
  }

  /// Obtiene los datos personales guardados
  static Future<Map<String, dynamic>?> getPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_personalDataKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando datos personales: $e');
        }
        return null;
      }
    }
    return null;
  }

  /// Guarda los datos del curriculum
  static Future<void> saveCurriculumData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_curriculumDataKey, jsonEncode(data));
  }

  /// Obtiene los datos del curriculum guardados
  static Future<Map<String, dynamic>?> getCurriculumData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_curriculumDataKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando datos del curriculum: $e');
        }
        return null;
      }
    }
    return null;
  }

  /// Guarda los datos de sesión
  static Future<void> saveSessionData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionDataKey, jsonEncode(data));
  }

  /// Obtiene los datos de sesión guardados
  static Future<Map<String, dynamic>?> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_sessionDataKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando datos de sesión: $e');
        }
        return null;
      }
    }
    return null;
  }

  static Future<void> saveParticipantDocumentsData(
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_participantDocumentsKey, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getParticipantDocumentsData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_participantDocumentsKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando documentos del participante: $e');
        }
        return null;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>> _getUserProgramsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_userProgramsKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando programas de usuario: $e');
        }
      }
    }
    return <String, dynamic>{};
  }
//FUNCIONES PROGRAMAS 
  static Future<void> _saveUserProgramsRaw(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProgramsKey, jsonEncode(data));
  }

  static Future<Set<String>> getUserPrograms(String username) async {
    final raw = await _getUserProgramsRaw();
    final list = raw[username];
    if (list is List) {
      return list.map((item) => item.toString()).toSet();
    }
    return <String>{};
  }
//
  static Future<void> setUserPrograms(
    String username,
    Set<String> programIds,
  ) async {
    final raw = await _getUserProgramsRaw();
    raw[username] = programIds.toList();
    await _saveUserProgramsRaw(raw);
  }

  static Future<void> addUserProgram(String username, String programId) async {
    final current = await getUserPrograms(username);
    current.add(programId);
    await setUserPrograms(username, current);
  }

  /// Limpia solo los datos de sesión
  static Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionDataKey);
  }

  /// Limpia todos los datos guardados
  static Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileImagePathKey);
    await prefs.remove(_personalDataKey);
    await prefs.remove(_curriculumDataKey);
    await prefs.remove(_sessionDataKey);
    await prefs.remove(_participantDocumentsKey);
    await prefs.remove(_userProgramsKey);
    await prefs.remove('signature_image_path');
    // NUEVO: limpiar también OCR pendiente
    await prefs.remove(_pendingOcrDataKey);

    // Eliminar imagen guardada
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imageFile = File(
        '${directory.path}/profile_images/$_profileImageFileName',
      );
      if (await imageFile.exists()) {
        await imageFile.delete();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error eliminando imagen: $e');
      }
    }
  }

  /// Key para guardar los datos de facturación
  static const String _facturacionDataKey = 'facturacion_data';

  /// Guarda los datos de facturación
  static Future<void> saveFacturacionData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_facturacionDataKey, jsonEncode(data));
  }

  /// Obtiene los datos de facturación guardados
  static Future<Map<String, dynamic>?> getFacturacionData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_facturacionDataKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando datos de facturación: $e');
        }
        return null;
      }
    }
    return null;
  }
}

/// NUEVO: Guarda datos de OCR pendientes (se generan en segundo plano)
Future<void> savePendingOcrData(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(LocalStorageService._pendingOcrDataKey, jsonEncode(data));
}

/// NUEVO: Obtiene datos de OCR pendientes si existen
Future<Map<String, dynamic>?> getPendingOcrData() async {
  final prefs = await SharedPreferences.getInstance();
  final dataString = prefs.getString(LocalStorageService._pendingOcrDataKey);
  if (dataString != null) {
    try {
      return jsonDecode(dataString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('Error parseando OCR pendiente: $e');
      }
      return null;
    }
  }
  return null;
}

/// NUEVO: Limpia datos de OCR pendientes (una vez aplicados en el formulario)
Future<void> clearPendingOcrData() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(LocalStorageService._pendingOcrDataKey);
}
