import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_inteligente_identidad.dart';

mixin IdentityOcrMixin {
  /// Detecta el modelo del CI (nuevo o antiguo) basándose en el texto reconocido
  String detectCIModel(RecognizedText recognizedText) {
    final fullText = recognizedText.text.toUpperCase();
    debugPrint("=== DETECCIÓN DE MODELO ===");

    final hasNewModelKeywords = RegExp(
      r'C[ÉE]DULA\s+DE\s+IDENTIDAD|DATOS\s+DEL\s+TITULAR|TITULAR|ESTADO\s+PLURINACIONAL',
      caseSensitive: false,
    ).hasMatch(fullText);

    if (hasNewModelKeywords) {
      debugPrint("✓ Modelo detectado: NUEVO");
      return "nuevo";
    }

    final hasOldModelKeywords = RegExp(
      r'REPUBLICA\s+DE\s+BOLIVIA|REP[ÚU]BLICA\s+DE\s+BOLIVIA',
      caseSensitive: false,
    ).hasMatch(fullText);

    if (hasOldModelKeywords) {
      debugPrint("✓ Modelo detectado: ANTIGUO");
      return "antiguo";
    }

    final nPatterns = [
      RegExp(r'N\s*[°º]', caseSensitive: false),
      RegExp(r'N\s*\.', caseSensitive: false),
      RegExp(r'NUMERO\s*[°º]?', caseSensitive: false),
      RegExp(r'N\s*:\s*\d', caseSensitive: false),
      RegExp(r'N\s+[°º]?\s*\d', caseSensitive: false),
    ];

    bool hasN = false;
    for (final pattern in nPatterns) {
      if (pattern.hasMatch(fullText)) {
        hasN = true;
        break;
      }
    }

    if (!hasN) {
      for (final block in recognizedText.blocks) {
        final blockText = block.text.toUpperCase();
        for (final pattern in nPatterns) {
          if (pattern.hasMatch(blockText)) {
            hasN = true;
            break;
          }
        }
        if (hasN) break;
      }
    }

    if (hasN) {
      final hasBarcodePattern =
          RegExp(r'[|]{2,}|[█]{2,}|[▄]{2,}|[■]{2,}').hasMatch(fullText) ||
          fullText.contains('QR') ||
          fullText.contains('CODIGO') ||
          fullText.contains('CÓDIGO') ||
          fullText.contains('BARRA') ||
          fullText.contains('BARRAS');

      bool hasBarcodeInBlocks = false;
      for (final block in recognizedText.blocks) {
        final blockText = block.text;
        if (RegExp(r'[|]{3,}|[█]{3,}|[▄]{3,}|[■]{3,}').hasMatch(blockText)) {
          hasBarcodeInBlocks = true;
          break;
        }
      }

      if (hasBarcodePattern || hasBarcodeInBlocks) return "antiguo";
      return "antiguo";
    }

    final hasNames = RegExp(
      r'(NOMBRES|APELLIDOS|NOMBRE|APELLIDO)',
      caseSensitive: false,
    ).hasMatch(fullText);

    if (hasNames && !hasN) return "nuevo";

    return "desconocido";
  }

  String cleanCI(String raw) {
    // 1. Limpieza básica y normalización
    String fixed = raw.trim().toUpperCase();
    
    // 2. Mantener solo caracteres alfanuméricos y guiones (característicos de complementos)
    // No eliminamos letras ('\D') porque el SEGIP usa complementos como -1B y extensiones
    fixed = fixed.replaceAll(RegExp(r'[^A-Z0-9\-]'), ''); 
    
    // 3. Devolvemos el valor limpio pero completo para no perder datos del usuario
    return fixed;
  }

  String formatDate(String raw) {
    if (raw.isEmpty) return "";
    String fixed = raw.replaceAll(RegExp(r'[.\-\s]'), '/');
    final parts = fixed.split('/');
    if (parts.length >= 3) {
      String day = parts[0].padLeft(2, '0');
      String month = parts[1].padLeft(2, '0');
      String year = parts[2];
      if (year.length == 2) {
        int y = int.tryParse(year) ?? 0;
        year = y > 30 ? "19$year" : "20$year";
      }
      return "$day/$month/$year";
    }
    return fixed;
  }

  /// Extrae nombres y apellidos del modelo nuevo usando el servicio inteligente
  Map<String, String> extractNewModelNames(RecognizedText recognizedText) {
    debugPrint("=== EXTRACCIÓN NUEVO MODELO (VIA SERVICE) ===");
    final data = ServicioOcrInteligenteIdentidad.extractData(recognizedText, null);
    return {
      'nombres': _normalizeName(data['nombres'] ?? ""),
      'apellidos': _normalizeName(data['apellidos'] ?? ""),
    };
  }

  /// Extrae nombre del modelo antiguo usando el servicio inteligente
  Map<String, String> extractOldModelNames(RecognizedText recognizedText) {
    debugPrint("=== EXTRACCIÓN MODELO ANTIGUO (VIA SERVICE) ===");
    final data = ServicioOcrInteligenteIdentidad.extractData(recognizedText, null);
    return {
      'nombres': _normalizeName(data['nombres'] ?? ""),
      'apellidos': _normalizeName(data['apellidos'] ?? ""),
    };
  }

  /// Separa un nombre completo en nombres y apellidos basándose en el número de palabras
  Map<String, String> splitFullName(String fullName) {
    return ServicioOcrInteligenteIdentidad.splitFullName(fullName);
  }

  String _normalizeName(String text) {
    if (text.isEmpty) return "";

    // 1. Filtrar ruidos institucionales típicos de Bolivia
    final noiseRegex = RegExp(
      r'ESTADO PLURINACIONAL DE BOLIVIA|C[ÉE]DULA DE IDENTIDAD|DATOS DEL TITULAR|REP[ÚU]BLICA DE BOLIVIA|ESTADO PLURINACIONAL',
      caseSensitive: false,
    );
    
    if (noiseRegex.hasMatch(text)) {
       // Si el bloque es puramente institucional, lo descartamos
       if (text.trim().length < 35) return "";
       // Si tiene el nombre antes del ruido, lo limpiamos
       text = text.split(noiseRegex)[0].trim();
    }

    // 2. Quitar ruidos comunes por posición
    String cleaned = text
        .split(RegExp(r'PROFESI[ÓO]N|ESTADO|DOMICILIO|LUGAR|FIRMA'))[0]
        .trim();

    // 3. Quitar caracteres no alfabéticos al inicio y final
    cleaned = cleaned.replaceAll(
      RegExp(r'^[^a-zA-ZÁÉÍÓÚÑÜáéíóúñü]+|[^a-zA-ZÁÉÍÓÚÑÜáéíóúñü]+$'),
      '',
    );

    if (cleaned.isEmpty || cleaned.length < 2) return "";

    return cleaned
        .split(' ')
        .map((word) {
          if (word.isEmpty) return "";
          final low = word.toLowerCase();
          if (['de', 'del', 'la', 'las', 'los', 'y'].contains(low)) return low;
          return low[0].toUpperCase() + low.substring(1);
        })
        .join(' ');
  }
}

