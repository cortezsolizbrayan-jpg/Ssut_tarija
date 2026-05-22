import 'package:flutter/material.dart';

/// 🎨 COLORES DEL SISTEMA UPEA
/// 
/// Centralización de todos los colores utilizados en la aplicación
/// para evitar duplicación y facilitar el mantenimiento.
abstract class AppColorsEscaneo {
  // Colores primarios
  static const Color kPrimaryColor = Color(0xFF2563EB);
  static const Color kPrimaryDark = Color(0xFF1E3A8A);
  
  // Colores de superficie y fondo
  static const Color kSurfaceColor = Color(0xFFF8FAFC);
  static const Color kCardColor = Colors.white;
  
  // Colores de texto
  static const Color kTextColor = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  
  // Colores de estado y semánticos
  static const Color kSuccessColor = Color(0xFF10B981);
  static const Color kErrorColor = Color(0xFFEF4444);
  static const Color kWarningColor = Color(0xFFF59E0B);
  static const Color kInfoColor = Color(0xFF3B82F6);
  
  // Colores de borde
  static const Color kBorderColor = Color(0xFFE2E8F0);
}

