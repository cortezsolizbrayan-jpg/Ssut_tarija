import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ServicioOcrInteligenteIdentidad {
  static Map<String, dynamic> extractData(
    RecognizedText frontOcr,
    RecognizedText? backOcr,
  ) {
    return extractDataFromText(frontOcr.text, backOcr?.text);
  }

  static Map<String, dynamic> extractDataFromText(
    String frontText,
    String? backText,
  ) {
    final model = _detectModel(frontText, backText);
    debugPrint('OCR model detectado: $model');

    final newFront = _extractNewFront(frontText);
    final oldFront = _extractOldFront(frontText);
    final newBack = backText != null ? _extractNewBack(backText) : <String, String>{};
    final oldBack = backText != null ? _extractOldBack(backText) : <String, String>{};

    final front = model == 'nuevo'
        ? newFront
        : model == 'antiguo'
            ? oldFront
            : _mergePrefer(newFront, oldFront);
    final back = model == 'nuevo'
        ? newBack
        : model == 'antiguo'
            ? oldBack
            : _mergePrefer(newBack, oldBack);

    return {
      'ci': _firstNotEmpty([front['ci'], back['ci'], newFront['ci'], oldFront['ci']]),
      'nombres': _firstNotEmpty([
        front['nombres'],
        back['nombres'],
        newFront['nombres'],
        oldFront['nombres'],
      ]),
      'apellidos': _firstNotEmpty([
        front['apellidos'],
        back['apellidos'],
        newFront['apellidos'],
        oldFront['apellidos'],
      ]),
      'fechaNacimiento': _firstNotEmpty([
        front['fechaNacimiento'],
        back['fechaNacimiento'],
        newFront['fechaNacimiento'],
        oldFront['fechaNacimiento'],
      ]),
      'fechaEmision': _firstNotEmpty([
        front['fechaEmision'],
        back['fechaEmision'],
        newFront['fechaEmision'],
        oldFront['fechaEmision'],
      ]),
      'fechaExpiracion': _firstNotEmpty([
        front['fechaExpiracion'],
        back['fechaExpiracion'],
        newFront['fechaExpiracion'],
        oldFront['fechaExpiracion'],
      ]),
      'lugarNacimiento': _firstNotEmpty([
        back['lugarNacimiento'],
        front['lugarNacimiento'],
        newBack['lugarNacimiento'],
        oldBack['lugarNacimiento'],
      ]),
      'profesion': _firstNotEmpty([
        back['profesion'],
        front['profesion'],
        newBack['profesion'],
        oldBack['profesion'],
      ]),
      'estadoCivil': _firstNotEmpty([
        back['estadoCivil'],
        front['estadoCivil'],
        newBack['estadoCivil'],
        oldBack['estadoCivil'],
      ]),
      'domicilio': _firstNotEmpty([
        back['domicilio'],
        front['domicilio'],
        newBack['domicilio'],
        oldBack['domicilio'],
      ]),
      'grupoSanguineo': _firstNotEmpty([
        back['grupoSanguineo'],
        front['grupoSanguineo'],
        newBack['grupoSanguineo'],
        oldBack['grupoSanguineo'],
      ]),
      'model': model,
    };
  }

  static Map<String, String> splitFullName(String fullName) {
    final cleaned = _stripNoise(fullName)
        .replaceAll(RegExp(r'[^\p{L}\s]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) {
      return {'nombres': '', 'apellidos': ''};
    }
    final parts = cleaned.split(' ');
    if (parts.length == 1) {
      return {'nombres': parts.first, 'apellidos': ''};
    }
    if (parts.length == 2) {
      return {'nombres': parts.first, 'apellidos': parts.last};
    }
    // Heurística: personas suelen tener 1-2 nombres y 2 apellidos.
    // Tomamos siempre los últimos 2 tokens como apellidos cuando hay 3+ partes.
    final apellidosTokens = parts.skip(parts.length - 2).toList();
    final nombresTokens = parts.take(parts.length - 2).toList();
    final nombres = nombresTokens.join(' ');
    final apellidos = apellidosTokens.join(' ');
    return {'nombres': nombres, 'apellidos': apellidos};
  }

  static bool _isFamilyMemberLine(String line) {
    final upper = line.toUpperCase();
    return upper.contains('MADRE') || upper.contains('PADRE') || upper.contains('MADRES') || upper.contains('PADRES');
  }

  static Map<String, String> _mergePrefer(
    Map<String, String> primary,
    Map<String, String> fallback,
  ) {
    final out = <String, String>{};
    final keys = <String>{
      ...primary.keys,
      ...fallback.keys,
    };
    for (final key in keys) {
      out[key] = _firstNotEmpty([primary[key], fallback[key]]);
    }
    return out;
  }

  static String _firstNotEmpty(List<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String _detectModel(String frontText, String? backText) {
    final front = frontText.toUpperCase();
    final back = backText?.toUpperCase() ?? '';
    if (RegExp(r'CEDULA\s+DE\s+IDENTIDAD').hasMatch(front)) return 'nuevo';
    if (front.contains('DATOS DEL TITULAR') || front.contains('ESTADO PLURINACIONAL')) {
      return 'nuevo';
    }
    if (back.contains('PERTENECE') || back.contains('CERTIFICA')) return 'antiguo';
    if (front.contains('VALIDA HASTA') || front.contains('NO.')) return 'antiguo';
    return 'desconocido';
  }

  static Map<String, String> _extractNewFront(String text) {
    final result = <String, String>{
      'ci': '',
      'nombres': '',
      'apellidos': '',
      'fechaNacimiento': '',
      'fechaEmision': '',
      'fechaExpiracion': '',
    };

    result['ci'] = _extractCIFallback(text);
    result['nombres'] = _extractLineValue(text, ['NOMBRES', 'NOMBRE']);
    result['apellidos'] = _extractLineValue(text, ['APELLIDOS', 'APELLIDO']);
    result['fechaNacimiento'] = _extractDateAfterLabel(text, [
      'FECHA DE NACIMIENTO',
      'NACIMIENTO',
      'NAC.',
      'NACIDO EL',
      'NACIO EL',
    ]);
    result['fechaEmision'] = _extractDateAfterLabel(text, [
      'FECHA DE EMISION',
      'EMISION',
      'EMIS',
    ]);
    result['fechaExpiracion'] = _extractDateAfterLabel(text, [
      'FECHA DE EXPIRACION',
      'EXPIRACION',
      'VENCIMIENTO',
      'VALIDEZ',
      'VENCE',
      'EXPIRA',
      'EXPIRA EL',
    ]);

    return result;
  }

  static Map<String, String> _extractNewBack(String text) {
    return {
      'lugarNacimiento': _extractLineValue(text, [
        'LUGAR DE NACIMIENTO',
        'LUGAR NACIMIENTO',
      ]),
      'domicilio': _extractLineValue(text, ['DOMICILIO']),
      'profesion': _extractLineValue(text, ['PROFESION', 'OCUPACION']),
      'estadoCivil': _extractLineValue(text, ['ESTADO CIVIL']),
      'grupoSanguineo': _extractLineValue(text, ['GRUPO SANGUINEO']),
    };
  }

  static Map<String, String> _extractOldFront(String text) {
    final ciByLabel = _extractLineValue(text, [
      'NO',
      'Nº',
      'N°',
      'NUMERO',
      'NRO',
    ]);
    return {
      'ci': _firstNotEmpty([ciByLabel, _extractCIFallback(text)]),
      'fechaExpiracion': _extractDateAfterLabel(text, [
        'VALIDA HASTA',
        'VALIDEZ',
        'VENCE',
        'EXPIRA',
        'EXPIRA EL',
      ]),
    };
  }

  static Map<String, String> _extractOldBack(String text) {
    final result = <String, String>{
      'nombres': '',
      'apellidos': '',
      'fechaNacimiento': '',
      'lugarNacimiento': '',
      'profesion': '',
      'estadoCivil': '',
      'domicilio': '',
    };

    final fullName = _extractFullNameOldBack(text);
    if (fullName.isNotEmpty) {
      final parts = splitFullName(fullName);
      result['nombres'] = parts['nombres'] ?? '';
      result['apellidos'] = parts['apellidos'] ?? '';
    }

    result['fechaNacimiento'] = _extractDateAfterLabel(text, [
      'NACIDO EL',
      'FECHA DE NACIMIENTO',
    ]);
    result['lugarNacimiento'] = _extractTextAfterLabelStart(text, ['EN']);
    result['profesion'] = _extractLineValue(text, ['PROFESION', 'OCUPACION']);
    result['estadoCivil'] = _extractLineValue(text, ['ESTADO CIVIL']);
    result['domicilio'] = _extractLineValue(text, ['DOMICILIO']);

    return result;
  }

  static String _extractCIFallback(String text) {
    final candidates = <String>[];
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      final upper = line.toUpperCase();
      if (upper.contains('FECHA') || upper.contains('NAC')) {
        continue;
      }
      // Evitar líneas de SECCIÓN / SERIE
      if (upper.contains('SECCI') || upper.contains('SERIE')) continue;

      for (final match in RegExp(r'(?:NO\\.?|NRO\\.?|N[°º]|N)\\s*[:\\-]?\\s*([0-9]{6,12})')
          .allMatches(upper)) {
        final number = match.group(1) ?? '';
        if (number.length < 6) continue;
        candidates.add(number);
      }

      // Si no hay prefijo, buscar números largos y descartar fechas
      if (!upper.contains('NO') && !upper.contains('NRO') && !upper.contains('N°')) {
        for (final match in RegExp(r'\\b(\\d{7,12})\\b').allMatches(upper)) {
          final number = match.group(1) ?? '';
          if (number.length < 7) continue;
          if (upper.contains('/') || upper.contains('-')) {
            if (RegExp(r'\\d{1,2}[/.-]\\d{1,2}[/.-]\\d{2,4}').hasMatch(upper)) {
              continue;
            }
          }
          if (upper.contains('SECCI') || upper.contains('SERIE')) continue;
          candidates.add(number);
        }
      }
    }
    
    if (candidates.isEmpty) return '';
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  static String _extractLineValue(String text, List<String> labels) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (int i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      final upper = raw.toUpperCase();
      for (final label in labels) {
        if (upper.contains(label)) {
          final cleaned = _stripNoise(_cleanLabel(raw, label));
          if (cleaned.isNotEmpty) return cleaned;
          if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            final nextClean = _stripNoise(next);
            if (nextClean.isNotEmpty) return nextClean;
          }
        }
      }
    }
    return '';
  }

  static String _extractDateAfterLabel(String text, List<String> labels) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (int i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      final upper = raw.toUpperCase();
      for (final label in labels) {
        if (upper.contains(label)) {
          final date = _extractDateFromText(raw);
          if (date.isNotEmpty) return date;
          if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            final dateNext = _extractDateFromText(next);
            if (dateNext.isNotEmpty) return dateNext;
          }
          // Búsqueda extendida en las siguientes 3 líneas si no se encontró
          for (int j = i + 2; j <= i + 3 && j < lines.length; j++) {
            final extra = lines[j].trim();
            final dateExtra = _extractDateFromText(extra);
            if (dateExtra.isNotEmpty) return dateExtra;
          }
        }
      }
    }
    return '';
  }

  static String _extractTextAfterLabelStart(
    String text,
    List<String> labels,
  ) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (int i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      final upper = raw.toUpperCase();
      for (final label in labels) {
        if (upper == label || upper.startsWith('$label ')) {
          final cleaned = _cleanLabel(raw, label);
          final cleanValue = _stripNoise(cleaned);
          if (cleanValue.isNotEmpty) return cleanValue;
          if (i + 1 < lines.length) {
            final next = lines[i + 1].trim();
            final nextClean = _stripNoise(next);
            if (nextClean.isNotEmpty) return nextClean;
          }
        }
      }
    }
    return '';
  }

  static String _extractFullNameOldBack(String text) {
    final lines = text.split(RegExp(r'[\r\n]+'));
    for (int i = 0; i < lines.length; i++) {
      final raw = lines[i].trim();
      if (raw.isEmpty) continue;
      final upper = raw.toUpperCase();
      if (upper.contains('PERTENECE') || upper.contains('CERTIFICA')) {
        for (int j = i; j < lines.length && j < i + 6; j++) {
          final line = lines[j].trim();
          final match = RegExp(r'A\s*:\s*(.+)', caseSensitive: false).firstMatch(line);
          if (match != null) {
            final name = _stripNoise(match.group(1) ?? '');
            if (_looksLikeName(name)) return name;
          }
          final cleaned = _stripNoise(line);
          if (_looksLikeName(cleaned)) {
            return cleaned;
          }
        }
      }
      final inlineMatch = RegExp(r'PERTENECE\s+A\s*:\s*(.+)', caseSensitive: false)
          .firstMatch(upper);
      if (inlineMatch != null) {
        final name = _stripNoise(inlineMatch.group(1) ?? '');
        if (_looksLikeName(name)) return name;
      }
    }
    return '';
  }

  static bool _looksLikeName(String value) {
    final cleaned = _stripNoise(value);
    if (cleaned.isEmpty) return false;
    final upper = cleaned.toUpperCase();
    if (RegExp(r'(PERTENECE|CERTIFICA|IMPRESI[ÓO]N|FOTOGRAF[ÍI]A)').hasMatch(upper)) {
      return false;
    }
    if (cleaned.length < 5) return false;
    if (!RegExp(r'^[\p{L}\s\.\-]+$', unicode: true).hasMatch(cleaned)) {
      return false;
    }
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    return words.length >= 2 && words.length <= 6;
  }

  static String _cleanLabel(String raw, String label) {
    final upper = raw.toUpperCase();
    final idx = upper.indexOf(label);
    if (idx == -1) return raw.trim();
    var out = raw.substring(idx + label.length).trim();
    if (out.startsWith(':')) out = out.substring(1).trim();
    return out;
  }

  static String _stripNoise(String value) {
    var cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    const noise = [
      'PERTENECE A',
      'CERTIFICA',
      'IMPRESION',
      'IMPRESIÓN',
      'FOTOGRAFIA',
      'FOTOGRAFÍA',
      'NOMBRES',
      'NOMBRE',
      'APELLIDOS',
      'APELLIDO',
      'CEDULA DE IDENTIDAD',
      'CEDULA',
      'CÉDULA',
      'CI',
      'DOCUMENTO',
      'DEL TITULAR',
      'DE IDENTIDAD',
      'DATOS DEL TITULAR',
    ];
    var result = cleaned;
    for (final word in noise) {
      final pattern = RegExp('\\b${RegExp.escape(word)}\\b', caseSensitive: false);
      result = result.replaceAll(pattern, '');
    }
    result = result.replaceAll(RegExp(r'^\s*[:\-\s]+'), '').trim();
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return result;
  }

  static String _extractDateFromText(String raw) {
    // 1) Intentar fechas numéricas comunes
    final numericMatch =
        RegExp(r'\d{1,2}[-/.\s]\d{1,2}[-/.\s]\d{2,4}').firstMatch(raw);
    if (numericMatch != null) {
      final value = numericMatch.group(0) ?? '';
      final fixed = value.replaceAll(RegExp(r'[-.\s]'), '/');
      final parts = fixed.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        var year = parts[2];
        if (year.length == 2) {
          final y = int.tryParse(year) ?? 0;
          year = y > 30 ? '19$year' : '20$year';
        }
        return '$day/$month/$year';
      }
      return fixed;
    }

    // 2) Intentar fechas con meses en texto: "14 DE SEPTIEMBRE DE 1999"
    final upper = _replaceAccents(raw.toUpperCase());
    final monthPatterns = [
      // "14 DE SEPTIEMBRE DE 1999" o con faltas de espacios
      RegExp(r'(\d{1,2})\s*DE\s*([A-ZÁÉÍÓÚ]+)\s*DE\s*(\d{2,4})', caseSensitive: false),
      // "14 SEPTIEMBRE 1999" sin "DE"
      RegExp(r'(\d{1,2})\s*([A-ZÁÉÍÓÚ]+)\s*(\d{2,4})', caseSensitive: false),
      // "14DESEPTIEMBREDE1999" fusionado
      RegExp(r'(\d{1,2})\s*DE?([A-ZÁÉÍÓÚ]+)DE?(\d{2,4})', caseSensitive: false),
    ];
    for (final pattern in monthPatterns) {
      final match = pattern.firstMatch(upper);
      if (match != null) {
        final day = match.group(1)!.padLeft(2, '0');
        final monthName = match.group(2) ?? '';
        final monthNum = _spanishMonthToNumber(monthName);
        var year = match.group(3) ?? '';
        if (year.length == 2) {
          final y = int.tryParse(year) ?? 0;
          year = y > 30 ? '19$year' : '20$year';
        }
        if (monthNum != null) {
          final mm = monthNum.toString().padLeft(2, '0');
          return '$day/$mm/$year';
        }
      }
    }

    // 3) Números pegados: 14091999 o 140999 (ddmmyyyy / ddmmyy)
    final packedDigits = RegExp(r'\b(\d{8}|\d{6})\b').firstMatch(raw);
    if (packedDigits != null) {
      final value = packedDigits.group(1)!;
      final day = value.substring(0, 2);
      final month = value.substring(2, 4);
      final yearRaw = value.length == 8 ? value.substring(4, 8) : value.substring(4, 6);
      final year = value.length == 8
          ? yearRaw
          : (int.tryParse(yearRaw) ?? 0) > 30
              ? '19$yearRaw'
              : '20$yearRaw';
      return '$day/$month/$year';
    }

    return '';
  }

  static int? _spanishMonthToNumber(String month) {
    final normalized = _replaceAccents(month.toUpperCase());
    const months = {
      'ENERO': 1,
      'FEBRERO': 2,
      'MARZO': 3,
      'ABRIL': 4,
      'MAYO': 5,
      'JUNIO': 6,
      'JULIO': 7,
      'AGOSTO': 8,
      'SEPTIEMBRE': 9,
      'SETIEMBRE': 9,
      'OCTUBRE': 10,
      'NOVIEMBRE': 11,
      'DICIEMBRE': 12,
    };
    return months[normalized];
  }

  static String _replaceAccents(String input) {
    return input
        .replaceAll('Á', 'A')
        .replaceAll('É', 'E')
        .replaceAll('Í', 'I')
        .replaceAll('Ó', 'O')
        .replaceAll('Ú', 'U')
        .replaceAll('Ü', 'U');
  }
}
