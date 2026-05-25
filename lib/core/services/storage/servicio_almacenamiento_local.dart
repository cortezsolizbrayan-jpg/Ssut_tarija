import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Funciones top-level para compute() ──────────────────────────────────────
// Deben estar fuera de la clase para poder pasarse a Isolate.

Map<String, dynamic>? _decodeJsonMap(String raw) {
  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Set<String> _decodeUserPrograms(List<dynamic> args) {
  // args[0] = jsonString, args[1] = username
  try {
    final raw = jsonDecode(args[0] as String) as Map<String, dynamic>;
    final list = raw[args[1] as String];
    if (list is List) return list.map((e) => e.toString()).toSet();
  } catch (_) {}
  return <String>{};
}

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
  static const String _activeEnrollmentKey = 'active_enrollment_v1';

  /// NUEVO: Key para saber si ya vio el tutorial de programas vigentes
  static const String _vigentesTutorialKey = 'vigentes_tutorial_v1';

  /// Nombre del archivo de la imagen de perfil
  static const String _profileImageFileName = 'profile_image.jpg';

  /// NUEVO: Key para guardar resultados de OCR en segundo plano
  static const String _pendingOcrDataKey = 'pending_ocr_data';

  /// NUEVO: Key para saber si el usuario ya realizó la validación académica (ex-facial)
  static const String _academicaValidadaKey = 'academica_validada_v1';
  static const String _lastMigratedVersionKey = 'last_migrated_app_version';

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

  /// Verifica si el usuario tiene una foto de perfil guardada
  static Future<bool> hasProfileImage() async {
    final file = await getProfileImageFile();
    return file != null && await file.exists();
  }

  /// Guarda el estado de la validación académica (identidad digital)
  static Future<void> saveAcademicaValidada(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_academicaValidadaKey, valor);
  }

  /// Verifica si el usuario ya realizó su validación académica
  static Future<bool> isAcademicaValidada() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_academicaValidadaKey) ?? false;
  }

  /// Guarda los datos personales
  static Future<void> savePersonalData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(data);
    final ok = await prefs.setString(_personalDataKey, encoded);
    if (!ok) {
      throw Exception(
        'No se pudo persistir los datos personales en el dispositivo',
      );
    }
  }

  /// Obtiene los datos personales guardados
  static Future<Map<String, dynamic>?> getPersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_personalDataKey);
    if (dataString == null) return null;
    return compute(_decodeJsonMap, dataString);
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
    if (dataString == null) return null;
    // compute() mueve el JSON decode al isolate — no bloquea el hilo UI
    return compute(_decodeJsonMap, dataString);
  }

  static Future<void> saveParticipantDocumentsData(
    Map<String, dynamic> data, [
    String? programId,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = programId != null
        ? '${_participantDocumentsKey}_$programId'
        : _participantDocumentsKey;
    await prefs.setString(key, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getParticipantDocumentsData([
    String? programId,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final key = programId != null
        ? '${_participantDocumentsKey}_$programId'
        : _participantDocumentsKey;
    final dataString = prefs.getString(key);
    if (dataString == null) return null;
    return compute(_decodeJsonMap, dataString);
  }

  /// Registra una inscripción como "en curso"
  static Future<void> setActiveEnrollment({
    required String programId,
    required String programName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'programId': programId,
      'programName': programName,
      'startTime': DateTime.now().toIso8601String(),
    };
    await prefs.setString(_activeEnrollmentKey, jsonEncode(data));
  }

  /// Obtiene la inscripción activa si existe
  static Future<Map<String, dynamic>?> getActiveEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_activeEnrollmentKey);
    if (dataString != null) {
      return jsonDecode(dataString) as Map<String, dynamic>;
    }
    return null;
  }

  /// Limpia la inscripción activa
  static Future<void> clearActiveEnrollment() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeEnrollmentKey);
  }

  /// Verifica si el usuario puede iniciar una nueva inscripción
  static Future<bool> canStartNewEnrollment() async {
    final active = await getActiveEnrollment();
    return active == null;
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
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_userProgramsKey);
    if (dataString == null) return <String>{};
    // compute() para no bloquear el hilo UI con el JSON decode
    return compute(_decodeUserPrograms, [dataString, username]);
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

  /// Limpia solo los datos de sesión (mantiene PIN y datos del usuario).
  /// Usar al cerrar sesión normal para que el usuario pueda volver a entrar con su PIN.
  static Future<void> clearSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionDataKey);
    // Marcar que el usuario acaba de cerrar sesión manualmente.
    // El login lo leerá una sola vez para no pedir PIN en ese momento.
    await prefs.setBool('just_logged_out', true);
  }

  /// Alias semántico de clearSessionData — cierra sesión manteniendo el PIN.
  static Future<void> clearSessionAndPin() => clearSessionData();

  /// Migra y limpia caches temporales cuando cambia la versión instalada.
  /// Conserva datos críticos del usuario (sesión, perfil y registros).
  static Future<void> runVersionedCacheMigrationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}'
          .trim();
      final lastVersion = prefs.getString(_lastMigratedVersionKey);

      if (lastVersion == currentVersion) return;

      // Limpieza selectiva de datos volátiles para evitar stale-cache tras update.
      await prefs.remove(_activeEnrollmentKey);
      await prefs.remove(_pendingOcrDataKey);
      await prefs.remove(_vigentesTutorialKey);

      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('${_participantDocumentsKey}_')) {
          await prefs.remove(key);
        }
      }

      await prefs.setString(_lastMigratedVersionKey, currentVersion);
      if (kDebugMode) {
        print(
          'Migración de cache aplicada: ${lastVersion ?? 'sin_version_previa'} -> $currentVersion',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error en migración de cache por versión: $e');
      }
    }
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
    await prefs.remove(_paymentReceiptsKey);
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

  /// Key para guardar comprobantes de pago por programa
  static const String _paymentReceiptsKey = 'payment_receipts_by_program';

  /// Guarda un comprobante de pago con metadatos para un programa específico
  static Future<void> savePaymentReceiptForProgram(
    String programaId,
    String receiptPath, {
    String? tipoPago,
    String? numeroDeposito,
    String? fechaDeposito,
    double? montoDeposito,
    String? conceptoPago,
    String? formaPago,
    String? personaFacturacionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final receiptsData = await _getPaymentReceiptsRaw();

    // Crear estructura si no existe
    if (!receiptsData.containsKey(programaId)) {
      receiptsData[programaId] = <String, dynamic>{};
    }

    // El tipo se determina por el parámetro tipoPago, el concepto o un valor por defecto
    final String tipoKey =
        tipoPago ??
        ((conceptoPago?.contains('MATRICULACION') ?? false)
            ? 'matricula'
            : (conceptoPago?.contains('COLEGIATURA') ?? false)
            ? 'colegiatura'
            : 'otro');

    // Guardar los datos del pago específico (matricula o colegiatura)
    final String saveKey = (tipoKey == 'matricula' || tipoKey == 'colegiatura')
        ? tipoKey
        : 'otro';

    receiptsData[programaId][saveKey] = {
      'receipt_path': receiptPath,
      'uploaded_at': DateTime.now().toIso8601String(),
      'numero_deposito': numeroDeposito,
      'fecha_deposito': fechaDeposito,
      'monto_deposito': montoDeposito,
      'concepto_pago': conceptoPago,
      'forma_pago': formaPago,
      'persona_facturacion_id': personaFacturacionId,
    };

    // Mantener compatibilidad con getters antiguos (apunta al último o matrícula)
    receiptsData[programaId]['receipt_path'] = receiptPath;

    await prefs.setString(_paymentReceiptsKey, jsonEncode(receiptsData));

    // ✅ IMPORTANTE: Sincronizar también con participant_documents para previsualización inmediata
    final docs = await getParticipantDocumentsData(programaId) ?? {};
    final String docKey = tipoKey == 'matricula'
        ? 'comprobante_matricula_path'
        : 'comprobante_colegiatura_path';
    docs[docKey] = receiptPath;
    await saveParticipantDocumentsData(docs, programaId);
  }

  /// Obtiene los metadatos de un pago específico para un programa
  static Future<Map<String, dynamic>?> getPaymentMetadataForProgram(
    String programaId, {
    String tipo = 'matricula',
  }) async {
    final receiptsData = await _getPaymentReceiptsRaw();
    final programData = receiptsData[programaId];
    if (programData == null) return null;

    if (programData.containsKey(tipo)) {
      return programData[tipo] as Map<String, dynamic>;
    }
    return null;
  }

  /// Obtiene el comprobante de pago para un programa específico
  static Future<String?> getPaymentReceiptForProgram(
    String programaId, {
    String tipo = 'matricula',
  }) async {
    final metadata = await getPaymentMetadataForProgram(programaId, tipo: tipo);
    return metadata?['receipt_path'] as String?;
  }

  /// Obtiene todos los comprobantes de pago por programa
  static Future<Map<String, dynamic>> _getPaymentReceiptsRaw() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString(_paymentReceiptsKey);
    if (dataString != null) {
      try {
        return jsonDecode(dataString) as Map<String, dynamic>;
      } catch (e) {
        if (kDebugMode) {
          print('Error parseando comprobantes de pago: $e');
        }
      }
    }
    return <String, dynamic>{};
  }

  /// Elimina el comprobante de pago de un programa específico
  static Future<void> removePaymentReceiptForProgram(String programaId) async {
    final prefs = await SharedPreferences.getInstance();
    final receiptsData = await _getPaymentReceiptsRaw();

    if (receiptsData.containsKey(programaId)) {
      receiptsData.remove(programaId);
      await prefs.setString(_paymentReceiptsKey, jsonEncode(receiptsData));
    }
  }

  /// Elimina un pago específico (matrícula o colegiatura) de un programa
  static Future<void> deletePaymentForProgram(
    String programaId, {
    required String tipo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final receiptsData = await _getPaymentReceiptsRaw();

    if (receiptsData.containsKey(programaId)) {
      final programData = Map<String, dynamic>.from(
        receiptsData[programaId] as Map,
      );
      programData.remove(tipo);

      // Si no quedan más pagos significativos, eliminar el nodo del programa
      if (programData.length <= 1 && programData.containsKey('receipt_path')) {
        receiptsData.remove(programaId);
      } else if (programData.isEmpty) {
        receiptsData.remove(programaId);
      } else {
        receiptsData[programaId] = programData;
      }

      await prefs.setString(_paymentReceiptsKey, jsonEncode(receiptsData));

      // Sincronizar con documentos (remover path)
      final docs = await getParticipantDocumentsData(programaId) ?? {};
      final String docKey = tipo == 'matricula'
          ? 'comprobante_matricula_path'
          : 'comprobante_colegiatura_path';
      if (docs.containsKey(docKey)) {
        docs.remove(docKey);
        await saveParticipantDocumentsData(docs, programaId);
      }
    }
  }

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

  /// Obtiene si el usuario ya vio el tutorial de programas vigentes
  static Future<bool> hasSeenVigentesTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vigentesTutorialKey) ?? false;
  }

  /// Guarda que el usuario ya vio el tutorial de programas vigentes
  static Future<void> saveVigentesTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vigentesTutorialKey, true);
  }

  // ── Progreso de registro ────────────────────────────────────────────────────

  static const String _registroProgresoKey = 'registro_progreso';

  /// Guarda la ruta donde quedó el usuario durante el registro.
  /// Llamar al entrar a cada pantalla del flujo de registro.
  static Future<void> saveRegistroProgreso(String ruta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registroProgresoKey, ruta);
  }

  /// Obtiene la ruta de progreso del registro (null si no hay registro en curso).
  static Future<String?> getRegistroProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registroProgresoKey);
  }

  /// Limpia el progreso del registro (llamar al completar el registro).
  static Future<void> clearRegistroProgreso() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registroProgresoKey);
  }
}

/// NUEVO: Guarda datos de OCR pendientes (se generan en segundo plano)
Future<void> savePendingOcrData(Map<String, dynamic> data) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    LocalStorageService._pendingOcrDataKey,
    jsonEncode(data),
  );
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
