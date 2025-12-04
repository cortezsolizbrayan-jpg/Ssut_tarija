import 'package:flutter/material.dart';

import 'components/inicio_header.dart';
import 'components/program_card.dart';
import 'components/program_type_tabs.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  ProgramTypeTab _selectedTab = ProgramTypeTab.todos;

  List<Map<String, dynamic>> _getFilteredPrograms() {
    switch (_selectedTab) {
      case ProgramTypeTab.todos:
        return [
          {'title': 'DIPLOMADO', 'progress': 75},
          {'title': 'MAESTRÍA', 'progress': 50},
          {'title': 'DOCTORADO', 'progress': 30},
          {'title': 'POSDOCTORADO', 'progress': 10},
        ];
      case ProgramTypeTab.diplomado:
        return [
          {'title': 'DIPLOMADO', 'progress': 75},
        ];
      case ProgramTypeTab.maestria:
        return [
          {'title': 'MAESTRÍA', 'progress': 50},
        ];
      case ProgramTypeTab.especialidades:
        return [
          {'title': 'ESPECIALIDAD', 'progress': 60},
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrograms = _getFilteredPrograms();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header azul oscuro con curva
              const InicioHeader(),
              // Selector de tipo de programa (tabs)
              ProgramTypeTabs(
                onTabChanged: (tab) {
                  setState(() {
                    _selectedTab = tab;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sección de logros / medallas (vista general)
                    const _AchievementsSection(),
                    const SizedBox(height: 24),
                    // Grid de tarjetas de programas filtradas
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: filteredPrograms
                          .map(
                            (program) => ProgramCard(
                              title: program['title'],
                              progress: program['progress'].toDouble(),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 40),
                    // Redes sociales
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            // En una app real, aquí iría el logo de Google
                          ),
                          const SizedBox(width: 20),
                          // Facebook
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'f',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          // Twitter
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1DA1F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.alternate_email,
                                color: Colors.white,
                                size: 24,
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
            ],
          ),
        ),
      ),
    );
  }
}

/// Sección superior con medallas / logros de los programas.
///
/// Ahora es desplazable horizontalmente y cada medalla tiene una animación
/// de giro cuando se toca.
class _AchievementsSection extends StatefulWidget {
  const _AchievementsSection();

  @override
  State<_AchievementsSection> createState() => _AchievementsSectionState();
}

class _AchievementsSectionState extends State<_AchievementsSection> {
  final List<Map<String, dynamic>> _achievements = [
    {
      'label': 'Maestría',
      'icon': Icons.emoji_events,
      'color': const Color(0xFFFFD54F), // dorado
    },
    {
      'label': 'Diplomado',
      'icon': Icons.workspace_premium,
      'color': const Color(0xFFB0BEC5), // plata
    },
    {
      'label': 'Doctorado',
      'icon': Icons.school,
      'color': const Color(0xFFB0BEC5),
    },
    {
      'label': 'Posdoctorado',
      'icon': Icons.star,
      'color': const Color(0xFFB0BEC5),
    },
    {
      'label': 'Cursos',
      'icon': Icons.menu_book,
      'color': const Color(0xFFB0BEC5),
    },
  ];

  /// Controla cuántas vueltas ha dado cada medalla.
  late final List<double> _turns;

  @override
  void initState() {
    super.initState();
    _turns = List<double>.filled(_achievements.length, 0.0);
  }

  void _onTapMedal(int index) {
    setState(() {
      _turns[index] += 1; // una vuelta completa
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 152,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Tus logros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _achievements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = _achievements[index];
                final color = item['color'] as Color;

                return GestureDetector(
                  onTap: () => _onTapMedal(index),
                  child: SizedBox(
                    width: 70,
                    height: 95,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        AnimatedRotation(
                          turns: _turns[index],
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutBack,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.15),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: color,
                              size: 34,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item['label'] as String,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
