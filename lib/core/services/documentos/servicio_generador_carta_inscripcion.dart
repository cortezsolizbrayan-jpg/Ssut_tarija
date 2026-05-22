import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Tipos de programas de posgrado disponibles
enum TipoPrograma {
  diplomado,
  especialidad,
  maestria,
  doctorado,
}

/// Servicio para generar cartas de solicitud de inscripción
class ServicioGeneradorCartaInscripcion {
  /// Abreviaturas de departamento para CI (ej. C.I. 8167727 Sc)
  static const Map<String, String> _abrevExpedido = {
    'LA PAZ': 'Lp',
    'ORURO': 'Or',
    'POTOSÍ': 'Po',
    'SANTA CRUZ': 'Sc',
    'BENI': 'Be',
    'PANDO': 'Pa',
    'COCHABAMBA': 'Cb',
    'CHUQUISACA': 'Ch',
    'TARIJA': 'Tj',
  };

  /// Genera una carta de solicitud de inscripción según el tipo de programa
  /// 
  /// Parámetros:
  /// - [tipoPrograma]: Tipo de programa (Diplomado, Especialidad, Maestría, Doctorado)
  /// - [nombrePrograma]: Nombre completo del programa
  /// - [modalidad]: Modalidad del programa (Virtual, Presencial, Semipresencial)
  /// - [nombreCompleto]: Nombre completo del solicitante
  /// - [numeroCI]: Número de cédula de identidad
  /// - [expedidoEn]: Departamento de expedición del CI (opcional, ej. SANTA CRUZ → "Sc")
  /// - [montoDeposito]: Monto del depósito bancario
  /// - [numeroRef]: Número de referencia de la carta (opcional, ej. " - - 8285")
  /// - [signatureImagePath]: Ruta de la imagen de la firma digital (opcional)
  /// - [guardarEnPreferencias]: Si es true, guarda la ruta en SharedPreferences (default: true)
  /// 
  /// Retorna: Ruta del archivo HTML generado
  Future<String> generarCarta({
    required TipoPrograma tipoPrograma,
    required String nombrePrograma,
    required String modalidad,
    required String nombreCompleto,
    required String numeroCI,
    String? expedidoEn,
    required String montoDeposito,
    String? numeroRef,
    String? signatureImagePath,
    bool guardarEnPreferencias = true,
  }) async {
    try {
      // Obtener la plantilla correspondiente
      final String nombrePlantilla = _obtenerNombrePlantilla(tipoPrograma);
      final String plantillaHTML = await rootBundle.loadString(
        'assets/templates/$nombrePlantilla',
      );

      // Obtener la fecha actual en formato español
      final String fechaActual = _obtenerFechaActual();

      // Expedido para CI: abreviatura con espacio (ej. " Sc") o vacío
      final String expedidoCi = expedidoEn != null && expedidoEn.isNotEmpty
          ? ' ${_abrevExpedido[expedidoEn.toUpperCase()] ?? expedidoEn}'
          : '';

      // Número de referencia (ej. " - - 8285") o vacío
      final String refStr = (numeroRef != null && numeroRef.trim().isNotEmpty)
          ? ' - - $numeroRef'
          : '';

      // Convertir firma a base64 si existe
      String firmaBase64 = '';
      if (signatureImagePath != null && signatureImagePath.isNotEmpty) {
        try {
          final File firmaFile = File(signatureImagePath);
          if (await firmaFile.exists()) {
            final bytes = await firmaFile.readAsBytes();
            firmaBase64 = base64Encode(bytes);
          }
        } catch (e) {
          // Si hay error al cargar la firma, continuar sin ella
          print('⚠️ Error al cargar firma: $e');
        }
      }

      // Reemplazar los marcadores de posición con los datos reales
      String cartaGenerada = plantillaHTML
          .replaceAll('{{FECHA_ACTUAL}}', fechaActual)
          .replaceAll('{{NOMBRE_PROGRAMA}}', nombrePrograma)
          .replaceAll('{{MODALIDAD}}', modalidad)
          .replaceAll('{{NOMBRE_COMPLETO}}', nombreCompleto)
          .replaceAll('{{NUMERO_CI}}', numeroCI)
          .replaceAll('{{EXPEDIDO_CI}}', expedidoCi)
          .replaceAll('{{NUMERO_REF}}', refStr)
          .replaceAll('{{MONTO_DEPOSITO}}', montoDeposito)
          .replaceAll('{{FIRMA_BASE64}}', firmaBase64)
          .replaceAll('{{FIRMA_DISPLAY}}', firmaBase64.isNotEmpty ? 'block' : 'none')
          .replaceAll('{{FIRMA_VISIBILIDAD}}', firmaBase64.isNotEmpty ? '' : 'style="display: none;"');

      // Guardar el archivo generado
      final String rutaArchivo = await _guardarArchivo(
        cartaGenerada,
        tipoPrograma,
        numeroCI,
        nombrePrograma,
      );

      return rutaArchivo;
    } catch (e) {
      throw Exception('Error al generar la carta de inscripción: $e');
    }
  }

  /// Obtiene el nombre de la plantilla según el tipo de programa
  String _obtenerNombrePlantilla(TipoPrograma tipo) {
    switch (tipo) {
      case TipoPrograma.diplomado:
        return 'carta_solicitud_inscripcion_diplomado.html';
      case TipoPrograma.especialidad:
        return 'carta_solicitud_inscripcion_especialidad.html';
      case TipoPrograma.maestria:
        return 'carta_solicitud_inscripcion_maestria.html';
      case TipoPrograma.doctorado:
        return 'carta_solicitud_inscripcion_doctorado.html';
    }
  }

  /// Obtiene la fecha actual en formato español
  String _obtenerFechaActual() {
    final DateTime ahora = DateTime.now();
    final DateFormat formatoFecha = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es');
    return formatoFecha.format(ahora);
  }

  /// Guarda el archivo HTML generado
  Future<String> _guardarArchivo(
    String contenido,
    TipoPrograma tipo,
    String numeroCI,
    String nombrePrograma,
  ) async {
    try {
      // Obtener el directorio de documentos de la aplicación
      final Directory directorioDocumentos = await getApplicationDocumentsDirectory();
      
      // Sanitizar nombre del programa para usarlo en nombre de archivo (eliminar caracteres no válidos)
      final String programId = nombrePrograma.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      
      // Crear subdirectorio para cartas si no existe
      final Directory directorioCartas = Directory('${directorioDocumentos.path}/cartas_inscripcion');
      if (!await directorioCartas.exists()) {
        await directorioCartas.create(recursive: true);
      }

      // Generar nombre de archivo único incluyendo el programa
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String tipoStr = tipo.toString().split('.').last;
      final String nombreArchivo = 'carta_inscripcion_${programId}_${tipoStr}_${numeroCI}_$timestamp.html';
      
      // Crear y escribir el archivo
      final File archivo = File('${directorioCartas.path}/$nombreArchivo');
      await archivo.writeAsString(contenido);

      return archivo.path;
    } catch (e) {
      throw Exception('Error al guardar el archivo: $e');
    }
  }

  /// Convierte el tipo de programa a texto legible
  String obtenerNombreTipoPrograma(TipoPrograma tipo) {
    switch (tipo) {
      case TipoPrograma.diplomado:
        return 'DIPLOMADO';
      case TipoPrograma.especialidad:
        return 'ESPECIALIDAD';
      case TipoPrograma.maestria:
        return 'MAESTRÍA';
      case TipoPrograma.doctorado:
        return 'DOCTORADO';
    }
  }

  /// Obtiene el plazo de documentación según el tipo de programa (en meses)
  int obtenerPlazoDocumentacion(TipoPrograma tipo) {
    switch (tipo) {
      case TipoPrograma.diplomado:
        return 8;
      case TipoPrograma.especialidad:
        return 10;
      case TipoPrograma.maestria:
        return 12;
      case TipoPrograma.doctorado:
        return 18;
    }
  }
}
