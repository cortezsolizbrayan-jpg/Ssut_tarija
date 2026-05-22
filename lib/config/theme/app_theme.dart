import 'package:flutter/material.dart';

/// Temas de la aplicación con colores institucionales UPEA.
/// El modo oscuro usa azul marino profundo — no negro puro.
class AppTheme {
  // ── Colores institucionales ───────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF005BAC);
  static const Color primaryBlueDark = Color(0xFF003F7A);
  static const Color lightBlue = Color(0xFF3D8FE0);
  static const Color accentBlue = Color(0xFF5BA3E8);
  static const Color successGreen = Color(0xFF4CAF50);

  // ── Modo claro ────────────────────────────────────────────────────────────
  static const Color _lBg = Color(0xFFEEF1F8);
  static const Color _lSurface = Color(0xFFF8F9FB);
  static const Color _lCard = Color(0xFFFFFFFF);
  static const Color _lBorder = Color(0xFFE0E4ED);
  static const Color _lText = Color(0xFF1A2E47);
  static const Color _lTextSub = Color(0xFF5A7A9A);

  // ── Modo nocturno azul ────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1B2E); // azul marino profundo
  static const Color darkSurface = Color(0xFF132338); // azul marino medio
  static const Color darkCard = Color(0xFF1A2E47); // azul marino claro
  static const Color darkCardAlt = Color(0xFF1F3554); // tarjetas secundarias
  static const Color darkBorder = Color(0xFF2A4A6B); // bordes azulados
  static const Color darkTextPrimary = Color(0xFFE8F0FA); // blanco azulado
  static const Color darkTextSecondary = Color(0xFF8BAFD4); // gris azulado
  static const Color darkAccent = Color(0xFF4DA6FF); // azul brillante

  // ── Acceso público para compatibilidad ───────────────────────────────────
  static const Color lightBackground = _lBg;
  static const Color lightSurface = _lSurface;
  static const Color lightCard = _lCard;
  static const Color lightBorder = _lBorder;
  static const Color lightTextPrimary = _lText;
  static const Color lightTextSecondary = _lTextSub;

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA CLARO
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryBlue,
      primary: primaryBlue,
      secondary: successGreen,
      surface: _lSurface,
      background: _lBg,
      brightness: Brightness.light,
      error: const Color(0xFFDC2626),
    ),
    scaffoldBackgroundColor: _lBg,
    canvasColor: _lBg,
    cardColor: _lCard,
    dialogBackgroundColor: _lCard,
    fontFamily: 'Intel',
    textTheme: _lightText,
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shadowColor: Color(0x14000000),
      color: _lCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      textColor: _lText,
      iconColor: primaryBlue,
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      textColor: _lText,
      iconColor: primaryBlue,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _lCard,
      modalBackgroundColor: _lCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: BorderSide(color: primaryBlue, width: 2),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lCard,
      errorStyle: TextStyle(height: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _lBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    dividerTheme: DividerThemeData(color: _lBorder, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: _lText, size: 24),
    chipTheme: ChipThemeData(
      backgroundColor: _lCard,
      selectedColor: primaryBlue.withOpacity(0.12),
      labelStyle: TextStyle(color: _lText),
      side: BorderSide(color: _lBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
        (s) => s.contains(MaterialState.selected)
            ? primaryBlue
            : Colors.grey.shade400,
      ),
      trackColor: MaterialStateProperty.resolveWith(
        (s) => s.contains(MaterialState.selected)
            ? primaryBlue.withOpacity(0.35)
            : Colors.grey.shade300,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _lCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        color: _lText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(color: _lTextSub, fontSize: 14),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lText,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: _lCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(color: _lText),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android:
            ZoomPageTransitionsBuilder(), // Más fluido que FadeUpwards
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEMA NOCTURNO AZUL
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    // colorScheme completo — propaga colores a todos los widgets Material
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: darkAccent,
      onPrimary: Colors.white,
      primaryContainer: darkCardAlt,
      onPrimaryContainer: darkTextPrimary,
      secondary: successGreen,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF1A3A2A),
      onSecondaryContainer: Color(0xFFA8D5B5),
      tertiary: accentBlue,
      onTertiary: Colors.white,
      tertiaryContainer: darkCard,
      onTertiaryContainer: darkTextPrimary,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: Color(0xFF3B1010),
      onErrorContainer: Color(0xFFFFB4AB),
      background: darkBackground,
      onBackground: darkTextPrimary,
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceVariant: darkCard,
      onSurfaceVariant: darkTextSecondary,
      outline: darkBorder,
      outlineVariant: Color(0xFF1E3A55),
      shadow: Color(0x8C000000),
      scrim: Color(0x8C000000),
      inverseSurface: darkTextPrimary,
      onInverseSurface: darkBackground,
      inversePrimary: primaryBlue,
    ),

    // Colores globales — cubren widgets que no usan colorScheme directamente
    scaffoldBackgroundColor: darkBackground,
    canvasColor: darkBackground, // fondo de Drawer, DropdownMenu, etc.
    cardColor: darkCard, // Card, AlertDialog, etc.
    dialogBackgroundColor: darkCard, // AlertDialog, SimpleDialog
    hintColor: darkTextSecondary,

    fontFamily: 'Intel',
    textTheme: _darkText,

    // ── AppBar ──────────────────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: darkSurface,
      foregroundColor: darkTextPrimary,
      iconTheme: IconThemeData(color: darkAccent),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        fontFamily: 'Poppins',
      ),
    ),

    // ── Cards ───────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: Color(0x61000000),
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: darkBorder, width: 0.5),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),

    // ── ListTile — cubre listas con fondo blanco ────────────────────────────
    listTileTheme: const ListTileThemeData(
      tileColor: Colors.transparent,
      selectedTileColor: Color(0x1A4DA6FF),
      textColor: darkTextPrimary,
      iconColor: darkAccent,
    ),

    // ── ExpansionTile ───────────────────────────────────────────────────────
    expansionTileTheme: const ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      textColor: darkTextPrimary,
      iconColor: darkAccent,
      collapsedTextColor: darkTextPrimary,
      collapsedIconColor: darkTextSecondary,
    ),

    // ── BottomSheet — cubre modales con fondo blanco ────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCard,
      modalBackgroundColor: darkCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // ── Drawer ──────────────────────────────────────────────────────────────
    drawerTheme: const DrawerThemeData(
      backgroundColor: darkSurface,
      scrimColor: Color(0x8C000000),
    ),

    // ── BottomNavigationBar ─────────────────────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      selectedItemColor: darkAccent,
      unselectedItemColor: darkTextSecondary,
      elevation: 8,
    ),

    // ── NavigationBar (Material 3) ──────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      indicatorColor: Color(0x334DA6FF),
      iconTheme: MaterialStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(MaterialState.selected)
              ? darkAccent
              : darkTextSecondary,
        ),
      ),
      labelTextStyle: MaterialStateProperty.resolveWith(
        (s) => TextStyle(
          color: s.contains(MaterialState.selected)
              ? darkAccent
              : darkTextSecondary,
          fontWeight: s.contains(MaterialState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
          fontSize: 12,
        ),
      ),
    ),

    // ── Buttons ─────────────────────────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkAccent,
        side: BorderSide(color: darkAccent, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: darkAccent),
    ),

    // ── Inputs ──────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      errorStyle: TextStyle(height: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: darkAccent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Color(0xFFEF4444)),
      ),
      hintStyle: TextStyle(color: darkTextSecondary),
      labelStyle: TextStyle(color: darkTextSecondary),
      prefixIconColor: darkTextSecondary,
      suffixIconColor: darkTextSecondary,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // ── Chips ───────────────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: darkCard,
      selectedColor: Color(0x404DA6FF),
      labelStyle: TextStyle(color: darkTextPrimary),
      side: BorderSide(color: darkBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),

    // ── Switch ──────────────────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith(
        (s) =>
            s.contains(MaterialState.selected) ? darkAccent : darkTextSecondary,
      ),
      trackColor: MaterialStateProperty.resolveWith(
        (s) =>
            s.contains(MaterialState.selected) ? Color(0x594DA6FF) : darkBorder,
      ),
    ),

    // ── Divider ─────────────────────────────────────────────────────────────
    dividerTheme: DividerThemeData(color: darkBorder, thickness: 1, space: 1),
    iconTheme: IconThemeData(color: darkTextPrimary, size: 24),

    // ── Dialog ──────────────────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        color: darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(color: darkTextSecondary, fontSize: 14),
    ),

    // ── SnackBar ─────────────────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardAlt,
      contentTextStyle: TextStyle(color: darkTextPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),

    // ── PopupMenu ────────────────────────────────────────────────────────────
    popupMenuTheme: PopupMenuThemeData(
      color: darkCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: TextStyle(color: darkTextPrimary),
    ),

    // ── TabBar ───────────────────────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      labelColor: darkAccent,
      unselectedLabelColor: darkTextSecondary,
      indicatorColor: darkAccent,
    ),

    // ── ProgressIndicator ────────────────────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: darkAccent,
      linearTrackColor: darkBorder,
      circularTrackColor: darkBorder,
    ),

    // ── Checkbox / Radio ─────────────────────────────────────────────────────
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith(
        (s) => s.contains(MaterialState.selected)
            ? darkAccent
            : Colors.transparent,
      ),
      checkColor: MaterialStateProperty.all(Colors.white),
      side: BorderSide(color: darkBorder, width: 1.5),
    ),
    radioTheme: RadioThemeData(
      fillColor: MaterialStateProperty.resolveWith(
        (s) =>
            s.contains(MaterialState.selected) ? darkAccent : darkTextSecondary,
      ),
    ),

    // ── Slider ───────────────────────────────────────────────────────────────
    sliderTheme: const SliderThemeData(
      activeTrackColor: darkAccent,
      inactiveTrackColor: darkBorder,
      thumbColor: darkAccent,
      overlayColor: Color(0x1A4DA6FF),
    ),

    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT THEMES
  // ═══════════════════════════════════════════════════════════════════════════
  static const TextTheme _lightText = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
      color: _lText,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
      color: _lText,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
      color: _lText,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: _lText,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: _lText,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _lText,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: _lText,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: _lText,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: _lTextSub,
    ),
  );

  static const TextTheme _darkText = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
      color: darkTextPrimary,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
      color: darkTextPrimary,
    ),
    displaySmall: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      fontFamily: 'Poppins',
      color: darkTextPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: darkTextPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: darkTextPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: darkTextPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: darkTextPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: darkTextPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: darkTextSecondary,
    ),
  );
}
