import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_ocr/flutter_native_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// Servicio OCR nativo optimizado usando flutter_native_ocr
/// 
/// Características:
/// - iOS: Apple Vision Framework (nativo, alta precisión)
/// - Android: Google ML Kit Text Recognition v2 (v16.0.1)
/// - Procesamiento on-device (sin internet)
/// - Preprocesamiento avanzado de imagen
/// - Mayor precisión en caracteres especiales (Ñ, tildes)
/// - Optimizado para Carnet de Identidad boliviano
class ServicioOcrOptimizado {
  static final ServicioOcrOptimizado _instance = ServicioOcrOptimizado._internal();
  factory ServicioOcrOptimizado() => _instance;
  ServicioOcrOptimizado._internal();

  final FlutterNativeOcr _flutterNativeOcr = FlutterNativeOcr();
  bool _isInitialized = false;

  /// Inicializa el servicio OCR nativo
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isInitialized = true;
      debugPrint('✅ ServicioOcrOptimizado inicializado con flutter_native_ocr');
      debugPrint('📱 iOS: Apple Vision Framework | Android: ML Kit v2');
    } catch (e) {
      debugPrint('❌ Error inicializando OCR: $e');
      rethrow;
    }
  }

  /// Extrae datos del Carnet de Identidad boliviano con preprocesamiento mejorado
  Future<Map<String, String>> extraerDatosCI(File imagenFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      debugPrint('🔄 Iniciando OCR nativo con preprocesamiento mejorado...');
      
      // 1. Preprocesar imagen con técnicas avanzadas
      final imagenOptimizada = await _preprocesarImagenMejorado(imagenFile);
      
      // 2. Ejecutar OCR nativo
      debugPrint('📸 Ejecutando OCR nativo...');
      final textoExtraido = await _flutterNativeOcr.recognizeText(imagenOptimizada.path);
      
      if (textoExtraido.isEmpty) {
        debugPrint('⚠️ No se detectó texto en la imagen');
        return {};
      }
      
      debugPrint('✅ Texto OCR extraído (${textoExtraido.length} caracteres)');
      debugPrint('📝 Texto: ${textoExtraido.substring(0, textoExtraido.length > 200 ? 200 : textoExtraido.length)}...');
      
      // 3. Extraer datos con regex mejorados
      final datos = _extraerDatosConRegex(textoExtraido);
      
      // 4. Limpiar archivo temporal
      try {
        await imagenOptimizada.delete();
      } catch (e) {
        debugPrint('⚠️ No se pudo eliminar archivo temporal: $e');
      }
      
      return datos;
      
    } catch (e) {
      debugPrint('❌ Error en OCR: $e');
      return {};
    }
  }

  /// Preprocesa la imagen con técnicas avanzadas para mejor OCR
  Future<File> _preprocesarImagenMejorado(File imagenFile) async {
    try {
      // Leer imagen original
      final bytes = await imagenFile.readAsBytes();
      img.Image? imagen = img.decodeImage(bytes);
      
      if (imagen == null) {
        throw Exception('No se pudo decodificar la imagen');
      }

      // 1. Redimensionar si es muy grande (máximo 1920px de ancho)
      if (imagen.width > 1920) {
        final ratio = 1920 / imagen.width;
        final nuevoAlto = (imagen.height * ratio).round();
        imagen = img.copyResize(imagen, width: 1920, height: nuevoAlto);
        debugPrint('↓ Redimensionado a ${imagen.width}x${imagen.height}');
      }

      // 2. Convertir a escala de grises
      imagen = img.grayscale(imagen);
      debugPrint('⚫ Convertido a escala de grises');

      // 3. Mejorar contraste y brillo
      imagen = img.adjustColor(
        imagen,
        contrast: 1.5,  // Aumentado para mejor definición
        brightness: 1.15,  // Aumentado para texto más claro
      );
      debugPrint('☀️ Contraste y brillo mejorados');

      // 4. Aplicar threshold adaptativo inteligente
      imagen = _aplicarThresholdAdaptativo(imagen);
      debugPrint('🎯 Threshold adaptativo aplicado');

      // 5. Aplicar sharpening para texto más nítido
      imagen = _aplicarSharpening(imagen);
      debugPrint('✨ Sharpening aplicado');

      // 6. Reducir ruido
      imagen = img.gaussianBlur(imagen, radius: 1);
      debugPrint('🧹 Ruido reducido');

      // 7. Aplicar dilatación morfológica para conectar caracteres
      imagen = _aplicarDilatacion(imagen);
      debugPrint('🔗 Dilatación aplicada');

      debugPrint('✅ Preprocesamiento completado');

      // Guardar imagen preprocesada temporalmente
      final directorio = await getTemporaryDirectory();
      final rutaTemporal = '${directorio.path}/ocr_preprocesado_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final archivoTemporal = File(rutaTemporal);
      await archivoTemporal.writeAsBytes(img.encodeJpg(imagen, quality: 98));

      return archivoTemporal;
    } catch (e) {
      debugPrint('❌ Error en preprocesamiento: $e');
      return imagenFile; // Retornar imagen original si falla
    }
  }

  /// Aplica threshold adaptativo inteligente
  img.Image _aplicarThresholdAdaptativo(img.Image imagen) {
    final resultado = img.Image.from(imagen);
    const ventana = 15; // Ventana para cálculo local
    const offset = -10; // Offset para mejor detección

    for (int y = 0; y < imagen.height; y++) {
      for (int x = 0; x < imagen.width; x++) {
        // Calcular promedio local
        int suma = 0;
        int contador = 0;

        for (int dy = -ventana ~/ 2; dy <= ventana ~/ 2; dy++) {
          for (int dx = -ventana ~/ 2; dx <= ventana ~/ 2; dx++) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx >= 0 && nx < imagen.width && ny >= 0 && ny < imagen.height) {
              final pixel = imagen.getPixel(nx, ny);
              suma += pixel.r.toInt();
              contador++;
            }
          }
        }

        final promedio = suma ~/ contador;
        final pixel = imagen.getPixel(x, y);
        final valor = pixel.r.toInt();

        // Aplicar threshold con offset
        if (valor > promedio + offset) {
          resultado.setPixelRgba(x, y, 255, 255, 255);
        } else {
          resultado.setPixelRgba(x, y, 0, 0, 0);
        }
      }
    }

    return resultado;
  }

  /// Aplica filtro de sharpening para texto más nítido
  img.Image _aplicarSharpening(img.Image imagen) {
    // Kernel de sharpening más agresivo
    final kernel = [
      0, -1, 0,
      -1, 10, -1,  // Aumentado de 9 a 10
      0, -1, 0,
    ];

    return img.convolution(imagen, kernel: kernel, div: 6);
  }

  /// Aplica dilatación morfológica para conectar caracteres fragmentados
  img.Image _aplicarDilatacion(img.Image imagen) {
    final resultado = img.Image.from(imagen);
    const ventana = 3;

    for (int y = 1; y < imagen.height - 1; y++) {
      for (int x = 1; x < imagen.width - 1; x++) {
        int maxValor = 0;

        // Buscar valor máximo en ventana 3x3
        for (int dy = -ventana ~/ 2; dy <= ventana ~/ 2; dy++) {
          for (int dx = -ventana ~/ 2; dx <= ventana ~/ 2; dx++) {
            final pixel = imagen.getPixel(x + dx, y + dy);
            maxValor = maxValor > pixel.r.toInt() ? maxValor : pixel.r.toInt();
          }
        }

        resultado.setPixelRgba(x, y, maxValor, maxValor, maxValor);
      }
    }

    return resultado;
  }

  /// Extrae datos del CI usando expresiones regulares mejoradas
  Map<String, String> _extraerDatosConRegex(String texto) {
    final datos = <String, String>{};
    
    // Normalizar texto
    final textoNormalizado = texto
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    
    debugPrint('🔍 Extrayendo datos del texto normalizado...');
    
    // 1. Extraer número de CI (7-10 dígitos)
    final regexCI = RegExp(r'\b(\d{7,10})\b');
    final matchCI = regexCI.firstMatch(textoNormalizado);
    if (matchCI != null) {
      datos['numeroDocumento'] = matchCI.group(1)!;
      debugPrint('✅ CI encontrado: ${datos['numeroDocumento']}');
    }
    
    // 2. Extraer nombres (después de "NOMBRES" o similar)
    final regexNombres = RegExp(
      r'(?:NOMBRES?|NAME)[:\s]*([A-ZÁÉÍÓÚÑ\s]{2,50})',
      caseSensitive: false,
    );
    final matchNombres = regexNombres.firstMatch(textoNormalizado);
    if (matchNombres != null) {
      datos['nombres'] = matchNombres.group(1)!.trim();
      debugPrint('✅ Nombres encontrados: ${datos['nombres']}');
    }
    
    // 3. Extraer apellidos (después de "APELLIDOS" o similar)
    final regexApellidos = RegExp(
      r'(?:APELLIDOS?|SURNAME)[:\s]*([A-ZÁÉÍÓÚÑ\s]{2,50})',
      caseSensitive: false,
    );
    final matchApellidos = regexApellidos.firstMatch(textoNormalizado);
    if (matchApellidos != null) {
      datos['apellidos'] = matchApellidos.group(1)!.trim();
      debugPrint('✅ Apellidos encontrados: ${datos['apellidos']}');
    }
    
    // 4. Extraer fecha de nacimiento (DD/MM/YYYY o DD-MM-YYYY)
    final regexFecha = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b');
    final matchFecha = regexFecha.firstMatch(textoNormalizado);
    if (matchFecha != null) {
      final dia = matchFecha.group(1)!.padLeft(2, '0');
      final mes = matchFecha.group(2)!.padLeft(2, '0');
      final anio = matchFecha.group(3)!;
      datos['fechaNacimiento'] = '$dia/$mes/$anio';
      debugPrint('✅ Fecha de nacimiento encontrada: ${datos['fechaNacimiento']}');
    }
    
    // 5. Extraer lugar de expedición
    final departamentos = [
      'LA PAZ', 'COCHABAMBA', 'SANTA CRUZ', 'ORURO', 'POTOSÍ', 'POTOSI',
      'CHUQUISACA', 'TARIJA', 'BENI', 'PANDO'
    ];
    
    for (final depto in departamentos) {
      if (textoNormalizado.toUpperCase().contains(depto)) {
        datos['expedido'] = depto;
        debugPrint('✅ Lugar de expedición encontrado: ${datos['expedido']}');
        break;
      }
    }
    
    debugPrint('📊 Datos extraídos: ${datos.length} campos');
    return datos;
  }

  /// Libera recursos del servicio OCR
  Future<void> dispose() async {
    _isInitialized = false;
    debugPrint('🔄 ServicioOcrOptimizado liberado');
  }
}
