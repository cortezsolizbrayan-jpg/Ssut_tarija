import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:refactor_template/core/services/otros/diccionario_nombres_bolivianos.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_inteligente_identidad.dart';

import '../utilidades/utilidades_preprocesamiento_imagen.dart';
import '../utilidades/utilidades_extraccion_texto.dart';

/// Mixin con la lógica de extracción de datos del CI desde texto OCR.
/// Usar junto con [IdentityOcrPipelineMixin] en la pantalla de subida.
mixin IdentityOcrExtractionMixin {
  /// Extrae el mejor CI desde múltiples textos (frontal, reverso, actual).
  /// Usa patrones robustos para detectar el número de cédula boliviano (5-11 dígitos).
  String pickBestCIFromTexts(String? front, String? back, String current) {
    final texts = <String>[
      if (front != null && front.isNotEmpty) front,
      if (back != null && back.isNotEmpty) back,
      if (current.isNotEmpty) current,
    ];

    // Patrones de CI boliviano (orden de mayor a menor precisión)
    final patterns = [
      // "CEDULA DE IDENTIDAD: 12345678"
      RegExp(
        r'C[EÉ]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})',
        caseSensitive: false,
      ),
      // "No." o "Nro."
      RegExp(
        r'(?:NO\.?|NRO\.?)\s*:?\s*[\s\-]*(\d{5,11})',
        caseSensitive: false,
      ),
      // "N°" o "N."
      RegExp(r'N\s*[°º\.]\s*:?\s*(\d{5,11})', caseSensitive: false),
      // "C.I." o "CI"
      RegExp(r'C\.?\s*I\.?\s*:?\s*(\d{5,11})', caseSensitive: false),
      // Secuencia de 7-10 dígitos (tamaño típico de CI boliviano)
      RegExp(r'\b(\d{7,10})\b'),
      // Fallback: 6-11 dígitos
      RegExp(r'(\d{6,11})'),
    ];

    String best = current;
    int bestScore = _scoreCi(current);

    for (final text in texts) {
      for (final pattern in patterns) {
        for (final m in pattern.allMatches(text)) {
          final ci = (m.group(1) ?? '').trim();
          final score = _scoreCi(ci);
          if (score > bestScore) {
            best = ci;
            bestScore = score;
          }
        }
        // Si ya encontramos uno bueno con este patrón, no seguir con patrones menos precisos
        if (bestScore >= 70) break;
      }
      if (bestScore >= 70) break;
    }
    return best;
  }

  /// Calcula un score para un CI candidato (mayor = mejor).
  int _scoreCi(String ci) {
    if (ci.isEmpty) return 0;
    final len = ci.length;
    // Rechazar si no son solo dígitos
    if (!RegExp(r'^\d+$').hasMatch(ci)) return 0;
    // Rechazar si es todo ceros
    if (ci == '0' * len) return 0;
    // Rechazar si es muy corto (< 5) o muy largo (> 11)
    if (len < 5 || len > 11) return 0;
    // Rechazar números muy pequeños (ej. años, días: 2024, 31, etc.)
    final num = int.tryParse(ci);
    if (num == null || num < 10000) return 0;

    // Score basado en longitud (7-9 dígitos es lo más común en Bolivia)
    if (len >= 7 && len <= 9) return 100;
    if (len == 10) return 90;
    if (len == 6) return 60;
    if (len == 11) return 50;
    if (len == 5) return 30;
    return 10;
  }

  String detectCIModel(RecognizedText recognizedText) {
    final fullText = recognizedText.text.toUpperCase();
    debugPrint('=== DETECCION DE MODELO ===');

    final hasCedulaIdentidad = RegExp(
      r'C[\u00C9E]DULA\s+DE\s+IDENTIDAD',
      caseSensitive: false,
    ).hasMatch(fullText);
    if (hasCedulaIdentidad) return 'nuevo';

    final nPatterns = [
      RegExp(r'N\s*[\u00B0\u00BA]', caseSensitive: false),
      RegExp(r'N\s*\.', caseSensitive: false),
      RegExp(r'NUMERO\s*[\u00B0\u00BA]?', caseSensitive: false),
      RegExp(r'N\s*:\s*\d', caseSensitive: false),
      RegExp(r'N\s+[\u00B0\u00BA]?\s*\d', caseSensitive: false),
    ];

    var hasN = nPatterns.any((p) => p.hasMatch(fullText));
    if (!hasN) {
      for (final block in recognizedText.blocks) {
        final blockText = block.text.toUpperCase();
        if (nPatterns.any((p) => p.hasMatch(blockText))) {
          hasN = true;
          break;
        }
      }
    }

    if (hasN) {
      final hasBarcodePattern =
          RegExp(r'\|{2,}').hasMatch(fullText) ||
          fullText.contains('QR') ||
          fullText.contains('CODIGO') ||
          fullText.contains('BARRA') ||
          fullText.contains('BARRAS');
      if (hasBarcodePattern) return 'antiguo';
      return 'antiguo';
    }

    final hasNames = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);
    if (hasNames) return 'nuevo';

    return 'desconocido';
  }

  bool isValidCI(String ci) {
    if (ci.length < 5 || ci.length > 11) return false;
    if (!RegExp(r'^\d+$').hasMatch(ci)) return false;
    if (int.tryParse(ci) == 0) return false;
    return true;
  }

  bool isLikelyDate(String number) {
    if (number.length == 8) {
      final day = int.tryParse(number.substring(0, 2));
      final month = int.tryParse(number.substring(2, 4));
      if (day != null && month != null) {
        if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
          return true;
        }
      }
    }
    return false;
  }

  String extractCIFromText(RecognizedText recognizedText) {
    final candidateCIs = <String>[];
    final fullText = recognizedText.text.toUpperCase();
    final cedulaPatterns = [
      RegExp(
        r'C[\u00C9E]DULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})',
        caseSensitive: false,
      ),
      RegExp(
        r'CEDULA\s+DE\s+IDENTIDAD\s*:?\s*(\d{5,11})',
        caseSensitive: false,
      ),
    ];
    final numeroPatterns = [
      RegExp(r'N\s*[\u00B0\u00BA\.]?\s*:?\s*(\d{5,11})', caseSensitive: false),
      RegExp(
        r'NUMERO\s*[\u00B0\u00BA]?\s*:?\s*(\d{5,11})',
        caseSensitive: false,
      ),
    ];
    final ciLabelPattern = RegExp(
      r'(?:CI|C\.I\.|CEDULA|C[\u00C9E]DULA)\s*:?\s*(\d{5,11})',
      caseSensitive: false,
    );

    String? firstValidFrom(String text) {
      for (final pattern in cedulaPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final ci = match.group(1)!.trim();
          if (isValidCI(ci)) return ci;
          candidateCIs.add(ci);
        }
      }
      for (final pattern in numeroPatterns) {
        final match = pattern.firstMatch(text);
        if (match != null) {
          final ci = match.group(1)!.trim();
          if (isValidCI(ci)) return ci;
          candidateCIs.add(ci);
        }
      }
      final labelMatch = ciLabelPattern.firstMatch(text);
      if (labelMatch != null) {
        final ci = labelMatch.group(1)!.trim();
        if (isValidCI(ci)) return ci;
        candidateCIs.add(ci);
      }
      return null;
    }

    for (final block in recognizedText.blocks) {
      final found = firstValidFrom(block.text.toUpperCase());
      if (found != null) return found;
    }
    final foundFull = firstValidFrom(fullText);
    if (foundFull != null) return foundFull;
    for (final match in RegExp(r'\b(\d{5,11})\b').allMatches(fullText)) {
      final ci = match.group(1)!;
      if (isValidCI(ci) && !isLikelyDate(ci)) {
        candidateCIs.add(ci);
      }
    }
    for (final ci in candidateCIs) {
      if (isValidCI(ci) && !isLikelyDate(ci)) return ci;
    }
    return '';
  }

  String extractNameFromText(
    RecognizedText recognizedText, {
    bool isFrontal = false,
    String model = 'desconocido',
  }) {
    if (isFrontal) {
      if (model != 'nuevo') {
        debugPrint('No buscar nombres en frontal (modelo antiguo)');
        return '';
      }
      debugPrint('Buscando nombres en frontal (modelo nuevo)');
    } else {
      if (model != 'antiguo') {
        debugPrint(
          'No buscar nombres en reverso (modelo nuevo - reverso tiene otros datos)',
        );
        return '';
      }
      debugPrint('Buscando nombres en reverso (modelo antiguo)');
    }

    final fullText = recognizedText.text.toUpperCase();
    final hasNameKeywords = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);

    if (hasNameKeywords) {
      final lines = recognizedText.text.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim().toUpperCase();
        if (RegExp(
          r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
          caseSensitive: false,
        ).hasMatch(line)) {
          for (int j = i + 1; j < (i + 4).clamp(0, lines.length); j++) {
            final candidateLine = lines[j].trim();
            final words = TextExtractionHelpers.extractValidWords(
              candidateLine,
            );
            if (words.length >= 2 &&
                !TextExtractionHelpers.isCommonNonNameWord(candidateLine) &&
                !TextExtractionHelpers.isLocationOrAddress(candidateLine)) {
              final namePattern = RegExp(
                r"^[A-Za-z\s\.\-']+$",
                caseSensitive: false,
              );
              if (namePattern.hasMatch(candidateLine) &&
                  candidateLine.length >= 6 &&
                  candidateLine.length <= 60) {
                debugPrint(
                  'Nombre encontrado cerca de palabra clave: $candidateLine',
                );
                return candidateLine;
              }
            }
          }
        }
      }
    }

    final List<String> candidateNames = [];

    if (model == 'antiguo' && !isFrontal) {
      final result = extractNameFromOldModel(recognizedText);
      if (result.isNotEmpty) return result;
    }

    for (final block in recognizedText.blocks) {
      final blockText = block.text.trim();
      final lines = blockText.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        final lineUpper = line.toUpperCase();

        bool isNearKeyword = false;
        if (lineUpper.contains('NOMBRES') ||
            lineUpper.contains('APELLIDOS') ||
            (model == 'antiguo' && lineUpper.contains('A:'))) {
          isNearKeyword = true;
        }
        if (!isNearKeyword && i > 0) {
          final prevLine = lines[i - 1].toUpperCase();
          if (prevLine.contains('NOMBRES') ||
              prevLine.contains('APELLIDOS') ||
              (model == 'antiguo' && prevLine.contains('A:'))) {
            isNearKeyword = true;
          }
        }

        final namePattern = RegExp(r"^[A-Za-z\s\.\-']+$", caseSensitive: false);
        final hasLetter = RegExp(r'[A-Za-z]').hasMatch(line);

        final hasProfession =
            lineUpper.contains('ABG') ||
            lineUpper.contains('ABOGADO') ||
            lineUpper.contains('ING') ||
            lineUpper.contains('INGENIERO') ||
            lineUpper.contains('DR') ||
            lineUpper.contains('DOCTOR') ||
            lineUpper.contains('LIC') ||
            lineUpper.contains('LICENCIADO') ||
            lineUpper.contains('SERIE') ||
            lineUpper.contains('SECCION') ||
            lineUpper.contains('FECHA') ||
            lineUpper.contains('BIO');

        if (line.length >= 6 &&
            line.length <= 60 &&
            namePattern.hasMatch(line) &&
            hasLetter &&
            !hasProfession) {
          if (!TextExtractionHelpers.isCommonNonNameWord(line) &&
              !TextExtractionHelpers.isLocationOrAddress(line)) {
            final words = TextExtractionHelpers.extractValidWords(line);
            if (words.length >= 2) {
              candidateNames.add(line.trim());
            }
          }
        }
      }
    }

    if (candidateNames.isEmpty) {
      final lines = recognizedText.text.split('\n');
      final namePattern2 = RegExp(r"^[A-Za-z\s\.\-']+$", caseSensitive: false);
      for (var line in lines) {
        line = line.trim();
        final hasLetter2 = RegExp(r'[A-Za-z]').hasMatch(line);
        final isValidLength = line.length >= 6 && line.length <= 60;
        final matchesPattern = namePattern2.hasMatch(line);
        final isNotCommonWord = !TextExtractionHelpers.isCommonNonNameWord(
          line,
        );

        if (isValidLength &&
            matchesPattern &&
            hasLetter2 &&
            isNotCommonWord &&
            !TextExtractionHelpers.isLocationOrAddress(line)) {
          final words = TextExtractionHelpers.extractValidWords(line);
          if (words.length >= 2) candidateNames.add(line);
        }
      }
    }

    if (candidateNames.isNotEmpty) {
      candidateNames.sort((a, b) {
        final wordsA = TextExtractionHelpers.extractValidWords(a);
        final wordsB = TextExtractionHelpers.extractValidWords(b);
        if (wordsB.length != wordsA.length) {
          return wordsB.length.compareTo(wordsA.length);
        }
        return b.length.compareTo(a.length);
      });
      return candidateNames.first.trim();
    }

    return '';
  }

  /// Extrae nombres y apellidos por separado buscando etiquetas "NOMBRES" y "APELLIDOS".
  /// Usa líneas en orden de lectura (blocks.lines) y texto plano.
  Map<String, String> extractNamesAndSurnames(RecognizedText recognizedText) {
    String nombres = '';
    String apellidos = '';

    // 1) Líneas en orden de lectura (más fiable que split por \n)
    final linesFromBlocks = <String>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final t = line.text.trim();
        if (t.isNotEmpty) linesFromBlocks.add(t);
      }
    }

    for (int i = 0; i < linesFromBlocks.length; i++) {
      final lineUpper = linesFromBlocks[i].toUpperCase();
      if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(lineUpper) && nombres.isEmpty) {
        for (int j = i + 1; j < linesFromBlocks.length && j < i + 4; j++) {
          final candidate = linesFromBlocks[j].trim();
          if (_isValidNameCandidate(candidate)) {
            nombres = _cleanNameField(candidate);
            debugPrint('Nombres (líneas): "$nombres"');
            break;
          }
        }
      }
      if (RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(lineUpper) &&
          apellidos.isEmpty) {
        for (int j = i + 1; j < linesFromBlocks.length && j < i + 4; j++) {
          final candidate = linesFromBlocks[j].trim();
          if (_isValidNameCandidate(candidate)) {
            apellidos = _cleanNameField(candidate);
            debugPrint('Apellidos (líneas): "$apellidos"');
            break;
          }
        }
      }
      final nomInline = RegExp(
        r'NOMBRES?\s*:+\s*(.+)',
        caseSensitive: false,
      ).firstMatch(linesFromBlocks[i]);
      if (nomInline != null && nombres.isEmpty) {
        final candidate = (nomInline.group(1) ?? '').trim();
        if (_isValidNameCandidate(candidate)) {
          nombres = _cleanNameField(candidate);
        }
      }
      final apeInline = RegExp(
        r'APELLIDOS?\s*:+\s*(.+)',
        caseSensitive: false,
      ).firstMatch(linesFromBlocks[i]);
      if (apeInline != null && apellidos.isEmpty) {
        final candidate = (apeInline.group(1) ?? '').trim();
        if (_isValidNameCandidate(candidate)) {
          apellidos = _cleanNameField(candidate);
        }
      }
    }

    // 2) Fallback: texto plano por líneas (por si el orden de blocks no coincide)
    if (nombres.isEmpty || apellidos.isEmpty) {
      final lines = recognizedText.text
          .split(RegExp(r'[\n\r]+'))
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      for (int i = 0; i < lines.length; i++) {
        final lineUpper = lines[i].toUpperCase();
        if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(lineUpper) &&
            nombres.isEmpty) {
          for (int j = i + 1; j < lines.length && j < i + 4; j++) {
            if (_isValidNameCandidate(lines[j])) {
              nombres = _cleanNameField(lines[j]);
              break;
            }
          }
        }
        if (RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(lineUpper) &&
            apellidos.isEmpty) {
          for (int j = i + 1; j < lines.length && j < i + 4; j++) {
            if (_isValidNameCandidate(lines[j])) {
              apellidos = _cleanNameField(lines[j]);
              break;
            }
          }
        }
      }
    }

    return {'nombres': nombres, 'apellidos': apellidos};
  }

  /// Verifica si un texto candidato parece ser un nombre válido (nombres o apellidos).
  bool _isValidNameCandidate(String text) {
    if (text.isEmpty || text.length < 4 || text.length > 80) return false;
    if (!RegExp(r'[A-Za-zÁ-Úá-úÑñ]').hasMatch(text)) return false;
    if (RegExp(r'^\d+$').hasMatch(text)) return false;
    if (TextExtractionHelpers.isCarnetText(text)) return false;
    if (TextExtractionHelpers.isCommonNonNameWord(text)) return false;
    final cleaned = _cleanNameField(text);
    final words = cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty || words.length > 6) return false;
    final upper = cleaned.toUpperCase();
    const blacklist = [
      'SERIE',
      'SECCION',
      'FECHA',
      'BIO',
      'PLURINAC',
      'ESTADO',
      'BOLIVIA',
      'DOMICILIO',
      'PROFESION',
      'OCUPACION',
      'CIVIL',
      'GRUPO',
      'SANGUINEO',
      'EMISION',
      'EXPIRACION',
      'VALIDEZ',
      'CEDULA',
      'IDENTIDAD',
      'NUMERO',
      'FIRMA',
      'FIRMA DEL INTERESADO',
      'FIRMA DEL TITULAR',
      'INTERESADO',
      'HUELLA',
      'TITULAR',
      'PERTENECE',
      'CERTIFICA',
      'FOTOGRAFIA',
      'IMPRESION',
      'DACTILAR',
    ];
    if (blacklist.any((word) => upper.contains(word))) return false;
    if (RegExp(r'^NOMBRES?[\s:]*$').hasMatch(upper) ||
        RegExp(r'^APELLIDOS?[\s:]*$').hasMatch(upper)) {
      return false;
    }
    final letterPart = cleaned.replaceAll(RegExp(r"[\s\-\.']"), '');
    if (letterPart.isEmpty) return false;
    final letterCount = letterPart
        .split('')
        .where((c) => RegExp(r'[A-Za-zÁ-Úá-úÑñ]').hasMatch(c))
        .length;
    if (letterCount < letterPart.length * 0.8) return false;
    return true;
  }

  /// Limpia un campo de nombre: quita números, símbolos extra, espacios dobles
  String _cleanNameField(String raw) {
    return raw
        .replaceAll(
          RegExp(r'[0-9\.\,\;\:\#\|\(\)\[\]\{\}\<\>\@\!\?\*\&\%\$\+\=\_\/\\]'),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String extractNameFromOldModel(RecognizedText recognizedText) {
    final text = recognizedText.text;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    bool looksLikeName(String line) {
      if (line.length < 6 || line.length > 80) return false;
      if (!RegExp(r'[A-Za-z]').hasMatch(line)) return false;
      if (TextExtractionHelpers.isCommonNonNameWord(line) ||
          TextExtractionHelpers.isLocationOrAddress(line)) {
        return false;
      }
      final words = TextExtractionHelpers.extractValidWords(line);
      return words.length >= 2 && words.length <= 6;
    }

    final perteneceIndex = lines.indexWhere(
      (l) => l.toUpperCase().contains('PERTENECE'),
    );
    if (perteneceIndex >= 0) {
      for (
        var i = perteneceIndex;
        i < lines.length && i < perteneceIndex + 6;
        i++
      ) {
        final cleaned = lines[i]
            .replaceFirst(RegExp(r'PERTENECE\s+A\s*:?'), '')
            .trim();
        if (looksLikeName(cleaned)) return cleaned;
      }
    }

    var best = '';
    var bestScore = 0;
    for (final line in lines) {
      if (!looksLikeName(line)) continue;
      final words = TextExtractionHelpers.extractValidWords(line);
      final score = words.length * 10 + line.length;
      if (score > bestScore) {
        bestScore = score;
        best = line;
      }
    }
    return best;
  }

  String extractFechaEmision(RecognizedText recognizedText, String model) {
    final fullText = recognizedText.text;
    final lines = fullText.split('\n');
    final datePattern = RegExp(
      r'\b(\d{2}[/\-.]\d{2}[/\-.]\d{4}|\d{4}[/\-.]\d{2}[/\-.]\d{2}|\d{8})\b',
    );
    final keywords = [
      'FECHA DE EMISION',
      'FECHA EMISION',
      'EMISION',
      'EMITIDO',
      'EXPEDICION',
    ];
    for (var i = 0; i < lines.length; i++) {
      final lineUpper = lines[i].toUpperCase();
      final hasKeyword = keywords.any(lineUpper.contains);
      if (!hasKeyword) continue;
      for (var j = i; j < lines.length && j <= i + 2; j++) {
        final match = datePattern.firstMatch(lines[j]);
        if (match != null) return match.group(1) ?? '';
      }
    }
    final fallback = datePattern.firstMatch(fullText);
    return fallback?.group(1) ?? '';
  }

  String extractFechaExpiracion(RecognizedText recognizedText, String model) {
    final fullText = recognizedText.text;
    final lines = fullText.split('\n');
    final datePattern = RegExp(
      r'\b(\d{2}[/\-.]\d{2}[/\-.]\d{4}|\d{4}[/\-.]\d{2}[/\-.]\d{2}|\d{8})\b',
    );
    final keywords = [
      'FECHA DE EXPIRACION',
      'VALIDEZ',
      'VIGENCIA',
      'EXPIRA',
      'VALIDO HASTA',
    ];
    for (var i = 0; i < lines.length; i++) {
      final lineUpper = lines[i].toUpperCase();
      final hasKeyword = keywords.any(lineUpper.contains);
      if (!hasKeyword) continue;
      for (var j = i; j < lines.length && j <= i + 2; j++) {
        final match = datePattern.firstMatch(lines[j]);
        if (match != null) return match.group(1) ?? '';
      }
    }
    final fallback = datePattern.firstMatch(fullText);
    return fallback?.group(1) ?? '';
  }

  String detectCardSide(RecognizedText recognizedText) {
    final fullText = recognizedText.text.toUpperCase();

    final hasCedulaIdentidad = RegExp(
      r'C[\u00C9E]DULA\s+DE\s+IDENTIDAD',
      caseSensitive: false,
    ).hasMatch(fullText);
    final hasN = RegExp(
      r'N\s*[\u00B0\u00BA]',
      caseSensitive: false,
    ).hasMatch(fullText);
    final hasCI = extractCIFromText(recognizedText).isNotEmpty;

    final hasBackData = RegExp(
      r'(LUGAR|DOMICILIO|OCUPACION|ESTADO CIVIL|NACIMIENTO|NACIDO EN)',
      caseSensitive: false,
    ).hasMatch(fullText);
    final hasNames = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);

    if ((hasCedulaIdentidad || hasN) && hasCI) {
      debugPrint('Detectado: ANVERSO');
      return 'front';
    }
    if (hasBackData || hasNames) {
      debugPrint('Detectado: REVERSO');
      return 'back';
    }
    debugPrint('Detectado: DESCONOCIDO');
    return 'unknown';
  }

  /// Realiza OCR con Google ML Kit en las imágenes del CI con preprocesamiento mejorado
  Future<Map<String, dynamic>> performOcrExtractionWithMlKit({
    required dynamic context,
    required dynamic frontImage,
    dynamic backImage,
    Function(double)? onProgress,
    Function(String)? onLog,
  }) async {
    try {
      onProgress?.call(0.2);
      onLog?.call('Inicializando reconocimiento de texto...');

      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );

      try {
        // --- PREPROCESAMIENTO DE IMÁGENES PARA MEJOR OCR (MULTI-INTENTO) ---
        final String frontPath = frontImage.path as String;
        final frontOriginalFile = File(frontPath);

        File? backOriginalFile;
        if (backImage != null) {
          final String backPath = backImage.path as String;
          backOriginalFile = File(backPath);
        }

        onLog?.call(
          'Preparando variantes de imagen para OCR (multi-intento)...',
        );

        // Variantes de procesamiento para la MISMA foto
        final List<Map<String, File?>> variants = [];

        // Variante 1: preprocesado estándar
        final frontStd = await ImagePreprocessingHelpers.prepareFileForOcr(
          frontOriginalFile,
        );
        File? backStd;
        if (backOriginalFile != null) {
          backStd = await ImagePreprocessingHelpers.prepareFileForOcr(
            backOriginalFile,
          );
        }
        variants.add({'front': frontStd, 'back': backStd});

        // Variante 2: preprocesado mejorado (escala de grises + más contraste)
        final frontEnhanced =
            await ImagePreprocessingHelpers.preprocessForOcrEnhanced(
              frontOriginalFile,
            );
        File? backEnhanced;
        if (backOriginalFile != null) {
          backEnhanced =
              await ImagePreprocessingHelpers.preprocessForOcrEnhanced(
                backOriginalFile,
              );
        }
        variants.add({'front': frontEnhanced, 'back': backEnhanced});

        // Variante 3: imagen original sin procesar (por si el preprocesado perjudica)
        variants.add({'front': frontOriginalFile, 'back': backOriginalFile});

        final attemptResults = <Map<String, dynamic>>[];

        for (var i = 0; i < variants.length; i++) {
          final variant = variants[i];
          final frontFile = variant['front'];
          if (frontFile == null || !frontFile.existsSync()) continue;

          final backFile = variant['back'];
          onLog?.call(
            'Iniciando intento OCR ${i + 1}/${variants.length} '
            '(${frontFile.path.split("/").last})',
          );

          final attempt = await _runSingleMlKitAttempt(
            textRecognizer: textRecognizer,
            frontFile: frontFile,
            backFile: backFile,
            onProgress: onProgress,
            onLog: onLog,
          );
          attemptResults.add(attempt);
        }

        // Combinar resultados de todos los intentos
        final combined = _combineMlKitAttempts(attemptResults);

        if (combined['success'] != true) {
          return combined;
        }

        onProgress?.call(1.0);
        onLog?.call('Extracción completada exitosamente (multi-intento)');

        return combined;
      } finally {
        textRecognizer.close();
      }
    } catch (e) {
      onLog?.call('Error en OCR: $e');
      debugPrint('Error completo en ML Kit OCR: $e');
      return {'success': false, 'error': 'Error al procesar las imágenes: $e'};
    }
  }

  /// Ejecuta un solo intento de OCR con ML Kit sobre archivos ya preprocesados.
  Future<Map<String, dynamic>> _runSingleMlKitAttempt({
    required TextRecognizer textRecognizer,
    required File frontFile,
    File? backFile,
    Function(double)? onProgress,
    Function(String)? onLog,
  }) async {
    // Procesar anverso
    onProgress?.call(0.3);
    onLog?.call('Reconociendo texto del anverso...');

    final frontInputImage = InputImage.fromFilePath(frontFile.path);
    final frontRecognizedText = await textRecognizer.processImage(
      frontInputImage,
    );

    onProgress?.call(0.5);
    onLog?.call('Extrayendo datos del anverso...');

    // Detectar modelo del CI
    final model = detectCIModel(frontRecognizedText);
    onLog?.call('Modelo detectado: $model');

    // Extraer CI del anverso
    final ci = extractCIFromText(frontRecognizedText);

    // Extraer nombre del anverso (solo en modelo nuevo)
    final nombresAnverso = extractNameFromText(
      frontRecognizedText,
      isFrontal: true,
      model: model,
    );

    // Procesar reverso si existe
    RecognizedText? backRecognizedText;
    String nombresReverso = '';

    if (backFile != null && backFile.existsSync()) {
      onProgress?.call(0.6);
      onLog?.call('Reconociendo texto del reverso...');

      final backInputImage = InputImage.fromFilePath(backFile.path);
      backRecognizedText = await textRecognizer.processImage(backInputImage);

      // Extraer nombre del reverso (solo en modelo antiguo)
      nombresReverso = extractNameFromText(
        backRecognizedText,
        isFrontal: false,
        model: model,
      );
    }

    onProgress?.call(0.7);
    onLog?.call('Analizando información extraída...');

    // Intentar extraer nombres y apellidos por separado (etiquetas NOMBRES/APELLIDOS)
    String nombresMl = '';
    String apellidosMl = '';
    final mapFront = extractNamesAndSurnames(frontRecognizedText);
    if ((mapFront['nombres'] ?? '').trim().isNotEmpty ||
        (mapFront['apellidos'] ?? '').trim().isNotEmpty) {
      nombresMl = (mapFront['nombres'] ?? '').trim();
      apellidosMl = (mapFront['apellidos'] ?? '').trim();
      onLog?.call('Nombres/apellidos por etiquetas (anverso)');
    }
    if (apellidosMl.isEmpty && backRecognizedText != null) {
      final mapBack = extractNamesAndSurnames(backRecognizedText);
      if ((mapBack['nombres'] ?? '').trim().isNotEmpty ||
          (mapBack['apellidos'] ?? '').trim().isNotEmpty) {
        if (nombresMl.isEmpty) nombresMl = (mapBack['nombres'] ?? '').trim();
        if (apellidosMl.isEmpty) {
          apellidosMl = (mapBack['apellidos'] ?? '').trim();
        }
        onLog?.call('Nombres/apellidos por etiquetas (reverso)');
      }
    }

    // Si no hubo etiquetas, usar línea completa y separar con heurística boliviana
    if (nombresMl.isEmpty && apellidosMl.isEmpty) {
      final nombreCompleto = nombresAnverso.isNotEmpty
          ? nombresAnverso
          : nombresReverso;
      final partes = nombreCompleto
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      // Bolivia: APELLIDO PATERNO + APELLIDO MATERNO + NOMBRE(S)
      if (partes.length >= 4) {
        apellidosMl = '${partes[0]} ${partes[1]}';
        nombresMl = partes.skip(2).join(' ');
      } else if (partes.length == 3) {
        apellidosMl = partes[0];
        nombresMl = '${partes[1]} ${partes[2]}';
      } else if (partes.length == 2) {
        apellidosMl = partes[0];
        nombresMl = partes[1];
      } else if (partes.length == 1) {
        apellidosMl = partes[0];
      }
      onLog?.call('Nombres/apellidos por heurística boliviana');
    }

    // Refinar con extracción nativa (ServicioOcrInteligenteIdentidad) para fechas y campos
    String ciFinal = ci;
    // Para nombres y apellidos, priorizar primero las heurísticas propias
    // y usar los valores nativos solo como respaldo si parecen claramente mejores.
    String nombresFinal = nombresMl;
    String apellidosFinal = apellidosMl;
    String fechaNac = '';
    String fechaEmi = '';
    String fechaExp = '';

    onProgress?.call(0.75);
    onLog?.call('Refinando con extracción nativa (análisis espacial)...');
    final nativeData = ServicioOcrInteligenteIdentidad.extractData(
      frontRecognizedText,
      backRecognizedText,
    );

    // --- PRIORIDAD CAMPOS CRÍTICOS: CI, NOMBRES Y APELLIDOS ---
    final nativeCi = (nativeData['ci'] ?? '').toString().trim();
    final nativeNombres = (nativeData['nombres'] ?? '').toString().trim();
    final nativeApellidos = (nativeData['apellidos'] ?? '').toString().trim();

    // Solo aceptar CI nativo si pasa las validaciones de formato
    if (nativeCi.isNotEmpty && isValidCI(nativeCi)) {
      ciFinal = nativeCi;
    }

    // 1) Si los nombres/apellidos heurísticos no son válidos, intentar con los nativos
    bool looksWeirdName(String text) {
      final trimmed = text.trim();
      if (trimmed.isEmpty) return true;
      final words = trimmed
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      // Un solo "nombre" muy corto suele ser ruido
      if (words.length == 1 && words.first.length < 4) return true;
      return false;
    }

    if ((!_isValidNameCandidate(nombresFinal) ||
            looksWeirdName(nombresFinal)) &&
        _isValidNameCandidate(nativeNombres)) {
      nombresFinal = nativeNombres;
    }
    if ((!_isValidNameCandidate(apellidosFinal) ||
            looksWeirdName(apellidosFinal)) &&
        _isValidNameCandidate(nativeApellidos)) {
      apellidosFinal = nativeApellidos;
    }

    // Ajuste final de CI usando todos los textos disponibles (anverso/reverso)
    final ciRepriorizado = pickBestCIFromTexts(
      frontRecognizedText.text,
      backRecognizedText?.text,
      ciFinal,
    );
    if (ciRepriorizado.isNotEmpty && isValidCI(ciRepriorizado)) {
      ciFinal = ciRepriorizado;
    }

    // Fechas y otros campos vienen directamente de la extracción nativa optimizada
    fechaNac = (nativeData['fechaNacimiento'] ?? '').toString().trim();
    fechaEmi = (nativeData['fechaEmision'] ?? '').toString().trim();
    fechaExp = (nativeData['fechaExpiracion'] ?? '').toString().trim();

    onLog?.call(
      'Extracción nativa aplicada y priorizada (Nac: $fechaNac, Emi: $fechaEmi)',
    );

    return {
      'ci': ciFinal,
      'nombres': nombresFinal,
      'apellidos': apellidosFinal,
      'fechaNacimiento': fechaNac,
      'fechaEmision': fechaEmi,
      'fechaExpiracion': fechaExp,
      'lugarNacimiento': (nativeData['lugarNacimiento'] ?? '')
          .toString()
          .trim(),
      'profesion': '',
      'estadoCivil': '',
      'domicilio': '',
      'grupoSanguineo': '',
    };
  }

  /// Combina los resultados de múltiples intentos de OCR escogiendo los datos más consistentes.
  Map<String, dynamic> _combineMlKitAttempts(
    List<Map<String, dynamic>> attempts,
  ) {
    if (attempts.isEmpty) {
      return {
        'success': false,
        'error':
            'No se pudo extraer información. Intente con mejor iluminación o ángulo.',
      };
    }

    // Listas de candidatos por campo
    final ciCandidates = <String>[];
    final nombresCandidates = <String>[];
    final apellidosCandidates = <String>[];
    final fechaNacCandidates = <String>[];
    final fechaEmiCandidates = <String>[];
    final fechaExpCandidates = <String>[];

    for (final a in attempts) {
      ciCandidates.add((a['ci'] ?? '').toString().trim());
      nombresCandidates.add((a['nombres'] ?? '').toString().trim());
      apellidosCandidates.add((a['apellidos'] ?? '').toString().trim());
      fechaNacCandidates.add((a['fechaNacimiento'] ?? '').toString().trim());
      fechaEmiCandidates.add((a['fechaEmision'] ?? '').toString().trim());
      fechaExpCandidates.add((a['fechaExpiracion'] ?? '').toString().trim());
    }

    final ciFinal = _pickBestCiCandidate(ciCandidates);
    final nombresFinal = _pickBestTextCandidate(nombresCandidates);
    final apellidosFinal = _pickBestTextCandidate(apellidosCandidates);

    final fechaNacFinal = TextExtractionHelpers.pickFirstNonEmpty(
      fechaNacCandidates,
    );
    final fechaEmiFinal = TextExtractionHelpers.pickFirstNonEmpty(
      fechaEmiCandidates,
    );
    final fechaExpFinal = TextExtractionHelpers.pickFirstNonEmpty(
      fechaExpCandidates,
    );

    if (ciFinal.isEmpty && nombresFinal.isEmpty && apellidosFinal.isEmpty) {
      return {
        'success': false,
        'error':
            'No se pudo extraer información. Intente con mejor iluminación o ángulo.',
      };
    }

    return {
      'success': true,
      'ci': ciFinal,
      'nombres': nombresFinal,
      'apellidos': apellidosFinal,
      'fechaNacimiento': fechaNacFinal,
      'fechaEmision': fechaEmiFinal,
      'fechaExpiracion': fechaExpFinal,
      'lugarNacimiento': '',
      'profesion': '',
      'estadoCivil': '',
      'domicilio': '',
      'grupoSanguineo': '',
    };
  }

  /// Elige el mejor CI entre varios candidatos usando el mismo scoring interno.
  String _pickBestCiCandidate(List<String> candidates) {
    String best = '';
    int bestScore = 0;
    for (final raw in candidates) {
      final ci = raw.trim();
      if (ci.isEmpty) continue;
      final score = _scoreCi(ci);
      if (score > bestScore) {
        bestScore = score;
        best = ci;
      }
    }
    return best;
  }

  /// Elige el texto más consistente entre varios candidatos (nombres/apellidos).
  /// Usa el diccionario para filtrar ruido OCR como "MABEUERESAO"
  String _pickBestTextCandidate(List<String> candidates) {
    final nonEmpty = candidates
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (nonEmpty.isEmpty) return '';

    // Filtrar candidatos que son claramente ruido OCR
    final validos = nonEmpty.where((c) {
      final words = c.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      // Al menos una palabra debe estar en el diccionario o ser similar
      return words.any((w) {
        final upper = w.toUpperCase();
        if (DiccionarioNombresBolivianos.esNombreOApellido(upper)) return true;
        // Verificar similitud (Levenshtein)
        final corregida = DiccionarioNombresBolivianos.corregirPalabra(upper);
        return corregida != upper;
      });
    }).toList();

    // Si hay candidatos válidos, usar solo esos; si no, usar todos (mejor que nada)
    final pool = validos.isNotEmpty ? validos : nonEmpty;
    if (pool.length == 1) return pool.first;

    double bestScore = -1;
    String best = pool.first;

    for (final cand in pool) {
      double score = 0;
      for (final other in pool) {
        if (identical(cand, other)) continue;
        score += TextExtractionHelpers.calculateTextSimilarity(cand, other);
      }
      score += cand.length / 100.0;
      if (score > bestScore) {
        bestScore = score;
        best = cand;
      }
    }

    return best;
  }
}

