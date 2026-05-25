import 'package:flutter/material.dart';
import 'datos_personales_validators.dart';

class PersonalDataProgressBar extends StatelessWidget {
  final double progress;

  const PersonalDataProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Completado ${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: DatosPersonalesConstants.primaryBlue.withOpacity(0.8),
              ),
            ),
            if (progress >= 1.0)
              const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EEF7),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0
                  ? Colors.green
                  : DatosPersonalesConstants.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }
}

