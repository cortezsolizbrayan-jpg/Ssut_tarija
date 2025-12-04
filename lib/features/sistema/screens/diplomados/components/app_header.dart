import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

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
            // Primera fila: Logo Posgrado, Banco Union, Notificaciones, Configuración y Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Logo Posgrado (centrado)
                  Expanded(
                    child: Image.asset(
                      'assets/images/logposgrado.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Banco Union
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Color(0xFF1A3A5C),
                        ),
                        SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'BANCO UNION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A5C),
                              ),
                            ),
                            Text(
                              'Número de cuenta único',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Notificaciones
                  Stack(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Configuración
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(
                        'assets/icons/profile_img.png',
                      ),
                    ),
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
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscador...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
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
                            _ProgramTypeSelector(
                              label: 'Diplomado',
                              type: ProgramType.diplomado,
                              isSelected: true,
                              onTap: () {},
                            ),
                            _ProgramTypeSelector(
                              label: 'Maestría',
                              type: ProgramType.maestria,
                              isSelected: false,
                              onTap: () {},
                            ),
                            _ProgramTypeSelector(
                              label: 'Doctorado',
                              type: ProgramType.doctorado,
                              isSelected: false,
                              onTap: () {},
                            ),
                            _ProgramTypeSelector(
                              label: 'Posdoctorado',
                              type: ProgramType.posdoctorado,
                              isSelected: false,
                              onTap: () {},
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
        return const Color(0xFF87CEEB).withOpacity(0.8); // Azul claro
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
