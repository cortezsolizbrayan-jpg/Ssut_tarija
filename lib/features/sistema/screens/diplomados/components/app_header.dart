import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/widgets/notification_icon_widget.dart';
import 'package:refactor_template/features/sistema/widgets/profile_avatar_widget.dart';

class AppHeader extends StatefulWidget {
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final Widget? menuButton;

  const AppHeader({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.menuButton,
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

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00448A), // Azul muy oscuro
            Color(0xFF0F7BD7), // Azul brillante
            Color(0xFF0B5FB4), // Azul medio-oscuro
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(175),
          bottomRight: Radius.circular(175),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Primera fila: Menu, Logo Posgrado, Banco Union, Notificaciones, Configuración y Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Menú hamburguesa (si se proporciona)
                  if (widget.menuButton != null) ...[
                    widget.menuButton!,
                    const SizedBox(width: 12),
                  ],
                  // Logo Posgrado (centrado)
                  Expanded(
                    child: Image.asset(
                      'assets/images/logoposgrado.jpg',
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Banco Union - Reducido
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.credit_card,
                          size: 14,
                          color: Color(0xFF1A3A5C),
                        ),
                        SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BANCO UNION',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A5C),
                              ),
                            ),
                            Text(
                              'Número de cuenta único',
                              style: TextStyle(
                                fontSize: 7,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Notificaciones - Más reducido
                  const NotificationIconWidget(size: 40, iconSize: 22),
                  const SizedBox(width: 6),
                  // Configuración - Más reducido
                  GestureDetector(
                    onTap: () {
                      context.push('/configuracion');
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Avatar - Más reducido
                  ProfileAvatarWidget(
                    radius: 16,
                    showShadow: true,
                    onTap: () {
                      context.push('/mis-datos-personales');
                    },
                  ),
                ],
              ),
            ),
            // Segunda fila: Título y subtítulo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                    'Todos los programas que está cursando o cursó',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Barra de búsqueda - Reducida
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
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
                  controller: widget.searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscador...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.grey,
                      size: 20,
                    ),
                    suffixIcon:
                        widget.searchController != null &&
                            widget.searchController!.text.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              widget.searchController!.clear();
                              widget.onSearchChanged?.call('');
                            },
                            child: const Icon(
                              Icons.clear,
                              color: Colors.grey,
                              size: 18,
                            ),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  onChanged: widget.onSearchChanged,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Selector de tipo de programa (Línea de tiempo)
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              child: Column(
                children: [
                  // Línea de tiempo con círculos conectados
                  SizedBox(
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Línea horizontal conectando los círculos
                        Positioned(
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
                        ),
                        // Círculos con iconos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _ProgramTypeSelector(
                                label: 'Diplomado',
                                type: ProgramType.diplomado,
                                isSelected: true,
                                onTap: () {},
                              ),
                            ),
                            Expanded(
                              child: _ProgramTypeSelector(
                                label: 'Maestría',
                                type: ProgramType.maestria,
                                isSelected: false,
                                onTap: () {},
                              ),
                            ),
                            Expanded(
                              child: _ProgramTypeSelector(
                                label: 'Doctorado',
                                type: ProgramType.doctorado,
                                isSelected: false,
                                onTap: () {},
                              ),
                            ),
                            Expanded(
                              child: _ProgramTypeSelector(
                                label: 'Posdoctorado',
                                type: ProgramType.posdoctorado,
                                isSelected: false,
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ProgramType { diplomado, maestria, doctorado, posdoctorado }

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

  Color _getCircleColor() {
    if (isSelected) {
      return const Color(
        0xFFFFC900,
      ); // Amarillo dorado cuando está seleccionado
    }
    switch (type) {
      case ProgramType.maestria:
        return const Color(0xFF1A3A5C).withOpacity(0.8); // Azul del header
      case ProgramType.doctorado:
        return Colors.grey.shade400.withOpacity(0.8); // Gris claro
      case ProgramType.posdoctorado:
        return Colors.grey.shade400.withOpacity(0.8); // Gris claro
      default:
        return Colors.grey.shade400.withOpacity(0.8);
    }
  }

  Widget _getIcon() {
    if (isSelected) {
      // Cuando está seleccionado, mostrar un escudo con check
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.2),
        ),
        child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
      );
    }
    switch (type) {
      case ProgramType.diplomado:
        return const Icon(Icons.description, color: Colors.white, size: 24);
      case ProgramType.maestria:
        return const Icon(Icons.school, color: Colors.white, size: 24);
      case ProgramType.doctorado:
        return const Icon(Icons.menu_book, color: Colors.white, size: 24);
      case ProgramType.posdoctorado:
        return const Icon(
          Icons.workspace_premium,
          color: Colors.white,
          size: 24,
        );
    }
  }

  //Comentario para prueba de commit
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final availableWidth = width - 40; // Padding horizontal
    final itemWidth = availableWidth / 4; // 4 items
    final fontSize = (itemWidth * 0.12).clamp(9.0, 12.0);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCircleColor(),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFFFC900)
                    : Colors.white.withOpacity(0.4),
                width: isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? const Color(0xFFFFC900).withOpacity(0.5)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: _getIcon()),
          ),
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
}
