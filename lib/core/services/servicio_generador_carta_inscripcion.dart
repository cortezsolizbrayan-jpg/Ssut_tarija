import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipos de programas de posgrado disponibles
enum TipoPrograma {
  diplomado,
  especialidad,
  maestria,
  doctorado,
}

/// Servicio para generar cartas de solicitud de inscripción
class ServicioGeneradorCartaInscripcion {
  /// Genera una carta de solicitud de inscripción según el tipo de programa
  /// 
  /// Parámetros:
  /// - [tipoPrograma]: Tipo de programa (Diplomado, Especialidad, Maestría, Doctorado)
  /// - [nombrePrograma]: Nombre completo del programa
  /// - [modalidad]: Modalidad del programa (Virtual, Presencial, Semipresencial)
  /// - [nombreCompleto]: Nombre completo del solicitante
  /// - [numeroCI]: Número de cédula de identidad
  /// - [montoDeposito]: Monto del depósito bancario
  /// - [guardarEnPreferencias]: Si es true, guarda la ruta en SharedPreferences (default: true)
  /// 
  /// Retorna: Ruta del archivo HTML generado
  Future<String> generarCarta({
    required TipoPrograma tipoPrograma,
    required String nombrePrograma,
    required String modalidad,
    required String nombreCompleto,
    required String numeroCI,
    required String montoDeposito,
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

      // Reemplazar los marcadores de posición con los datos reales
      String cartaGenerada = plantillaHTML
          .replaceAll('{{FECHA_ACTUAL}}', fechaActual)
          .replaceAll('{{NOMBRE_PROGRAMA}}', nombrePrograma)
          .replaceAll('{{MODALIDAD}}', modalidad)
          .replaceAll('{{NOMBRE_COMPLETO}}', nombreCompleto)
          .replaceAll('{{NUMERO_CI}}', numeroCI)
          .replaceAll('{{MONTO_DEPOSITO}}', montoDeposito);

      // Guardar el archivo generado
      final String rutaArchivo = await _guardarArchivo(
        cartaGenerada,
        tipoPrograma,
        numeroCI,
      );

      // Guardar la ruta en SharedPreferences si se solicita
      if (guardarEnPreferencias) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cartaInscripcionPath', rutaArchivo);
      }

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
  ) async {
    try {
      // Obtener el directorio de documentos de la aplicación
      final Directory directorioDocumentos = await getApplicationDocumentsDirectory();
      
      // Crear subdirectorio para cartas si no existe
      final Directory directorioCartas = Directory('${directorioDocumentos.path}/cartas_inscripcion');
      if (!await directorioCartas.exists()) {
        await directorioCartas.create(recursive: true);
      }

      // Generar nombre de archivo único
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String tipoStr = tipo.toString().split('.').last;
      final String nombreArchivo = 'carta_inscripcion_${tipoStr}_${numeroCI}_$timestamp.html';
      
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
