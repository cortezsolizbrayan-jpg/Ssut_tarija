import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Un 'Microservicio' de lógica robusta para la extracción de datos de identidad.
/// Diseñado para ser 'a prueba de fallas' mediante múltiples estrategias de detección.
class IdentitySmartOcrService {
  
  static const List<String> _forbiddenWords = [
    'ESTADO', 'PLURINACIONAL', 'BOLIVIA', 'DATOS', 'TITULAR', 'CEDULA', 'IDENTIDAD',
    'NACIMIENTO', 'EMISION', 'EXPIRACION', 'VENCIMIENTO', 'DOMICILIO', 'LUGAR',
    'DOCUMENTOS', 'REGISTRADOS', 'FIRMA', 'OCUPACION', 'CIVIL', 'SERECI', 'SEGIP',
    // Encabezados Institucionales (AGRESIVO)
    'SERVICIO', 'GENERAL', 'IDENTIFICACION', 'PERSONAL', 'TRIBUNAL', 'SUPREMO', 
    'ELECTORAL', 'ORGANO', 'UNIDAD', 'POLICIA', 'NACIONAL', 'DIRECCION',
    'SERIE', 'SECCION', 'REPUBLICA', 'CORTE', 'DISTRITO', 'JUDICIAL', 'FEDERAL',
    // Fragmentos basura específicos reportados
    'DEROL', 'IVIA', 'ESTAD', 'PLURI', 'NACION', 'TRIBUN', 'SUPREM', 'REGIS',
    'INCACLONAL', 'CLONAL', 'INCA', 'CIONAL', 'NAL', 'DEBOL', 'BOL', // Mencionados por el usuario
    'DDLURINDI', 'IRINAC', 'ADOPL', 'UINACGIONAL', 'RINAC', // NUEVA BASURA REPORTADA
    // Palabras estructurales o de fechas
    'EMITIDA', 'DEPARTAMENTO', 'PAIS', 'CIUDAD', 'LOCALIDAD', 'PROVINCIA', 'SECCION',
    'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'IMPRESION', 'PERTENECE',
    'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'
  ];

  /// Extrae datos estructurados de los resultados de OCR
  static Map<String, dynamic> extractData(RecognizedText frontOcr, RecognizedText? backOcr) {
    debugPrint("🚀 Iniciando extracción Smart OCR v5 (Anti-Garbage)...");
    
    final frontLines = _getSortedLines(frontOcr);
    final backLines = backOcr != null ? _getSortedLines(backOcr) : <String>[];
    final allTextLines = [...frontLines, ...backLines];
    
    // 1. Detectar Modelo (Referencial, para el reporte final)
    final model = _detectModel(frontLines, backLines);
    
    // 2. Extraer CI (Prioridad Máxima)
    String ci = _extractCI(frontLines);
    if (ci.isEmpty && backLines.isNotEmpty) ci = _extractCI(backLines);
    
    // 3. Extracción de Nombres - PIPELINE DE ESTRATEGIAS
    // En lugar de confiar en _detectModel, probamos las estrategias en orden de especificidad.
    
    Map<String, String> bestMatch = {'nombres': '', 'apellidos': ''};

    // ESTRATEGIA A: Patrón de Carnet Antiguo ("PERTENECE A")
    // Es el más específico. Si existe, es casi seguro que es un carnet antiguo.
    final matchAntiguo = _extractOldModelNames(allTextLines);
    if (matchAntiguo['nombres']!.isNotEmpty) {
      debugPrint("✅ Estrategia 'Antiguo' exitosa.");
      bestMatch = matchAntiguo;
    }

    // ESTRATEGIA B: Patrón de Carnet Nuevo ("NOMBRES:", "APELLIDOS:")
    // Si la A falló, buscamos etiquetas explícitas.
    if (bestMatch['nombres']!.isEmpty) {
      final matchNuevo = _extractNamesFromLines(allTextLines);
      if (matchNuevo['nombres']!.isNotEmpty) {
         debugPrint("✅ Estrategia 'Nuevo' (Etiquetas) exitosa.");
         bestMatch = matchNuevo;
      }
    }

    // ESTRATEGIA C: Fallback ELIMINADO intencionalmente para evitar basura.
    // Si no encontramos etiquetas claras, devolvemos vacío y forzamos manual.
    
    return {
      'ci': ci,
      'nombres': bestMatch['nombres'] ?? "",
      'apellidos': bestMatch['apellidos'] ?? "",
      'fechaEmision': _extractFecha(frontLines, isEmision: true),
      'fechaExpiracion': _extractFecha(frontLines, isEmision: false),
      'model': model,
    };
  }
  
  static bool _containsForbiddenWords(String text) {
    if (text.isEmpty) return false;
    // Normalizar: Quitar acentos y mayúsculas
    final normalized = _removeAccents(text).toUpperCase();
    return _forbiddenWords.any((word) => normalized.contains(word));
  }

  /// Valida si un string parece un nombre real usando Heurística Lingüística
  /// (Evita tener una lista infinita de basura como "DDLURINDI", "ADOPL")
  static bool _isValidName(String text) {
    if (text.length < 3) return false;
    
    // 1. Limpieza básica (Solo letras)
    if (!RegExp(r'^[a-zA-ZÁÉÍÓÚÑÜáéíóúñü\s]+$').hasMatch(text)) return false;
    
    // 2. Filtro de palabras prohibidas estrictas
    if (_containsForbiddenWords(text)) return false;

    // 3. ANÁLISIS LINGÜÍSTICO (Anti-Basura)
    final words = text.split(' ');
    for (final word in words) {
       if (word.length < 2) continue; // Ignorar letras sueltas por ahora
       // Si alguna palabra individual es "impronunciable" o basura, descartamos todo el nombre
       if (!_isPronounceable(word)) {
         debugPrint("🗑 Descartando nombre '$text' por palabra sospechosa: '$word'");
         return false;
       }
    }

    return true;
  }

  /// Verifica si una palabra tiene estructura fonética humana (Español)
  static bool _isPronounceable(String word) {
    final w = _removeAccents(word).toUpperCase();
    
    // REGLA 1: Debe tener al menos una vocal
    if (!RegExp(r'[AEIOUY]').hasMatch(w)) return false;

    // REGLA 2: No puede tener 3 consonantes seguidas (salvo excepciones raras, pero filtra "ADOPL" si fuera ADOPLTR)
    // "DDLURINDI" -> DDL (3 cons) -> REJECT
    // "PLURINACIONAL" -> PLU (2 cons) -> OK
    if (RegExp(r'[BCDFGHJKLMNPQRSTVWXZ]{3,}').hasMatch(w)) return false;

    // REGLA 3: No puede tener 3 vocales seguidas a menos que sea un triptongo muy común (Miau),
    // pero en nombres es raro. "UINACGIONAL" -> UINA (ok), pero ayuda.
    if (RegExp(r'[AEIOU]{4,}').hasMatch(w)) return false;

    // REGLA 4: Caracteres repetidos al inicio (anti "DDLURINDI")
    // En español ninguna palabra empieza con doble consonante idéntica (salvo Ll, rr pero rr no inicia)
    if (w.length > 2 && w[0] == w[1] && !"LRC".contains(w[0])) { // Excepción para L (Llama), R (erroneo inicio), C (Accion - no inicio)
       return false; 
    }
    
    // REGLA 5: Longitud mínima de basura
    // Si es una palabra larga (>8) y no tiene vocales balanceadas (ratio < 20%), es basura.
    int vowels = w.split('').where((c) => "AEIOU".contains(c)).length;
    if (w.length > 6 && (vowels.toDouble() / w.length) < 0.2) return false;

    return true;
  } // _extractCI sigue abajo...


  static String _extractCI(List<String> lines) {
    // 1. Buscar etiqueta pattern "CI: 12345"
    for (final line in lines) {
      if (_isFuzzyLabel(line, ['C.I.', 'NUMERO', 'NO.', 'CEDULA'])) {
         final match = RegExp(r'\d{6,10}').firstMatch(line);
         if (match != null) return match.group(0)!;
      }
    }
    // 2. Buscar números crudos
    for (final line in lines) {
      final matches = RegExp(r'\b(\d{6,10})\b').allMatches(line); 
      for (final m in matches) {
        final val = m.group(0)!;
        if (!val.startsWith('0') && !_isLikelyDatePart(val)) return val;
      }
    }
    return "";
  }
  
  /// Detecta si es Anverso (Frente) o Reverso (Atras)
  static String detectSide(RecognizedText text) {
    final lines = _getSortedLines(text);
    final content = _removeAccents(lines.join(" ").toUpperCase());

    int frontScore = 0;
    int backScore = 0;

    if (_isFuzzyLabel(content, ['PLURINACIONAL', 'REPUBLICA', 'TITULAR', 'SERIE', 'SECCION'])) frontScore += 3;
    if (_isFuzzyLabel(content, ['CEDULA', 'IDENTIDAD'])) frontScore += 2;
    if (_isFuzzyLabel(content, ['NOMBRES', 'APELLIDOS', 'PERTENECE'])) frontScore += 2;

    if (_isFuzzyLabel(content, ['HUELLA', 'DACTILAR', 'FIRMA', 'INTERESADO'])) backScore += 3;
    if (_isFuzzyLabel(content, ['DOMICILIO', 'ESTADO', 'CIVIL', 'OCUPACION', 'PROFESION'])) backScore += 2;
    if (_isFuzzyLabel(content, ['LIBRO', 'PARTIDA', 'FOLIO', 'ORC', 'O.R.C.'])) backScore += 3;
    
    if (frontScore > backScore) return 'anverso';
    if (backScore > frontScore) return 'reverso';
    return 'desconocido';
  }

  static Map<String, String> _extractNamesFromLines(List<String> lines) {
    String nombres = "";
    String apellidos = "";
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (_isFuzzyLabel(line, ['NOMBRES', 'NOMBRE'])) {
        final val = _getLineValueSimple(lines, i, ['NOMBRES', 'NOMBRE']);
        // VALIDACIÓN ESTRICTA: Si parece basura, lo ignoramos
        if (_isValidName(val)) {
           nombres = val;
        }
      }
      if (_isFuzzyLabel(line, ['APELLIDOS', 'APELLIDO', 'PATERNO', 'MATERNO'])) {
        String val = _getLineValueSimple(lines, i, ['APELLIDOS', 'APELLIDO', 'PATERNO', 'MATERNO']);
        if (val.isNotEmpty && _isValidName(val)) {
           if (apellidos.isEmpty) apellidos = val;
           else apellidos += " $val";
        }
      }
    }
    return {'nombres': nombres, 'apellidos': apellidos};
  }

  static Map<String, String> _extractOldModelNames(List<String> lines) {
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      
      // Lógica SIMPLE de Antiguo:
      // Buscar la línea que dice "PERTENECE A"
      if (_isFuzzyLabel(line, ['PERTENECE', 'IMPRESION'])) {
        
        // 1. Intentar sacar nombre de la MISMA línea
        // "IMPRESION PERTENECE A: JUAN PEREZ" -> "JUAN PEREZ"
        // Quitamos palabras clave y caracteres basura
        String candidate = _removeKeywords(line, ['IMPRESION', 'PERTENECE', 'A', 'DE', 'BOLIVIA', ':']).trim();

        // 2. Si quedó vacía (solo decía "PERTENECE A:"), tomar la SIGUIENTE línea
        if (candidate.length < 3 && i + 1 < lines.length) {
          candidate = lines[i+1].trim();
        }

        // LIMPIEZA FINAL Y VALIDACIÓN ESTRICTA
        if (_isValidName(candidate)) {
           return splitFullName(candidate);
        }
      }
    }
    return {'nombres': '', 'apellidos': ''};
  }

  static String _extractFecha(List<String> lines, {required bool isEmision}) {
    final patterns = isEmision 
      ? ['EMISION', 'FECHA'] 
      : ['EXPIRACION', 'VENCIMIENTO', 'VENCE', 'VALIDEZ'];
      
    for (int i = 0; i < lines.length; i++) {
      if (_isFuzzyLabel(lines[i], patterns)) {
          final match = RegExp(r'\d{1,2}[-./]\d{1,2}[-./]\d{2,4}').firstMatch(lines[i]);
          if (match != null) return match.group(0)!;
          if (i + 1 < lines.length) {
             final nextMatch = RegExp(r'\d{1,2}[-./]\d{1,2}[-./]\d{2,4}').firstMatch(lines[i+1]);
             if (nextMatch != null) return nextMatch.group(0)!;
          }
      }
    }
    return "";
  }

  // --- UTILS SIMPLIFICADOS ---

  /// Recupera el valor eliminando la etiqueta. Si queda vacío, mira abajo.
  static String _getLineValueSimple(List<String> lines, int index, List<String> labels) {
    String current = lines[index];
    // Quitar etiqueta de la línea
    current = _removeKeywords(current, [...labels, ':', '.']).trim();
    
    if (current.length > 2) return current;
    
    // Si quedó vacío, devolver línea siguiente (si no es otra etiqueta)
    if (index + 1 < lines.length) {
      final next = lines[index+1];
      if (!_isAnyLabel(next)) return next;
    }
    return "";
  }

  static String _removeKeywords(String text, List<String> keywords) {
    String process = text;
    for (final k in keywords) {
      // Reemplazo case-insensitive simple
      process = process.replaceAll(RegExp(k, caseSensitive: false), "");
    }
    // Limpiar caracteres especiales que pudieron quedar "::"
    return process.replaceAll(RegExp(r'[:.\-]'), "").trim();
  }

  static bool _isFuzzyLabel(String text, List<String> labels) {
    final words = _removeAccents(text).toUpperCase().split(RegExp(r'\s+'));
    for (final word in words) {
      if (word.length < 4) continue; 
      for (final label in labels) {
        int threshold = label.length > 6 ? 2 : 1;
        if (_levenshtein(word, label) <= threshold) return true;
      }
    }
    return false;
  }
  
  static bool _isAnyLabel(String text) {
    return _isFuzzyLabel(text, ['NOMBRE', 'APELLIDO', 'FECHA', 'CEDULA', 'EXPIRACION', 'PERTENECE']);
  }

  static Map<String, String> splitFullName(String fullName) {
    // Pipeline de limpieza final al nombre completo
    String clean = _cleanNoise(fullName);
    
    // Si después de limpiar queda basura corta (ej: "e"), devolver vacío
    if (clean.length < 3) return {'nombres': '', 'apellidos': ''};

    final words = clean.split(' ').where((w) => w.length > 1).toList(); // Filtrar palabras de 1 letra
    
    if (words.length >= 4) {
      return {'nombres': words.sublist(0, words.length - 2).join(' '), 'apellidos': words.sublist(words.length - 2).join(' ')};
    } else if (words.length >= 2) {
      return {'nombres': words[0], 'apellidos': words.sublist(1).join(' ')};
    }
    // Si solo hay 1 palabra, asumimos es nombre
    return {'nombres': clean, 'apellidos': ''};
  }

  static bool _isLikelyDatePart(String num) {
    if (num.length != 4) return false;
    final val = int.tryParse(num);
    return val != null && val > 1900 && val < 2100;
  }

  static String _cleanNoise(String text) {
    // Conservar solo letras y espacios
    return text.replaceAll(RegExp(r'[^a-zA-ZÁÉÍÓÚÑÜáéíóúñü\s]'), '').trim();
  }
  
  static String _removeAccents(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšYYÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYYyyZz'; 
    for (int i = 0; i < withDia.length; i++) {      
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  /// Ordena y FILTRA POR ZONA (ROI) los bloques de texto
  /// Elimina encabezados (top 20%) y pies de página irrelevantes para reducir basura.
  static List<String> _getSortedLines(RecognizedText recognizedText) {
    List<TextBlock> blocks = List.from(recognizedText.blocks);
    
    if (blocks.isEmpty) return [];

    // 1. Determinar los límites del documento (Bounding Box total)
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    
    for (var b in blocks) {
      if (b.boundingBox.top < minY) minY = b.boundingBox.top;
      if (b.boundingBox.bottom > maxY) maxY = b.boundingBox.bottom;
    }
    
    final height = maxY - minY;
    // Definimos la "Zona de Títulos" como el 15-20% superior del bloque de texto detectado
    final headerThreshold = minY + (height * 0.18); 

    // 2. Filtrar Bloques
    blocks = blocks.where((b) {
       // Eliminar bloques que están muy arriba (Encabezados basura como "ESTADO PLURI...", "REPUBLICA")
       // Excepción: Si el bloque dice "CEDULA" o "C.I.", lo dejamos pasar porque es vital
       if (b.boundingBox.bottom < headerThreshold) {
          final txt = b.text.toUpperCase();
          if (!txt.contains("CEDULA") && !txt.contains("C.I.") && !txt.contains("NO.")) {
             return false; // Es basura del encabezado
          }
       }
       return true;
    }).toList();

    // 3. Ordenar lo que queda
    blocks.sort((a, b) {
      int yDiff = (a.boundingBox.top - b.boundingBox.top).abs().toInt();
      if (yDiff < 10) return a.boundingBox.left.compareTo(b.boundingBox.left);
      return a.boundingBox.top.compareTo(b.boundingBox.top);
    });

    return blocks.expand((b) => b.text.split('\n')).map((s) => s.trim()).toList();
  }

  /// Calcula el Rectángulo de Interés (ROI) ignorando basura del encabezado.
  /// Útil para recortar visualmente la imagen en la UI.
  static Rect getRelevantROI(RecognizedText recognizedText) {
    List<TextBlock> blocks = List.from(recognizedText.blocks);
    if (blocks.isEmpty) return Rect.zero;

    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    for (var b in blocks) {
      if (b.boundingBox.top < minY) minY = b.boundingBox.top;
      if (b.boundingBox.bottom > maxY) maxY = b.boundingBox.bottom;
    }
    
    final height = maxY - minY;
    final headerThreshold = minY + (height * 0.18); 

    double rMinX = double.infinity, rMinY = double.infinity;
    double rMaxX = double.negativeInfinity, rMaxY = double.negativeInfinity;
    
    int keptBlocks = 0;

    for (var b in blocks) {
       // Misma lógica de filtro
       if (b.boundingBox.bottom < headerThreshold) {
          final txt = b.text.toUpperCase();
          if (!txt.contains("CEDULA") && !txt.contains("C.I.") && !txt.contains("NO.")) {
             continue; 
          }
       }
       
       if (b.boundingBox.left < rMinX) rMinX = b.boundingBox.left;
       if (b.boundingBox.top < rMinY) rMinY = b.boundingBox.top;
       if (b.boundingBox.right > rMaxX) rMaxX = b.boundingBox.right;
       if (b.boundingBox.bottom > rMaxY) rMaxY = b.boundingBox.bottom;
       keptBlocks++;
    }

    if (keptBlocks == 0) return Rect.zero;

    // Agregar un pequeño padding (margen)
    return Rect.fromLTRB(
      rMinX - 10, 
      rMinY - 10, 
      rMaxX + 10, 
      rMaxY + 10
    );
  }

  static String _detectModel(List<String> frontLines, List<String> backLines) {
    // (Este método se mantiene por compatibilidad, aunque ya NO se usa para decidir la extracción)
    // Se usa solo para reporte
    final text = [...frontLines, ...backLines].join(" ");
    if (_isFuzzyLabel(text, ['PLURINATIONAL', 'PLURINACIONAL', 'TITULAR'])) return "nuevo";
    if (_isFuzzyLabel(text, ['REPUBLICA', 'PERTENECE'])) return "antiguo";
    return "desconocido";
  }

  static int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) v0[i] = i;

    for (int i = 0; i < s.length; i++) {
        v1[0] = i + 1;
        for (int j = 0; j < t.length; j++) {
            int cost = (s[i] == t[j]) ? 0 : 1;
            v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((curr, next) => curr < next ? curr : next);
        }
        for (int j = 0; j < v0.length; j++) v0[j] = v1[j];
    }
    return v1[t.length];
  }
}
