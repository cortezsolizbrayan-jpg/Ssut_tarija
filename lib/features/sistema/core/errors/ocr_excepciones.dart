/// 🚨 EXCEPCIONES ESPECÍFICAS PARA OCR
/// 
/// Jerarquía de excepciones para el procesamiento de documentos
/// que permite un manejo de errores más preciso y depuración facilitada.
library;

/// Excepción base para errores de OCR
abstract class OcrException implements Exception {
  final String message;
  final String? details;
  
  OcrException(this.message, [this.details]);
  
  @override
  String toString() => details != null 
      ? '$message: $details' 
      : message;
}

/// Excepción cuando la imagen no es válida
class ImagenNoValidaException extends OcrException {
  final String? path;
  
  ImagenNoValidaException(super.message, [this.path, super.details]);
}

/// Excepción cuando falla el procesamiento
class ProcesamientoFalloException extends OcrException {
  final Exception? causaOriginal;
  
  ProcesamientoFalloException(super.message, [this.causaOriginal, super.details]);
}

/// Excepción cuando el OCR no puede extraer texto
class OcrExtraccionFallidaException extends OcrException {
  final int intentos;
  
  OcrExtraccionFallidaException(super.message, [this.intentos = 1, super.details]);
}

/// Excepción cuando el documento no tiene el formato esperado
class FormatoDocumentoInvalidoException extends OcrException {
  final String? tipoDetectado;
  
  FormatoDocumentoInvalidoException(super.message, [this.tipoDetectado, super.details]);
}

