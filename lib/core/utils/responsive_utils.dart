import 'package:flutter/material.dart';

/// Utilidades para diseño responsive en múltiples dispositivos
/// Soporta: Teléfonos, Tablets, Tablets grandes, Desktop
class ResponsiveUtils {
  // ══════════════════════════════════════════════════════════════════════════
  // BREAKPOINTS (Puntos de quiebre para diferentes dispositivos)
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Ancho mínimo para tablet (7-8 pulgadas)
  static const double tabletBreakpoint = 600.0;
  
  /// Ancho mínimo para tablet grande (10+ pulgadas)
  static const double largeTabletBreakpoint = 900.0;
  
  /// Ancho mínimo para desktop
  static const double desktopBreakpoint = 1200.0;

  // ══════════════════════════════════════════════════════════════════════════
  // DETECCIÓN DE TIPO DE DISPOSITIVO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Verifica si el dispositivo es un teléfono móvil
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Verifica si el dispositivo es una tablet (7-10 pulgadas)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < largeTabletBreakpoint;
  }

  /// Verifica si el dispositivo es una tablet grande (10+ pulgadas)
  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= largeTabletBreakpoint && width < desktopBreakpoint;
  }

  /// Verifica si el dispositivo es desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Verifica si es tablet o más grande
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // VALORES RESPONSIVE SEGÚN DISPOSITIVO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Retorna un valor según el tipo de dispositivo
  static T valueByDevice<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? largeTablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isLargeTablet(context) && largeTablet != null) return largeTablet;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PADDING Y MÁRGENES RESPONSIVE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Padding horizontal responsive
  static double horizontalPadding(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 16.0,
      tablet: 32.0,
      largeTablet: 48.0,
      desktop: 64.0,
    );
  }

  /// Padding vertical responsive
  static double verticalPadding(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      largeTablet: 32.0,
      desktop: 40.0,
    );
  }

  /// Espaciado entre cards responsive
  static double cardSpacing(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      largeTablet: 20.0,
      desktop: 24.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAMAÑOS DE FUENTE RESPONSIVE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Tamaño de fuente para títulos principales
  static double titleFontSize(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 24.0,
      tablet: 28.0,
      largeTablet: 32.0,
      desktop: 36.0,
    );
  }

  /// Tamaño de fuente para subtítulos
  static double subtitleFontSize(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 18.0,
      tablet: 20.0,
      largeTablet: 22.0,
      desktop: 24.0,
    );
  }

  /// Tamaño de fuente para texto normal
  static double bodyFontSize(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 14.0,
      tablet: 15.0,
      largeTablet: 16.0,
      desktop: 16.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ANCHO MÁXIMO DE CONTENIDO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Ancho máximo para contenido (evita que se estire demasiado en pantallas grandes)
  static double maxContentWidth(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: double.infinity,
      tablet: 800.0,
      largeTablet: 1000.0,
      desktop: 1200.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // NÚMERO DE COLUMNAS PARA GRIDS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Número de columnas para grid de cards
  static int gridColumns(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 1,
      tablet: 2,
      largeTablet: 3,
      desktop: 4,
    );
  }

  /// Número de columnas para grid de programas
  static int programGridColumns(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 1,
      tablet: 2,
      largeTablet: 2,
      desktop: 3,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ORIENTACIÓN DEL DISPOSITIVO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Verifica si el dispositivo está en modo horizontal
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Verifica si el dispositivo está en modo vertical
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAMAÑOS DE ICONOS RESPONSIVE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Tamaño de ícono pequeño
  static double smallIconSize(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 18.0,
      tablet: 20.0,
      largeTablet: 22.0,
      desktop: 24.0,
    );
  }

  /// Tamaño de ícono mediano
  static double mediumIconSize(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 24.0,
      tablet: 28.0,
      largeTablet: 32.0,
      desktop: 36.0,
    );
  }

  /// Tamaño de ícono grande
  static double largeIconSize(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 48.0,
      tablet: 56.0,
      largeTablet: 64.0,
      desktop: 72.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ALTURA DE BOTONES RESPONSIVE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Altura de botón estándar
  static double buttonHeight(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 48.0,
      tablet: 52.0,
      largeTablet: 56.0,
      desktop: 60.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS RESPONSIVE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Border radius para cards
  static double cardBorderRadius(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 16.0,
      tablet: 18.0,
      largeTablet: 20.0,
      desktop: 24.0,
    );
  }

  /// Border radius para botones
  static double buttonBorderRadius(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 10.0,
      tablet: 12.0,
      largeTablet: 14.0,
      desktop: 16.0,
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // INFORMACIÓN DEL DISPOSITIVO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Obtiene el nombre del tipo de dispositivo actual
  static String getDeviceType(BuildContext context) {
    if (isDesktop(context)) return 'Desktop';
    if (isLargeTablet(context)) return 'Tablet Grande';
    if (isTablet(context)) return 'Tablet';
    return 'Móvil';
  }

  /// Obtiene información completa del dispositivo
  static Map<String, dynamic> getDeviceInfo(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return {
      'type': getDeviceType(context),
      'width': size.width,
      'height': size.height,
      'orientation': isLandscape(context) ? 'Horizontal' : 'Vertical',
      'pixelRatio': MediaQuery.of(context).devicePixelRatio,
    };
  }

  /// Escala un tamaño base según ancho de pantalla, con límites seguros.
  static double scale(
    BuildContext context,
    double base, {
    double minFactor = 0.88,
    double maxFactor = 1.25,
  }) {
    final width = MediaQuery.of(context).size.width;
    final factor = (width / 390.0).clamp(minFactor, maxFactor);
    return base * factor;
  }

  /// Devuelve una altura de tarjeta/preview de documento adaptable.
  static double docCardHeight(BuildContext context) {
    return valueByDevice(
      context: context,
      mobile: 170.0,
      tablet: 210.0,
      largeTablet: 230.0,
      desktop: 250.0,
    );
  }

  /// Columnas adaptativas por ancho para grids simples.
  static int adaptiveColumnsByWidth(
    BuildContext context, {
    double minTileWidth = 220,
    int minColumns = 1,
    int maxColumns = 6,
  }) {
    final width = MediaQuery.of(context).size.width;
    final cols = (width / minTileWidth).floor();
    return cols.clamp(minColumns, maxColumns);
  }
}

/// Widget que adapta su contenido según el tipo de dispositivo
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? largeTablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.largeTablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.valueByDevice(
      context: context,
      mobile: mobile,
      tablet: tablet,
      largeTablet: largeTablet,
      desktop: desktop,
    );
  }
}

/// Widget que centra el contenido y limita su ancho máximo
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveUtils.maxContentWidth(context),
        ),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.horizontalPadding(context),
            ),
        child: child,
      ),
    );
  }
}

/// Widget para crear grids responsive
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? largeTabletColumns;
  final int? desktopColumns;
  final double? spacing;
  final double? runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.largeTabletColumns,
    this.desktopColumns,
    this.spacing,
    this.runSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final columns = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      largeTablet: largeTabletColumns ?? 3,
      desktop: desktopColumns ?? 4,
    );

    final effectiveSpacing = spacing ?? ResponsiveUtils.cardSpacing(context);

    return GridView.count(
      crossAxisCount: columns,
      crossAxisSpacing: effectiveSpacing,
      mainAxisSpacing: runSpacing ?? effectiveSpacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

