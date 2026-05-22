import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class IdentityStepIndicator extends StatelessWidget {
  final int currentStep;
  const IdentityStepIndicator({super.key, required this.currentStep});

  static const Color primaryBlue = Color(0xFF305BA4);

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 600),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _stepItem(context, 1, "Captura", currentStep >= 1),
          _stepLine(context, currentStep >= 2),
          _stepItem(context, 2, "Análisis", currentStep >= 2),
          _stepLine(context, currentStep >= 3),
          _stepItem(context, 3, "Validación", currentStep >= 3),
        ],
      ),
    );
  }

  Widget _stepItem(BuildContext context, int step, String label, bool active) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: ResponsiveUtils.scale(context, 35),
          height: ResponsiveUtils.scale(context, 35),
          decoration: BoxDecoration(
            color: active ? primaryBlue : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: active ? primaryBlue : Colors.grey[300]!, width: 2),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: active ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveUtils.scale(context, 11),
            color: active ? primaryBlue : Colors.grey,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(BuildContext context, bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 25, left: 10, right: 10),
        color: active ? primaryBlue : Colors.grey[200],
      ),
    );
  }
}

