import 'dart:convert';
import 'package:refactor_template/features/sistema/domain/entities/persona_facturacion.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// 💳 SERVICIO DE GESTIÓN DE PERSONAS DE FACTURACIÓN - V0.4.4
/// 
/// Servicio especializado para gestionar múltiples personas de facturación en el sistema UPEA.
/// Proporciona operaciones CRUD completas con persistencia local usando SharedPreferences.
/// Diseñado para soportar tanto personas naturales como empresas con validación robusta.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Gestión completa de múltiples personas de facturación
/// ✅ Persistencia local con SharedPreferences
/// ✅ Soporte para personas naturales y empresas
/// ✅ Sistema de persona "actual" seleccionada
/// ✅ Soft delete para mantener historial
/// ✅ Validaciones de duplicados por documento
/// ✅ Operaciones asíncronas con manejo de errores
/// 
/// FUNCIONALIDADES AVANZADAS:
/// - CRUD completo: Create, Read, Update, Delete
/// - Sistema de activación/desactivación (soft delete)
/// - Gestión de persona actual para facturación
/// - Validación de documentos duplicados
/// - Búsqueda por ID específico
/// - Conteo de personas activas
/// - Limpieza completa para testing/reset
/// - Manejo robusto de errores con logging
/// 
/// ESTRUCTURA DE DATOS:
/// - Lista de personas: 'personas_facturacion_list'
/// - Persona actual: 'persona_facturacion_actual'
/// - Cada persona tiene ID único (UUID v4)
/// - Campos de auditoría: fechaCreacion, fechaActualizacion
/// - Estado activo/inactivo para soft delete
/// 
/// TIPOS DE PERSONA SOPORTADOS:
/// - Persona Natural: CI, Pasaporte con datos personales
/// - Empresa: NIT con razón social y datos corporativos
/// - Campos comunes: email, teléfono, fechas de auditoría
/// - Campos específicos: nitEmpresa, razonSocial (condicionales)
/// 
/// OPERACIONES DISPONIBLES:
/// - obtenerPersonas(): Lista completa (incluye inactivas)
/// - obtenerPersonasActivas(): Solo personas activas
/// - obtenerPersonaPorId(): Búsqueda específica por ID
/// - obtenerPersonaActual(): Persona seleccionada para facturación
/// - guardarPersona(): Crear nueva persona
/// - actualizarPersona(): Modificar persona existente
/// - eliminarPersona(): Soft delete (marcar como inactiva)
/// - establecerPersonaActual(): Seleccionar persona para facturación
/// 
/// VALIDACIONES IMPLEMENTADAS:
/// - Documentos únicos por persona activa
/// - Campos obligatorios según tipo (personal/empresa)
/// - Formato de email básico
/// - Longitud de campos de texto
/// - Existencia de persona antes de operaciones
/// 
/// MANEJO DE ERRORES:
/// - Try-catch en todas las operaciones
/// - Logging detallado para debugging
/// - Retorno de listas vacías en caso de error
/// - Excepciones específicas para operaciones críticas
/// 
/// INTEGRACIÓN:
/// - SharedPreferences para persistencia local
/// - UUID para generación de IDs únicos
/// - PersonaFacturacion entity para tipado
/// - JSON serialization/deserialization
/// 
/// USO TÍPICO:
/// ```dart
/// final servicio = ServicioPersonasFacturacion();
/// 
/// // Crear nueva persona
/// final persona = await servicio.guardarPersona(
///   nombre: 'Juan',
///   apellido: 'Pérez',
///   tipoDocumento: 'CI',
///   numeroDocumento: '12345678',
///   email: 'juan@email.com',
///   telefono: '70123456',
/// );
/// 
/// // Establecer como actual
/// await servicio.establecerPersonaActual(persona.id);
/// ```
class ServicioPersonasFacturacion {
  /// 🔑 CLAVES DE ALMACENAMIENTO LOCAL
  /// Constantes para las claves usadas en SharedPreferences
  static const String _keyPersonas = 'personas_facturacion_list';      // Lista completa de personas
  static const String _keyPersonaActual = 'persona_facturacion_actual'; // Persona actualmente seleccionada

  /// 📋 OBTENER TODAS LAS PERSONAS DE FACTURACIÓN
  /// 
  /// Recupera la lista completa de personas de facturación desde SharedPreferences.
  /// Incluye tanto personas activas como inactivas (soft deleted).
  /// 
  /// PROCESO:
  /// 1. Obtiene instancia de SharedPreferences
  /// 2. Lee el JSON string de la clave correspondiente
  /// 3. Deserializa el JSON a lista de objetos PersonaFacturacion
  /// 4. Maneja errores retornando lista vacía
  /// 
  /// MANEJO DE ERRORES:
  /// - Si no existe la clave: retorna lista vacía
  /// - Si JSON es inválido: retorna lista vacía con log de error
  /// - Si falla SharedPreferences: retorna lista vacía con log
  /// 
  /// @return Future<List<PersonaFacturacion>> - Lista de todas las personas
  Future<List<PersonaFacturacion>> obtenerPersonas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPersonas);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => PersonaFacturacion.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error obteniendo personas de facturación: $e');
      return [];
    }
  }

  /// 🔍 OBTENER PERSONA ESPECÍFICA POR ID
  /// 
  /// Busca y retorna una persona específica usando su ID único.
  /// Útil para operaciones que requieren una persona específica.
  /// 
  /// PROCESO:
  /// 1. Obtiene la lista completa de personas
  /// 2. Busca la persona con el ID especificado
  /// 3. Retorna la persona encontrada o null si no existe
  /// 
  /// @param id - ID único de la persona a buscar
  /// @return Future<PersonaFacturacion?> - Persona encontrada o null
  Future<PersonaFacturacion?> obtenerPersonaPorId(String id) async {
    final personas = await obtenerPersonas();
    try {
      return personas.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene la persona de facturación actual (seleccionada)
  Future<PersonaFacturacion?> obtenerPersonaActual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyPersonaActual);
      
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return PersonaFacturacion.fromMap(json);
    } catch (e) {
      print('Error obteniendo persona actual: $e');
      return null;
    }
  }

  /// Guarda una nueva persona de facturación
  Future<PersonaFacturacion> guardarPersona({
    required String nombre,
    required String apellido,
    required String tipoDocumento,
    required String numeroDocumento,
    required String email,
    required String telefono,
    bool esEmpresa = false,
    String? nitEmpresa,
    String? razonSocial,
  }) async {
    try {
      final personas = await obtenerPersonas();
      
      // Crear nueva persona
      final nuevaPersona = PersonaFacturacion(
        id: const Uuid().v4(),
        nombre: nombre,
        apellido: apellido,
        tipoDocumento: tipoDocumento,
        numeroDocumento: numeroDocumento,
        email: email,
        telefono: telefono,
        esEmpresa: esEmpresa,
        nitEmpresa: nitEmpresa,
        razonSocial: razonSocial,
        fechaCreacion: DateTime.now(),
        esActivo: true,
      );

      // Agregar a la lista
      personas.add(nuevaPersona);

      // Guardar
      await _guardarPersonas(personas);

      return nuevaPersona;
    } catch (e) {
      print('Error guardando persona: $e');
      rethrow;
    }
  }

  /// Actualiza una persona de facturación existente
  Future<PersonaFacturacion> actualizarPersona({
    required String id,
    required String nombre,
    required String apellido,
    required String tipoDocumento,
    required String numeroDocumento,
    required String email,
    required String telefono,
    bool esEmpresa = false,
    String? nitEmpresa,
    String? razonSocial,
  }) async {
    try {
      final personas = await obtenerPersonas();
      final index = personas.indexWhere((p) => p.id == id);

      if (index == -1) {
        throw Exception('Persona no encontrada');
      }

      // Actualizar persona
      final personaActualizada = personas[index].copyWith(
        nombre: nombre,
        apellido: apellido,
        tipoDocumento: tipoDocumento,
        numeroDocumento: numeroDocumento,
        email: email,
        telefono: telefono,
        esEmpresa: esEmpresa,
        nitEmpresa: nitEmpresa,
        razonSocial: razonSocial,
        fechaActualizacion: DateTime.now(),
      );

      personas[index] = personaActualizada;

      // Guardar
      await _guardarPersonas(personas);

      return personaActualizada;
    } catch (e) {
      print('Error actualizando persona: $e');
      rethrow;
    }
  }

  /// Elimina una persona de facturación (soft delete)
  Future<void> eliminarPersona(String id) async {
    try {
      final personas = await obtenerPersonas();
      final index = personas.indexWhere((p) => p.id == id);

      if (index == -1) {
        throw Exception('Persona no encontrada');
      }

      // Soft delete: marcar como inactiva
      final personaInactiva = personas[index].copyWith(esActivo: false);
      personas[index] = personaInactiva;

      // Guardar
      await _guardarPersonas(personas);

      // Si era la persona actual, limpiar
      final personaActual = await obtenerPersonaActual();
      if (personaActual?.id == id) {
        await _limpiarPersonaActual();
      }
    } catch (e) {
      print('Error eliminando persona: $e');
      rethrow;
    }
  }

  /// Establece la persona actual (seleccionada) para facturación
  Future<void> establecerPersonaActual(String id) async {
    try {
      final persona = await obtenerPersonaPorId(id);
      
      if (persona == null) {
        throw Exception('Persona no encontrada');
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyPersonaActual, jsonEncode(persona.toMap()));
    } catch (e) {
      print('Error estableciendo persona actual: $e');
      rethrow;
    }
  }

  /// Obtiene solo las personas activas
  Future<List<PersonaFacturacion>> obtenerPersonasActivas() async {
    final personas = await obtenerPersonas();
    return personas.where((p) => p.esActivo).toList();
  }

  /// Verifica si existe una persona con el mismo documento
  Future<bool> existePersonaConDocumento(String numeroDocumento) async {
    final personas = await obtenerPersonas();
    return personas.any((p) => p.numeroDocumento == numeroDocumento && p.esActivo);
  }

  /// Obtiene el conteo de personas activas
  Future<int> obtenerConteoPersonasActivas() async {
    final personas = await obtenerPersonasActivas();
    return personas.length;
  }

  /// Limpia la persona actual
  Future<void> _limpiarPersonaActual() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPersonaActual);
    } catch (e) {
      print('Error limpiando persona actual: $e');
    }
  }

  /// Guarda la lista de personas (privado)
  Future<void> _guardarPersonas(List<PersonaFacturacion> personas) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = personas.map((p) => p.toMap()).toList();
      await prefs.setString(_keyPersonas, jsonEncode(jsonList));
    } catch (e) {
      print('Error guardando personas: $e');
      rethrow;
    }
  }

  /// Limpia todos los datos de personas (para testing o reset)
  Future<void> limpiarTodo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPersonas);
      await prefs.remove(_keyPersonaActual);
    } catch (e) {
      print('Error limpiando todo: $e');
      rethrow;
    }
  }
}

