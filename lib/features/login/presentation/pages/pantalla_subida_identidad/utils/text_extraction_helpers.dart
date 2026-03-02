import 'package:flutter/foundation.dart';

/// Helpers para extracción y validación de texto OCR de documentos de identidad
class TextExtractionHelpers {
  /// Extrae palabras válidas de un texto (principalmente letras)
  static List<String> extractValidWords(String text) {
    final words = text.split(RegExp(r'\s+'));
    return words.where((word) {
      final cleanWord = word.replaceAll(RegExp(r'[\.\-\x27]'), '').trim();
      if (cleanWord.length < 2) return false;

      final letterCount = cleanWord
          .split('')
          .where((c) => RegExp(r'[A-Za-z]').hasMatch(c))
          .length;
      final letterRatio = cleanWord.isNotEmpty
          ? letterCount / cleanWord.length
          : 0;

      return letterRatio >= 0.7 && !RegExp(r'^\d+$').hasMatch(cleanWord);
    }).toList();
  }

  /// Remueve profesiones y títulos del texto
  static String removeProfessions(String text) {
    final professions = [
      'ABG', 'ABOGADO', 'ABOGADA',
      'ING', 'INGENIERO', 'INGENIERA',
      'DR', 'DOCTOR', 'DOCTORA',
      'LIC', 'LICENCIADO', 'LICENCIADA',
      'SR', 'SENOR', 'SRA', 'SENORA',
      'SRTA', 'SENORITA',
      'MSC', 'MASTER', 'MAGISTER',
      'PH.D', 'PHD',
    ];

    String cleaned = text.trim();

    for (final profession in professions) {
      final startPattern = RegExp('^$profession\\s+', caseSensitive: false);
      if (startPattern.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(startPattern, '').trim();
      }

      final endPattern = RegExp('\\s+$profession\$', caseSensitive: false);
      if (endPattern.hasMatch(cleaned)) {
        cleaned = cleaned.replaceFirst(endPattern, '').trim();
      }

      final middlePattern = RegExp('\\s+$profession\\s+', caseSensitive: false);
      cleaned = cleaned.replaceAll(middlePattern, ' ').trim();

      final dotPattern = RegExp('\\s+$profession\\.', caseSensitive: false);
      cleaned = cleaned.replaceAll(dotPattern, '').trim();
    }

    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned;
  }

  /// Valida si un texto es un nombre válido
  static bool isValidName(String text) {
    final words = extractValidWords(text);

    if (words.length < 2) return false;

    for (final word in words) {
      if (word.length < 3) return false;
    }

    if (text.trim().length < 8) return false;

    final shortWords = words.where((w) => w.length < 3).length;
    if (shortWords > 0) return false;

    return true;
  }

  /// Verifica si el texto contiene profesiones
  static bool containsProfession(String text) {
    final upperText = text.toUpperCase();
    final professions = [
      'ABG', 'ABOGADO', 'ABOGADA',
      'ING', 'INGENIERO', 'INGENIERA',
      'DR', 'DOCTOR', 'DOCTORA',
      'LIC', 'LICENCIADO', 'LICENCIADA',
    ];

    for (final profession in professions) {
      if (upperText.contains(profession)) return true;
    }
    return false;
  }

  /// Verifica si el texto es parte del carnet (no es un nombre)
  static bool isCarnetText(String text) {
    final upperText = text.toUpperCase();
    final carnetPhrases = [
      'SERVICIO GENERAL DE IDENTIFICACION PERSONAL',
      'SERVICIO GENERAL',
      'IDENTIFICACION PERSONAL',
      'CEDULA DE IDENTIDAD',
      'CERTIFICA',
      'QUE LA FIRMA',
      'FOTOGRAFIA E IMPRESION',
      'PERTENECE A',
      'FIRMA DEL INTERESADO',
      'FIRMA DEL TITULAR',
      'DEL INTERESADO',
      'DEL TITULAR',
      'FIRMA DEL',
      'FIRMA',
      'HUELLA DIGITAL',
      'HUELLA DACTILAR',
      'ESTADO PLURINACIONAL DE BOLIVIA',
      'ESTADO PLURINACIONAL',
      'PLURINACIONAL DE BOLIVIA',
      'NOMBRES',
      'APELLIDOS',
      'NOMBRE',
      'APELLIDO',
    ];

    for (final phrase in carnetPhrases) {
      if (upperText.contains(phrase)) {
        debugPrint("⚠️ Texto rechazado (frase del carnet): $phrase");
        return true;
      }
    }
    return false;
  }

  /// Verifica si una palabra es común y no es un nombre
  static bool isCommonNonNameWord(String text) {
    if (isCarnetText(text)) return true;

    final upperText = text.toUpperCase();
    final commonWords = [
      'BOLIVIA', 'BOLIVIANO', 'REPUBLICA', 'ESTADO',
      'PLURINACIONAL', 'PLURINACIONAL DE BOLIVIA',
      'IDENTIDAD', 'CEDULA', 'CIUDADANIA', 'NACIONALIDAD',
      'FECHA', 'NACIMIENTO', 'EXPEDICION', 'VIGENCIA',
      'SEXO', 'ESTADO CIVIL', 'PROFESION', 'OCUPACION',
      'DOMICILIO', 'LUGAR', 'LUGAR DE NACIMIENTO', 'NACIDO EN',
      'DEPARTAMENTO', 'PROVINCIA', 'MUNICIPIO',
      'SEGMENTO', 'CODIGO',
      'SERVICIO GENERAL', 'IDENTIFICACION PERSONAL',
      'ABG', 'ABOGADO', 'ABOGADA',
      'ING', 'INGENIERO', 'INGENIERA',
      'DR', 'DOCTOR', 'DOCTORA',
      'LIC', 'LICENCIADO', 'LICENCIADA',
      'SR', 'SENOR', 'SRA', 'SENORA', 'SRTA', 'SENORITA',
      'LA PAZ', 'SANTA CRUZ', 'COCHABAMBA', 'ORURO',
      'POTOSI', 'SUCRE', 'TARIJA', 'BENI', 'PANDO',
      'MURILLO', 'EL ALTO', 'CIUDAD', 'ZONA',
      'CALLE', 'AVENIDA', 'BARRIO',
      'SERIE', 'SECCION', 'BIO', 'VALIDA HASTA',
    ];

    final placePatterns = [
      RegExp(
        r'\b(LA PAZ|SANTA CRUZ|COCHABAMBA|ORURO|POTOSI|SUCRE|TARIJA|BENI|PANDO)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(MURILLO|EL ALTO|CIUDAD|ZONA|CALLE|AVENIDA|BARRIO)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(ALTO|BAJO|NORTE|SUR|ESTE|OESTE|CENTRO)\b',
        caseSensitive: false,
      ),
    ];

    for (final pattern in placePatterns) {
      if (pattern.hasMatch(upperText)) return true;
    }

    for (final word in commonWords) {
      if (upperText.contains(word)) return true;
    }

    return false;
  }

  /// Verifica si un texto es un lugar o dirección (no un nombre)
  static bool isLocationOrAddress(String text) {
    final upperText = text.toUpperCase();

    final locationPatterns = [
      RegExp(
        r'\b(LA PAZ|SANTA CRUZ|COCHABAMBA|ORURO|POTOSI|SUCRE|TARIJA|BENI|PANDO)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(MURILLO|EL ALTO|CIUDAD|ZONA|CALLE|AVENIDA|BARRIO|URBANIZACION)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(ALTO|BAJO|NORTE|SUR|ESTE|OESTE|CENTRO|PLAZA|MERCADO)\b',
        caseSensitive: false,
      ),
      RegExp(r'\b(.*\d+.*)\b', caseSensitive: false),
    ];

    for (final pattern in locationPatterns) {
      if (pattern.hasMatch(upperText)) {
        final words = upperText.split(RegExp(r'\s+'));
        if (words.length > 3 || RegExp(r'\d').hasMatch(upperText)) {
          return true;
        }
      }
    }

    if (upperText.contains('EL ALTO') ||
        upperText.contains('LA PAZ') ||
        upperText.contains('MURILLO')) {
      return true;
    }

    return false;
  }

  /// Verifica si una línea es válida para contener un nombre
  static bool isValidNameLine(String line) {
    final upper = line.toUpperCase();
    final invalidKeywords = [
      'SERIE', 'SECCION', 'FECHA', 'BIO',
      'NOMBRES', 'APELLIDOS',
      'ABG', 'ABOGADO', 'ING', 'INGENIERO',
      'DR', 'DOCTOR', 'LIC', 'LICENCIADO',
      'EN:', 'PROFESION', 'OCUPACION',
      'DOMICILIO', 'ESTADO CIVIL',
    ];

    for (final keyword in invalidKeywords) {
      if (upper.contains(keyword)) return false;
    }

    return !isCommonNonNameWord(line) && !isLocationOrAddress(line);
  }

  /// Verifica si una línea es de familiares
  static bool isFamilyMemberLine(String line) {
    final upper = line.toUpperCase();
    return upper.contains('MADRE') ||
        upper.contains('PADRE') ||
        upper.contains('MADRES') ||
        upper.contains('PADRES');
  }

  /// Calcula la similitud entre dos textos (0.0 a 1.0)
  static double calculateTextSimilarity(String text1, String text2) {
    if (text1.isEmpty || text2.isEmpty) return 0.0;

    final normalized1 = text1.replaceAll(RegExp(r'\s+'), ' ').trim();
    final normalized2 = text2.replaceAll(RegExp(r'\s+'), ' ').trim();

    final words1 = normalized1.split(' ').where((w) => w.length > 2).toSet();
    final words2 = normalized2.split(' ').where((w) => w.length > 2).toSet();

    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final commonWords = words1.intersection(words2);
    final totalWords = words1.union(words2);

    if (totalWords.isEmpty) return 0.0;

    return commonWords.length / totalWords.length;
  }

  /// Elige el primer valor no vacío de una lista
  static String pickFirstNonEmpty(List<String> values) {
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }
}
