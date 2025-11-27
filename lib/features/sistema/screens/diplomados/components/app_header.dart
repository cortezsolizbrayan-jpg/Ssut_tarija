import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A3A5C), // Azul oscuro
            Color(0xFF2C5F8D), // Azul medio
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(175),
          bottomRight: Radius.circular(175),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Primera fila: Menu, Logo Posgrado, Banco Union, Notificaciones y Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Hamburger menu
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: () {
                        // TODO: Abrir menú lateral
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Logo Posgrado con birrete
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            const Text(
                              'Posgrado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Positioned(
                              left: 40,
                              top: -8,
                              child: Icon(
                                Icons.school,
                                color: Colors.amber,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Banco Union
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BANCO UNION',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Número de cuenta único',
                        style: TextStyle(fontSize: 8, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Notificaciones con badge
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          // TODO: Abrir notificaciones
                        },
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
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
                  const SizedBox(width: 8),
                  // Avatar del usuario
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: const AssetImage(
                        'assets/icons/profile_img.png',
                      ),
                      onBackgroundImageError: (_, __) {},
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[300],
                        ),
                        child: const Icon(Icons.person, color: Colors.grey),
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
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar programas...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
      return Colors.green;
    }
    switch (type) {
      case ProgramType.maestria:
        return const Color(0xFF87CEEB); // Azul claro
      case ProgramType.doctorado:
      case ProgramType.posdoctorado:
        return Colors.grey.shade400; // Gris claro
      default:
        return Colors.grey.shade400;
    }
  }

  Widget _getIcon() {
    if (isSelected && type == ProgramType.diplomado) {
      return const Icon(Icons.check, color: Colors.white, size: 24);
    }
    switch (type) {
      case ProgramType.maestria:
        return const Icon(Icons.school, color: Colors.white, size: 20);
      case ProgramType.doctorado:
        return const Icon(Icons.menu_book, color: Colors.white, size: 20);
      case ProgramType.posdoctorado:
        return const Icon(Icons.more_horiz, color: Colors.white, size: 24);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getCircleColor(),
              border: Border.all(
                color: isSelected
                    ? Colors.green
                    : Colors.white.withOpacity(0.3),
                width: 2,
              ),
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
