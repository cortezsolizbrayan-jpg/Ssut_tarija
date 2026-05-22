import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Conjunto de validadores y utilidades para el formulario de datos personales.
///
/// Este archivo contiene:
/// - `DatosPersonalesValidators`: validaciones puntuales de campos (CI, celular, email, etc.).
/// - `DatosPersonalesConstants`: constantes estáticas para listas desplegables y colores.
/// - `DatosPersonalesHelpers`: funciones auxiliares para normalización, parsing y construcción de datos.
/// - funciones de vibración para feedback háptico.

class DatosPersonalesValidators {
  /// Valida la cédula de identidad (CI).
  ///
  /// - Acepta nulos y cadenas vacías (devuelve `null` para permitir validaciones opcionales).
  /// - Extrae sólo dígitos y comprueba que la longitud esté entre 5 y 8.
  static String? validateCI(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    // Mantener sólo dígitos, ignorar guiones, espacios o letras.
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    // CI típicas en Bolivia tienen entre 5 y 8 dígitos.
    if (digits.length < 5 || digits.length > 8) {
      return 'CI debe tener 5 a 8 dígitos';
    }
    return null;
  }

  /// Valida número de celular local.
  ///
  /// - Permite nulos/vacíos (devuelve `null`).
  /// - Requiere exactamente 8 dígitos (formato boliviano estándar para celulares).
  static String? validateCelular(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) return 'Celular debe tener 8 dígitos';
    return null;
  }

  /// Valida formato de correo electrónico.
  ///
  /// - Usa una expresión regular razonablemente estricta para detectar correos válidos.
  /// - Devuelve `null` si el campo está vacío para permitir validación opcional.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    // Nota: la regex está dividida para evitar problemas con comillas en el literal.
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&'
              "'" +
          r'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ingrese un correo electrónico válido';
    }
    return null;
  }

  /// Valida número de teléfono (alternativo o fijo).
  ///
  /// - Acepta entre 7 y 9 dígitos.
  static String? validateTelefono(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 9) {
      return 'Teléfono debe tener 7 a 9 dígitos';
    }
    return null;
  }

  /// Valida que al menos uno de los apellidos esté presente.
  ///
  /// - `value` es el apellido paterno ingresado por el usuario.
  /// - `materno` es el contenido actual del campo materno (se pasa para comprobar ambos).
  static String? validateApellidoPaterno(String? value, String materno) {
    final paterno = value?.trim() ?? '';
    if (paterno.isEmpty && materno.isEmpty) {
      return 'Ingrese al menos un apellido';
    }
    return null;
  }

  /// Igual que `validateApellidoPaterno`, pero validando el apellido materno.
  static String? validateApellidoMaterno(String? value, String paterno) {
    final materno = value?.trim() ?? '';
    if (paterno.isEmpty && materno.isEmpty) {
      return 'Ingrese al menos un apellido';
    }
    return null;
  }
}

/// Constantes usadas en la pantalla de datos personales (listas y colores).
class DatosPersonalesConstants {
  // Color principal de la UI para esta sección.
  static const Color primaryBlue = Color(0xFF005BAC);
  // Color de fondo ligero usado en contenedores.
  static const Color background = Color(0xFFEEF1F8);

  // Opciones para el selector "Expedido en" (provincias/ciudades de Bolivia).
  static const List<String> expedidoEnItems = [
    'LA PAZ',
    'ORURO',
    'POTOSÍ',
    'SANTA CRUZ',
    'BENI',
    'PANDO',
    'COCHABAMBA',
    'CHUQUISACA',
    'TARIJA',
  ];

  // Opciones de nacionalidad que se muestran en el formulario.
  static const List<String> nacionalidadItems = [
    'BOLIVIANA',
    'BOLIVIANO',
    'EXTRANJERO',
    'EXTRANJERA',
  ];

  // Géneros disponibles.
  static const List<String> generoItems = ['MASCULINO', 'FEMENINO', 'OTRO'];

  // Ciudades comunes para nacimiento/residencia.
  static const List<String> ciudadItems = [
    'LA PAZ',
    'SANTA CRUZ',
    'COCHABAMBA',
    'ORURO',
    'POTOSÍ',
    'SUCRE',
    'TARIJA',
    'BENI',
    'PANDO',
  ];

  // Estado civil.
  static const List<String> estadoCivilItems = [
    'SOLTERO(A)',
    'CASADO(A)',
    'DIVORCIADO(A)',
    'VIUDO(A)',
  ];
}

/// Helpers y utilidades adicionales para manejo de datos personales.
class DatosPersonalesHelpers {
  /// Normaliza un valor de dropdown para comparaciones (mayúsculas + trim).
  static String _normalizeDropdown(String v) => v.toUpperCase().trim();

  /// Intenta emparejar un texto libre con un ítem de la lista `items`.
  ///
  /// - Si hay coincidencia exacta (ignorando mayúsculas/espacios) devuelve el ítem.
  /// - Si no, intenta coincidencias parciales (primeros 3-4 caracteres) para tolerancia.
  /// - Devuelve `null` si no encuentra match.
  static String? matchDropdownItem(String? value, List<String> items) {
    if (value == null || value.trim().isEmpty) return null;
    final norm = _normalizeDropdown(value);
    // Primera pasada: coincidencia exacta.
    for (final item in items) {
      if (_normalizeDropdown(item) == norm) return item;
    }
    // Segunda pasada: coincidencia parcial (tolerancia para entrada incompleta).
    for (final item in items) {
      final itemNorm = _normalizeDropdown(item);
      if (norm.startsWith(itemNorm.substring(0, itemNorm.length.clamp(0, 4))) ||
          itemNorm.startsWith(norm.substring(0, norm.length.clamp(0, 4)))) {
        return item;
      }
    }
    return null;
  }

  /// Formatea una fecha a `dd/MM/yyyy`.
  static String formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Parsea una fecha guardada en varios formatos comunes.
  ///
  /// - Acepta separadores `/`, `-`, `.`, o espacios.
  /// - Detecta si la primera parte es año o día según su valor (>31 → año).
  /// - Devuelve `null` si la fecha no es válida o está fuera de rango.
  static DateTime? parseSavedDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final parts = s
        .trim()
        .split(RegExp(r'[/\-.\s]'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.length != 3) return null;
    final p0 = int.tryParse(parts[0]);
    final p1 = int.tryParse(parts[1]);
    final p2 = int.tryParse(parts[2]);
    if (p0 == null || p1 == null || p2 == null) return null;
    int d, m, y;
    // Si la primera parte es mayor a 31, probablemente sea el año (formato yyyy/mm/dd)
    if (p0 > 31) {
      y = p0;
      m = p1;
      d = p2;
    } else if (p2 > 31) {
      // Si la tercera parte es mayor a 31, probablemente sea el año (dd/mm/yyyy)
      d = p0;
      m = p1;
      y = p2;
    } else {
      // Por defecto asumimos formato dd/mm/yy
      d = p0;
      m = p1;
      y = p2;
    }
    // Validaciones básicas de rango
    if (d > 31 ||
        d < 1 ||
        m > 12 ||
        m < 1 ||
        y < 1900 ||
        y > DateTime.now().year) {
      return null;
    }
    return DateTime(y, m, d);
  }

  /// Convierte cualquier valor a string y lo trimmea.
  static String str(dynamic v) => (v?.toString() ?? '').trim();

  /// Calcula el progreso del formulario como fracción [0..1].
  ///
  /// - Se considera completado cada campo requerido básico.
  /// - `expedidoEn` y `expedidoEnController` se usan en conjunto (uno de los dos debe contener valor).
  static double calculateFormProgress({
    required String nombre,
    required String apPaterno,
    required String apMaterno,
    required String? expedidoEn,
    required String expedidoEnController,
    required String? genero,
    required String? nacionalidad,
    required String celular,
    required String correo,
  }) {
    final tieneApellido =
        apPaterno.trim().isNotEmpty || apMaterno.trim().isNotEmpty;
    final required = [
      nombre.trim().isNotEmpty,
      tieneApellido,
      (expedidoEn ?? expedidoEnController).trim().isNotEmpty,
      genero != null && genero.isNotEmpty,
      nacionalidad != null && nacionalidad.trim().isNotEmpty,
      celular.trim().isNotEmpty,
      correo.trim().isNotEmpty,
    ];
    final filled = required.where((b) => b).length;
    return filled / required.length;
  }

  /// Construye el mapa que representa los datos personales listos para persistir.
  ///
  /// - Normaliza cadenas con `trim()`.
  /// - Usa valores por defecto cuando el usuario no seleccionó opciones en dropdowns.
  static Map<String, dynamic> buildPersonalData({
    required String nombre,
    required String apPaterno,
    required String apMaterno,
    required String fechaNacimiento,
    required String numeroCI,
    required String complemento,
    required String? selectedExpedidoEn,
    required String expedidoEnController,
    required String? selectedNacionalidad,
    required String nacionalidadController,
    required String? selectedCiudadNacimiento,
    required String ciudadNacimientoController,
    required String? selectedGenero,
    required String? selectedCiudadResidencia,
    required String direccion,
    required String nroCasa,
    required String celular,
    required String correo,
    required String telefonoAlternativo,
    required String telefonoTrabajo,
    required String nit,
    required String razonSocial,
    required String fechaEmision,
    required String fechaExpiracion,
    Map<String, dynamic>? existing,
  }) {
    return {
      ...?existing,
      'nombre': nombre.trim(),
      'apPaterno': apPaterno.trim(),
      'apMaterno': apMaterno.trim(),
      'fechaNacimiento': fechaNacimiento.trim(),
      'numeroCI': numeroCI.trim(),
      'complemento': complemento.trim(),
      'expedidoEn': selectedExpedidoEn ?? expedidoEnController.trim(),
      'nacionalidad': selectedNacionalidad ?? nacionalidadController.trim(),
      'ciudadNacimiento':
          selectedCiudadNacimiento ?? ciudadNacimientoController.trim(),
      'genero': selectedGenero ?? '',
      'ciudadResidencia': selectedCiudadResidencia ?? '',
      'direccion': direccion.trim(),
      'nroCasa': nroCasa.trim(),
      'celular': celular.trim(),
      'correo': correo.trim(),
      'telefonoAlternativo': telefonoAlternativo.trim(),
      'telefonoTrabajo': telefonoTrabajo.trim(),
      'nit': nit.trim(),
      'razonSocial': razonSocial.trim(),
      'fechaEmision': fechaEmision.trim(),
      'fechaExpiracion': fechaExpiracion.trim(),
    };
  }
}

/// Genera una vibración corta para indicar error.
void vibrateOnError(BuildContext context) {
  // Llamamos al feedback háptico del dispositivo. El parámetro `context` se mantiene
  // para compatibilidad con los llamados desde widgets, aunque no se usa internamente.
  HapticFeedback.vibrate();
}

/// Genera un impacto háptico más fuerte (útil para acciones importantes).
void vibrateHeavy(BuildContext context) {
  HapticFeedback.heavyImpact();
}
