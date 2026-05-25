import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:refactor_template/core/services/ocr/servicio_ocr_ia_avanzado.dart';
import 'package:refactor_template/core/services/image_processing/servicio_preprocesamiento_imagen.dart';
import 'package:refactor_template/features/sistema/core/errors/ocr_excepciones.dart';

/// 🧠 CASO DE USO PARA PROCESAR DOCUMENTOS
///
/// Encapsula toda la lógica de procesamiento de imágenes OCR
/// separándola de la capa de presentación (UI).
///
/// RESPONSABILIDADES:
/// ✅ Preprocesamiento de imágenes
/// ✅ Ejecución de OCR con ML Kit
/// ✅ Análisis con IA avanzada
/// ✅ Limpieza de archivos temporales
/// ✅ Manejo de errores específicos
class ProcesarDocumentoUsecase {
  final TextRecognizer textRecognizer;

  ProcesarDocumentoUsecase({required this.textRecognizer});

  /// Ejecuta el procesamiento completo de un documento
  ///
  /// @param imagenFrente Archivo de la imagen del frente (requerido)
  /// @param imagenReverso Archivo de la imagen del reverso (opcional)
  /// @param tipoEsperado Tipo de documento esperado para validación
  /// @return ResultadoOcrIA con todos los campos extraídos
  /// @throws ImagenNoValidaException si las imágenes son inválidas
  /// @throws ProcesamientoFalloException si falla el procesamiento
  Future<ResultadoOcrIA> ejecutar({
    required File imagenFrente,
    File? imagenReverso,
    TipoDocumento? tipoEsperado,
  }) async {
    // Validar imágenes
    _validarImagenes(imagenFrente, imagenReverso);

    String? processedFrontPath;
    String? processedBackPath;

    try {
      // PREPROCESAMIENTO: Mejorar calidad de imágenes
      debugPrint('🖼️ Iniciando preprocesamiento de imágenes...');

      processedFrontPath = await _preprocesarImagen(imagenFrente, 'frente');

      if (imagenReverso != null) {
        processedBackPath = await _preprocesarImagen(imagenReverso, 'reverso');
      }

      // EJECUTAR OCR en las imágenes preprocesadas
      final textoFrente = await _ejecutarOcr(processedFrontPath!, 'frente');

      RecognizedText? textoReverso;
      if (processedBackPath != null) {
        textoReverso = await _ejecutarOcr(processedBackPath, 'reverso');
      }

      // ANALIZAR con IA
      final resultado = await ServicioOcrIaAvanzado.analizarDocumento(
        textoOcr: textoFrente,
        textoOcrReverso: textoReverso,
        tipoEsperado: tipoEsperado,
      );

      // LIMPIAR archivos temporales
      await _limpiarArchivosTemporales(
        processedFrontPath,
        imagenFrente.path,
        processedBackPath,
        imagenReverso?.path,
      );

      // AGREGAR metadatos de rutas de imágenes originales
      resultado.metadatos['ci_front_path'] = imagenFrente.path;
      if (imagenReverso != null) {
        resultado.metadatos['ci_back_path'] = imagenReverso.path;
      }

      return resultado;
    } on OcrException {
      // Relanzar excepciones específicas de OCR
      rethrow;
    } catch (e, stackTrace) {
      // Limpiar archivos temporales en caso de error
      await _limpiarArchivosTemporales(
        processedFrontPath,
        imagenFrente.path,
        processedBackPath,
        imagenReverso?.path,
      );

      debugPrint('❌ Error en procesamiento OCR: $e');
      debugPrint('Stack trace: $stackTrace');

      throw ProcesamientoFalloException(
        'Error al procesar el documento con IA',
        e is Exception ? e : null,
        'Detalle técnico: $e',
      );
    }
  }

  /// Valida que las imágenes existan y sean accesibles
  void _validarImagenes(File frente, File? reverso) {
    if (!frente.existsSync()) {
      throw ImagenNoValidaException(
        'La imagen del frente no existe o no es accesible',
        frente.path,
      );
    }

    if (reverso != null && !reverso.existsSync()) {
      throw ImagenNoValidaException(
        'La imagen del reverso no existe o no es accesible',
        reverso.path,
      );
    }
  }

  /// Preprocesa una imagen si es necesario
  Future<String?> _preprocesarImagen(File imagen, String lado) async {
    final calidad = ServicioPreprocesamientoImagen.evaluarCalidad(imagen);
    debugPrint('📊 Calidad $lado: ${calidad['calidad']}%');

    if (calidad['calidad'] < 80) {
      debugPrint('🔧 Preprocesando imagen de $lado...');
      final ruta = await ServicioPreprocesamientoImagen.procesarParaOCR(imagen);
      debugPrint('✅ Imagen de $lado preprocesada');
      return ruta;
    }

    debugPrint(
      '✨ Imagen de $lado tiene calidad suficiente, sin preprocesamiento',
    );
    return imagen.path;
  }

  /// Ejecuta OCR en una imagen
  Future<RecognizedText> _ejecutarOcr(String ruta, String lado) async {
    debugPrint('📷 Ejecutando OCR en imagen de $lado...');
    final inputImage = InputImage.fromFilePath(ruta);
    final texto = await textRecognizer.processImage(inputImage);
    debugPrint('✅ OCR completado para imagen de $lado');
    return texto;
  }

  /// Limpia archivos temporales generados durante el preprocesamiento
  Future<void> _limpiarArchivosTemporales(
    String? processedFront,
    String originalFront,
    String? processedBack,
    String? originalBack,
  ) async {
    // Limpiar frente
    if (processedFront != null && processedFront != originalFront) {
      await _eliminarArchivoSeguro(processedFront, 'frente');
    }

    // Limpiar reverso
    if (processedBack != null && processedBack != originalBack) {
      await _eliminarArchivoSeguro(processedBack, 'reverso');
    }
  }

  /// Elimina un archivo de forma segura sin lanzar errores
  Future<void> _eliminarArchivoSeguro(String ruta, String etiqueta) async {
    try {
      final archivo = File(ruta);
      if (await archivo.exists()) {
        await archivo.delete();
        debugPrint('🗑️ Archivo temporal de $etiqueta eliminado: $ruta');
      }
    } catch (e) {
      debugPrint('⚠️ No se pudo eliminar archivo temporal de $etiqueta: $ruta');
      debugPrint('   Error: $e');
    }
  }
}

