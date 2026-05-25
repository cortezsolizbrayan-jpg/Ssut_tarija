import 'package:flutter/material.dart';

/// Provee el callback para abrir/cerrar el menú lateral a cualquier
/// widget descendiente del árbol, sin necesidad de pasar el callback
/// manualmente por cada pantalla.
class MenuLateralScope extends InheritedWidget {
  final VoidCallback onToggleMenu;
  final bool isOpen;

  const MenuLateralScope({
    super.key,
    required this.onToggleMenu,
    required this.isOpen,
    required super.child,
  });

  static MenuLateralScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MenuLateralScope>();
  }

  @override
  bool updateShouldNotify(MenuLateralScope oldWidget) =>
      oldWidget.isOpen != isOpen;
}

/// Botón de menú hamburguesa estándar para usar en AppBar.leading.
/// Se conecta automáticamente al MenuLateralScope del árbol.
class BotonMenuLateral extends StatelessWidget {
  const BotonMenuLateral({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = MenuLateralScope.of(context);
    if (scope == null) return const SizedBox.shrink();

    return IconButton(
      onPressed: scope.onToggleMenu,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          scope.isOpen ? Icons.close_rounded : Icons.menu_rounded,
          key: ValueKey(scope.isOpen),
          color: Colors.white,
          size: 26,
        ),
      ),
      tooltip: scope.isOpen ? 'Cerrar menú' : 'Abrir menú',
    );
  }
}
