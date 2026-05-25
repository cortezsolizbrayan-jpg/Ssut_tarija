import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refactor_template/config/theme/app_theme.dart';

class QuickItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const QuickItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}

/// BottomNavigationBar personalizado que responde al tema claro/oscuro.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onShellTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onShellTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 360;
    final isTablet = w >= 700;

    final barHeight = isTablet ? 72.0 : (isSmall ? 60.0 : 64.0);
    final hPad = isTablet ? 20.0 : 12.0;
    final bPad = isTablet ? 14.0 : 10.0;

    // Colores adaptativos
    final bgColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark
        ? AppTheme.darkBorder
        : AppTheme.primaryBlue.withOpacity(0.15);
    final shadowColor = isDark
        ? Colors.black38
        : AppTheme.primaryBlue.withOpacity(0.10);

    final items = [
      QuickItem(
        title: 'Programas',
        icon: Icons.menu_book,
        onTap: () => onShellTap?.call(0),
      ),
      QuickItem(
        title: 'Vigentes',
        icon: Icons.calendar_month,
        onTap: () => onShellTap?.call(1),
      ),
      QuickItem(
        title: 'Inicio',
        icon: Icons.home,
        onTap: () => onShellTap?.call(2),
      ),
      QuickItem(
        title: 'C.V.',
        icon: Icons.person,
        onTap: () => onShellTap?.call(3),
      ),
      QuickItem(
        title: 'Docs',
        icon: Icons.folder,
        onTap: () => onShellTap?.call(4),
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(hPad, 0, hPad, bPad),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: borderColor, width: isDark ? 0.8 : 1),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: List.generate(items.length, (i) {
              return Expanded(
                child: _NavBarItem(
                  icon: items[i].icon,
                  label: items[i].title,
                  isSelected: currentIndex == i,
                  isSmall: isSmall,
                  isTablet: isTablet,
                  isDark: isDark,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    items[i].onTap();
                  },
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isSmall;
  final bool isTablet;
  final bool isDark;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isSmall,
    required this.isTablet,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // En modo oscuro el acento es el azul brillante; en claro el azul institucional
    final activeColor = isDark ? AppTheme.darkAccent : AppTheme.primaryBlue;
    final inactiveColor = isDark
        ? AppTheme.darkTextSecondary
        : const Color(0xFF6E7B8A);
    final activeBg = activeColor.withOpacity(isDark ? 0.18 : 0.12);
    final activeBorder = activeColor.withOpacity(isDark ? 0.45 : 0.35);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.symmetric(
            horizontal: isTablet ? 8 : 4,
            vertical: isSmall ? 7 : 8,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 10 : 6,
            vertical: isSmall ? 3 : 4,
          ),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: activeBorder, width: 0.8)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: isTablet ? 24 : (isSmall ? 19 : 21),
              ),
              SizedBox(height: isSmall ? 1.5 : 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 11 : (isSmall ? 9 : 10),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
