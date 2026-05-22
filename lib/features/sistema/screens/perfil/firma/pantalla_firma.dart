import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/premium_alerts.dart';

class PantallaFirma extends StatefulWidget {
  static const String name = 'pantalla_firma';
  const PantallaFirma({super.key});

  @override
  State<PantallaFirma> createState() => _PantallaFirmaState();
}

class _PantallaFirmaState extends State<PantallaFirma> {
  final List<Offset?> _points = [];
  bool _isSaving = false;

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _saveSignature() async {
    if (_points.isEmpty) {
      PremiumAlerts.showError(
        context,
        'Por favor, dibuje su firma antes de guardar.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      final backgroundPaint = Paint()
        ..color = Colors.white; // Fondo blanco para transparencia si se desa

      // Dibujar fondo transparente
      canvas.drawRect(const Rect.fromLTWH(0, 0, 500, 300), backgroundPaint);

      final Paint paint = Paint()
        ..color =
            const Color(0xFF003366) // Azul tinta
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.5;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(500, 300);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/firma_temporal.png');
        await file.writeAsBytes(pngBytes);

        // Guardar la ruta en SharedPreferences (LocalStorageService)
        await LocalStorageService.saveSignatureImage(file.path);

        if (mounted) {
          PremiumAlerts.showSuccess(context, 'Firma guardada correctamente.');
          context.pop(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        PremiumAlerts.showError(context, 'Error al guardar la firma: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Firma Digital',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF005BAC),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Por favor, dibuje su rúbrica o firma personal en el siguiente recuadro. Esta imagen será adjuntada en sus documentos oficiales de inscripción y solicitudes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF005BAC), width: 2),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onPanStart: (details) {
                          setState(() {
                            RenderBox renderBox =
                                context.findRenderObject() as RenderBox;
                            _points.add(
                              renderBox.globalToLocal(details.globalPosition),
                            );
                          });
                        },
                        onPanUpdate: (details) {
                          setState(() {
                            RenderBox renderBox =
                                context.findRenderObject() as RenderBox;
                            _points.add(
                              renderBox.globalToLocal(details.globalPosition),
                            );
                          });
                        },
                        onPanEnd: (details) {
                          setState(() {
                            _points.add(null);
                          });
                        },
                        child: CustomPaint(
                          painter: _SignaturePainter(points: _points),
                          size: Size.infinite,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _points.isEmpty ? null : _clearSignature,
                      icon: Icon(
                        Icons.clear,
                        color: _points.isEmpty
                            ? Colors.grey.shade400
                            : Colors.red,
                      ),
                      label: Text(
                        'Limpiar',
                        style: TextStyle(
                          color: _points.isEmpty
                              ? Colors.grey.shade400
                              : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: _points.isEmpty
                              ? Colors.grey.shade300
                              : Colors.red,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: _points.isEmpty
                            ? Colors.grey.shade50
                            : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: (_points.isEmpty || _isSaving)
                          ? null
                          : _saveSignature,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.save,
                              color: (_points.isEmpty || _isSaving)
                                  ? Colors.grey.shade400
                                  : Colors.white,
                            ),
                      label: Text(
                        _isSaving ? 'Guardando...' : 'Guardar Firma',
                        style: TextStyle(
                          color: (_points.isEmpty || _isSaving)
                              ? Colors.grey.shade400
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (_points.isEmpty || _isSaving)
                            ? Colors.grey.shade200
                            : const Color(0xFF005BAC),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: (_points.isEmpty || _isSaving) ? 0 : 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    Paint background = Paint()..color = Colors.white;
    Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, background);

    Paint paint = Paint()
      ..color = const Color(0xFF003366)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawPoints(ui.PointMode.points, [points[i]!], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

