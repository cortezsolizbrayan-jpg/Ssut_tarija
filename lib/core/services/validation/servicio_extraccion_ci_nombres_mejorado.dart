import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:refactor_template/core/services/otros/diccionario_nombres_bolivianos.dart';

/// Servicio ESPECIALIZADO en extraer CI y NOMBRES con máxima precisión
class ServicioExtraccionCiNombresMejorado {
  static String extraerCI(RecognizedText frontOcr, RecognizedText? backOcr) {
    debugPrint('🔍 Iniciando extracción de CI...');
    String ci = _buscarCIConEtiqueta(frontOcr);
    if (ci.isNotEmpty) {
      debugPrint('✅ CI con etiqueta: $ci');
      return ci;
    }
    if (backOcr != null) {
      ci = _buscarCIConEtiqueta(backOcr);
      if (ci.isNotEmpty) {
        debugPrint('✅ CI reverso: $ci');
        return ci;
      }
    }
    ci = _buscarCISecuenciaNumerica(frontOcr);
    if (ci.isNotEmpty) {
      debugPrint('✅ CI secuencia: $ci');
      return ci;
    }
    if (backOcr != null) {
      ci = _buscarCISecuenciaNumerica(backOcr);
      if (ci.isNotEmpty) {
        debugPrint('✅ CI secuencia reverso: $ci');
        return ci;
      }
    }
    debugPrint('⚠️ No se pudo extraer CI');
    return '';
  }

  static String _buscarCIConEtiqueta(RecognizedText ocr) {
    final etiquetas = [
      'CEDULA DE IDENTIDAD',
      'CÉDULA DE IDENTIDAD',
      'CEDULA',
      'CÉDULA',
      'C.I.',
      'CI',
      'NUMERO',
      'NÚMERO',
      'No.',
      'Nro.',
      'N°',
    ];
    for (final block in ocr.blocks) {
      final texto = block.text.toUpperCase();
      bool tieneEtiqueta = etiquetas.any(
        (e) => texto.contains(e.toUpperCase()),
      );
      if (!tieneEtiqueta) continue;
      final ciEnBloque = _extraerNumeroCI(block.text);
      if (ciEnBloque.isNotEmpty) return ciEnBloque;
      for (final otroBlock in ocr.blocks) {
        if (otroBlock == block) continue;
        final diffY = (otroBlock.boundingBox.top - block.boundingBox.top).abs();
        if (diffY < 20) {
          final ciCercano = _extraerNumeroCI(otroBlock.text);
          if (ciCercano.isNotEmpty) return ciCercano;
        }
      }
      for (final line in block.lines) {
        final ciEnLinea = _extraerNumeroCI(line.text);
        if (ciEnLinea.isNotEmpty) return ciEnLinea;
      }
    }
    return '';
  }

  static String _buscarCISecuenciaNumerica(RecognizedText ocr) {
    final candidatos = <String>[];
    for (final block in ocr.blocks) {
      for (final line in block.lines) {
        final ci = _extraerNumeroCI(line.text);
        if (ci.isNotEmpty) candidatos.add(ci);
      }
    }
    candidatos.sort((a, b) => b.length.compareTo(a.length));
    for (final candidato in candidatos) {
      if (_esNumeroValido(candidato)) return candidato;
    }
    return '';
  }

  static String _extraerNumeroCI(String texto) {
    var textoCorregido = _corregirCaracteresNumericos(texto);
    final patrones = [RegExp(r'\b(\d{7,10})\b'), RegExp(r'(\d{5,11})')];
    for (final patron in patrones) {
      final match = patron.firstMatch(textoCorregido);
      if (match != null) {
        final numero = match.group(1)!;
        if (_esNumeroValido(numero)) return numero;
      }
    }
    return '';
  }

  static bool _esNumeroValido(String numero) {
    if (numero.length < 7 || numero.length > 11) return false;
    if (numero == '0' * numero.length) return false;
    final num = int.tryParse(numero);
    if (num == null) return false;
    if (num < 1000000) return false;
    if (num >= 1900 && num <= 2100) return false;
    if (numero.length == 8) {
      final dd = int.tryParse(numero.substring(0, 2));
      final mm = int.tryParse(numero.substring(2, 4));
      if (dd != null &&
          mm != null &&
          dd >= 1 &&
          dd <= 31 &&
          mm >= 1 &&
          mm <= 12) {
        return false;
      }
    }
    return true;
  }

  static String _corregirCaracteresNumericos(String texto) {
    return texto
        .replaceAll('O', '0')
        .replaceAll('I', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll(' ', '');
  }

  static String extraerNombres(
    RecognizedText frontOcr,
    RecognizedText? backOcr,
  ) {
    debugPrint('🔍 Extrayendo NOMBRES...');
    final nombres = _seleccionarMejorNombreOApellido(
      frontOcr,
      backOcr,
      esNombres: true,
    );
    if (nombres.isNotEmpty) {
      debugPrint(' Nombres seleccionados: $nombres');
      return nombres;
    }
    debugPrint(' No se pudieron extraer nombres');
    return '';
  }

  static String extraerApellidos(
    RecognizedText frontOcr,
    RecognizedText? backOcr,
  ) {
    debugPrint('🔍 Extrayendo APELLIDOS...');
    final apellidos = _seleccionarMejorNombreOApellido(
      frontOcr,
      backOcr,
      esNombres: false,
    );
    if (apellidos.isNotEmpty) {
      debugPrint('✅ Apellidos seleccionados: $apellidos');
      return apellidos;
    }
    debugPrint('⚠️ No se pudieron extraer apellidos');
    return '';
  }

  static String _seleccionarMejorNombreOApellido(
    RecognizedText frontOcr,
    RecognizedText? backOcr, {
    required bool esNombres,
  }) {
    final scoreByCandidate = <String, int>{};

    void addCandidate(String value, int sourceWeight) {
      final cleaned = _limpiarNombre(value);
      if (cleaned.isEmpty || !_esNombreValido(cleaned)) return;
      final totalScore =
          sourceWeight + _puntuarCandidatoNombre(cleaned, esNombres);
      scoreByCandidate.update(
        cleaned,
        (prev) => prev + totalScore,
        ifAbsent: () => totalScore,
      );
    }

    final etiquetas = esNombres
        ? ['NOMBRES', 'NOMBRE']
        : ['APELLIDOS', 'APELLIDO', 'PATERNO', 'MATERNO'];

    for (final c in _buscarConEtiquetaCandidatos(frontOcr, etiquetas)) {
      addCandidate(c, 45);
    }

    if (backOcr != null) {
      addCandidate(_buscarEnPatronPertenece(backOcr, esNombres: esNombres), 40);
    }

    if (backOcr != null) {
      for (final c in _buscarConEtiquetaCandidatos(backOcr, etiquetas)) {
        addCandidate(c, 24);
      }
    }

    addCandidate(_buscarEnPatronPertenece(frontOcr, esNombres: esNombres), 20);

    for (final c in _buscarBloqueNombreCandidatos(
      frontOcr,
      esNombres: esNombres,
    )) {
      addCandidate(c, 16);
    }

    if (scoreByCandidate.isEmpty) return '';

    final sorted = scoreByCandidate.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  static List<String> _buscarConEtiquetaCandidatos(
    RecognizedText ocr,
    List<String> etiquetas,
  ) {
    final candidates = <String>[];
    for (final block in ocr.blocks) {
      for (int i = 0; i < block.lines.length; i++) {
        final linea = block.lines[i];
        final texto = linea.text.toUpperCase();
        bool tieneEtiqueta = etiquetas.any((e) => texto.contains(e));
        if (!tieneEtiqueta) continue;

        final candidato = _limpiarNombre(linea.text);
        if (_esNombreValido(candidato)) candidates.add(candidato);

        for (int j = i + 1; j < i + 3 && j < block.lines.length; j++) {
          final sig = _limpiarNombre(block.lines[j].text);
          if (_esNombreValido(sig)) candidates.add(sig);
        }

        for (int j = i + 1; j < i + 4 && j < block.lines.length; j++) {
          final candidato2 = _limpiarNombre(block.lines[j].text);
          if (_esNombreValido(candidato2)) candidates.add(candidato2);
        }
      }
    }
    return candidates;
  }

  static String _buscarEnPatronPertenece(
    RecognizedText ocr, {
    required bool esNombres,
  }) {
    final textoCompleto = ocr.text;
    final upper = textoCompleto.toUpperCase();
    final perteneceIdx = upper.indexOf('PERTENECE');
    if (perteneceIdx == -1) return '';

    String segmento = textoCompleto.substring(perteneceIdx);
    segmento = segmento.replaceFirst(
      RegExp(r'PERTENECE\s*A?\s*:?\s*', caseSensitive: false),
      '',
    );

    final lineas = segmento.split(RegExp(r'\n|\r\n|\r'));
    String lineaNombre = '';
    for (final linea in lineas) {
      final limpia = linea.trim();
      if (limpia.isEmpty) continue;
      final limpiaUpper = limpia.toUpperCase();

      if (limpiaUpper == 'SECCION' || limpiaUpper == 'SECCIÓN') {
        continue;
      }

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

    if (lineaNombre.isEmpty) return '';

    final palabras = _extraerPalabrasLimpias(lineaNombre);
    if (palabras.isEmpty) return '';

    if (palabras.length >= 3) {
      return esNombres
          ? palabras.sublist(0, palabras.length - 2).join(' ')
          : palabras.sublist(palabras.length - 2).join(' ');
    } else if (palabras.length == 2) {
      return esNombres ? palabras[0] : palabras[1];
    } else if (palabras.length == 1) {
      return esNombres ? palabras[0] : '';
    }
    return '';
  }

  static List<String> _buscarBloqueNombreCandidatos(
    RecognizedText ocr, {
    required bool esNombres,
  }) {
    final candidates = <String>[];
    for (final block in ocr.blocks) {
      for (final line in block.lines) {
        final texto = line.text.trim();
        if (!_esNombreValido(texto)) continue;

        final limpio = _limpiarNombre(texto);
        if (limpio.isEmpty) continue;

        final palabras = limpio
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .toList();

        if (esNombres) {
          if (palabras.length >= 2) {
            candidates.add(palabras.sublist(0, palabras.length - 2).join(' '));
          } else if (palabras.length == 1) {
            candidates.add(palabras[0]);
          }
        } else {
          if (palabras.length >= 2) {
            candidates.add(palabras.sublist(palabras.length - 2).join(' '));
          }
        }
      }
    }
    return candidates;
  }

  static List<String> _extraerPalabrasLimpias(String texto) {
    const palabrasRuido = {
      'SHIFT',
      'DELETE',
      'DELETI',
      'CTRL',
      'ALT',
      'ESC',
      'TAB',
      'CERTIFICA',
      'FIRMA',
      'FOTOGRAFIA',
      'IMPRESION',
      'IMPRESIÓN',
      'PERTENECE',
      'DACTILAR',
      'HUELLA',
      'DATO',
      'REGISTRADOS',
      'DOCUMENTOS',
      'SERIE',
      'NUMERO',
      'NÚMERO',
      'CEDULA',
      'CÉDULA',
      'IDENTIDAD',
      'BOLIVIANA',
      'PLURINACIONAL',
      'ESTADO',
      'SERVICIO',
      'GENERAL',
      'IDENTIFICACION',
      'IDENTIFICACIÓN',
      'PERSONAL',
      'DOMICILIO',
      'PROFESION',
      'PROFESIÓN',
      'OCUPACION',
      'OCUPACIÓN',
      'ESTUDIANTE',
      'SOLTERO',
      'SOLTERA',
      'CASADO',
      'CASADA',
      'VIUDO',
      'VIUDA',
      'NACIDO',
      'NACIDA',
      'NACIMIENTO',
      'REPUBLICA',
      'REPÚBLICA',
      'BOLIVIA',
      'SEGIP',
      'CARNET',
      'ILIMITADO',
      'INDEFINIDO',
      'PERMANENTE',
      'DE',
      'EL',
      'LA',
      'EN',
      'Y',
      'E',
      'QUE',
      'CON',
      'POR',
      'A',
    };

    final palabrasBrutas = texto.split(RegExp(r'[\s\n\r,.:;]+'));
    final palabrasLimpias = <String>[];

    for (final palabra in palabrasBrutas) {
      final limpia = palabra.replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F]'), '');
      if (limpia.length < 2) continue;
      final upper = limpia.toUpperCase();
      if (palabrasRuido.contains(upper)) continue;
      if (limpia != upper) continue;
      palabrasLimpias.add(upper);
    }

    return palabrasLimpias;
  }

  static bool _esNombreValido(String texto) {
    final limpio = texto.trim();
    if (limpio.length < 2 || limpio.length > 80) return false;
    final numeros = limpio.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length > 2) return false;
    final letras = limpio.replaceAll(RegExp(r'[^A-Za-z\u00C0-\u024F]'), '');
    if (letras.length < limpio.length * 0.85) return false;
    final upper = limpio.toUpperCase();

    const institucionalPalabras = {
      'ESTADO',
      'PLURINACIONAL',
      'BOLIVIA',
      'BOLIVIANA',
      'REPUBLICA',
      'REPÚBLICA',
      'CEDULA',
      'CÉDULA',
      'IDENTIDAD',
      'SERVICIO',
      'GENERAL',
      'IDENTIFICACION',
      'IDENTIFICACIÓN',
      'PERSONAL',
      'SEGIP',
      'CARNET',
      'NOMBRES',
      'NOMBRE',
      'APELLIDOS',
      'APELLIDO',
      'FECHA',
      'EMISION',
      'EMISIÓN',
      'EXPIRACION',
      'EXPIRACIÓN',
      'FIRMA',
      'HUELLA',
      'TITULAR',
      'INTERESADO',
      'SERIE',
      'BIO',
      'REGISTRADOS',
      'DOCUMENTOS',
      'DACTILAR',
      'IMPRESION',
      'FOTOGRAFIA',
      'NACIDO',
      'NACIDA',
      'NACIMIENTO',
      'PROFESION',
      'PROFESIÓN',
      'OCUPACION',
      'OCUPACIÓN',
      'ESTUDIANTE',
      'SOLTERO',
      'SOLTERA',
      'CASADO',
      'CASADA',
      'VIUDO',
      'VIUDA',
      // 'REPUBLICA',  // Duplicado, ya está arriba
      // 'REPÚBLICA', // Duplicado, ya está arriba
      // 'BOLIVIA',   // Duplicado, ya está arriba
      'DE',
      'LA',
      'EL',
      'Y',
      'E',
      'QUE',
      'CON',
      'POR',
      'A',
    };

    if (institucionalPalabras.contains(upper)) return false;

    final dictScore = _calcularScoreDiccionario(limpio);
    if (dictScore >= 8) return true;
    if (dictScore >= 5 && limpio.length >= 4) return true;

    return letras.length >= 3;
  }

  static int _calcularScoreDiccionario(String texto) {
    final tokens = texto
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    int score = 0;
    for (final token in tokens) {
      if (DiccionarioNombresBolivianos.esNombreConocido(token)) score += 3;
      if (DiccionarioNombresBolivianos.esApellidoConocido(token)) score += 3;
    }
    return score;
  }

  static int _puntuarCandidatoNombre(String value, bool esNombres) {
    final tokens = value
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return -100;

    int score = 0;
    if (tokens.isNotEmpty && tokens.length <= 4) score += 8;
    if (tokens.length > 4) score -= 6;

    int nombreMatches = 0;
    int apellidoMatches = 0;
    for (final t in tokens) {
      if (DiccionarioNombresBolivianos.esNombreConocido(t)) nombreMatches++;
      if (DiccionarioNombresBolivianos.esApellidoConocido(t)) apellidoMatches++;
      if (t.length == 1) score -= 6;
    }

    if (esNombres) {
      score += nombreMatches * 5;
      score += apellidoMatches;
      if (nombreMatches == 0 && tokens.length > 1) score -= 4;
    } else {
      score += apellidoMatches * 5;
      score += nombreMatches;
      if (apellidoMatches == 0 && tokens.length >= 2) score -= 5;
      if (apellidoMatches == 0 && tokens.length == 1) score -= 8;
    }

    if (tokens.length == 2 &&
        esNombres &&
        nombreMatches == 1 &&
        apellidoMatches == 1) {
      score -= 10;
    }

    return score;
  }

  static String _seleccionarDivisionPalabras(
    List<String> palabras,
    bool esNombres,
  ) {
    if (palabras.length >= 3) {
      return esNombres
          ? palabras.sublist(0, palabras.length - 2).join(' ')
          : palabras.sublist(palabras.length - 2).join(' ');
    } else if (palabras.length == 2) {
      return esNombres ? palabras[0] : palabras[1];
    } else if (palabras.length == 1) {
      return esNombres ? palabras[0] : '';
    }
    return '';
  }

  static String _limpiarNombre(String nombre) {
    String limpio = nombre.trim();
    limpio = _corregirCaracteresEnNombre(limpio);

    const etiquetas = ['NOMBRES:', 'NOMBRE:', 'APELLIDOS:', 'APELLIDO:'];
    for (final etiqueta in etiquetas) {
      if (limpio.toUpperCase().startsWith(etiqueta)) {
        limpio = limpio.substring(etiqueta.length).trim();
      }
    }
    limpio = limpio.replaceAll(RegExp(r"[^A-Za-z\u00C0-\u024F\s\-']"), '');
    limpio = limpio.replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();
    final palabras = limpio
        .split(' ')
        .map(_normalizarTokenNombreOcr)
        .where((p) => p.isNotEmpty)
        .toList();
    final corregidas = palabras
        .map(
          (p) => p.length >= 3
              ? DiccionarioNombresBolivianos.corregirPalabra(p)
              : p,
        )
        .toList();
    return corregidas.join(' ');
  }

  static String _normalizarTokenNombreOcr(String token) {
    if (token.isEmpty) return token;
    final letters = token.replaceAll(RegExp(r"[^A-Z\u00C0-\u024F]"), '');
    if (letters.length < 2) return token;
    return token
        .replaceAll('0', 'O')
        .replaceAll('1', 'I')
        .replaceAll('5', 'S')
        .replaceAll('8', 'B')
        .replaceAll('@', 'A')
        .replaceAll('|', 'I');
  }

  static String _corregirCaracteresEnNombre(String texto) {
    return texto
        .replaceAllMapped(
          RegExp(r'([A-Z])0([A-Z])'),
          (match) => '${match.group(1)!}O${match.group(2)!}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z])1([A-Z])'),
          (match) => '${match.group(1)!}I${match.group(2)!}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z])5([A-Z])'),
          (match) => '${match.group(1)!}S${match.group(2)!}',
        )
        .replaceAllMapped(
          RegExp(r'([A-Z])8([A-Z])'),
          (match) => '${match.group(1)!}B${match.group(2)!}',
        )
        .replaceAll('Ç', 'C')
        .replaceAll('Ž', 'Z')
        .replaceAll('Ÿ', 'Y')
        .replaceAll('Ã', 'A')
        .replaceAll('Õ', 'O')
        .replaceAll('Ñ', 'N');
  }
}
