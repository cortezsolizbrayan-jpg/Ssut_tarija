import 'package:flutter/material.dart';
import '../constants.dart';

enum MapStepStatus { pending, inProgress, completed }

class TimelineNode extends StatelessWidget {
  final MapStepStatus status;

  const TimelineNode({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    double size = 28;

    switch (status) {
      case MapStepStatus.completed:
        color = MisDocumentosConstants.kSuccessColor;
        icon = Icons.check_circle_rounded;
        break;
      case MapStepStatus.inProgress:
        color = MisDocumentosConstants.kPrimaryColor;
        icon = Icons.pending_actions_rounded;
        break;
      case MapStepStatus.pending:
        color = Colors.grey.shade400;
        icon = Icons.circle_outlined;
        size = 20;
        break;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: status == MapStepStatus.pending ? Colors.white : color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: status == MapStepStatus.pending ? Border.all(color: color, width: 2) : null,
      ),
      child: Center(
        child: Icon(
          icon,
          color: color,
          size: size * 0.7,
        ),
      ),
    );
  }
}
