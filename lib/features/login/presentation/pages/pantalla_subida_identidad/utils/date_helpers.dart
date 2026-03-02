/// Helpers para procesamiento y normalización de fechas en documentos
class DateHelpers {
  /// Normaliza una línea reemplazando caracteres similares a dígitos
  static String normalizeDateLine(String line) {
    final buffer = StringBuffer();
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      final prev = i > 0 ? line[i - 1] : '';
      final next = i + 1 < line.length ? line[i + 1] : '';
      final hasDigitNearby =
          RegExp(r'\d').hasMatch(prev) || RegExp(r'\d').hasMatch(next);
      if (hasDigitNearby) {
        if (char == 'O' || char == 'o') {
          buffer.write('0');
          continue;
        }
        if (char == 'I' || char == 'l' || char == '|' || char == '!') {
          buffer.write('1');
          continue;
        }
        if (char == 'S' || char == 's') {
          buffer.write('5');
          continue;
        }
      }
      buffer.write(char);
    }
    return buffer.toString();
  }

  /// Parsea una cadena de fecha en diferentes formatos
  static DateTime? parseDateString(String raw) {
    final cleaned =
        raw.replaceAll(RegExp(r'[.\-\s]+'), '/').replaceAll('//', '/');
    final parts = cleaned.split('/');
    if (parts.length < 3) return null;

    int? day;
    int? month;
    int? year;

    if (parts[0].length == 4) {
      year = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      day = int.tryParse(parts[2]);
    } else {
      day = int.tryParse(parts[0]);
      month = int.tryParse(parts[1]);
      year = int.tryParse(parts[2]);
    }

    if (day == null || month == null || year == null) return null;
    if (year < 100) year = year > 30 ? 1900 + year : 2000 + year;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    return DateTime(year, month, day);
  }

  /// Formatea una fecha al formato DD/MM/YYYY
  static String formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString().padLeft(4, '0');
    return '$dd/$mm/$yyyy';
  }

  /// Busca y extrae una fecha de una línea de texto
  static String findDateInLine(String line) {
    final normalized = normalizeDateLine(line);
    final datePatterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'),
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})'),
      RegExp(r'(\d{1,2}\.\d{1,2}\.\d{2,4})'),
      RegExp(r'(\d{4}\.\d{1,2}\.\d{1,2})'),
      RegExp(r'(\d{1,2}\s+\d{1,2}\s+\d{2,4})'),
      RegExp(r'(\d{4}\s+\d{1,2}\s+\d{1,2})'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(normalized);
      if (match != null) {
        final raw = match.group(1)!.trim();
        if (raw.length < 6) continue;
        final parsed = parseDateString(raw);
        if (parsed != null) return formatDate(parsed);
      }
    }
    return '';
  }

  /// Verifica si un número parece ser una fecha (para evitar confundirlo con CI)
  static bool isLikelyDate(String text) {
    if (text.length != 8) return false;
    final parsed = parseDateString(text);
    if (parsed == null) return false;
    final now = DateTime.now();
    return parsed.year >= 1900 && parsed.year <= now.year + 50;
  }
}
