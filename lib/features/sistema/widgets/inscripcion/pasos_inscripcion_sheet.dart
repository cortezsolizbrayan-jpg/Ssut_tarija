import 'package:flutter/material.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';

/// Datos de un paso individual en el proceso de inscripción.
class PasoInscripcionData {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  const PasoInscripcionData({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
  });
}

/// Bottom sheet que muestra los pasos del proceso de inscripción.
class PasosInscripcionSheet extends StatefulWidget {
  final ProgramaPosgrado programa;
  const PasosInscripcionSheet({super.key, required this.programa});

  @override
  State<PasosInscripcionSheet> createState() => _PasosInscripcionSheetState();
}

class _PasosInscripcionSheetState extends State<PasosInscripcionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _pasos = [
    PasoInscripcionData(
      icono: Icons.person_outline_rounded,
      titulo: 'Paso 1 · Datos personales',
      descripcion: 'Asegúrate de tener tu nombre completo, CI y datos de contacto actualizados en tu perfil.',
      color: Color(0xFF1565C0),
    ),
    PasoInscripcionData(
      icono: Icons.folder_copy_outlined,
      titulo: 'Paso 2 · Documentos requeridos',
      descripcion: 'Prepara tu título académico, hoja de vida y fotocopia de CI en formato PDF o imagen.',
      color: Color(0xFF6A1B9A),
    ),
    PasoInscripcionData(
      icono: Icons.description_outlined,
      titulo: 'Paso 3 · Carta de inscripción',
      descripcion: 'La app generará automáticamente tu carta de solicitud de inscripción con tus datos.',
      color: Color(0xFF00695C),
    ),
    PasoInscripcionData(
      icono: Icons.receipt_long_outlined,
      titulo: 'Paso 4 · Comprobante de pago',
      descripcion: 'Sube el comprobante de depósito bancario de matrícula y colegiatura para completar tu inscripción.',
      color: Color(0xFFE65100),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.programa.tipo.isNotEmpty
        ? widget.programa.tipo[0].toUpperCase() + widget.programa.tipo.substring(1).toLowerCase()
        : 'Programa';
    final nombre = widget.programa.titulo.isNotEmpty
        ? widget.programa.titulo
        : widget.programa.tipo;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF005BAC), Color(0xFF003F7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipo.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Proceso de inscripción — 4 pasos',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Lista de pasos
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  ..._pasos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final paso = entry.value;
                    final delay = i * 0.15;
                    final animation = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
                    );
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (_, hijo) => Opacity(
                        opacity: animation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - animation.value)),
                          child: hijo,
                        ),
                      ),
                      child: PasoInscripcionTile(paso: paso, index: i + 1),
                    );
                  }),
                  const SizedBox(height: 8),
                  // Nota informativa
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF005BAC).withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: Color(0xFF005BAC), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'La app te guiará en cada paso. Puedes completar los requisitos en cualquier momento y volver a intentar la inscripción.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Botones
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'Iniciar inscripción',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
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

class PasoInscripcionTile extends StatelessWidget {
  final PasoInscripcionData paso;
  final int index;
  const PasoInscripcionTile({super.key, required this.paso, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paso.color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: paso.color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: paso.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(paso.icono, color: paso.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso.titulo,
                  style: TextStyle(
                    color: paso.color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paso.descripcion,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

