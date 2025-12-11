import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/screens/diplomados/diplomados_screen.dart';
import 'package:refactor_template/features/sistema/widgets/notification_icon_widget.dart';
import 'package:refactor_template/features/sistema/widgets/profile_avatar_widget.dart';

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
                  // Hamburger menu - Reducido
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // TODO: Abrir menú lateral
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Logo Posgrado con birrete - Reducido
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            const Text(
                              'Posgrado',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Positioned(
                              left: 36,
                              top: -7,
                              child: Icon(
                                Icons.school,
                                color: Colors.amber,
                                size: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Banco Union - Reducido
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BANCO UNION',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A3A5C),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Número de cuenta único',
                        style: TextStyle(fontSize: 7, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Notificaciones - Reducido
                  const NotificationIconWidget(size: 44, iconSize: 24),
                  const SizedBox(width: 8),
                  // Icono de configuración - Reducido
                  GestureDetector(
                    onTap: () {
                      context.push('/configuracion');
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar del usuario - Reducido
                  ProfileAvatarWidget(
                    radius: 18,
                    showShadow: false,
                    onTap: () {
                      context.push('/mis-datos-personales');
                    },
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
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFC900),
                        foregroundColor: const Color(0xFF1A3A5C),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        minimumSize: const Size(0, 44),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
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
