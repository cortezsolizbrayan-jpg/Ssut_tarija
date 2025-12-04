import 'package:flutter/material.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';

class InicioHeader extends StatelessWidget {
  const InicioHeader({super.key});

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
            // Primera fila: Menu, Logo Posgrado, Banco Union, Notificaciones, Configuración y Avatar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Hamburger menu
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 28,
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
                  // Icono de configuración
                  IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () {
                      // TODO: Abrir configuración
                    },
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
            // Título, subtítulo y botón "Ver mis programas"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hola!, Guadalupe',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Estudia hoy, triunfa mañana...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 180,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC900),
                        foregroundColor: const Color(0xFF1A3A5C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DiplomadosScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Ver mis programas',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
