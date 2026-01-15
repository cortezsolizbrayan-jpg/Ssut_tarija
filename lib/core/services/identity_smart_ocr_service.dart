import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum Direction { right, bottom }

/// Servicio de OCR Avanzado con Análisis Espacial (V6 'Eagle Eye')
class IdentitySmartOcrService {
  /// Extrae datos estructurados usando análisis espacial de bloques
  static Map<String, dynamic> extractData(
    RecognizedText frontOcr,
    RecognizedText? backOcr,
  ) {
    debugPrint("🚀 Iniciando Smart OCR V6 (Análisis Espacial)...");

    // Intentar extracción espacial primero (Más precisa para Nombres/Fechas con etiquetas)
    Map<String, String> frontData = _extractSpatial(frontOcr);

    // Si falló algo crítico en el frente, intentar estrategias antiguas
    if (frontData['ci'] == null || frontData['ci']!.isEmpty) {
      frontData['ci'] = _extractCIFallback(frontOcr);
    }

    // Procesar reverso si existe (a veces el CI está mejor ahí o datos extra)
    Map<String, String> backData = {};
    if (backOcr != null) {
      backData = _extractSpatial(backOcr);
      if ((frontData['ci'] == null || frontData['ci']!.isEmpty) &&
          backData['ci'] != null) {
        frontData['ci'] = backData['ci'] ?? '';
      }
    }

    // Unificar resultados
    return {
      'ci': frontData['ci'] ?? "",
      'nombres': frontData['nombres'] ?? "",
      'apellidos': frontData['apellidos'] ?? "",
      'fechaEmision': frontData['fechaEmision'] ?? "",
      'fechaExpiracion': frontData['fechaExpiracion'] ?? "",
      'model': 'v6-spatial',
    };
  }

  // --- MODELO ESPACIAL ---

  static Map<String, String> _extractSpatial(RecognizedText text) {
    final Map<String, String> result = {
      'ci': '',
      'nombres': '',
      'apellidos': '',
      'fechaEmision': '',
      'fechaExpiracion': '',
    };

    // 1. CI (Buscar etiqueta 'CEDULA' o 'C.I.')
    TextBlock? ciLabel = _findBlockByKeywords(text, [
      'CEDULA',
      'C.I.',
      'CI',
      'NUMERO',
      'N°',
      'Nº',
      'N.',
    ]);
    if (ciLabel != null) {
      // Buscar a la derecha o abajo con patrones mejorados
      result['ci'] = _findTextNear(text, ciLabel.boundingBox, [
        Direction.right,
        Direction.bottom,
      ], pattern: r'\d{5,10}(\s*[-]?\s*[A-Z]{2})?');

      // Si no encontró con extensión, intentar sin extensión
      if (result['ci']!.isEmpty) {
        result['ci'] = _findTextNear(text, ciLabel.boundingBox, [
          Direction.right,
          Direction.bottom,
        ], pattern: r'\d{5,10}');
      }
    }

    // También buscar en líneas que contengan palabras clave comunes
    if (result['ci']!.isEmpty) {
      for (final block in text.blocks) {
        for (final line in block.lines) {
          String lineText = line.text.toUpperCase();
          if (lineText.contains('CEDULA') ||
              lineText.contains('C.I.') ||
              lineText.contains('NUMERO') ||
              lineText.contains('N°') ||
              lineText.contains('Nº')) {
            // Buscar número en la misma línea
            String normalized = line.text
                .toUpperCase()
                .replaceAll('O', '0')
                .replaceAll('I', '1')
                .replaceAll('L', '1')
                .replaceAll('S', '5')
                .replaceAll('G', '6')
                .replaceAll('B', '8');

            final match = RegExp(
              r'(\d{5,10})(\s*[-]?\s*([A-Z]{2}))?',
            ).firstMatch(normalized);
            if (match != null) {
              String ciNumber = match.group(1) ?? '';
              String? extension = match.group(3);

              int? val = int.tryParse(ciNumber);
              if (val != null && (val > 1900 && val < 2100)) continue;
              if (ciNumber.length < 5) continue;

              if (extension != null) {
                const validExt = [
                  'LP',
                  'SC',
                  'CB',
                  'OR',
                  'PT',
                  'CH',
                  'TJ',
                  'BE',
                  'PA',
                  'BN',
                ];
                if (validExt.contains(extension)) {
                  result['ci'] = "$ciNumber $extension";
                  break;
                }
              }

              if (result['ci']!.isEmpty) {
                result['ci'] = ciNumber;
                break;
              }
            }
          }
        }
        if (result['ci']!.isNotEmpty) break;
      }
    }

    // Si no encuentra por etiqueta, buscar patrón directo en todo el texto
    if (result['ci']!.isEmpty) {
      result['ci'] = _extractCIFallback(text);
    }

    // 2. NOMBRES (Buscar etiqueta 'NOMBRES')
    TextBlock? nombresLabel = _findBlockByKeywords(text, ['NOMBRES', 'NOMBRE']);
    if (nombresLabel != null) {
      result['nombres'] = _findTextNear(text, nombresLabel.boundingBox, [
        Direction.bottom,
        Direction.right,
      ], onlyLetters: true);
    }

    // 3. APELLIDOS (Buscar etiqueta 'APELLIDOS', 'PATERNO', 'MATERNO')
    // Intentar buscar PATERNO y MATERNO por separado
    TextBlock? paternoLabel = _findBlockByKeywords(text, ['PATERNO']);
    TextBlock? maternoLabel = _findBlockByKeywords(text, ['MATERNO']);

    if (paternoLabel != null || maternoLabel != null) {
      String p = paternoLabel != null
          ? _findTextNear(text, paternoLabel.boundingBox, [
              Direction.bottom,
              Direction.right,
            ], onlyLetters: true)
          : "";
      String m = maternoLabel != null
          ? _findTextNear(text, maternoLabel.boundingBox, [
              Direction.bottom,
              Direction.right,
            ], onlyLetters: true)
          : "";
      result['apellidos'] = "$p $m".trim();
    }

    if (result['apellidos']!.isEmpty) {
      TextBlock? apellidosLabel = _findBlockByKeywords(text, [
        'APELLIDOS',
        'APELLIDO',
      ]);
      if (apellidosLabel != null) {
        result['apellidos'] = _findTextNear(text, apellidosLabel.boundingBox, [
          Direction.bottom,
          Direction.right,
        ], onlyLetters: true);
      } else {
        // Fallback: A veces "Apellidos" no está explícito, pero está debajo de nombres
        // O es el formato antiguo "PERTENECE A:"
        TextBlock? perteneceLabel = _findBlockByKeywords(text, [
          'PERTENECE',
          'PERTENECE A',
        ]);
        if (perteneceLabel != null) {
          String fullName = _findTextNear(text, perteneceLabel.boundingBox, [
            Direction.right,
            Direction.bottom,
          ], onlyLetters: true);
          if (fullName.isNotEmpty) {
            final parts = splitFullName(fullName);
            result['nombres'] = parts['nombres'] ?? "";
            result['apellidos'] = parts['apellidos'] ?? "";
          }
        }
      }
    }

    // 4. FECHAS
    // Regex flexible: DD/MM/AAAA o DD-MM-AAAA o DD.MM.AAAA o con espacios
    final datePattern = r'\d{1,2}[-/. \s]\d{1,2}[-/. \s]\d{2,4}';

    // (Opcional, no la pedimos en el form, pero ayuda a ubicar otras)

    // Emision
    TextBlock? emisionLabel = _findBlockByKeywords(text, [
      'EMISION',
      'EMISIÓN',
    ]);
    if (emisionLabel != null) {
      result['fechaEmision'] = _findTextNear(text, emisionLabel.boundingBox, [
        Direction.right,
        Direction.bottom,
      ], pattern: datePattern);
    }

    // Expiracion / Vencimiento / Validez
    TextBlock? expLabels = _findBlockByKeywords(text, [
      'EXPIRACION',
      'VENCIMIENTO',
      'VALIDEZ',
      'VÁLIDA',
      'HASTA',
      'VENCE',
    ]);
    if (expLabels != null) {
      result['fechaExpiracion'] = _findTextNear(text, expLabels.boundingBox, [
        Direction.right,
        Direction.bottom,
      ], pattern: datePattern);
    }

    // Fallback: Si no se encuentran por etiqueta espacial, buscar fechas sueltas
    // (Cuidado: esto es agresivo, asumimos lógica de posición si hay múltiples fechas)
    if (result['fechaExpiracion']!.isEmpty) {
      // En carnets nuevos, la fecha de expiración suele estar abajo a la derecha o ser la fecha más futura
      final allDates = _findAllDates(text, datePattern);
      if (allDates.isNotEmpty) {
        // Asumir la fecha más lejana es la de expiración
        result['fechaExpiracion'] = allDates.last; // Simple heurística
      }
    }

    return result;
  }

  // --- UTILS ESPACIALES ---

  static TextBlock? _findBlockByKeywords(
    RecognizedText text,
    List<String> keywords,
  ) {
    for (final block in text.blocks) {
      final str = block.text.toUpperCase();
      for (final k in keywords) {
        if (str.contains(k)) return block;
        // Fuzzy simple (si la palabra es larga)
        if (k.length > 4) {
          final words = str.split(RegExp(r'\s+'));
          for (final w in words) {
            if (w.isEmpty) continue;
            if (_levenshtein(w, k) < 2) return block;
          }
        }
      }
    }
    return null;
  }

  /// Busca texto "cerca" de un rectángulo ancla en las direcciones dadas.
  static String _findTextNear(
    RecognizedText text,
    Rect anchor,
    List<Direction> directions, {
    String? pattern,
    bool onlyLetters = false,
  }) {
    // Definir zonas de búsqueda
    // "Right": misma franja Y, X > anchor.right
    // "Bottom": X similar (solapamiento), Y > anchor.bottom

    double closestDist = double.infinity;
    String bestMatch = "";

    for (final block in text.blocks) {
      if (block.boundingBox == anchor) continue; // Skip self

      // Check if valid candidate content
      String content = block.text.trim();

      // Normalizar caracteres comunes mal reconocidos antes de buscar
      String normalizedContent = content
          .toUpperCase()
          .replaceAll('O', '0')
          .replaceAll('I', '1')
          .replaceAll('L', '1')
          .replaceAll('S', '5')
          .replaceAll('G', '6')
          .replaceAll('B', '8')
          .replaceAll('Z', '2')
          .replaceAll('Q', '0')
          .replaceAll('D', '0');

      if (pattern != null) {
        final reg = RegExp(pattern, caseSensitive: false);
        // Buscar en contenido normalizado
        if (!reg.hasMatch(normalizedContent)) {
          // También buscar en líneas individuales del bloque
          bool foundInLines = false;
          for (final line in block.lines) {
            String lineNormalized = line.text
                .toUpperCase()
                .replaceAll('O', '0')
                .replaceAll('I', '1')
                .replaceAll('L', '1')
                .replaceAll('S', '5')
                .replaceAll('G', '6')
                .replaceAll('B', '8');
            if (reg.hasMatch(lineNormalized)) {
              final m = reg.firstMatch(lineNormalized);
              if (m != null) {
                content = m.group(0)!;
                foundInLines = true;
                break;
              }
            }
          }
          if (!foundInLines) continue;
        } else {
          // Extract specific match
          final m = reg.firstMatch(normalizedContent);
          if (m != null) {
            content = m.group(0)!;
            // Limpiar guiones/puntos si es un CI
            if (pattern.contains(r'\d')) {
              content = content.replaceAll(RegExp(r'[-.\s]'), '');
              // Si tiene extensión, mantenerla
              final extMatch = RegExp(
                r'(\d+)\s*([A-Z]{2})?',
                caseSensitive: false,
              ).firstMatch(normalizedContent);
              if (extMatch != null && extMatch.group(2) != null) {
                content =
                    "${extMatch.group(1)} ${extMatch.group(2)!.toUpperCase()}";
              }
            }
          }
        }
      }
      if (onlyLetters) {
        // Filtrar basura corta
        if (content.length < 3) continue;
        if (content.contains(RegExp(r'[0-9]')) && content.length < 5) continue;
      }

      bool isCandidate = false;
      double dist = double.infinity;

      for (final dir in directions) {
        if (dir == Direction.right) {
          // Verificar solapamiento Y
          double yOverlap = math.max(
            0,
            math.min(anchor.bottom, block.boundingBox.bottom) -
                math.max(anchor.top, block.boundingBox.top),
          );
          bool isRowAligned =
              yOverlap >
              (anchor.height * 0.3); // Al menos 30% de altura compartida

          if (isRowAligned && block.boundingBox.left > (anchor.right - 20)) {
            double d = block.boundingBox.left - anchor.right;
            if (d > -20 && d < 300) {
              // Cerca a la derecha
              if (d < dist) {
                dist = d;
                isCandidate = true;
              }
            }
          }
        } else if (dir == Direction.bottom) {
          // Verificar solapamiento X
          double xOverlap = math.max(
            0,
            math.min(anchor.right, block.boundingBox.right) -
                math.max(anchor.left, block.boundingBox.left),
          );
          bool isColAligned =
              xOverlap >
              (math.min(anchor.width, block.boundingBox.width) * 0.3);

          if (isColAligned && block.boundingBox.top > (anchor.bottom - 10)) {
            double d = block.boundingBox.top - anchor.bottom;
            if (d > -10 && d < 150) {
              // Inmediatamente abajo
              if (d < dist) {
                dist = d;
                isCandidate = true;
              }
            }
          }
        }
      }

      if (isCandidate && dist < closestDist) {
        closestDist = dist;
        bestMatch = content;
      }
    }

    return bestMatch.replaceAll(RegExp(r'[\r\n]'), ' ').trim();
  }

  // --- LOGICA ANTIGUA / HIBRIDA (Optimizado) ---

  static String _extractCIFallback(RecognizedText text) {
    // Patrones mejorados para CI boliviano:
    // - CI con extensión: 1234567 LP, 1234567-LP, etc.
    // - CI sin extensión: 1234567
    // - CI con guiones: 1-234-567
    final validCIPatterns = [
      RegExp(
        r'\b(\d{5,10})\s*[-]?\s*([A-Z]{2})\b',
        caseSensitive: false,
      ), // Con extensión
      RegExp(r'\b(\d{1,3}[-.\s]?\d{3}[-.\s]?\d{3,4})\b'), // Con guiones/puntos
      RegExp(r'\b(\d{5,10})\b'), // Solo números
    ];

    // Primero intentar buscar en líneas individuales (más preciso)
    for (final block in text.blocks) {
      for (final line in block.lines) {
        String lineText = line.text.trim();
        if (lineText.isEmpty || lineText.length > 30) continue;

        // Normalizar caracteres comunes mal reconocidos
        String normalized = lineText
            .toUpperCase()
            .replaceAll('O', '0')
            .replaceAll('I', '1')
            .replaceAll('L', '1')
            .replaceAll('S', '5')
            .replaceAll('G', '6')
            .replaceAll('B', '8')
            .replaceAll('Z', '2')
            .replaceAll('Q', '0')
            .replaceAll('D', '0');

        // Intentar cada patrón
        for (final pattern in validCIPatterns) {
          final match = pattern.firstMatch(normalized);
          if (match != null) {
            String ciNumber = match.group(1) ?? '';
            String? extension = match.group(2);

            // Limpiar el número de guiones/puntos
            ciNumber = ciNumber.replaceAll(RegExp(r'[-.\s]'), '');

            // Validar que no sea un año
            int? val = int.tryParse(ciNumber);
            if (val != null && (val > 1900 && val < 2100)) continue;

            // Validar longitud mínima
            if (ciNumber.length < 5) continue;

            // Validar extensión si existe
            if (extension != null) {
              const validExt = [
                'LP',
                'SC',
                'CB',
                'OR',
                'PT',
                'CH',
                'TJ',
                'BE',
                'PA',
                'BN',
              ];
              if (validExt.contains(extension.toUpperCase())) {
                return "$ciNumber ${extension.toUpperCase()}";
              }
            }

            return ciNumber;
          }
        }
      }
    }

    // Fallback: buscar en bloques completos
    for (final block in text.blocks) {
      if (block.text.length > 100) continue; // Ignorar bloques muy grandes

      String normalized = block.text
          .toUpperCase()
          .replaceAll('O', '0')
          .replaceAll('I', '1')
          .replaceAll('L', '1')
          .replaceAll('S', '5')
          .replaceAll('G', '6')
          .replaceAll('B', '8')
          .replaceAll('Z', '2')
          .replaceAll('Q', '0')
          .replaceAll('D', '0');

      for (final pattern in validCIPatterns) {
        final match = pattern.firstMatch(normalized);
        if (match != null) {
          String ciNumber = match.group(1) ?? '';
          String? extension = match.group(2);

          ciNumber = ciNumber.replaceAll(RegExp(r'[-.\s]'), '');

          int? val = int.tryParse(ciNumber);
          if (val != null && (val > 1900 && val < 2100)) continue;
          if (ciNumber.length < 5) continue;

          if (extension != null) {
            const validExt = [
              'LP',
              'SC',
              'CB',
              'OR',
              'PT',
              'CH',
              'TJ',
              'BE',
              'PA',
              'BN',
            ];
            if (validExt.contains(extension.toUpperCase())) {
              return "$ciNumber ${extension.toUpperCase()}";
            }
          }

          return ciNumber;
        }
      }
    }

    return "";
  }

  static String detectSide(RecognizedText text) {
    final str = text.text.toUpperCase();
    if (str.contains('HUELLA') ||
        str.contains('DACTILAR') ||
        str.contains('CIVIL') ||
        str.contains('PROFESION')) {
      return 'reverso';
    }
    return 'anverso';
  }

  static Rect getRelevantROI(RecognizedText text) {
    // Retorna el bounding box total del texto detectado más un margen
    double minX = double.infinity, minY = double.infinity, maxX = 0, maxY = 0;
    if (text.blocks.isEmpty) return Rect.zero;

    for (final b in text.blocks) {
      if (b.boundingBox.left < minX) minX = b.boundingBox.left;
      if (b.boundingBox.top < minY) minY = b.boundingBox.top;
      if (b.boundingBox.right > maxX) maxX = b.boundingBox.right;
      if (b.boundingBox.bottom > maxY) maxY = b.boundingBox.bottom;
    }
    double padding = 50.0; // Píxeles base
    return Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  // --- UTILS COMUNES ---
  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;
    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);
    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }
    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce(math.min);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[t.length];
  }

  static Map<String, String> splitFullName(String fullName) {
    final words = fullName.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return {'nombres': fullName, 'apellidos': ''};

    // Heurística simple: Últimos 2 son apellidos, resto nombres
    // (Funciona bien para la mayoría de latinos: Juan Carlos Perez Lopez)
    if (words.length >= 3) {
      final apellidos = words.sublist(words.length - 2).join(' ');
      final nombres = words.sublist(0, words.length - 2).join(' ');
      return {'nombres': nombres, 'apellidos': apellidos};
    }

    return {'nombres': words[0], 'apellidos': words.sublist(1).join(' ')};
  }

  //Fecha de nacimiento
  static List<String> _findAllDates(RecognizedText text, String pattern) {
    final reg = RegExp(pattern);
    final List<String> dates = [];
    for (final b in text.blocks) {
      final matches = reg.allMatches(b.text);
      for (final m in matches) {
        String d = m.group(0)!;
        // Normalizar separadores a '/'
        d = d.replaceAll(RegExp(r'[-. \s]'), '/');
        dates.add(d);
      }
    }

    DateTime? parseDate(String raw) {
      final parts = raw.split('/');
      if (parts.length < 3) return null;
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      int? year = int.tryParse(parts[2]);
      if (day == null || month == null || year == null) return null;
      if (year < 100) year = year > 30 ? 1900 + year : 2000 + year;
      if (month < 1 || month > 12) return null;
      if (day < 1 || day > 31) return null;
      return DateTime(year, month, day);
    }

    dates.sort((a, b) {
      final da = parseDate(a);
      final db = parseDate(b);
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });
    return dates;
  }
}
