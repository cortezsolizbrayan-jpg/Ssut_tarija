import 'package:flutter/material.dart';

/// Tokens de diseño centralizados siguiendo el design system (Posgrado UPEA)
class DesignTokens {
  // Colores primarios UPEA
  static const Color primaryBlue = Color(0xFF305BA4);
  static const Color primaryBlueLight = Color(0xFF3D8FE0);
  static const Color lightBlue = Color(0xFF3D8FE0);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);

  // Colores de fondo (claro)
  static const Color mainBackground = Color(0xFFEEF1F8);
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Color(0xFFF8F9FB);
  static Color get headerBackground => primaryBlue.withOpacity(0.08);

  // Colores modo oscuro
  static const Color darkBackground = Color(0xFF050816);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkBorder = Color(0xFF374151);

  // Colores de borde
  static const Color defaultBorder = Color(0xFFE0E4ED);
  static const Color focusedBorder = Color(0xFF005BAC);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // Colores de texto
  static const Color primaryText = Color(0xFF333333);
  static const Color secondaryText = Color(0xFF666666);
  static const Color lightText = Color(0xFF999999);

  // Familias de fuentes
  static const String primaryFont = 'Inter';
  static const String secondaryFont = 'Poppins';
  static const String scriptFont = 'Parisienne';

  // Espaciado estándar
  static const double extraSmall = 6.0;
  static const double small = 8.0;
  static const double medium = 12.0;
  static const double large = 16.0;
  static const double extraLarge = 20.0;
  static const double xxl = 24.0;

  // Radio de borde
  static const double smallRadius = 10.0;
  static const double mediumRadius = 14.0;
  static const double largeRadius = 16.0;
  static const double extraLargeRadius = 20.0;

  // Sombras
  static List<BoxShadow> get defaultCardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get selectedCardShadow => [
        BoxShadow(
          color: primaryBlue.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  // Estilos de texto
  static const TextStyle cardTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: primaryText,
    fontFamily: secondaryFont,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: secondaryText,
    fontFamily: primaryFont,
  );

  static const TextStyle formInput = TextStyle(
    fontSize: 17,
    color: Colors.black,
    fontFamily: primaryFont,
  );

  static const TextStyle infoLabel = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: secondaryText,
    fontFamily: primaryFont,
  );

  static const TextStyle infoValue = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: primaryText,
    fontFamily: primaryFont,
  );

  // Duraciones de animación
  static const Duration fastAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // Curvas de animación
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.easeOutBack;
  static const Curve smoothCurve = Curves.easeOut;
}

/// Extensiones para facilitar el uso de los tokens
extension DesignTokensExtension on BuildContext {
  /// Obtiene el ancho responsivo para padding de formularios
  double get responsiveHorizontalPadding => MediaQuery.of(this).size.width * 0.04;
  
  /// Obtiene el alto responsivo para padding de formularios
  double get responsiveVerticalPadding => MediaQuery.of(this).size.height * 0.035;
  
  /// Verifica si es una pantalla pequeña
  bool get isSmallScreen => MediaQuery.of(this).size.width < 600;
  
  /// Verifica si es una pantalla grande
  bool get isLargeScreen => MediaQuery.of(this).size.width >= 1200;
}
