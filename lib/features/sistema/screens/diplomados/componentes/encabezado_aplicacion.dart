import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';

// ============================================================================
// CONSTANTES
// ============================================================================

class _AppHeaderColors {
  static const backgroundColor1 = Color(0xFF005BAC);
  static const backgroundColor2 = Color(0xFF004A86);
  static const accentYellow = Color(0xFFFFC900);
}

class _AppHeaderDimensions {
  static const double headerBorderRadius = 40.0;
  static const double backButtonSize = 40.0;
  static const double logoHeight = 36.0;
  static const double avatarRadius = 18.0;
  static const double searchBarHeight = 44.0;
  static const double selectorCircleSize = 56.0;
  static const double horizontalPadding = 20.0;
}

// ============================================================================
// ENUMS
// ============================================================================

enum ProgramType { diplomado, maestria, doctorado, posdoctorado }

// ============================================================================
// Widget PRINCIPAL
// ============================================================================

class AppHeader extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final ProgramType selectedProgram;
  final ValueChanged<ProgramType>? onProgramSelected;
  final bool showProgramTypeRow;

  const AppHeader({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.selectedProgram = ProgramType.diplomado,
    this.onProgramSelected,
    this.showProgramTypeRow = true,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  @override
  void initState() {
    super.initState();
    widget.searchController?.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _handleBackNavigation() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/sistema/pantalla_principal');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _buildHeaderDecoration(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _TopBar(
              onBackTap: _handleBackNavigation,
              onProfileTap: () => context.push('/mis-datos-personales'),
            ),
            const _TitleSection(),
            _SearchBar(
              controller: widget.searchController,
              onChanged: widget.onSearchChanged,
              onClear: () {
                widget.searchController?.clear();
                widget.onSearchChanged?.call('');
              },
            ),
            if (widget.showProgramTypeRow) ...[
              const SizedBox(height: 8),
              _ProgramTypeRow(
                selectedType: widget.selectedProgram,
                onTypeSelected: widget.onProgramSelected,
              ),
            ],
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildHeaderDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _AppHeaderColors.backgroundColor1,
          _AppHeaderColors.backgroundColor2,
        ],
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(_AppHeaderDimensions.headerBorderRadius),
        bottomRight: Radius.circular(_AppHeaderDimensions.headerBorderRadius),
      ),
      boxShadow: [
        BoxShadow(
          color: _AppHeaderColors.backgroundColor2.withOpacity(0.4),
          blurRadius: 18,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }
}

// ============================================================================
// WidgetS INTERNOS
// ============================================================================

/// Barra superior con botÃ³n atrÃ¡s, logo y avatar
class _TopBar extends StatelessWidget {
  final VoidCallback onBackTap;
  final VoidCallback onProfileTap;

  const _TopBar({
    required this.onBackTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _AppHeaderDimensions.horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          _CircleButton(
            onTap: onBackTap,
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Image.asset(
              'assets/images/logoposgrado.jpg',
              height: _AppHeaderDimensions.logoHeight,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 6),
          ProfileAvatarWidget(
            radius: _AppHeaderDimensions.avatarRadius,
            showShadow: true,
            onTap: onProfileTap,
          ),
        ],
      ),
    );
  }
}

/// BotÃ³n circular reutilizable
class _CircleButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _CircleButton({
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _AppHeaderDimensions.backButtonSize,
        height: _AppHeaderDimensions.backButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
        child: child,
      ),
    );
  }
}

/// SecciÃ³n de tÃ­tulo y subtÃ­tulo
class _TitleSection extends StatelessWidget {
  const _TitleSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _AppHeaderDimensions.horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mis Programas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Todos los programas que estÃ¡ cursando o cursÃ³',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de bÃºsqueda
class _SearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const _SearchBar({
    this.controller,
    this.onChanged,
    this.onClear,
  });

  bool get _hasText => controller?.text.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _AppHeaderDimensions.horizontalPadding,
        vertical: 12,
      ),
      child: Container(
        height: _AppHeaderDimensions.searchBarHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Buscador...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
            suffixIcon: _hasText
                ? GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Fila de selectores de tipo de programa
class _ProgramTypeRow extends StatelessWidget {
  final ProgramType selectedType;
  final ValueChanged<ProgramType>? onTypeSelected;

  const _ProgramTypeRow({
    required this.selectedType,
    this.onTypeSelected,
  });

  static const _programLabels = {
    ProgramType.diplomado: 'Diplomado',
    ProgramType.maestria: 'MaestrÃ­a',
    ProgramType.doctorado: 'Doctorado',
    ProgramType.posdoctorado: 'Posdoctorado',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      child: SizedBox(
        height: 80,
        child: Stack(
          alignment: Alignment.center,
          children: [
            _buildConnectorLine(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: ProgramType.values.map((type) {
                return Expanded(
                  child: _ProgramTypeSelector(
                    label: _programLabels[type]!,
                    type: type,
                    isSelected: type == selectedType,
                    onTap: () => onTypeSelected?.call(type),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectorLine() {
    return Positioned(
      left: 40,
      right: 40,
      top: 25,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}

/// Selector individual de tipo de programa
class _ProgramTypeSelector extends StatelessWidget {
  final String label;
  final ProgramType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProgramTypeSelector({
    required this.label,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  static const _typeIcons = {
    ProgramType.diplomado: Icons.description,
    ProgramType.maestria: Icons.school,
    ProgramType.doctorado: Icons.menu_book,
    ProgramType.posdoctorado: Icons.workspace_premium,
  };

  Color get _circleColor {
    if (isSelected) return _AppHeaderColors.accentYellow;
    if (type == ProgramType.maestria) {
      return _AppHeaderColors.backgroundColor2.withOpacity(0.8);
    }
    return Colors.grey.shade400.withOpacity(0.8);
  }

  Color get _borderColor {
    return isSelected
        ? _AppHeaderColors.accentYellow
        : Colors.white.withOpacity(0.4);
  }

  Widget get _icon {
    if (isSelected) {
      return const Icon(Icons.check_circle, color: Colors.white, size: 28);
    }
    return Icon(_typeIcons[type], color: Colors.white, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final itemWidth = (width - 40) / 4;
    final fontSize = (itemWidth * 0.12).clamp(9.0, 12.0);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCircle(),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircle() {
    return Container(
      width: _AppHeaderDimensions.selectorCircleSize,
      height: _AppHeaderDimensions.selectorCircleSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _circleColor,
        border: Border.all(
          color: _borderColor,
          width: isSelected ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _AppHeaderColors.accentYellow.withOpacity(0.5)
                : Colors.black.withOpacity(0.2),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(child: _icon),
    );
  }
}



