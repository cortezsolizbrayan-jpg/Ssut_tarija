import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../constants.dart';
import '../widgets/signature_painter.dart';

class LegalDocumentModal extends StatefulWidget {
  final String title;
  final String content;
  final String confirmText;
  final Function(Uint8List? signature)? onConfirm;

  const LegalDocumentModal({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = "Aceptar",
    this.onConfirm,
  });

  @override
  State<LegalDocumentModal> createState() => _LegalDocumentModalState();
}

class _LegalDocumentModalState extends State<LegalDocumentModal> {
  final GlobalKey _signatureKey = GlobalKey();
  List<Offset?> _points = [];

  Future<Uint8List?> _captureSignature() async {
    if (_points.length < 2) return null;
    try {
      final boundary = _signatureKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MisDocumentosConstants.kPrimaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: MisDocumentosConstants.kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: MisDocumentosConstants.fontHeading,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MisDocumentosConstants.kTextColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: MisDocumentosConstants.kTextSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SelectableText(
                      widget.content,
                      style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF334155),
                      ),
                      textAlign: TextAlign.justify,
                    ),

                    if (widget.onConfirm != null) ...[
                      const Divider(height: 32, thickness: 1),
                      Text(
                        "Firma digital",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RepaintBoundary(
                        key: _signatureKey,
                        child: Container(
                          height: 170,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _points.length < 2
                                  ? const Color(0xFFCBD5E1)
                                  : MisDocumentosConstants.kPrimaryColor.withOpacity(0.6),
                            ),
                          ),
                          child: GestureDetector(
                            onPanStart: (details) {
                              final box = _signatureKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              final local = box.globalToLocal(details.globalPosition);
                              setState(() {
                                _points = List.of(_points)..add(local);
                              });
                            },
                            onPanUpdate: (details) {
                              final box = _signatureKey.currentContext?.findRenderObject() as RenderBox?;
                              if (box == null) return;
                              final local = box.globalToLocal(details.globalPosition);
                              setState(() {
                                _points = List.of(_points)..add(local);
                              });
                            },
                            onPanEnd: (_) {
                              setState(() {
                                _points = List.of(_points)..add(null);
                              });
                            },
                            child: CustomPaint(
                              painter: SignaturePainter(_points),
                              child: Container(
                                alignment: Alignment.center,
                                child: _points.length < 2
                                    ? const Text(
                                        "Firma aquí con tu dedo",
                                        style: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Puedes borrar y volver a firmar si lo necesitas.",
                            style: TextStyle(fontSize: 11, color: MisDocumentosConstants.kTextSecondary),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() => _points = []),
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text("Limpiar"),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: MisDocumentosConstants.kSuccessColor, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Al continuar, aceptas firmar este documento digitalmente con tus datos registrados.",
                              style: TextStyle(fontSize: 12, color: MisDocumentosConstants.kTextSecondary, fontStyle: FontStyle.italic),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Fixed Bottom Action
          if (widget.onConfirm != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Cancelar", style: TextStyle(color: MisDocumentosConstants.kTextSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final png = await _captureSignature();
                          widget.onConfirm?.call(png);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MisDocumentosConstants.kPrimaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(widget.confirmText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}


