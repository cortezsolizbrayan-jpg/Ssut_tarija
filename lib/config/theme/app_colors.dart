import 'package:flutter/material.dart';

/// Extensión de contexto para acceder a los colores adaptativos del tema.
///
/// Uso:
///   context.colors.background   → fondo principal
///   context.colors.surface      → fondo de tarjetas
///   context.colors.primary      → azul institucional
///   context.colors.onSurface    → texto principal
///
extension AppColorsExtension on BuildContext {
  AppColors get colors => AppColors.of(this);
}

/// Paleta de colores adaptativa claro/oscuro.
class AppColors {
  final bool isDark;

  const AppColors._(this.isDark);

  factory AppColors.of(BuildContext context) {
    return AppColors._(Theme.of(context).brightness == Brightness.dark);
  }

  // ── Fondos ────────────────────────────────────────────────────────────────
  /// Fondo principal del Scaffold
  Color get background => isDark
      ? const Color(0xFF0D1B2E) // azul marino profundo
      : const Color(0xFFEEF1F8); // gris azulado claro

  /// Fondo de superficies (AppBar secundario, drawers)
  Color get surface => isDark
      ? const Color(0xFF132338) // azul marino medio
      : const Color(0xFFF8F9FB); // blanco azulado

  /// Fondo de tarjetas / contenedores elevados
  Color get card => isDark
      ? const Color(0xFF1A2E47) // azul marino claro
      : Colors.white;

  /// Fondo de tarjetas secundarias / inputs
  Color get cardAlt => isDark
      ? const Color(0xFF1F3554) // azul marino más claro
      : const Color(0xFFF0F4F8);

  // ── Bordes ────────────────────────────────────────────────────────────────
  Color get border =>
      isDark ? const Color(0xFF2A4A6B) : const Color(0xFFE0E4ED);

  Color get borderLight =>
      isDark ? const Color(0xFF1E3A55) : const Color(0xFFF0F4F8);

  // ── Texto ─────────────────────────────────────────────────────────────────
  Color get textPrimary => isDark
      ? const Color(0xFFE8F0FA) // blanco azulado
      : const Color(0xFF1A2E47); // azul marino oscuro

  Color get textSecondary => isDark
      ? const Color(0xFF8BAFD4) // gris azulado
      : const Color(0xFF5A7A9A); // azul grisáceo

  Color get textHint =>
      isDark ? const Color(0xFF4A6A8A) : const Color(0xFF9BAFC0);

  // ── Colores institucionales ───────────────────────────────────────────────
  /// Azul institucional UPEA — igual en ambos modos
  Color get primary => const Color(0xFF005BAC);

  /// Acento azul — más brillante en oscuro para mejor contraste
  Color get accent => isDark
      ? const Color(0xFF4DA6FF) // azul brillante
      : const Color(0xFF005BAC); // azul institucional

  Color get accentLight => isDark
      ? const Color(0xFF4DA6FF).withOpacity(0.18)
      : const Color(0xFF005BAC).withOpacity(0.10);

  // ── Sombras ───────────────────────────────────────────────────────────────
  Color get shadow =>
      isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.08);

  // ── Estados ───────────────────────────────────────────────────────────────
  Color get success => const Color(0xFF4CAF50);
  Color get warning => const Color(0xFFFF9800);
  Color get error => isDark ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

  // ── Helpers ───────────────────────────────────────────────────────────────
  /// Devuelve un color con opacidad adaptada al modo
  Color withAdaptiveOpacity(
    Color base, {
    double light = 0.1,
    double dark = 0.18,
  }) {
    return base.withOpacity(isDark ? dark : light);
  }

  /// Gradiente del header institucional (igual en ambos modos)
  LinearGradient get headerGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF005BAC), Color(0xFF004A86)],
  );

  /// Gradiente de fondo para tarjetas en modo oscuro
  LinearGradient get cardGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2E47), Color(0xFF132338)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8F9FB)],
        );
}
