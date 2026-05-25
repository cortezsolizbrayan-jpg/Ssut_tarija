import 'package:flutter/material.dart';

/// Tarjeta de detalle de matrícula con información de pago
class MatriculaDetailCard extends StatelessWidget {
  final String matriculaNumber;
  final String concepto;
  final DateTime fechaVencimiento;
  final double montoDdeuda;
  final DateTime? fechaPago;
  final String? coordinador;
  final bool isPagado;
  final VoidCallback? onFacturaPressed;

  const MatriculaDetailCard({
    super.key,
    required this.matriculaNumber,
    required this.concepto,
    required this.fechaVencimiento,
    required this.montoDdeuda,
    this.fechaPago,
    this.coordinador,
    this.isPagado = false,
    this.onFacturaPressed,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005BAC);
    const successGreen = Color(0xFF4CAF50);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPagado
              ? primaryBlue.withOpacity(0.3)
              : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con número de matrícula
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Matrícula Nro. $matriculaNumber',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),

          // Contenido
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Concepto de pago
                _buildInfoRow('Concepto de Pago:', concepto),
                const SizedBox(height: 8),

                // Fecha de vencimiento
                _buildInfoRow(
                  'Fecha de Vencimiento:',
                  _formatDate(fechaVencimiento),
                ),
                const SizedBox(height: 8),

                // Monto de deuda
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        'Monto de deuda:',
                        '${montoDdeuda.toStringAsFixed(0)} bs.',
                        valueStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),

                    // Estado de pago
                    if (isPagado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: successGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: successGreen,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pagado',
                              style: TextStyle(
                                color: successGreen,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 8),

                // Fecha de pago (si existe)
                if (fechaPago != null)
                  _buildInfoRow('Fecha de Pago:', _formatDate(fechaPago!)),

                if (fechaPago != null) const SizedBox(height: 12),

                // Responsable del registro
                if (coordinador != null) ...[
                  const Divider(height: 24),
                  Text(
                    'Responsable del Registro de pago:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Coordinador: $coordinador',
                    style: const TextStyle(
                      fontSize: 14,
                      color: primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Botones
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Botón Pagado (deshabilitado si ya está pagado)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isPagado ? null : () {},
                        icon: Icon(
                          isPagado ? Icons.check : Icons.payment,
                          size: 18,
                        ),
                        label: const Text('Pagado'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPagado
                              ? Colors.grey[400]
                              : primaryBlue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[400],
                          disabledForegroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: isPagado ? 0 : 2,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Botón Factura
                    ElevatedButton.icon(
                      onPressed: onFacturaPressed,
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Factura'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF666666),
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          TextSpan(
            text: value,
            style:
                valueStyle ??
                const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}

