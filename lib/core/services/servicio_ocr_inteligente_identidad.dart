import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum Direction { right, bottom }

/// Servicio de OCR Avanzado con Análisis Espacial (V6 'Eagle Eye')
class ServicioOcrInteligenteIdentidad {
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

    // Procesar reverso si existe
    Map<String, String> backData = {};
    if (backOcr != null) {
      backData = _extractSpatial(backOcr);
      if ((frontData['ci'] == null || frontData['ci']!.isEmpty) &&
          backData['ci'] != null) {
        frontData['ci'] = backData['ci'] ?? '';
      }
    }

    // ── NUEVO: Extraer del patrón 'pertenece' del reverso boliviano ──────
    // ("CERTIFICA: Que la firma ... pertenece NOMBRE APELLIDO Nacido el DD de Mes de AAAA")
    String backText = backOcr?.text ?? '';
    String frontText2 = frontOcr.text;
    final pertData = _extractFromPertenecePattern(backText.isNotEmpty ? backText : frontText2);
    if (pertData['nombres'] != null && pertData['nombres']!.isNotEmpty) {
      if (frontData['nombres'] == null || frontData['nombres']!.isEmpty) {
        frontData['nombres'] = pertData['nombres']!;
      }
    }
    if (pertData['apellidos'] != null && pertData['apellidos']!.isNotEmpty) {
      if (frontData['apellidos'] == null || frontData['apellidos']!.isEmpty) {
        frontData['apellidos'] = pertData['apellidos']!;
      }
    }
    // Fecha de nacimiento del patrón 'Nacido el'
    if (pertData['fechaNacimiento'] != null && pertData['fechaNacimiento']!.isNotEmpty) {
      frontData['fechaNacimiento'] = pertData['fechaNacimiento']!;
      debugPrint("📅 Fecha de nacimiento extraída del reverso: '${frontData['fechaNacimiento']}'");
    }

    // Refuerzo: si nombres/apellidos vacíos, extraer por líneas (orden de lectura)
    if (frontData['nombres']!.isEmpty || frontData['apellidos']!.isEmpty) {
      final lineData = _extractNamesFromLines(frontOcr);
      if (lineData['nombres']!.isNotEmpty) frontData['nombres'] = lineData['nombres']!;
      if (lineData['apellidos']!.isNotEmpty) frontData['apellidos'] = lineData['apellidos']!;
    }
    if (backOcr != null && (frontData['nombres']!.isEmpty || frontData['apellidos']!.isEmpty)) {
      final backLineData = _extractNamesFromLines(backOcr);
      if (frontData['nombres']!.isEmpty && backLineData['nombres']!.isNotEmpty) frontData['nombres'] = backLineData['nombres']!;
      if (frontData['apellidos']!.isEmpty && backLineData['apellidos']!.isNotEmpty) frontData['apellidos'] = backLineData['apellidos']!;
    }

    // Último recurso: extracción por texto plano (regex sobre texto concatenado)
    if (frontData['nombres']!.isEmpty || frontData['apellidos']!.isEmpty) {
      final textData = extractDataFromText(frontOcr.text, backOcr?.text);
      if (frontData['nombres']!.isEmpty && (textData['nombres'] ?? '').toString().trim().isNotEmpty) frontData['nombres'] = (textData['nombres'] ?? '').toString().trim();
      if (frontData['apellidos']!.isEmpty && (textData['apellidos'] ?? '').toString().trim().isNotEmpty) frontData['apellidos'] = (textData['apellidos'] ?? '').toString().trim();
    }

    // Limpiar valores que sean solo etiquetas o basura
    frontData['nombres'] = _stripLabelAndValidateName(frontData['nombres']!);
    frontData['apellidos'] = _stripLabelAndValidateName(frontData['apellidos']!);

    return {
      'ci': frontData['ci'] ?? "",
      'nombres': frontData['nombres'] ?? "",
      'apellidos': frontData['apellidos'] ?? "",
      'fechaEmision': frontData['fechaEmision'] ?? "",
      'fechaExpiracion': frontData['fechaExpiracion'] ?? "",
      'fechaNacimiento': frontData['fechaNacimiento'] ?? "",
      'model': 'v6-spatial',
    };
  }

  /// Recorre bloques y líneas en orden para extraer nombres/apellidos por etiqueta.
  static Map<String, String> _extractNamesFromLines(RecognizedText text) {
    final result = <String, String>{'nombres': '', 'apellidos': ''};
    final lines = <String>[];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
    }
    for (int i = 0; i < lines.length; i++) {
      final lineUpper = lines[i].toUpperCase();
      // Etiqueta sola en la línea (NOMBRES / NOMBRE / APELLIDOS / APELLIDO)
      if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(lineUpper) && result['nombres']!.isEmpty) {
        for (int j = i + 1; j < lines.length && j < i + 4; j++) {
          final candidate = _cleanName(lines[j]);
          if (_isValidNameContent(candidate)) {
            result['nombres'] = _stripLabelAndValidateName(candidate);
            break;
          }
        }
      }
      if (RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(lineUpper) && result['apellidos']!.isEmpty) {
        for (int j = i + 1; j < lines.length && j < i + 4; j++) {
          final candidate = _cleanName(lines[j]);
          if (_isValidNameContent(candidate)) {
            result['apellidos'] = _stripLabelAndValidateName(candidate);
            break;
          }
        }
      }
      // Etiqueta y valor en la misma línea: "NOMBRES: JUAN CARLOS"
      final nomInline = RegExp(r'NOMBRES?\s*:+\s*(.+)', caseSensitive: false).firstMatch(lines[i]);
      if (nomInline != null && result['nombres']!.isEmpty) {
        final candidate = _cleanName(nomInline.group(1) ?? '');
        if (_isValidNameContent(candidate)) result['nombres'] = _stripLabelAndValidateName(candidate);
      }
      final apeInline = RegExp(r'APELLIDOS?\s*:+\s*(.+)', caseSensitive: false).firstMatch(lines[i]);
      if (apeInline != null && result['apellidos']!.isEmpty) {
        final candidate = _cleanName(apeInline.group(1) ?? '');
        if (_isValidNameContent(candidate)) result['apellidos'] = _stripLabelAndValidateName(candidate);
      }
    }
    return result;
  }

  /// Verifica si el texto es un candidato válido para nombre/apellido (solo letras, 2–6 palabras, sin etiquetas).
  static bool _isValidNameContent(String text) {
    final t = text.trim();
    if (t.length < 4 || t.length > 80) return false;
    final cleaned = _cleanName(t);
    if (cleaned.length < 4) return false;
    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 1 || words.length > 6) return false;
    final upper = cleaned.toUpperCase();
    const labelWords = ['NOMBRES', 'NOMBRE', 'APELLIDOS', 'APELLIDO', 'FIRMA', 'INTERESADO', 'TITULAR', 'HUELLA', 'CEDULA', 'NUMERO', 'FECHA', 'DOMICILIO', 'PROFESION', 'ESTADO', 'CIVIL', 'PLURINACIONAL', 'BOLIVIA'];
    for (final w in labelWords) {
      if (upper == w || upper.startsWith('$w ') || upper.endsWith(' $w')) return false;
      if (upper.contains(' $w ') || upper.contains('$w:')) return false;
    }
    final letterOnly = cleaned.replaceAll(RegExp(r"[\s\-\.']"), '');
    if (letterOnly.isEmpty) return false;
    final letterCount = letterOnly.split('').where((c) => RegExp(r'[A-Za-zÁ-Úá-úÑñ]').hasMatch(c)).length;
    if (letterCount < letterOnly.length * 0.85) return false;
    return true;
  }

  /// Quita etiquetas al inicio/final y devuelve nombre limpio; si no es válido devuelve vacío.
  static String _stripLabelAndValidateName(String raw) {
    String t = _cleanName(raw);
    const prefixes = ['NOMBRES', 'NOMBRE', 'APELLIDOS', 'APELLIDO'];
    final upper = t.toUpperCase();
    for (final p in prefixes) {
      if (upper == p) return '';
      if (upper.startsWith('$p ') || upper.startsWith('$p:')) {
        t = t.substring(p.length).replaceFirst(RegExp(r'^[\s:]+'), '').trim();
        break;
      }
    }
    if (!_isValidNameContent(t)) return '';
    return t;
  }

  // ── NUEVO: Patrón del reverso boliviano ─────────────────────────────────
  //
  // Formato típico del reverso del CI boliviano:
  //   "CERTIFICA: Que la firma, fotografía e impresión pertenece
  //    [RUIDO OCR] NOMBRE1 NOMBRE2 APELLIDO1 APELLIDO2
  //    Nacido el 14 de Septiembre de 1999 , en ..."
  //
  // La estrategia es:
  //  1. Encontrar el segmento entre 'pertenece' y 'Nacido'.
  //  2. Limpiar palabras-ruido OCR (palabras cortas, con minúsculas internas, etc.).
  //  3. Las últimas 2 palabras = apellidos; las anteriores = nombres.
  //  4. Parsear la fecha en español 'DD de Mes de AAAA'.

  static const List<String> _kMesesEs = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// Intenta extraer nombres, apellidos y fecha de nacimiento del texto completo
  /// del reverso del carnet de identidad boliviano.
  static Map<String, String> _extractFromPertenecePattern(String text) {
    final result = <String, String>{
      'nombres': '',
      'apellidos': '',
      'fechaNacimiento': '',
    };
    if (text.isEmpty) return result;

    final upper = text.toUpperCase();

    // ── 1. Buscar el segmento 'PERTENECE ... NACIDO EL' ─────────────────
    // También acepta variantes sin 'Nacido el' al final.
    final perteneceIdx = upper.indexOf('PERTENECE');
    if (perteneceIdx == -1) return result;

    // Texto desde donde aparece 'pertenece'
    String segment = text.substring(perteneceIdx);

    // Quitar el prefijo 'PERTENECE A:' / 'PERTENECE'
    segment = segment.replaceFirst(RegExp(r'^PERTENECE\s*A?\s*:?\s*', caseSensitive: false), '').trim();

    // Separar en 'bloque nombre' y todo lo que viene después de 'Nacido'
    final nacidoMatch = RegExp(
      r'(?:Nacido|Nacida)\s+el\s+',
      caseSensitive: false,
    ).firstMatch(segment);

    String nameBlock = nacidoMatch != null
        ? segment.substring(0, nacidoMatch.start).trim()
        : segment.trim();

    // ── 2. Fecha de nacimiento ──────────────────────────────────────────
    // Intentar primero formato texto español: '14 de Septiembre de 1999'
    if (nacidoMatch != null) {
      final afterNacido = segment.substring(nacidoMatch.end);
      final fechaEs = _parseFechaEspanol(afterNacido);
      if (fechaEs != null) {
        result['fechaNacimiento'] = fechaEs;
      }
    }
    // También buscar en el texto completo por si acaso
    if (result['fechaNacimiento']!.isEmpty) {
      final fechaEs = _parseFechaEspanol(text);
      if (fechaEs != null) result['fechaNacimiento'] = fechaEs;
    }

    // ── 3. Limpiar el bloque de nombre ──────────────────────────────────
    // Quitar puntuación, el prefijo 'SHIFT', 'DELETI', etc. (artefactos OCR)
    // Regla: conservar solo palabras que:
    //   a) Sean todas MAYÚSCULAS (carnet usa MAYÚSCULAS para nombres)
    //   b) Tengan ≥ 2 caracteres
    //   c) No sean palabras-ruido conocidas
    final noiseWords = {
      'SHIFT', 'DELETE', 'DELETI', 'APOJP', 'APoJP', 'CTRL',
      'ALT', 'ESC', 'TAB', 'CAPS', 'LOCK', 'A', 'AN', 'DE',
      'EL', 'LA', 'EN', 'Y', 'E', 'QUE', 'CON', 'POR',
      'PARA', 'SU', 'LOS', 'LAS', 'DEL', 'AL', 'UN', 'UNA',
      // palabras que aparecen en el texto descriptivo del reverso
      'CERTIFICA', 'FIRMA', 'FOTOGRAFIA', 'FOTOGRAFÍA', 'IMPRESION',
      'IMPRESIÓN', 'PERTENECE', 'DACTILAR', 'HUELLA', 'DATO',
    };

    // Tokenizar en palabras
    final rawWords = nameBlock.split(RegExp(r'[\s\n\r,.:;]+'));
    final List<String> cleanWords = [];
    for (final w in rawWords) {
      final wClean = w.replaceAll(RegExp(r"[^A-ZÁ-ÚÑa-zá-úñ]"), '');
      if (wClean.length < 2) continue;

      final wUpper = wClean.toUpperCase();
      if (noiseWords.contains(wUpper)) continue;

      // Filtrar palabras que son claramente artefactos:
      // si tienen mezcla irregular de mayúsculas/minúsculas en medio
      // (ej. 'APoJP') → skip.
      // Las palabras reales del carnet son TODAS MAYÚSCULAS.
      final isAllUpper = wClean == wClean.toUpperCase();
      if (!isAllUpper) continue;

      // Verificar que sea solo letras (incluyendo acentuadas)
      if (!RegExp(r'^[A-ZÁÉÍÓÚÑÜ]+$').hasMatch(wUpper)) continue;

      cleanWords.add(wUpper);
    }

    debugPrint("🔍 OCR Pertenece: palabras limpias = $cleanWords");

    if (cleanWords.isEmpty) return result;

    // ── 4. Heurística boliviana: ────────────────────────────────────────
    // Formato en carnet: "APELLIDO1 APELLIDO2 NOMBRE1 [NOMBRE2]"
    //   → últimas 2 palabras = apellidos; anteriores = nombres
    // Pero también puede ser "NOMBRE1 NOMBRE2 APELLIDO1 APELLIDO2"
    // → usamos splitFullName (que asume primeras 2 = apellidos) cuando hay ≥ 3 palabras
    if (cleanWords.length >= 3) {
      // Carnet boliviano: los apellidos van AL FINAL del bloque 'PERTENECE'
      // porque el texto dice "pertenece [nombre] [apellidos]"
      // Ej: "RICHARD ERICK HUAÑAPACO CHURA" → nombres=RICHARD ERICK, ap=HUAÑAPACO CHURA
      final apellidos = '${cleanWords[cleanWords.length - 2]} ${cleanWords[cleanWords.length - 1]}';
      final nombres = cleanWords.sublist(0, cleanWords.length - 2).join(' ');
      result['apellidos'] = apellidos.trim();
      result['nombres'] = nombres.trim();
    } else if (cleanWords.length == 2) {
      result['apellidos'] = cleanWords[1];
      result['nombres'] = cleanWords[0];
    } else {
      result['nombres'] = cleanWords[0];
    }

    debugPrint("✅ OCR Pertenece → nombres='${result['nombres']}' apellidos='${result['apellidos']}' nacimiento='${result['fechaNacimiento']}'");
    return result;
  }

  /// Parsea una fecha en español del tipo '14 de Septiembre de 1999'
  /// y devuelve 'dd/mm/yyyy' o null si no se encuentra.
  static String? _parseFechaEspanol(String text) {
    // Patrón: número (1-31), 'de', mes en texto, 'de', año (4 dígitos)
    final re = RegExp(
      r'(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|'
      r'septiembre|octubre|noviembre|diciembre)\s+de\s+(\d{4})',
      caseSensitive: false,
    );
    final m = re.firstMatch(text);
    if (m == null) return null;

    final day = int.tryParse(m.group(1) ?? '') ?? 0;
    final mesStr = (m.group(2) ?? '').toLowerCase();
    final year = int.tryParse(m.group(3) ?? '') ?? 0;

    final month = _kMesesEs.indexOf(mesStr) + 1; // 1-based
    if (day < 1 || day > 31 || month < 1 || year < 1900 || year > 2100) return null;

    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Extrae datos estructurados desde texto plano (ej. salida de Google Vision).
  static Map<String, dynamic> extractDataFromText(String frontText, [String? backText]) {
    final combined = backText != null && backText.isNotEmpty
        ? '$frontText\n$backText'
        : frontText;
    final upper = combined.toUpperCase();
    final result = <String, dynamic>{
      'ci': '',
      'nombres': '',
      'apellidos': '',
      'fechaEmision': '',
      'fechaExpiracion': '',
      'fechaNacimiento': '',
      'lugarNacimiento': '',
      'profesion': '',
      'estadoCivil': '',
      'domicilio': '',
      'grupoSanguineo': '',
    };
    // CI: patrones comunes (carnet boliviano) - Mejorado con más variantes
    final ciPatterns = [
      // Patrón con etiqueta "CEDULA DE IDENTIDAD" seguida del número
      RegExp(r'C[EÉ]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})', caseSensitive: false),
      // "No." o "Nro." seguido del número
      RegExp(r'(?:NO\.?|NRO\.?)\s*:?\s*[\s\-]*(\d{5,11})', caseSensitive: false),
      // "N°" o "N." con variaciones
      RegExp(r'N\s*[°º\.]\s*:?\s*(\d{5,11})', caseSensitive: false),
      // "C.I." o "CI"
      RegExp(r'C\.?\s*I\.?\s*:?\s*(\d{5,11})', caseSensitive: false),
      // "NUMERO" (a veces aparece solo)
      RegExp(r'NUMERO\s*:?\s*(\d{5,11})', caseSensitive: false),
      // Secuencia larga de dígitos (7-10 caracteres, típico de CI boliviano)
      RegExp(r'\b(\d{7,10})\b'),
      // Último recurso: buscar cualquier secuencia de 6-11 dígitos
      RegExp(r'(\d{6,11})'),
    ];
    
    // Intentar extraer con cada patrón en orden de precisión
    for (final re in ciPatterns) {
      final matches = re.allMatches(combined);
      for (final m in matches) {
        final ci = (m.group(1) ?? '').trim();
        // Validar que sea un CI razonable: entre 5 y 11 dígitos, no todo ceros
        if (ci.length >= 5 && ci.length <= 11 && ci != '0' * ci.length) {
          final ciNum = int.tryParse(ci);
          // Evitar números muy pequeños (ej. años, días)
          if (ciNum != null && ciNum > 10000) {
            result['ci'] = ci;
            break;
          }
        }
      }
      if (result['ci']!.isNotEmpty) break;
    }
    // Nombres / Apellidos: extracción mejorada con múltiples estrategias
    // Estrategia 1: Etiqueta en una línea, valor en la siguiente (común en carnets nuevos)
    final lines = combined.split(RegExp(r'[\n\r]+'));
    for (int i = 0; i < lines.length; i++) {
      final lineUpper = lines[i].toUpperCase().trim();
      final nextLine = i + 1 < lines.length ? lines[i + 1].trim() : '';
      
      // Buscar "NOMBRES" o "NOMBRE" en la línea actual
      if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(lineUpper) && nextLine.isNotEmpty && result['nombres'] == '') {
        final clean = _cleanName(nextLine);
        if (clean.length >= 2) result['nombres'] = clean;
      }
      
      // Buscar "APELLIDOS" o "APELLIDO" en la línea actual
      if (RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(lineUpper) && nextLine.isNotEmpty && result['apellidos'] == '') {
        final clean = _cleanName(nextLine);
        if (clean.length >= 2) result['apellidos'] = clean;
      }
      
      // Etiqueta y valor en la misma línea (ej. "NOMBRES: JUAN CARLOS")
      final nombresInlineMatch = RegExp(r'NOMBRES?\s*:+\s*([A-ZÁ-Ú\s]+)', caseSensitive: false).firstMatch(lines[i]);
      if (nombresInlineMatch != null && result['nombres'] == '') {
        final clean = _cleanName(nombresInlineMatch.group(1) ?? '');
        if (clean.length >= 2) result['nombres'] = clean;
      }
      
      final apellidosInlineMatch = RegExp(r'APELLIDOS?\s*:+\s*([A-ZÁ-Ú\s]+)', caseSensitive: false).firstMatch(lines[i]);
      if (apellidosInlineMatch != null && result['apellidos'] == '') {
        final clean = _cleanName(apellidosInlineMatch.group(1) ?? '');
        if (clean.length >= 2) result['apellidos'] = clean;
      }
    }
    
    // Estrategia 2: Si no se encontró, buscar en todo el texto con regex amplia
    if (result['nombres'] == '' || result['apellidos'] == '') {
      // Buscar "NOMBRES" seguido de texto hasta el siguiente campo o fin
      final nombresMatch = RegExp(
        r'NOMBRES?\s*:?\s*([A-ZÁ-Ú][A-Za-zÁ-ú\s\-\.]+?)(?=\s*(?:APELLIDOS?|FECHA|NACIMIENTO|C\.?I\.?|NÚMERO|DOMICILIO|PROFESION|\d{1,2}/\d{1,2}/\d{2,4}|$))',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(combined);
      if (nombresMatch != null && result['nombres'] == '') {
        final clean = _cleanName(nombresMatch.group(1) ?? '');
        if (clean.length >= 2) result['nombres'] = clean;
      }
      
      // Buscar "APELLIDOS" seguido de texto
      final apellidosMatch = RegExp(
        r'APELLIDOS?\s*:?\s*([A-ZÁ-Ú][A-Za-zÁ-ú\s\-\.]+?)(?=\s*(?:NOMBRES?|FECHA|NACIMIENTO|C\.?I\.?|NÚMERO|DOMICILIO|PROFESION|\d{1,2}/\d{1,2}/\d{2,4}|$))',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(combined);
      if (apellidosMatch != null && result['apellidos'] == '') {
        final clean = _cleanName(apellidosMatch.group(1) ?? '');
        if (clean.length >= 2) result['apellidos'] = clean;
      }
    }
    // Fechas
    final datePattern = RegExp(r'(\d{1,2})[/\-.\s](\d{1,2})[/\-.\s](\d{2,4})');
    for (final m in datePattern.allMatches(combined)) {
      final s = '${m.group(1)}/${m.group(2)}/${m.group(3)}';
      if (result['fechaEmision'] == '' && upper.contains('EMISION')) result['fechaEmision'] = s;
      else if (result['fechaExpiracion'] == '' && (upper.contains('EXPIR') || upper.contains('VALIDEZ'))) result['fechaExpiracion'] = s;
      else if (result['fechaNacimiento'] == '' && (upper.contains('NACIMIENTO') || upper.contains('NACIDO'))) result['fechaNacimiento'] = s;
    }
    // Lugar nacimiento, profesion, estado civil, domicilio, grupo sanguineo (etiquetas simples)
    final labelValue = RegExp(r'(LUGAR|DOMICILIO|OCUPACION|PROFESION|ESTADO\s+CIVIL|GRUPO\s+SANGUINEO)\s*:?\s*([^\n]+)', caseSensitive: false);
    for (final m in labelValue.allMatches(combined)) {
      final label = (m.group(1) ?? '').toUpperCase();
      final value = (m.group(2) ?? '').trim();
      if (label.contains('LUGAR') && !label.contains('DOMICILIO')) result['lugarNacimiento'] = value;
      else if (label.contains('DOMICILIO')) result['domicilio'] = value;
      else if (label.contains('OCUPACION') || label.contains('PROFESION')) result['profesion'] = value;
      else if (label.contains('ESTADO') && label.contains('CIVIL')) result['estadoCivil'] = value;
      else if (label.contains('GRUPO') && label.contains('SANGUINEO')) result['grupoSanguineo'] = value;
    }
    return result;
  }

  // --- MODELO ESPACIAL ---

  static Map<String, String> _extractSpatial(RecognizedText text) {
    debugPrint("🔍 OCR: Iniciando extracción espacial");
    debugPrint(
      "🔍 OCR: Total de bloques de texto encontrados: ${text.blocks.length}",
    );

    // Debug: Mostrar todo el texto reconocido
    String allText = text.blocks.map((block) => block.text).join(' ');
    debugPrint("🔍 OCR: Texto completo reconocido: '$allText'");

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
      'NUMERO',
    ]);
    debugPrint("🔍 OCR: Buscando etiqueta CI - Encontrada: ${ciLabel != null}");
    if (ciLabel != null) {
      debugPrint("🔍 OCR: Etiqueta CI encontrada: '${ciLabel.text}'");
      // Buscar a la derecha o abajo
      result['ci'] = _findTextNear(text, ciLabel.boundingBox, [
        Direction.right,
        Direction.bottom,
      ], pattern: r'\d{5,10}');
      debugPrint("🔍 OCR: CI extraído cerca de etiqueta: '${result['ci']}'");
    }
    // Si no encuentra por etiqueta, buscar patrón directo
    if (result['ci']!.isEmpty) {
      result['ci'] = _extractCIFallback(text);
      debugPrint("🔍 OCR: CI extraído por fallback: '${result['ci']}'");
    }

    // 2. NOMBRES (Buscar etiqueta 'NOMBRES')
    TextBlock? nombresLabel = _findBlockByKeywords(text, ['NOMBRES', 'NOMBRE']);
    debugPrint(
      "🔍 OCR: Buscando etiqueta NOMBRES - Encontrada: ${nombresLabel != null}",
    );
    if (nombresLabel != null) {
      debugPrint("🔍 OCR: Etiqueta NOMBRES encontrada: '${nombresLabel.text}'");
      result['nombres'] = _findTextNear(text, nombresLabel.boundingBox, [
        Direction.bottom,
        Direction.right,
      ], onlyLetters: true);
      debugPrint("🔍 OCR: Nombres extraídos: '${result['nombres']}'");
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

      // Comprobar si el contenido es un candidato válido
      String content = block.text.trim();
      if (pattern != null) {
        final reg = RegExp(pattern);
        if (!reg.hasMatch(content)) continue;
        // Extract specific match
        final m = reg.firstMatch(content);
        if (m != null) content = m.group(0)!;
      }
      if (onlyLetters) {
        if (content.length < 3) continue;
        if (content.contains(RegExp(r'[0-9]')) && content.length < 5) continue;
        final cleaned = _cleanName(content);
        if (!_isValidNameContent(cleaned)) continue;
        content = _stripLabelAndValidateName(cleaned);
        if (content.isEmpty) continue;
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
  //logiquita antigua
  // --- LOGICA ANTIGUA / HIBRIDA (Optimizado) ---

  static String _extractCIFallback(RecognizedText text) {
    final validCIPattern = RegExp(r'\b(\d{5,10})\b');

    // Recorrer bloques buscando patrón de número puro
    for (final block in text.blocks) {
      // Ignorar bloques muy grandes (párrafos) o muy pequeños
      if (block.text.length > 50) continue;

      final normalized = block.text
          .toUpperCase()
          .replaceAll('O', '0')
          .replaceAll('I', '1')
          .replaceAll('B', '8');
      final match = validCIPattern.firstMatch(normalized);
      if (match != null) {
        String ci = match.group(1)!;
        // Validar que no sea un año (ej 2025)
        int? val = int.tryParse(ci);
        if (val != null && (val > 1900 && val < 2100)) continue;
        return ci;
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
    double padding =
        120.0; // Píxeles base aumentado para cubrir mejor el área del carnet (recorte al margen)
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

  /// Limpia nombres/apellidos: quita números, símbolos y espacios extra
  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'[0-9\.\,\;\:\#\|\(\)\[\]\{\}\<\>\@\!\?\*\&\%\$\+\=\_\/\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Map<String, String> splitFullName(String fullName) {
    final cleaned = _cleanName(fullName);
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length < 2) return {'nombres': fullName, 'apellidos': ''};

    // Heurística boliviana: Primeras 2 palabras = apellidos, resto = nombres
    // (Formato: APELLIDO1 APELLIDO2 NOMBRE1 NOMBRE2...)
    if (words.length >= 3) {
      final apellidos = '${words[0]} ${words[1]}';
      final nombres = words.sublist(2).join(' ');
      return {'nombres': nombres, 'apellidos': apellidos};
    }
    return {'nombres': words[1], 'apellidos': words[0]};
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
//FUNCION DE PARSEO DE FECHA
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
///FUNCION DE ORDENAMIENTO DE FECHAS
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
