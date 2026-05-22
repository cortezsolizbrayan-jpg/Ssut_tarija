import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiplomadoCard extends StatefulWidget {
  const DiplomadoCard({
    super.key,
    required this.tipo,
    required this.titulo,
    this.subtitulo,
    this.saldoPendiente,
    required this.progresoPago,
    this.estaCompletado = false,
    this.modalidad,
    this.duracion,
    this.creditos,
  });

  final String tipo;
  final String titulo;
  final String? subtitulo;
  final double? saldoPendiente;
  final double progresoPago; // Valor entre 0 y 100
  final bool estaCompletado;
  final String? modalidad;
  final String? duracion;
  final int? creditos;

  @override
  State<DiplomadoCard> createState() => _DiplomadoCardState();
}

class _DiplomadoCardState extends State<DiplomadoCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progressValue = (widget.progresoPago / 100).clamp(0.0, 1.0);

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: AnimatedScale(
        scale: _isHovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: Card(
          color: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: _isHovered ? 5 : 2,
          shadowColor: colorScheme.primary.withOpacity(0.18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _goToDetallePrograma,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.95),
                          colorScheme.primary.withOpacity(0.55),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.tipo),
                        labelStyle: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        side: BorderSide.none,
                        backgroundColor: colorScheme.primaryContainer,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      const Spacer(),
                      _buildStatusPill(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.titulo,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                      color: const Color(0xFF1C1B1F),
                      letterSpacing: 0.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.subtitulo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitulo!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF5F6368),
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.modalidad != null)
                        _buildInfoChip(Icons.public_rounded, widget.modalidad!),
                      if (widget.duracion != null)
                        _buildInfoChip(Icons.schedule_rounded, widget.duracion!),
                      if (widget.creditos != null)
                        _buildInfoChip(
                          Icons.auto_stories_rounded,
                          '${widget.creditos} créditos',
                        ),
                    ],
                  ),
                  if (!widget.estaCompletado && widget.saldoPendiente != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEF0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFFCCD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 18,
                            color: Color(0xFFD32F2F),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Saldo pendiente: ${widget.saldoPendiente!.toInt()} Bs.',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFB71C1C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Progreso de pago',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5F6368),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${widget.progresoPago.toInt()}%',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: widget.estaCompletado
                              ? const Color(0xFF2E7D32)
                              : colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: progressValue),
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 9,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.estaCompletado
                              ? const Color(0xFF2E7D32)
                              : colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _goToDetallePrograma,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text(
                        'Ver Programa',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _goToDetallePrograma() {
    context.push(
      '/detalle-programa',
      extra: {'titulo': widget.titulo, 'tipo': widget.tipo},
    );
  }

  Widget _buildStatusPill() {
    if (widget.estaCompletado) {
      return _pill(
        label: 'Completado',
        icon: Icons.check_circle_rounded,
        bg: const Color(0xFFE8F5E9),
        fg: const Color(0xFF2E7D32),
      );
    }
    return _pill(
      label: 'En curso',
      icon: Icons.timelapse_rounded,
      bg: const Color(0xFFE3F2FD),
      fg: const Color(0xFF1565C0),
    );
  }

  Widget _pill({
    required String label,
    required IconData icon,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

