import 'package:flutter/material.dart';

/// Diálogo con recomendaciones para escanear documentos
class ScanTipsDialog {
  /// Muestra el diálogo de consejos de escaneo
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Recomendaciones de escaneo'),
          content: const Text(
            'Coloca el carnet en una superficie plana y bien iluminada (luz blanca, sin sombras ni reflejos). '
            'Mantén la cámara estable y encuadra todo el documento. '
            'Evita fondos con patrones y texto. '
            'Si tu nombre tiene ñ, procura que esté nítida para que se reconozca correctamente.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Entendido, escanear'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}

