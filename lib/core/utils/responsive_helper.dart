import 'package:flutter/material.dart';

/// Clase helper para manejar tamaños responsive en toda la aplicación
/// Se basa en el ancho de pantalla para adaptar todos los elementos UI
class ResponsiveHelper {
  final BuildContext context;
  late final double PantallaWidth;
  
  ResponsiveHelper(this.context) {
    PantallaWidth = MediaQuery.of(context).size.width;
  }
  
  // ━━━ Breakpoints ━━━
  bool get isSmall => PantallaWidth < 380;
  bool get isMedium => PantallaWidth < 600;
  bool get isLarge => PantallaWidth >= 1024;
  
  // ━━━ AppBar ━━━
  double get menuIconSize => isSmall ? 20.0 : 22.0;
  double get settingsIconSize => isSmall ? 18.0 : 20.0;
  double get avatarWidgetRadius => isSmall ? 13.0 : 15.0;
  double get logoHeight => isSmall ? 30.0 : (isMedium ? 34.0 : 36.0);
  double get leadingWidth => isSmall ? 50.0 : 60.0;
  double get notificationSize => isSmall ? 30.0 : 34.0;
  double get iconNotificationSize => isSmall ? 16.0 : 18.0;
  
  // ━━━ Profile Card ━━━
  double get avatarRadius => isSmall ? 24.0 : (isMedium ? 28.0 : 30.0);
  double get avatarBorder => isSmall ? 2.0 : 3.0;
  double get nombreFontSize => isSmall ? 15.0 : (isMedium ? 16.5 : 18.0);
  double get saludoFontSize => isSmall ? 10.5 : (isMedium ? 11.0 : 12.0);
  double get badgeFontSize => isSmall ? 7.5 : (isMedium ? 8.0 : 9.0);
  double get botonFontSize => isSmall ? 10.5 : (isMedium ? 11.0 : 12.0);
  double get botonPadding => isSmall ? 7.0 : (isMedium ? 8.0 : 9.0);
  double get cardPaddingH => isSmall ? 12.0 : (isMedium ? 14.0 : 16.0);
  double get cardPaddingV => isSmall ? 10.0 : (isMedium ? 12.0 : 14.0);
  double get cardBorderRadius => isSmall ? 18.0 : (isMedium ? 20.0 : 22.0);
  double get spacingAvatarInfo => isSmall ? 10.0 : 14.0;
  double get iconBtnSize => isSmall ? 13.0 : 15.0;
  double get iconArrowSize => isSmall ? 10.0 : 12.0;
  
  // ━━━ Top Section ━━━
  double get topSectionPaddingH => isSmall ? 16.0 : 20.0;
  double get topSectionPaddingTop => isSmall ? 12.0 : 16.0;
  double get topSectionBottomPadding => topSectionPaddingH + 20;
  
  // ━━━ Carrusel ━━━
  double get carouselHeight => isSmall ? 170.0 : (isMedium ? 180.0 : 190.0);
  double get carouselItemMargin => isSmall ? 6.0 : (isMedium ? 7.0 : 8.0);
  double get carouselItemBorderRadius => isSmall ? 15.0 : (isMedium ? 16.0 : 18.0);
  double get carouselTitleFontSize => isSmall ? 11.0 : (isMedium ? 11.5 : 12.0);
  double get carouselModalidadFontSize => isSmall ? 9.0 : (isMedium ? 9.5 : 10.0);
  double get carouselIconLocation => isSmall ? 10.0 : 12.0;
  
  // ━━━ CEUB ━━━
  double get ceubPadding => isSmall ? 16.0 : 20.0;
  double get ceubLogoHeight => isSmall ? 55.0 : (isMedium ? 60.0 : 68.0);
  double get ceubTitleFontSize => isSmall ? 11.5 : (isMedium ? 12.0 : 13.0);
  double get ceubSubFontSize => isSmall ? 9.5 : (isMedium ? 10.0 : 11.0);
  double get ceubBtnFontSize => isSmall ? 9.5 : (isMedium ? 10.0 : 11.0);
  double get ceubBtnPadding => isSmall ? 10.0 : (isMedium ? 12.0 : 14.0);
  double get ceubBtnBorderRadius => badgeFontSize - 1;
  double get ceubIconSize => badgeFontSize + 3;
  
  // ━━━ Slogan ━━━
  double get sloganLogoHeight => isSmall ? 28.0 : (isMedium ? 32.0 : 36.0);
  double get sloganFontSize => isSmall ? 13.0 : (isMedium ? 14.0 : 15.0);
  double get sloganHorizontalPadding => isSmall ? 16.0 : 20.0;
  double get sloganVerticalPadding => isSmall ? 18.0 : 26.0;
  double get sloganSpacing => isSmall ? 8.0 : 10.0;
  
  // ━━━ Helpers de cálculo ━━━
  EdgeInsets get topSectionPadding => EdgeInsets.fromLTRB(
    topSectionPaddingH,
    topSectionPaddingTop,
    topSectionPaddingH,
    0,
  );
  
  EdgeInsets get cardPadding => EdgeInsets.symmetric(
    horizontal: cardPaddingH,
    vertical: cardPaddingV,
  );
  
  EdgeInsets get ceubPaddingAll => EdgeInsets.fromLTRB(
    ceubPadding,
    ceubPadding + 6,
    ceubPadding,
    ceubPadding + 2,
  );
  
  EdgeInsets get sloganPadding => EdgeInsets.fromLTRB(
    sloganHorizontalPadding,
    sloganVerticalPadding,
    sloganHorizontalPadding,
    sloganVerticalPadding,
  );
}
