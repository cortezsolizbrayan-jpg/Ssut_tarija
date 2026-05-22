import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/animations/enhanced_animations.dart';

class MisProgramasCard extends StatefulWidget {
  const MisProgramasCard({
    super.key,
    required this.programa,
    required this.onTap,
    required this.index,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  final dynamic programa;
  final VoidCallback onTap;
  final int index;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  @override
  State<MisProgramasCard> createState() => _MisProgramasCardState();
}

class _MisProgramasCardState extends State<MisProgramasCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estaCompletado =
        widget.programa.estado.contains('ESTADO_COMPLETO') ||
        widget.programa.estado.contains('COMPLETADO');
    final progresoPago = estaCompletado ? 100.0 : 65.0; // Simulado

    return RepaintBoundary(
      child: GestureDetector(
        onTapDown: (_) {
          setState(() => _isPressed = true);
          _controller.forward();
        },
        onTapUp: (_) {
          setState(() => _isPressed = false);
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () {
          setState(() => _isPressed = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, hijo) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
                    boxShadow: [
                      BoxShadow(
                        color: _isPressed
                            ? DesignTokens.primaryBlue.withOpacity(0.3)
                            : Colors.black.withOpacity(0.08),
                        blurRadius: _isPressed ? 20 : 10,
                        spreadRadius: _isPressed ? 2 : 0,
                        offset: Offset(0, _isPressed ? 8 : 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: DesignTokens.large),
                      _buildTitle(),
                      const SizedBox(height: DesignTokens.medium),
                      _buildInfoRow(),
                      const SizedBox(height: DesignTokens.large),
                      _buildStatusBadge(estaCompletado),
                      const SizedBox(height: DesignTokens.large),
                      _buildPaymentProgress(progresoPago, estaCompletado),
                      const SizedBox(height: DesignTokens.large),
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3A5C),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.programa.tipo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (widget.programa.descuento != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.programa.descuento!.toInt()}% desc.',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (widget.onFavoriteToggle != null)
          GestureDetector(
            onTap: widget.onFavoriteToggle,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.isFavorite ? Colors.red.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: widget.isFavorite ? Colors.red : Colors.grey.shade600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.programa.titulo,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          widget.programa.duracion,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 16),
        Icon(Icons.school, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(
          widget.programa.modalidad,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool estaCompletado) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: estaCompletado
            ? Colors.green.shade50
            : widget.programa.estado.contains('ABIERTAS')
                ? Colors.blue.shade50
                : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.programa.estado,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: estaCompletado
              ? Colors.green.shade700
              : widget.programa.estado.contains('ABIERTAS')
                  ? Colors.blue.shade700
                  : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _buildPaymentProgress(double progresoPago, bool estaCompletado) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progreso del Pago',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: DesignTokens.small),
              SmoothProgressIndicator(
                value: progresoPago / 100,
                height: 10,
                color: estaCompletado ? DesignTokens.successGreen : DesignTokens.primaryBlue,
                backgroundColor: Colors.grey.shade100,
                showShimmer: !estaCompletado,
              ),
              const SizedBox(height: 4),
              Text(
                '${progresoPago.toInt()}%',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1A3A5C).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              estaCompletado ? '🎓' : '📚',
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Ver Programa',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

