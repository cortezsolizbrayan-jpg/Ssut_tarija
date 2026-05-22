import 'package:flutter/material.dart';

class PersonalDataResponsiveGroup extends StatelessWidget {
  final List<Widget> children;
  final double width;

  const PersonalDataResponsiveGroup({
    super.key,
    required this.children,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isLandscape = width > height;
    final isTablet = width > 600;
    final isSmallPantalla = width < 500;

    if (isSmallPantalla) {
      return Column(
        children: children
            .map(
              (hijo) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: hijo,
              ),
            )
            .toList(),
      );
    }

    if (isLandscape && isTablet && children.length >= 3) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index < children.length - 1 ? 16 : 0,
              ),
              child: child,
            ),
          );
        }).toList(),
      );
    }

    if (isTablet && children.length == 2) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 16),
          Expanded(child: children[1]),
        ],
      );
    }

    if (children.length >= 3) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[0]),
              const SizedBox(width: 16),
              Expanded(child: children[1]),
            ],
          ),
          const SizedBox(height: 16),
          children.length > 2 ? children[2] : const SizedBox.shrink(),
          if (children.length > 3)
            ...children
                .sublist(3)
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: c,
                  ),
                ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 16),
        Expanded(
          child: children.length > 1 ? children[1] : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

