import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// CONSTANTES
// ============================================================================

class _QuickActionsColors {
  static const requisitos = Color(0xFF005BAC);
  static const pagos = Color(0xFF4CAF50);
  static const certificados = Color(0xFFFFC107);
  static const escanearQR = Color(0xFFE91E63);
}

class _QuickActionsDimensions {
  static const double horizontalPadding = 20.0;
  static const double verticalPadding = 10.0;
  static const double itemSize = 64.0;
  static const double iconSize = 28.0;
  static const double borderRadius = 20.0;
  static const double labelFontSize = 11.0;
  static const Duration animationDuration = Duration(milliseconds: 600);
}

// ============================================================================
// MODELO DE DATOS
// ============================================================================

class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  final VoidCallback? customAction;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    this.route,
    this.customAction,
  });

  void execute(BuildContext context) {
    if (customAction != null) {
      customAction!();
    } else if (route != null) {
      context.push(route!);
    }
  }
}

// ============================================================================
// Widget PRINCIPAL
// ============================================================================

class QuickActions extends StatelessWidget {
  final List<QuickActionItem>? customActions;

  const QuickActions({
    super.key,
    this.customActions,
  });

  static const List<QuickActionItem> _defaultActions = [
    QuickActionItem(
      icon: Icons.assignment_rounded,
      label: 'Requisitos',
      color: _QuickActionsColors.requisitos,
      route: '/sistema/requisitos',
    ),
    QuickActionItem(
      icon: Icons.payments_rounded,
      label: 'Pagos',
      color: _QuickActionsColors.pagos,
      route: '/sistema/pagos',
    ),
    QuickActionItem(
      icon: Icons.workspace_premium_rounded,
      label: 'Certificados',
      color: _QuickActionsColors.certificados,
      route: '/sistema/certificados',
    ),
    QuickActionItem(
      icon: Icons.qr_code_scanner_rounded,
      label: 'Escanear QR',
      color: _QuickActionsColors.escanearQR,
      route: '/sistema/escanear-qr',
    ),
  ];

  List<QuickActionItem> get _actions => customActions ?? _defaultActions;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _QuickActionsDimensions.horizontalPadding,
          vertical: _QuickActionsDimensions.verticalPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _actions
              .map((action) => _QuickActionButton(item: action))
              .toList(),
        ),
      ),
    );
  }
}

// ============================================================================
// WidgetS INTERNOS
// ============================================================================

/// Botón individual de acción rápida
class _QuickActionButton extends StatelessWidget {
  final QuickActionItem item;

  const _QuickActionButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return FadeInDown(
      duration: _QuickActionsDimensions.animationDuration,
      child: GestureDetector(
        onTap: () => item.execute(context),
        child: Column(
          children: [
            _GlassContainer(
              child: Icon(
                item.icon,
                color: item.color,
                size: _QuickActionsDimensions.iconSize,
              ),
            ),
            const SizedBox(height: 8),
            _ActionLabel(text: item.label),
          ],
        ),
      ),
    );
  }
}

/// Contenedor con efecto glassmorphism
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_QuickActionsDimensions.borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: _QuickActionsDimensions.itemSize,
          height: _QuickActionsDimensions.itemSize,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(_QuickActionsDimensions.borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Etiqueta de texto para la acción
class _ActionLabel extends StatelessWidget {
  final String text;

  const _ActionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: _QuickActionsDimensions.labelFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }
}

