import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class PremiumAlerts {
  /// Muestra un Snackbar premium con diseño moderno y animado
  static void showSnackBar(
    BuildContext context, {
    required String message,
    required String title,
    IconData icon = Icons.info_outline,
    Color color = const Color(0xFF305BA4),
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      duration: duration,
      content: FadeInUp(
        duration: const Duration(milliseconds: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          message,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Muestra un éxito con estilo premium
  static void showSuccess(BuildContext context, String message, {String title = "Éxito"}) {
    showSnackBar(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_outline,
      color: const Color(0xFF4CAF50),
    );
  }

  /// Muestra un error con estilo premium
  static void showError(BuildContext context, String message, {String title = "Error"}) {
    showSnackBar(
      context,
      title: title,
      message: message,
      icon: Icons.error_outline,
      color: const Color(0xFFE53935),
    );
  }

  /// Muestra una advertencia con estilo premium
  static void showWarning(BuildContext context, String message, {String title = "Atención"}) {
    showSnackBar(
      context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFFFA000),
    );
  }

  /// Muestra un diálogo premium persistente (estilo Glassmorphism)
  static Future<void> showPremiumDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
            ),
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              contentPadding: EdgeInsets.zero,
              content: getPremiumDialogWidget(
                context,
                title: title,
                message: message,
                icon: icon,
                color: color,
                primaryButtonText: primaryButtonText,
                onPrimaryPressed: onPrimaryPressed,
                secondaryButtonText: secondaryButtonText,
                onSecondaryPressed: onSecondaryPressed,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Retorna el widget del diálogo premium para uso personalizado
  static Widget getPremiumDialogWidget(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    Widget? customHeader,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customHeader != null) customHeader,
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (customHeader == null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 40),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (primaryButtonText != null)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (onPrimaryPressed == null) {
                              Navigator.pop(context);
                            } else {
                              onPrimaryPressed.call();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            primaryButtonText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    if (secondaryButtonText != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          if (onSecondaryPressed == null) {
                            Navigator.pop(context);
                          } else {
                            onSecondaryPressed.call();
                          }
                        },
                        child: Text(
                          secondaryButtonText,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
