import 'package:flutter/material.dart';
import '../constants.dart';
import 'timeline_node.dart';

class VerticalTimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final MapStepStatus status;
  final bool isFirst;
  final bool isLast;

  const VerticalTimelineStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.status,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : _getLineColor(),
                  ),
                ),
                TimelineNode(status: status),
                Expanded(
                  flex: 10,
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : _getLineColor(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: MisDocumentosConstants.fontHeading,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: MisDocumentosConstants.kTextColor,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: MisDocumentosConstants.fontBody,
                    fontSize: 12,
                    color: MisDocumentosConstants.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ...children,
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLineColor() {
    switch (status) {
      case MapStepStatus.completed:
        return MisDocumentosConstants.kSuccessColor;
      case MapStepStatus.inProgress:
        return MisDocumentosConstants.kPrimaryColor;
      case MapStepStatus.pending:
        return Colors.grey.shade300;
    }
  }
}
