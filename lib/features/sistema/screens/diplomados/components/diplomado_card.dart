import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiplomadoCard extends StatelessWidget {
  const DiplomadoCard({
    super.key,
    required this.tipo,
    required this.titulo,
    this.saldoPendiente,
    required this.progresoPago,
    this.estaCompletado = false,
  });

  final String tipo;
  final String titulo;
  final double? saldoPendiente;
  final double progresoPago; // Valor entre 0 y 100
  final bool estaCompletado;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge de tipo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tipo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Título
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Estado o saldo pendiente
          if (estaCompletado)
            Row(
              children: [
                const Text(
                  'Completado: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ...List.generate(5, (index) {
                  return const Icon(Icons.star, color: Colors.green, size: 18);
                }),
              ],
            )
          else if (saldoPendiente != null)
            Text(
              'Saldo Pendiente: ${saldoPendiente!.toInt()} Bs.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
          // Progreso del pago con mascota
          Row(
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
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progresoPago / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          estaCompletado
                              ? Colors.green
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Mascota
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF87CEEB).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    estaCompletado ? '🎓' : '🎓',
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botón Ver Programa
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push(
                  '/detalle-programa',
                  extra: {'titulo': titulo, 'tipo': tipo},
                );
              },
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
          ),
        ],
      ),
    );
  }
}
