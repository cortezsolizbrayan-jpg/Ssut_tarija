import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum Direction { right, bottom }

// ═══════════════════════════════════════════════════════════════════════════════
// SERVICIO OCR INTELIGENTE PARA CI BOLIVIANO (V7)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Estrategia de extracción (en orden de prioridad):
//   1. Análisis ESPACIAL: busca etiquetas ("NOMBRES", "CI", etc.) y lee el
//      texto cercano por posición (derecha / abajo).
//   2. Patrón PERTENECE: en el reverso boliviano busca el bloque entre
//      "pertenece" y datos posteriores, usando un diccionario de nombres
//      para separar nombre de pila vs. apellidos.
//   3. Extracción por LÍNEAS: recorre las líneas OCR buscando etiquetas
//      seguidas de valores.
//   4. Extracción por TEXTO PLANO: regex sobre el texto concatenado.
//
// Fechas: Se deducen cronológicamente (la más vieja = nacimiento, etc.)
// ═══════════════════════════════════════════════════════════════════════════════

class ServicioOcrInteligenteIdentidad {

  // ─── PUNTO DE ENTRADA PRINCIPAL ──────────────────────────────────────────

  /// Extrae CI, nombres, apellidos y fechas de los textos OCR del anverso/reverso.
  static Map<String, dynamic> extractData(
    RecognizedText frontOcr,
    RecognizedText? backOcr,
  ) {
    debugPrint("🚀 Iniciando Smart OCR V7...");

    // Paso 1: Extracción espacial del anverso
    Map<String, String> data = _extractSpatial(frontOcr);

    // Paso 2: CI fallback si no se encontró
    if ((data['ci'] ?? '').isEmpty) {
      data['ci'] = _extractCIFallback(frontOcr);
    }

    // Paso 3: Extracción espacial del reverso (si existe)
    if (backOcr != null) {
      final backData = _extractSpatial(backOcr);
      if ((data['ci'] ?? '').isEmpty && (backData['ci'] ?? '').isNotEmpty) {
        data['ci'] = backData['ci']!;
      }
    }

    // Paso 4: Patrón "pertenece" del reverso boliviano
    final backText = backOcr?.text ?? '';
    final pertData = _extractFromPertenecePattern(
      backText.isNotEmpty ? backText : frontOcr.text,
    );
    _mergeIfEmpty(data, pertData, 'nombres');
    _mergeIfEmpty(data, pertData, 'apellidos');
    if ((pertData['fechaNacimiento'] ?? '').isNotEmpty) {
      data['fechaNacimiento'] = pertData['fechaNacimiento']!;
    }

    // Paso 5: Extracción por líneas (fallback)
    if ((data['nombres'] ?? '').isEmpty || (data['apellidos'] ?? '').isEmpty) {
      _fillFromLines(data, frontOcr);
      if (backOcr != null) _fillFromLines(data, backOcr);
    }

    // Paso 6: Extracción por texto plano (último recurso)
    if ((data['nombres'] ?? '').isEmpty || (data['apellidos'] ?? '').isEmpty) {
      final textData = extractDataFromText(frontOcr.text, backOcr?.text);
      _mergeStringIfEmpty(data, textData, 'nombres');
      _mergeStringIfEmpty(data, textData, 'apellidos');
    }

    // Limpieza final: quitar basura institucional de nombres
    data['nombres'] = _stripLabelAndValidateName(data['nombres'] ?? '');
    data['apellidos'] = _stripLabelAndValidateName(data['apellidos'] ?? '');

    // Paso 7: Fechas inteligentes
    _deduceDates(data, frontOcr, backOcr);

    debugPrint("📊 Datos extraídos finales:");
    debugPrint("   CI: ${data['ci']}");
    debugPrint("   Nombres: ${data['nombres']}");
    debugPrint("   Apellidos: ${data['apellidos']}");

    return {
      'ci': data['ci'] ?? '',
      'nombres': data['nombres'] ?? '',
      'apellidos': data['apellidos'] ?? '',
      'fechaEmision': data['fechaEmision'] ?? '',
      'fechaExpiracion': data['fechaExpiracion'] ?? '',
      'fechaNacimiento': data['fechaNacimiento'] ?? '',
      'model': 'v7-clean',
    };
  }

  // ─── HELPERS DE MERGE ────────────────────────────────────────────────────

  /// Copia valor de [source] a [target] solo si target está vacío.
  static void _mergeIfEmpty(
    Map<String, String> target,
    Map<String, String> source,
    String key,
  ) {
    if ((target[key] ?? '').isEmpty && (source[key] ?? '').isNotEmpty) {
      target[key] = source[key]!;
    }
  }

  /// Merge desde Map<String, dynamic> (extractDataFromText devuelve dynamic).
  static void _mergeStringIfEmpty(
    Map<String, String> target,
    Map<String, dynamic> source,
    String key,
  ) {
    final v = (source[key] ?? '').toString().trim();
    if ((target[key] ?? '').isEmpty && v.isNotEmpty) {
      target[key] = v;
    }
  }

  /// Rellena nombres/apellidos desde extracción por líneas.
  static void _fillFromLines(Map<String, String> data, RecognizedText text) {
    final lineData = _extractNamesFromLines(text);
    _mergeIfEmpty(data, lineData, 'nombres');
    _mergeIfEmpty(data, lineData, 'apellidos');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 1: EXTRACCIÓN POR LÍNEAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Recorre líneas OCR buscando etiquetas como "NOMBRES:" seguidas de valores.
  static Map<String, String> _extractNamesFromLines(RecognizedText text) {
    final result = <String, String>{'nombres': '', 'apellidos': ''};

    // Aplanar todos los bloques en una lista de líneas
    final lines = <String>[];
    for (final block in text.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) lines.add(t);
      }
    }

    for (int i = 0; i < lines.length; i++) {
      final lineUpper = lines[i].toUpperCase();

      // Caso A: Etiqueta sola en la línea → valor en la siguiente línea
      if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(lineUpper) && result['nombres']!.isEmpty) {
        result['nombres'] = _findValueAfterLabel(lines, i);
      }
      if (RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(lineUpper) && result['apellidos']!.isEmpty) {
        result['apellidos'] = _findValueAfterLabel(lines, i);
      }

      // Caso B: Etiqueta y valor en misma línea → "NOMBRES: JUAN CARLOS"
      if (result['nombres']!.isEmpty) {
        final m = RegExp(r'NOMBRES?\s*:+\s*(.+)', caseSensitive: false).firstMatch(lines[i]);
        if (m != null) {
          final c = _cleanName(m.group(1)!);
          if (_isValidNameContent(c)) result['nombres'] = _stripLabelAndValidateName(c);
        }
      }
      if (result['apellidos']!.isEmpty) {
        final m = RegExp(r'APELLIDOS?\s*:+\s*(.+)', caseSensitive: false).firstMatch(lines[i]);
        if (m != null) {
          final c = _cleanName(m.group(1)!);
          if (_isValidNameContent(c)) result['apellidos'] = _stripLabelAndValidateName(c);
        }
      }
    }
    return result;
  }

  /// Busca un valor nombre/apellido en las líneas siguientes a una etiqueta.
  static String _findValueAfterLabel(List<String> lines, int labelIdx) {
    for (int j = labelIdx + 1; j < lines.length && j < labelIdx + 4; j++) {
      final candidate = _cleanName(lines[j]);
      if (_isValidNameContent(candidate)) {
        return _stripLabelAndValidateName(candidate);
      }
    }
    return '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 2: VALIDACIÓN Y LIMPIEZA DE NOMBRES
  // ═══════════════════════════════════════════════════════════════════════════

  /// ¿Es texto válido para un nombre/apellido? (solo letras, sin basura institucional)
  static bool _isValidNameContent(String text) {
    final t = text.trim();
    if (t.length < 4 || t.length > 80) return false;

    final cleaned = _cleanName(t);
    if (cleaned.length < 4) return false;

    final words = cleaned.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty || words.length > 6) return false;

    final upper = cleaned.toUpperCase();

    // Rechazar palabras institucionales
    const forbidden = [
      'ESTADO', 'PLURINACIONAL', 'BOLIVIA', 'BOLUVIA', 'IDENTIDAD',
      'TITULAR', 'DATOS', 'REPUBLICA', 'REPÚBLICA', 'CARNET',
      'CEDULA', 'CÉDULA', 'SERVICIO', 'GENERAL',
      'SERIE', 'SECCION', 'SECCIÓN', 'BIO', 'REGISTRADOS',
      'DOCUMENTOS', 'DACTILAR', 'IMPRESION', 'FOTOGRAFIA',
    ];
    for (final w in forbidden) {
      if (upper.contains(w)) return false;
    }

    // Rechazar etiquetas de formulario
    const labels = [
      'NOMBRES', 'NOMBRE', 'APELLIDOS', 'APELLIDO', 'FIRMA',
      'INTERESADO', 'HUELLA', 'CEDULA', 'NUMERO', 'FECHA',
      'DOMICILIO', 'PROFESION', 'CIVIL',
    ];
    for (final w in labels) {
      if (upper == w || upper.startsWith('$w ') || upper.endsWith(' $w')) return false;
      if (upper.contains(' $w ') || upper.contains('$w:')) return false;
    }

    // Al menos 80% deben ser letras
    final letterOnly = cleaned.replaceAll(RegExp(r"[\s\-\.']"), '');
    if (letterOnly.isEmpty) return false;
    final letterCount = letterOnly.split('').where(
      (c) => RegExp(r'[A-Za-zÁ-Úá-úÑñ]').hasMatch(c),
    ).length;
    return letterCount >= letterOnly.length * 0.80;
  }

  /// Quita etiquetas al inicio ("NOMBRES: ...") y valida. Devuelve '' si basura.
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

  /// Limpia un nombre: quita números, símbolos y espacios extra.
  static String _cleanName(String raw) {
    return raw
        .replaceAll(RegExp(r'[0-9\.\,\;\:\#\|\(\)\[\]\{\}\<\>\@\!\?\*\&\%\$\+\=\_\/\\]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 3: PATRÓN "PERTENECE" (REVERSO BOLIVIANO)
  // ═══════════════════════════════════════════════════════════════════════════
  //
  // El reverso del CI boliviano dice:
  //   "CERTIFICA: Que la firma, fotografía e impresión pertenece
  //    NOMBRE1 [NOMBRE2] APELLIDO1 APELLIDO2
  //    Nacido el DD de Mes de AAAA en LUGAR..."
  //
  // CUIDADO: El OCR a veces mezcla el orden y pone el nombre DESPUÉS de
  // "Nacido el" (no antes). Por eso buscamos nombres en TODO el texto
  // después de "pertenece", filtrando con el diccionario.

  static const List<String> _kMesesEs = [
    'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
    'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
  ];

  /// Extrae nombres, apellidos y fecha de nacimiento del texto del reverso.
  static Map<String, String> _extractFromPertenecePattern(String text) {
    final result = <String, String>{
      'nombres': '',
      'apellidos': '',
      'fechaNacimiento': '',
    };
    if (text.isEmpty) return result;

    final upper = text.toUpperCase();

    // 1) Encontrar "PERTENECE" con variantes OCR
    int perteneceIdx = upper.indexOf('PERTENECE');
    if (perteneceIdx == -1) {
      // Intentar variantes OCR comunes
      final variantes = ['PERTENEC', 'PERTENEC E', 'PERTENE CE', 'PERTENECE'];
      for (final v in variantes) {
        final idx = upper.indexOf(v);
        if (idx != -1) { perteneceIdx = idx; break; }
      }
      if (perteneceIdx == -1) return result;
    }

    // Todo el texto después de "pertenece"
    String segment = text.substring(perteneceIdx);
    segment = segment.replaceFirst(
      RegExp(r'^PERTENECE?\s*A?\s*:?\s*', caseSensitive: false), '',
    ).trim();

    // 2) Extraer fecha de nacimiento (formato español: "14 de Septiembre de 1999")
    result['fechaNacimiento'] = _parseFechaEspanol(segment) ?? '';
    if (result['fechaNacimiento']!.isEmpty) {
      result['fechaNacimiento'] = _parseFechaEspanol(text) ?? '';
    }

    // 3) Limpiar el segmento para encontrar palabras-nombre
    //    SOLO tomar la primera línea después de "PERTENECE A:" = nombre completo
    //    El carnet boliviano tiene: "RICHARD ERICK HUAÑAPACO CHURA" en la primera línea
    //    Luego "Nacido el...", "En:", "Profesión:", "Domicilio:", etc.
    final lineas = segment.split(RegExp(r'\n|\r\n|\r'));
    String lineaNombre = '';
    for (final linea in lineas) {
      final limpia = linea.trim();
      if (limpia.isEmpty) continue;
      final limpiaUpper = limpia.toUpperCase();
      // Parar si encontramos campos de otros datos
      if (limpiaUpper.startsWith('NACIDO') ||
          limpiaUpper.startsWith('NACIDA') ||
          limpiaUpper.startsWith('EN:') ||
          limpiaUpper.startsWith('PROFESION') ||
          limpiaUpper.startsWith('PROFESIÓN') ||
          limpiaUpper.startsWith('DOMICILIO') ||
          limpiaUpper.startsWith('DOCUMENTOS') ||
          limpiaUpper.startsWith('ESTADO CIVIL')) {
        break;
      }
      lineaNombre = limpia;
      break;
    }

    // Si no encontramos línea de nombre, usar el segmento completo como fallback
    final segmentoParaNombre = lineaNombre.isNotEmpty ? lineaNombre : segment;
    final cleanWords = _extractCleanWordsFromSegment(segmentoParaNombre);

    debugPrint("🔍 OCR Pertenece: palabras limpias = $cleanWords");
    if (cleanWords.isEmpty) return result;

    // 4) Separar nombres de apellidos con diccionario
    final separated = _separateNamesFromSurnames(cleanWords);
    if (separated.length >= 2) {
      result['nombres'] = separated[0];
      result['apellidos'] = separated[1];
    } else if (cleanWords.length >= 3) {
      // Fallback: últimas 2 = apellidos, anteriores = nombres
      result['apellidos'] = '${cleanWords[cleanWords.length - 2]} ${cleanWords.last}';
      result['nombres'] = cleanWords.sublist(0, cleanWords.length - 2).join(' ');
    } else if (cleanWords.length == 2) {
      result['nombres'] = cleanWords[0];
      result['apellidos'] = cleanWords[1];
    } else {
      result['nombres'] = cleanWords[0];
    }

    debugPrint("✅ Pertenece → nombres='${result['nombres']}' "
        "apellidos='${result['apellidos']}' nacimiento='${result['fechaNacimiento']}'");
    return result;
  }

  /// Extrae palabras limpias de un segmento de texto del reverso.
  /// Filtra ruido OCR, palabras institucionales y basura.
  static List<String> _extractCleanWordsFromSegment(String segment) {
    // Palabras que NUNCA son nombres de persona
    const noiseWords = <String>{
      // Artefactos de teclado/OCR
      'SHIFT', 'DELETE', 'DELETI', 'APOJP', 'CTRL', 'ALT', 'ESC', 'TAB',
      // Artículos y preposiciones
      'A', 'AN', 'DE', 'EL', 'LA', 'EN', 'Y', 'E', 'QUE', 'CON', 'POR',
      'PARA', 'SU', 'LOS', 'LAS', 'DEL', 'AL', 'UN', 'UNA',
      // Texto descriptivo del reverso del CI
      'CERTIFICA', 'FIRMA', 'FOTOGRAFIA', 'FOTOGRAFÍA', 'IMPRESION',
      'IMPRESIÓN', 'PERTENECE', 'DACTILAR', 'HUELLA', 'DATO',
      'SIGNATURA', 'INTERESADO', 'SERVICIO', 'GENERAL', 'IDENTIFICACION',
      'IDENTIFICACIÓN', 'PERSONAL', 'SEGIP', 'REGISTRO', 'REGISTRADO',
      'DOCUMENTO', 'DOCUMENTOS', 'EMITIDA', 'EMITIÓ', 'NACIDO', 'NACIDA',
      'CIVIL', 'SOLTERO', 'SOLTERA', 'CASADO', 'CASADA', 'VIUDO', 'VIUDA',
      'DIVORCIADO', 'DIVORCIADA',
      'OCUPACION', 'OCUPACIÓN', 'ESTUDIANTE', 'DOMICILIO',
      'ESTADO', 'PLURINACIONAL', 'BOLIVIA', 'BOLUVIA',
      'REPUBLICA', 'REPÚBLICA',
      // Ruido del anverso del CI boliviano
      'SERIE', 'SECCION', 'SECCIÓN', 'BIO', 'REGISTRADOS',
      'NUMERO', 'NÚMERO', 'CEDULA', 'CÉDULA', 'IDENTIDAD',
      // Ciudades/departamentos bolivianos comunes (ruido del reverso)
      'COCHABAMBA', 'ORURO', 'POTOSI', 'TARIJA', 'SUCRE', 'TRINIDAD',
      'COBIJA', 'RIBERALTA', 'GUAYARAMERIN',
    };

    // Prefijos de ruido institucional
    const noisePrefixes = [
      'ESTADO', 'PLURINACIONAL', 'ESTADOPLURINACIONAL',
      'ESTADURINACIONAL', 'ESTADURINACIONA',
      'REPUBLICA', 'REPÚBLICA', 'BOLIVIA', 'BOLUVIA',
    ];

    final rawWords = segment.split(RegExp(r'[\s\n\r,.:;()\/\-]+'));
    final List<String> cleanWords = [];

    for (final w in rawWords) {
      // Quitar caracteres no-letra
      final wClean = w.replaceAll(RegExp(r"[^A-ZÁ-ÚÑa-zá-úñ]"), '');
      if (wClean.length < 2) continue;

      // Normalizar a mayúsculas
      final wUpper = wClean.toUpperCase();

      // Filtros
      if (noiseWords.contains(wUpper)) continue;
      if (!RegExp(r'^[A-ZÁÉÍÓÚÑÜ]+$').hasMatch(wUpper)) continue;
      if (noisePrefixes.any((p) => wUpper.startsWith(p))) continue;
      if (wUpper.length > 15) continue; // Concatenaciones OCR

      cleanWords.add(wUpper);
    }

    return cleanWords;
  }

  /// Parsea fecha en español: "14 de Septiembre de 1999" → "14/09/1999"
  static String? _parseFechaEspanol(String text) {
    final re = RegExp(
      r'(\d{1,2})\s*de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|'
      r'septiembre|sept\s*iembre|octubre|noviembre|diciembre)\s+de\s+(\d{4})',
      caseSensitive: false,
    );
    final m = re.firstMatch(text);
    if (m == null) return null;

    final day = int.tryParse(m.group(1) ?? '') ?? 0;
    final mesStr = (m.group(2) ?? '').toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final year = int.tryParse(m.group(3) ?? '') ?? 0;

    // Buscar mes (soporta "sept iembre" y variantes OCR)
    int month = 0;
    for (int i = 0; i < _kMesesEs.length; i++) {
      if (mesStr.startsWith(_kMesesEs[i].substring(0, math.min(4, _kMesesEs[i].length)))) {
        month = i + 1;
        break;
      }
    }

    if (day < 1 || day > 31 || month < 1 || year < 1900 || year > 2100) return null;
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 4: DICCIONARIO DE NOMBRES BOLIVIANOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Nombres de pila hispanos/bolivianos más comunes.
  static const Set<String> _kNombresComunes = {
    // ── Masculinos ──
    'ABEL','ABRAHAM','ADOLFO','ADRIAN','AGUSTIN','ALBERTO','ALEJANDRO','ALEX',
    'ALFREDO','ALVARO','ANDRES','ANGEL','ANTONIO','ARMANDO','ARTURO','AUGUSTO',
    'BENJAMIN','BORIS','BRAYAN','BRYAN','CARLOS','CESAR','CHRISTIAN','CRISTIAN',
    'CRISTOBAL','DANIEL','DARIO','DAVID','DIEGO','EDGAR','EDUARDO','ELIAS',
    'EMILIO','ENRIQUE','ERICK','ERNESTO','ESTEBAN','FABIAN','FEDERICO','FELIPE',
    'FERNANDO','FRANCISCO','FREDDY','GABRIEL','GERARDO','GONZALO','GUADALUPE',
    'GUILLERMO','GUSTAVO','HECTOR','HENRY','HERNAN','HUGO','IGNACIO',
    'IVAN','JAVIER','JESUS','JHON','JORGE','JOSE','JOSUE','JUAN','JULIO',
    'KEVIN','LEONARDO','LEONIDAS','LEOPOLDO','LUIS','MANUEL','MARCELO','MARCO',
    'MARCOS','MARIO','MARTIN','MATEO','MAXIMO','MIGUEL','NICOLAS','OMAR',
    'OSCAR','PABLO','PATRICIO','PAUL','PEDRO','RAFAEL','RAMIRO','RAUL',
    'RENATO','RICARDO','RICHARD','ROBERTO','RODRIGO','ROLANDO','RONALD',
    'RUBEN','SAMUEL','SANTIAGO','SERGIO','SIMON','TOMAS','VICTOR','WALTER',
    'WILLY','WILSON','XAVIER','YHON','YOFRE',
    // ── Femeninos ──
    'ADRIANA','ALEJANDRA','ALEXANDRA','ANA','ANDREA','ANGIE','ANTONIA',
    'BEATRIZ','BRENDA','CAMILA','CARLA','CARMEN','CAROLINA','CECILIA',
    'CLAUDIA','DANIELA','DIANA','ELENA','ELISA','ELIZABETH','EMILY',
    'EMMA','ESTHER','EVA','FABRICIA','FERNANDA','GABRIELA','GLORIA',
    'GRACIELA','INGRID','ISABEL','JACQUELINE','JESSICA','JOHANNA',
    'JULIA','KAREN','KATHERIN','LAURA','LENA','LESLIE','LILIANA',
    'LORENA','LUCIA','LUISA','MARCELA','MARIA','MARIANA','MARLENE',
    'MARTHA','MELISSA','MILAGROS','MIRIAM','MONICA','NATALIA','NOELIA',
    'NORMA','OLGA','PAOLA','PATRICIA','PRISCILA','ROSA','ROXANA','RUTH',
    'SANDRA','SARA','SILVIA','SONIA','SOFIA','STEPHANIE','SUSAN','SUSANA',
    'TATIANA','TANIA','TERESA','VANESSA','VERONICA','VIRGINIA',
    'WENDY','XIOMARA','YESSENIA','YOLANDA','ZULMA',
  };

  /// Separa [words] en [nombres, apellidos] usando el diccionario.
  ///
  /// Lógica: las primeras palabras que están en el diccionario = nombres de pila.
  /// Cuando encontramos la primera palabra que NO está = empieza apellidos.
  /// Máximo 2 nombres, máximo 2 apellidos.
  static List<String> _separateNamesFromSurnames(List<String> words) {
    if (words.length < 2) return [];

    final List<String> nombres = [];
    final List<String> apellidos = [];
    bool inNombres = true;

    for (final w in words) {
      if (inNombres) {
        if (_kNombresComunes.contains(w)) {
          nombres.add(w);
          if (nombres.length >= 2) inNombres = false;
        } else {
          inNombres = false;
          apellidos.add(w);
        }
      } else {
        apellidos.add(w);
        if (apellidos.length >= 2) break;
      }
    }

    if (nombres.isEmpty || apellidos.isEmpty) return [];

    debugPrint("✅ Diccionario → nombres='${nombres.join(' ')}' "
        "apellidos='${apellidos.join(' ')}'");
    return [nombres.join(' '), apellidos.join(' ')];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 5: EXTRACCIÓN POR TEXTO PLANO (REGEX)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extrae datos desde texto plano concatenado (fallback genérico).
  static Map<String, dynamic> extractDataFromText(String frontText, [String? backText]) {
    final combined = backText != null && backText.isNotEmpty
        ? '$frontText\n$backText'
        : frontText;
    final upper = combined.toUpperCase();

    final result = <String, dynamic>{
      'ci': '', 'nombres': '', 'apellidos': '',
      'fechaEmision': '', 'fechaExpiracion': '', 'fechaNacimiento': '',
      'lugarNacimiento': '', 'profesion': '', 'estadoCivil': '',
      'domicilio': '', 'grupoSanguineo': '',
    };

    // ── CI: buscar con patrones de mayor a menor precisión ──
    result['ci'] = _extractCIFromText(combined);

    // ── Nombres/Apellidos: por etiqueta ──
    _extractNamesFromTextLines(result, combined);

    // ── Fechas: por etiqueta explícita y fallback ──
    _extractDatesFromText(result, combined, upper);

    // ── Otros campos: etiquetas simples ──
    _extractMiscFields(result, combined);

    return result;
  }

  /// Extrae CI del texto plano probando patrones de mayor a menor precisión.
  static String _extractCIFromText(String text) {
    final patterns = [
      RegExp(r'C[EÉ]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})', caseSensitive: false),
      RegExp(r'(?:NO\.?|NRO\.?)\s*:?\s*[\s\-]*(\d{5,11})', caseSensitive: false),
      RegExp(r'N\s*[°º\.]\s*:?\s*(\d{5,11})', caseSensitive: false),
      RegExp(r'C\.?\s*I\.?\s*:?\s*(\d{5,11})', caseSensitive: false),
      RegExp(r'NUMERO\s*:?\s*(\d{5,11})', caseSensitive: false),
      RegExp(r'\b(\d{7,10})\b'),
      RegExp(r'(\d{6,11})'),
    ];

    for (final re in patterns) {
      for (final m in re.allMatches(text)) {
        final ci = (m.group(1) ?? '').trim();
        if (ci.length >= 5 && ci.length <= 11 && ci != '0' * ci.length) {
          final ciNum = int.tryParse(ci);
          if (ciNum != null && ciNum > 10000) return ci;
        }
      }
    }
    return '';
  }

  /// Extrae nombres/apellidos por etiquetas en las líneas del texto.
  static void _extractNamesFromTextLines(Map<String, dynamic> result, String text) {
    final lines = text.split(RegExp(r'[\n\r]+'));

    for (int i = 0; i < lines.length; i++) {
      final lineUpper = lines[i].toUpperCase().trim();
      final nextLine = i + 1 < lines.length ? lines[i + 1].trim() : '';

      // Etiqueta sola → valor en siguiente línea
      if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(lineUpper) && nextLine.isNotEmpty && result['nombres'] == '') {
        final clean = _cleanName(nextLine);
        if (clean.length >= 2) result['nombres'] = clean;
      }
      if (RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(lineUpper) && nextLine.isNotEmpty && result['apellidos'] == '') {
        final clean = _cleanName(nextLine);
        if (clean.length >= 2) result['apellidos'] = clean;
      }

      // Etiqueta y valor en misma línea
      final nomMatch = RegExp(r'NOMBRES?\s*:+\s*([A-ZÁ-Ú\s]+)', caseSensitive: false).firstMatch(lines[i]);
      if (nomMatch != null && result['nombres'] == '') {
        final clean = _cleanName(nomMatch.group(1)!);
        if (clean.length >= 2) result['nombres'] = clean;
      }
      final apeMatch = RegExp(r'APELLIDOS?\s*:+\s*([A-ZÁ-Ú\s]+)', caseSensitive: false).firstMatch(lines[i]);
      if (apeMatch != null && result['apellidos'] == '') {
        final clean = _cleanName(apeMatch.group(1)!);
        if (clean.length >= 2) result['apellidos'] = clean;
      }
    }
  }

  /// Extrae fechas del texto por etiquetas y fallback genérico.
  static void _extractDatesFromText(Map<String, dynamic> result, String text, String upper) {
    // Emisión
    final emisionMatch = RegExp(
      r'(EMISION|EMISIÓN|EMITIDA(?:\s+EL)?|F\.?\s*EMISION)\s*:?\s*(\d{1,2}[/\-.\s]\d{1,2}[/\-.\s]\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (emisionMatch != null) {
      result['fechaEmision'] = (emisionMatch.group(2) ?? '').replaceAll(RegExp(r'[-.\s]+'), '/');
    }

    // Expiración
    final expMatch = RegExp(
      r'(EXPIRACION|EXPIRACIÓN|EXPIRA(?:\s+EL)?|VENCE|VENCIMIENTO|VALIDEZ|VÁLIDA(?:\s+HASTA)?)\s*:?\s*(\d{1,2}[/\-.\s]\d{1,2}[/\-.\s]\d{2,4}|INDEFINID[OA]|ILIMITADO|PERMANENTE)',
      caseSensitive: false,
    ).firstMatch(text);
    if (expMatch != null) {
      final raw = (expMatch.group(2) ?? '').trim().toUpperCase();
      result['fechaExpiracion'] = raw.contains('INDEFINID') || raw.contains('ILIMITADO') || raw.contains('PERMANENTE') ? 'ILIMITADO' : raw.replaceAll(RegExp(r'[-.\s]+'), '/');
    }
  }

  /// Extrae campos misceláneos (lugar, profesión, estado civil, etc.)
  static void _extractMiscFields(Map<String, dynamic> result, String text) {
    final labelValue = RegExp(
      r'(LUGAR|DOMICILIO|OCUPACION|PROFESION|ESTADO\s+CIVIL|GRUPO\s+SANGUINEO)\s*:?\s*([^\n]+)',
      caseSensitive: false,
    );
    for (final m in labelValue.allMatches(text)) {
      final label = (m.group(1) ?? '').toUpperCase();
      final value = (m.group(2) ?? '').trim();
      if (label.contains('LUGAR') && !label.contains('DOMICILIO')) {
        result['lugarNacimiento'] = value;
      } else if (label.contains('DOMICILIO')) result['domicilio'] = value;
      else if (label.contains('OCUPACION') || label.contains('PROFESION')) result['profesion'] = value;
      else if (label.contains('ESTADO') && label.contains('CIVIL')) result['estadoCivil'] = value;
      else if (label.contains('GRUPO') && label.contains('SANGUINEO')) result['grupoSanguineo'] = value;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 6: MODELO ESPACIAL (por posición de bloques OCR)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extracción espacial: busca etiquetas y lee valores cercanos por posición.
  static Map<String, String> _extractSpatial(RecognizedText text) {
    debugPrint("🔍 OCR: Extracción espacial (${text.blocks.length} bloques)");

    final result = <String, String>{
      'ci': '', 'nombres': '', 'apellidos': '',
      'fechaEmision': '', 'fechaExpiracion': '',
    };

    // ── CI ──
    final ciLabel = _findBlockByKeywords(text, ['CEDULA', 'C.I.', 'NRO', 'NUMERO', 'NÚMERO']);
    if (ciLabel != null) {
      result['ci'] = _findTextNear(text, ciLabel.boundingBox, [Direction.right, Direction.bottom], pattern: r'\d{5,10}');
    }
    if (result['ci']!.isEmpty) {
      result['ci'] = _extractCIFallback(text);
    }

    // ── NOMBRES ──
    final nombresLabel = _findBlockByKeywords(text, ['NOMBRES', 'NOMBRE']);
    if (nombresLabel != null) {
      result['nombres'] = _findTextNear(text, nombresLabel.boundingBox, [Direction.bottom, Direction.right], onlyLetters: true);
    }

    // ── APELLIDOS (separados o juntos) ──
    final paternoLabel = _findBlockByKeywords(text, ['PATERNO']);
    final maternoLabel = _findBlockByKeywords(text, ['MATERNO']);
    if (paternoLabel != null || maternoLabel != null) {
      final p = paternoLabel != null
          ? _findTextNear(text, paternoLabel.boundingBox, [Direction.bottom, Direction.right], onlyLetters: true) : '';
      final m = maternoLabel != null
          ? _findTextNear(text, maternoLabel.boundingBox, [Direction.bottom, Direction.right], onlyLetters: true) : '';
      result['apellidos'] = '$p $m'.trim();
    }
    if (result['apellidos']!.isEmpty) {
      final apeLabel = _findBlockByKeywords(text, ['APELLIDOS', 'APELLIDO']);
      if (apeLabel != null) {
        result['apellidos'] = _findTextNear(text, apeLabel.boundingBox, [Direction.bottom, Direction.right], onlyLetters: true);
      } else {
        // Fallback: "PERTENECE A:" del anverso
        final pertLabel = _findBlockByKeywords(text, ['PERTENECE', 'PERTENECE A']);
        if (pertLabel != null) {
          final fullName = _findTextNear(text, pertLabel.boundingBox, [Direction.right, Direction.bottom], onlyLetters: true);
          if (fullName.isNotEmpty) {
            final parts = splitFullName(fullName);
            result['nombres'] = parts['nombres'] ?? '';
            result['apellidos'] = parts['apellidos'] ?? '';
          }
        }
      }
    }

    // ── FECHAS ──
    const datePattern = r'\d{1,2}[-/. \s]\d{1,2}[-/. \s]\d{2,4}';

    final emisionLabel = _findBlockByKeywords(text, ['EMISION', 'EMISIÓN', 'EMITIDA', 'EMITIDA EL', 'F. EMISION']);
    if (emisionLabel != null) {
      result['fechaEmision'] = _findTextNear(text, emisionLabel.boundingBox, [Direction.right, Direction.bottom], pattern: datePattern);
    }

    final expLabel = _findBlockByKeywords(text, ['EXPIRACION', 'EXPIRACIÓN', 'EXPIRA', 'EXPIRA EL', 'VENCIMIENTO', 'VALIDEZ', 'VENCE']);
    if (expLabel != null) {
      result['fechaExpiracion'] = _findTextNear(text, expLabel.boundingBox, [Direction.right, Direction.bottom], pattern: datePattern);
    }

    // Fallback fechas: la más futura = expiración
    if (result['fechaExpiracion']!.isEmpty) {
      final allDates = _findAllDates(text, datePattern);
      if (allDates.isNotEmpty) result['fechaExpiracion'] = allDates.last;
    }

    return result;
  }

  // ─── Utilidades espaciales ───────────────────────────────────────────────

  /// Busca un bloque que contenga alguna de las [keywords].
  static TextBlock? _findBlockByKeywords(RecognizedText text, List<String> keywords) {
    for (final block in text.blocks) {
      final str = block.text.toUpperCase();
      for (final k in keywords) {
        if (str.contains(k)) return block;
        if (k.length > 4) {
          for (final w in str.split(RegExp(r'\s+'))) {
            if (w.isNotEmpty && _levenshtein(w, k) < 2) return block;
          }
        }
      }
    }
    return null;
  }

  /// Busca texto cercano a un [anchor] rect en las [directions] dadas.
  static String _findTextNear(
    RecognizedText text,
    Rect anchor,
    List<Direction> directions, {
    String? pattern,
    bool onlyLetters = false,
  }) {
    double closestDist = double.infinity;
    String bestMatch = '';

    for (final block in text.blocks) {
      if (block.boundingBox == anchor) continue;

      // Preparar contenido candidato
      String content = block.text.trim();
      if (pattern != null) {
        final reg = RegExp(pattern);
        if (!reg.hasMatch(content)) continue;
        final m = reg.firstMatch(content);
        if (m != null) content = m.group(0)!;
      }
      if (onlyLetters) {
        if (content.length < 3) continue;
        final cleaned = _cleanName(content);
        if (!_isValidNameContent(cleaned)) continue;
        content = _stripLabelAndValidateName(cleaned);
        if (content.isEmpty) continue;
      }

      // Medir proximidad en cada dirección
      bool isCandidate = false;
      double dist = double.infinity;

      for (final dir in directions) {
        if (dir == Direction.right) {
          final yOverlap = math.max(0.0, math.min(anchor.bottom, block.boundingBox.bottom) - math.max(anchor.top, block.boundingBox.top));
          if (yOverlap > anchor.height * 0.3 && block.boundingBox.left > anchor.right - 20) {
            final d = block.boundingBox.left - anchor.right;
            if (d > -20 && d < 300 && d < dist) { dist = d; isCandidate = true; }
          }
        } else if (dir == Direction.bottom) {
          final xOverlap = math.max(0.0, math.min(anchor.right, block.boundingBox.right) - math.max(anchor.left, block.boundingBox.left));
          if (xOverlap > math.min(anchor.width, block.boundingBox.width) * 0.3 && block.boundingBox.top > anchor.bottom - 10) {
            final d = block.boundingBox.top - anchor.bottom;
            if (d > -10 && d < 150 && d < dist) { dist = d; isCandidate = true; }
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

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 7: CI FALLBACK (heurística posicional)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Extrae CI usando heurística posicional cuando no hay etiqueta clara.
  static String _extractCIFallback(RecognizedText text) {
    final validCI = RegExp(r'\b(\d{5,10})\b');
    final List<TextBlock> candidates = [];

    for (final block in text.blocks) {
      if (block.text.length > 50) continue;
      final normalized = block.text.toUpperCase()
          .replaceAll('O', '0').replaceAll('I', '1').replaceAll('B', '8');
      final match = validCI.firstMatch(normalized);
      if (match != null) {
        final ci = match.group(1)!;
        final val = int.tryParse(ci);
        if (val != null && (val <= 1900 || val >= 2100)) candidates.add(block);
      }
    }

    if (candidates.isEmpty) return '';

    // Calcular ancho total para heurística posicional
    double totalWidth = 0;
    for (final b in text.blocks) {
      if (b.boundingBox.right > totalWidth) totalWidth = b.boundingBox.right;
    }

    // Scoring: izquierda = probable CI, derecha+arriba = probable serie
    TextBlock? best;
    double bestScore = -9999;
    for (final c in candidates) {
      double score = 0;
      if (c.boundingBox.left < totalWidth * 0.55) {
        score += 50;
      } else if (c.boundingBox.top < 250) score -= 100;
      if (c.text.trim().length <= 12) score += 20;
      if (score > bestScore) { bestScore = score; best = c; }
    }

    if (best == null) return '';
    final normalized = best.text.toUpperCase()
        .replaceAll('O', '0').replaceAll('I', '1').replaceAll('B', '8');
    return validCI.firstMatch(normalized)?.group(1) ?? '';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 8: DEDUCCIÓN INTELIGENTE DE FECHAS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Deduce fechas (nacimiento, emisión, expiración) por lógica cronológica.
  static void _deduceDates(Map<String, String> data, RecognizedText frontOcr, RecognizedText? backOcr) {
    const datePattern = r'\d{1,2}[-/. \s]\d{1,2}[-/. \s]\d{2,4}';
    final allDatesStr = <String>[];
    allDatesStr.addAll(_findAllDates(frontOcr, datePattern));
    if (backOcr != null) allDatesStr.addAll(_findAllDates(backOcr, datePattern));

    final validDates = allDatesStr.map(_toDate).whereType<DateTime>().toSet().toList();
    validDates.sort();

    final currentYear = DateTime.now().year;
    String fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    if (validDates.isNotEmpty) {
      // Nacimiento: la fecha más vieja si es ≥ 18 años atrás
      final oldest = validDates.first;
      if (currentYear - oldest.year >= 18) {
        data['fechaNacimiento'] = fmtDate(oldest);
        validDates.removeAt(0);
      }

      if (validDates.length >= 2) {
        data['fechaEmision'] = fmtDate(validDates.first);
        data['fechaExpiracion'] = fmtDate(validDates.last);
      } else if (validDates.length == 1) {
        final d = validDates.first;
        if (d.isAfter(DateTime.now())) {
          data['fechaExpiracion'] = fmtDate(d);
          if ((data['fechaEmision'] ?? '').isEmpty) {
            data['fechaEmision'] = fmtDate(DateTime(d.year - 10, d.month, d.day));
          }
        } else {
          data['fechaEmision'] = fmtDate(d);
          if ((data['fechaExpiracion'] ?? '').isEmpty) {
            data['fechaExpiracion'] = fmtDate(DateTime(d.year + 10, d.month, d.day));
          }
        }
      }
    }

    // Carnet indefinido
    final allText = '${frontOcr.text} ${backOcr?.text ?? ''}'.toUpperCase();
    if (allText.contains('INDEFINID') || allText.contains('ILIMITADO') || allText.contains('PERMANENTE')) {
      data['fechaExpiracion'] = 'ILIMITADO';
    }
  }

  /// Convierte "DD/MM/YYYY" a DateTime.
  static DateTime? _toDate(String d) {
    final parts = d.split('/');
    if (parts.length < 3) return null;
    int day = int.tryParse(parts[0]) ?? 0;
    int month = int.tryParse(parts[1]) ?? 0;
    int year = int.tryParse(parts[2]) ?? 0;
    if (year < 100) year = year > 30 ? 1900 + year : 2000 + year;
    if (day == 0 || month == 0 || year == 0 || month > 12 || day > 31) return null;
    return DateTime(year, month, day);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SECCIÓN 9: UTILIDADES GENERALES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Detecta el lado del documento (anverso/reverso).
  static String detectSide(RecognizedText text) {
    final str = text.text.toUpperCase();
    if (str.contains('HUELLA') || str.contains('DACTILAR') ||
        str.contains('CIVIL') || str.contains('PROFESION')) {
      return 'reverso';
    }
    return 'anverso';
  }

  /// Retorna el bounding box de todo el texto + margen.
  static Rect getRelevantROI(RecognizedText text) {
    if (text.blocks.isEmpty) return Rect.zero;
    double minX = double.infinity, minY = double.infinity, maxX = 0, maxY = 0;
    for (final b in text.blocks) {
      if (b.boundingBox.left < minX) minX = b.boundingBox.left;
      if (b.boundingBox.top < minY) minY = b.boundingBox.top;
      if (b.boundingBox.right > maxX) maxX = b.boundingBox.right;
      if (b.boundingBox.bottom > maxY) maxY = b.boundingBox.bottom;
    }
    const padding = 120.0;
    return Rect.fromLTRB(minX - padding, minY - padding, maxX + padding, maxY + padding);
  }

  /// Separa nombre completo en nombres/apellidos (heurística boliviana).
  static Map<String, String> splitFullName(String fullName) {
    final cleaned = _cleanName(fullName);
    final words = cleaned.split(RegExp(r'\s+'));
    if (words.length < 2) return {'nombres': fullName, 'apellidos': ''};

    // Heurística boliviana: primeras 2 = apellidos, resto = nombres
    if (words.length >= 3) {
      return {
        'nombres': words.sublist(2).join(' '),
        'apellidos': '${words[0]} ${words[1]}',
      };
    }
    return {'nombres': words[1], 'apellidos': words[0]};
  }

  /// Distancia de Levenshtein entre dos strings.
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

  /// Busca todas las fechas en los bloques OCR, las normaliza y ordena.
  static List<String> _findAllDates(RecognizedText text, String pattern) {
    final reg = RegExp(pattern);
    final dates = <String>[];
    for (final b in text.blocks) {
      for (final m in reg.allMatches(b.text)) {
        dates.add(m.group(0)!.replaceAll(RegExp(r'[-. \s]'), '/'));
      }
    }
    dates.sort((a, b) {
      final da = _toDate(a);
      final db = _toDate(b);
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });
    return dates;
  }
}
