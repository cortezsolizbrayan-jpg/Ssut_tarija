import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';

class MisProgramasHeader extends StatelessWidget {
  const MisProgramasHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(
                0xFF005BAC,
              ), // Azul institucional (igual que otras pantallas)
              Color(0xFF004A86), // Degradado institucional
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(100),
            bottomRight: Radius.circular(100),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          20 + MediaQuery.of(context).padding.top,
          20,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primera fila: MenÃº, Logo Posgrado y otros iconos
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  // BotÃ³n AtrÃ¡s
                  _buildRoundButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.go('/sistema/pantalla_principal');
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'POSGRADO',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Color(0xB3000000),
                            offset: Offset(2, 2),
                            blurRadius: 6,
                          ),
                        ],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Avatar con Hero para transición fluida
                  Hero(
                    tag: 'avatar_hero_main',
                    child: ProfileAvatarWidget(
                      radius: 18,
                      showShadow: false,
                      onTap: () => context.push('/mis-datos-personales'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // TÃ­tulo
            FadeInLeft(
              duration: const Duration(milliseconds: 350),
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'Mis Programas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color(0x99000000),
                      offset: Offset(1, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // SubtÃ­tulo
            FadeInRight(
              duration: const Duration(milliseconds: 350),
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Todos los programas que estÃ¡ cursando o cursÃ³.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.95),
                  shadows: const [
                    Shadow(
                      color: Color(0x80000000),
                      offset: Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isGradient = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isGradient ? null : Colors.white,
          gradient: isGradient
              ? const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: isGradient ? Colors.white : Colors.black,
          size: 22,
        ),
      ),
    );
  }
}
