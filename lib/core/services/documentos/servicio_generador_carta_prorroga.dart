import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio para generar cartas de solicitud de prórroga para entrega de título
class ServicioGeneradorCartaProrroga {
  
  /// Abreviaturas de departamento para CI
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

  /// Genera una carta de solicitud de prórroga
  Future<String> generarCarta({
    required String nombrePrograma,
    required String nombreCompleto,
    required String numeroCI,
    String? expedidoEn,
    int plazoMeses = 8,
    String? signatureImagePath,
  }) async {
    try {
      final String plantillaHTML = await rootBundle.loadString(
        'assets/templates/carta_solicitud_prorroga.html',
      );

      final String fechaActual = _obtenerFechaActual();

      final String expedidoCi = expedidoEn != null && expedidoEn.isNotEmpty
          ? ' ${_abrevExpedido[expedidoEn.toUpperCase()] ?? expedidoEn}'
          : '';

      String firmaBase64 = '';
      if (signatureImagePath != null && signatureImagePath.isNotEmpty) {
        try {
          final File firmaFile = File(signatureImagePath);
          if (await firmaFile.exists()) {
            final bytes = await firmaFile.readAsBytes();
            firmaBase64 = base64Encode(bytes);
          }
        } catch (e) {
          print('⚠️ Error al cargar firma: $e');
        }
      }

      String cartaGenerada = plantillaHTML
          .replaceAll('{{FECHA_ACTUAL}}', fechaActual)
          .replaceAll('{{NOMBRE_PROGRAMA}}', nombrePrograma)
          .replaceAll('{{NOMBRE_COMPLETO}}', nombreCompleto)
          .replaceAll('{{NUMERO_CI}}', numeroCI)
          .replaceAll('{{EXPEDIDO_CI}}', expedidoCi)
          .replaceAll('{{PLAZO_MESES}}', plazoMeses.toString())
          .replaceAll('{{FIRMA_BASE64}}', firmaBase64)
          .replaceAll('{{FIRMA_DISPLAY}}', firmaBase64.isNotEmpty ? 'block' : 'none')
          .replaceAll('{{FIRMA_VISIBILIDAD}}', firmaBase64.isNotEmpty ? '' : 'style="display: none;"');

      final String rutaArchivo = await _guardarArchivo(
        cartaGenerada,
        numeroCI,
        nombrePrograma,
      );

      return rutaArchivo;
    } catch (e) {
      throw Exception('Error al generar la carta de prórroga: $e');
    }
  }

  String _obtenerFechaActual() {
    final DateTime ahora = DateTime.now();
    final DateFormat formatoFecha = DateFormat('d \'de\' MMMM \'de\' yyyy', 'es');
    return formatoFecha.format(ahora);
  }

  Future<String> _guardarArchivo(
    String contenido,
    String numeroCI,
    String nombrePrograma,
  ) async {
    try {
      final Directory directorioDocumentos = await getApplicationDocumentsDirectory();
      final String programId = nombrePrograma.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final Directory directorioCartas = Directory('${directorioDocumentos.path}/cartas_prorroga');
      
      if (!await directorioCartas.exists()) {
        await directorioCartas.create(recursive: true);
      }

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String nombreArchivo = 'carta_prorroga_${programId}_${numeroCI}_$timestamp.html';
      
      final File archivo = File('${directorioCartas.path}/$nombreArchivo');
      await archivo.writeAsString(contenido);

      return archivo.path;
    } catch (e) {
      throw Exception('Error al guardar el archivo: $e');
    }
  }
}
