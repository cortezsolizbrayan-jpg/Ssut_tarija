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
      body: Column(
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
          // Contenido principal
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid de tarjetas de programas filtradas
                  GridView.count(
                    crossAxisCount: 2,
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
          ),
        ],
      ),
    );
  }
}
