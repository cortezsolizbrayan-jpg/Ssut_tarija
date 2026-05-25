import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_turbo_ram.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_inteligente_identidad.dart';
import 'package:refactor_template/core/services/validation/servicio_extraccion_ci_nombres_mejorado.dart';
import 'package:refactor_template/core/services/otros/cancellation_token.dart';
import 'package:refactor_template/core/services/otros/diccionario_nombres_bolivianos.dart';

/// Servicio optimizado para procesar imágenes de CI en background
/// Evita bloquear la UI durante el procesamiento pesado
class ServicioProcesamientoCiOptimizado {
  /// Procesa las imágenes del CI en un isolate separado para no bloquear la UI
  static Future<Map<String, dynamic>> procesarImagenesCI({
    required File frontImage,
    required File backImage,
    required Function(String) onProgress,
    CancellationToken? cancellationToken,
  }) async {
    try {
      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }
      onProgress('Preparando imágenes...');

      // 1. Copiar archivos a ubicación permanente en paralelo
      final persisted = await Future.wait<File>([
        _persistirArchivo(frontImage, 'ci_front'),
        _persistirArchivo(backImage, 'ci_back'),
      ]);
      final frontPermanent = persisted[0];
      final backPermanent = persisted[1];

      onProgress('Normalizando imágenes...');

      // 2. Normalizar imágenes en un ISOLATE REAL para no congelar la UI
      final normalizedPaths = await compute(_normalizarImagenesEnIsolate, {
        'frontPath': frontPermanent.path,
        'backPath': backPermanent.path,
        'tempDir': (await getTemporaryDirectory()).path,
      });

      if (normalizedPaths == null) {
        throw Exception('Error al normalizar imágenes');
      }

      onProgress('Analizando texto con IA...');

      // 3. Realizar OCR usando servicio TURBO con caché en RAM
      final frontFile = File(normalizedPaths['front']!);
      final backFile = File(normalizedPaths['back']!);

      // Procesar ambos lados con el servicio TURBO
      final ocrResults = await ServicioOcrTurboRam.procesarAmbosLadosTurbo(
        frontImage: frontFile,
        backImage: backFile,
        onProgress: (side, progress) {
          if (side == 'front') {
            onProgress('Analizando anverso... ${(progress * 100).toInt()}%');
          } else {
            onProgress(
              'Analizando reverso... ${(progress * 100).toInt()}%\n(puede tardar unos segundos)',
            );
          }
        },
        usarCache: true,
        cancellationToken: cancellationToken,
      );

      if (cancellationToken?.isCancelled ?? false) {
        throw CancellationException();
      }

      final frontOcr = ocrResults['front'];
      final backOcr = ocrResults['back'];

      if (frontOcr == null || backOcr == null) {
        throw Exception('Error al procesar OCR');
      }

      // Mostrar estadísticas de caché
      final stats = ServicioOcrTurboRam.obtenerEstadisticasCache();
      debugPrint(
        '📊 Caché RAM: ${stats['imagenes_en_cache']} imágenes, ${stats['resultados_en_cache']} resultados',
      );
      debugPrint(
        '💾 Memoria usada: ${stats['memoria_imagenes_mb'].toStringAsFixed(2)} MB',
      );

      onProgress('Extrayendo datos...');

      // Ceder el hilo principal antes de la extracción pesada
      await Future<void>.delayed(Duration.zero);

      // 4. Extraer datos usando AMBOS servicios para máxima precisión
      final ciMejorado = ServicioExtraccionCiNombresMejorado.extraerCI(
        frontOcr,
        backOcr,
      );
      final nombresMejorado =
          ServicioExtraccionCiNombresMejorado.extraerNombres(frontOcr, backOcr);
      final apellidosMejorado =
          ServicioExtraccionCiNombresMejorado.extraerApellidos(
            frontOcr,
            backOcr,
          );

      // Ceder el hilo antes del análisis inteligente
      await Future<void>.delayed(Duration.zero);

      // Luego usar el servicio inteligente para fechas y otros datos
      final datosInteligentes = ServicioOcrInteligenteIdentidad.extractData(
        frontOcr,
        backOcr,
      );

      final nombresFinal = _seleccionarMejorCampoPersona(
        principal: nombresMejorado,
        secundario: (datosInteligentes['nombres'] ?? '').toString(),
        esNombres: true,
      );
      final apellidosFinal = _seleccionarMejorCampoPersona(
        principal: apellidosMejorado,
        secundario: (datosInteligentes['apellidos'] ?? '').toString(),
        esNombres: false,
      );

      // Combinar resultados: CI mejorado + consenso robusto para nombres/apellidos
      final extractedData = {
        'ci': ciMejorado.isNotEmpty ? ciMejorado : datosInteligentes['ci'],
        'nombres': nombresFinal,
        'apellidos': apellidosFinal,
        'fechaEmision': datosInteligentes['fechaEmision'],
        'fechaExpiracion': datosInteligentes['fechaExpiracion'],
        'fechaNacimiento': datosInteligentes['fechaNacimiento'],
      };

      debugPrint('📊 Datos extraídos finales:');
      debugPrint('   CI: ${extractedData['ci']}');
      debugPrint('   Nombres: ${extractedData['nombres']}');
      debugPrint('   Apellidos: ${extractedData['apellidos']}');

      return {
        'success': true,
        'data': extractedData,
        'frontPath': frontPermanent.path,
        'backPath': backPermanent.path,
      };
    } catch (e) {
      debugPrint('Error en procesamiento CI: $e');
      if (e is CancellationException) {
        rethrow;
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Persiste un archivo temporal a ubicación permanente
  static Future<File> _persistirArchivo(File tempFile, String prefix) async {
    try {
      // Reintentar hasta 3 veces si el archivo no existe (puede estar escribiéndose)
      int attempts = 0;
      while (!await tempFile.exists() && attempts < 3) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }

      if (!await tempFile.exists()) {
        throw Exception(
          'Archivo temporal no existe después de reintentos: ${tempFile.path}',
        );
      }

      final dir = await getApplicationDocumentsDirectory();
      final ciDir = Directory('${dir.path}/ci_scans');

      if (!await ciDir.exists()) {
        await ciDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final permanentFile = File('${ciDir.path}/${prefix}_$timestamp.jpg');

      await tempFile.copy(permanentFile.path);

      return permanentFile;
    } catch (e) {
      debugPrint('❌ Error persistiendo archivo: $e');
      debugPrint('   Archivo fuente: ${tempFile.path}');
      debugPrint('   Existe archivo: ${await tempFile.exists()}');
      rethrow;
    }
  }

  /// Normaliza imágenes en un isolate separado utilizando la librería 'image'
  /// Esta función se ejecuta fuera del hilo principal de Flutter
  static Future<Map<String, String>?> _normalizarImagenesEnIsolate(
    Map<String, String> params,
  ) async {
    try {
      final frontPath = params['frontPath']!;
      final backPath = params['backPath']!;
      final tempDir = params['tempDir']!;

      // Normalizar anverso
      final frontNormalized = _normalizarImagenSync(
        File(frontPath),
        tempDir,
      );

      // Normalizar reverso
      final backNormalized = _normalizarImagenSync(
        File(backPath),
        tempDir,
      );

      return {'front': frontNormalized.path, 'back': backNormalized.path};
    } catch (e) {
      // No podemos usar debugPrint aquí porque estamos en un isolate puro sin binding de Flutter
      return null;
    }
  }

  /// Normaliza una imagen (orientación, tamaño, contraste)
  /// Versión síncrona para ser ejecutada dentro del isolate
  static File _normalizarImagenSync(File imageFile, String tempDirPath) {
    try {
      final bytes = imageFile.readAsBytesSync();
      var image = img.decodeImage(bytes);

      if (image == null) return imageFile;

      // 1. Corregir orientación
      image = img.bakeOrientation(image);

      // 2. Redimensionar inteligencia (equilibrio precisión/velocidad)
      if (image.width > 1100) {
        image = img.copyResize(image, width: 1100);
      }

      // 3. Ajustes moderados: más legible para OCR sin sobreexponer texto
      image = img.adjustColor(image, contrast: 1.15, brightness: 1.0);

      // 4. Guardar con mejor calidad para reducir confusión de letras similares
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final normalizedFile = File('$tempDirPath/normalized_$timestamp.jpg');

      normalizedFile.writeAsBytesSync(img.encodeJpg(image, quality: 88));

      return normalizedFile;
    } catch (e) {
      return imageFile;
    }
  }

  /// Limpia archivos temporales antiguos (llamar periódicamente)
  static Future<void> limpiarArchivosAntiguos() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ciDir = Directory('${dir.path}/ci_scans');

      if (!await ciDir.exists()) return;

      final now = DateTime.now();
      final files = await ciDir.list().toList();

      for (final entity in files) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = now.difference(stat.modified);

          // Eliminar archivos más antiguos de 7 días
          if (age.inDays > 7) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error limpiando archivos antiguos: $e');
    }
  }

  /// Limpia el caché de RAM del servicio OCR Turbo
  static void limpiarCacheOcr() {
    ServicioOcrTurboRam.limpiarCache();
    debugPrint('🧹 Caché de OCR limpiado');
  }

  /// Obtiene estadísticas del caché de OCR
  static Map<String, dynamic> obtenerEstadisticasCacheOcr() {
    return ServicioOcrTurboRam.obtenerEstadisticasCache();
  }

  static String _seleccionarMejorCampoPersona({
    required String principal,
    required String secundario,
    required bool esNombres,
  }) {
    final a = _postProcesarCampoPersona(
      _normalizarCampoPersona(principal),
      esNombres,
    );
    final b = _postProcesarCampoPersona(
      _normalizarCampoPersona(secundario),
      esNombres,
    );

    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    if (a == b) return a;

    final scoreA = _puntuarCampoPersona(a, esNombres);
    final scoreB = _puntuarCampoPersona(b, esNombres);

    // Si uno es claramente mejor, usar ese.
    if ((scoreA - scoreB).abs() >= 5) {
      return scoreA > scoreB ? a : b;
    }

    // Si son similares, preferir el que tenga más tokens útiles (menos ruido).
    final lenA = a.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).length;
    final lenB = b.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).length;
    if (esNombres) {
      // nombres suele tener 1-3 palabras
      final distA = (lenA - 2).abs();
      final distB = (lenB - 2).abs();
      if (distA != distB) return distA < distB ? a : b;
    } else {
      // apellidos bolivianos típicamente 2 palabras
      final distA = (lenA - 2).abs();
      final distB = (lenB - 2).abs();
      if (distA != distB) return distA < distB ? a : b;
    }

    return scoreA >= scoreB ? a : b;
  }

  static String _normalizarCampoPersona(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r"[^A-Za-z\u00C0-\u024F\s\-']"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .toUpperCase();
  }

  /// Ajuste final: si llegó un "nombre completo" mezclado, separa según diccionario.
  /// Esto sube precisión sin rerun de OCR.
  static String _postProcesarCampoPersona(String value, bool esNombres) {
    final tokens = value
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.length < 3) return value;

    // Si parecen venir NOMBRES+APELLIDOS juntos (4+ tokens), recortar de forma boliviana.
    if (tokens.length >= 4) {
      final last2 = tokens.sublist(tokens.length - 2);
      final first2 = tokens.sublist(0, 2);

      final last2ApellidoScore = last2
          .where(DiccionarioNombresBolivianos.esApellidoConocido)
          .length;
      final first2NombreScore = first2
          .where(DiccionarioNombresBolivianos.esNombreConocido)
          .length;

      if (esNombres) {
        // Si los últimos 2 son apellidos probables, quitarlos.
        if (last2ApellidoScore >= 1) {
          final trimmed = tokens.sublist(0, tokens.length - 2).join(' ');
          return trimmed;
        }
      } else {
        // Si los primeros 1-2 son nombres probables, quedarnos con últimos 2.
        if (first2NombreScore >= 1) {
          return last2.join(' ');
        }
      }
    }

    // Normalizar tamaño típico
    if (esNombres && tokens.length > 3) {
      return tokens.take(3).join(' ');
    }
    if (!esNombres && tokens.length > 2) {
      return tokens.sublist(tokens.length - 2).join(' ');
    }

    return value;
  }

  static int _puntuarCampoPersona(String value, bool esNombres) {
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
    }
    return score;
  }
}

