import 'package:flutter/material.dart';
import '../constants.dart';

class ProgressCard extends StatelessWidget {
  final double progress;
  final int done;
  final int total;
  final bool ciOk;
  final bool tituloOk;
  final bool prorrogaOk;

  const ProgressCard({
    super.key,
    required this.progress,
    required this.done,
    required this.total,
    required this.ciOk,
    required this.tituloOk,
    required this.prorrogaOk,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MisDocumentosConstants.kPrimaryColor, Color(0xFF1976D2)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: MisDocumentosConstants.kPrimaryColor.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assignment_turned_in_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progreso Total',
                      style: TextStyle(
                        fontFamily: MisDocumentosConstants.fontHeading,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '$done de $total hitos completados',
                      style: TextStyle(
                        fontFamily: MisDocumentosConstants.fontBody,
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: MisDocumentosConstants.kAccentColor.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: MisDocumentosConstants.fontHeading,
                    color: MisDocumentosConstants.kPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 14,
                    width: maxWidth,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.fastOutSlowIn,
                    height: 14,
                    width: maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [MisDocumentosConstants.kAccentColor, Color(0xFFFFD54F)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
