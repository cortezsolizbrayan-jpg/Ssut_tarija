import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'components/inicio_header.dart';
import 'components/program_card.dart';
import 'components/program_type_tabs.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_datos_personales_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> with SingleTickerProviderStateMixin {
  ProgramTypeTab _selectedTab = ProgramTypeTab.todos;
  bool _isDataComplete = true;
  String _userName = '';
  
  // UN SOLO controlador - MÁS EFICIENTE
  late AnimationController _controller;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkDataStatus();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // RÁPIDO: 300ms
    );
  }
  
  void _startAnimations() {
    if (_animationsInitialized) {
      _controller.reset();
    }
    _animationsInitialized = true;
    _controller.forward();
  }
  //controlador 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkDataStatus() async {
    final personalData = await LocalStorageService.getPersonalData();
    final session = await LocalStorageService.getSessionData();
    
    if (!mounted) return;

    setState(() {
      _userName = (personalData?['nombre'] as String?)?.trim() ?? 
                  (session?['nombreUsuario'] as String?)?.trim() ?? 
                  'Usuario';
      
      final requiredFields = [
        personalData?['nombre'],
        personalData?['apPaterno'],
        personalData?['numeroCI'],
        personalData?['correo'],
        personalData?['celular'],
      ];
      
      _isDataComplete = requiredFields.every((f) => f != null && f.toString().trim().isNotEmpty);
    });
  }

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
        return [{'title': 'DIPLOMADO', 'progress': 75}];
      case ProgramTypeTab.maestria:
        return [{'title': 'MAESTRÍA', 'progress': 50}];
      case ProgramTypeTab.especialidades:
        return [{'title': 'ESPECIALIDAD', 'progress': 60}];
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPrograms = _getFilteredPrograms();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAnimations();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          child: FadeTransition(
            opacity: _controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header - SOLO FADE
                InicioHeader(userName: _userName),
                
                if (!_isDataComplete)
                  _buildOnboardingBanner(),
                
                // Tabs - SOLO FADE
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
                      // Medallas - SIMPLIFICADAS
                      const _AchievementsSectionOptimized(),
                      
                      const SizedBox(height: 24),
                      
                      // Grid - SOLO FADE
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: filteredPrograms.map((program) {
                          return ProgramCard(
                            title: program['title'],
                            progress: program['progress'].toDouble(),
                          );
                        }).toList(),
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
                            _buildSocialIcon('G', const Color(0xFF4285F4), Colors.white),
                            const SizedBox(width: 20),
                            _buildSocialIcon('f', Colors.white, const Color(0xFF1877F2)),
                            const SizedBox(width: 20),
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFF1DA1F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.alternate_email, color: Colors.white, size: 24),
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
      ),
    );
  }
  
  Widget _buildSocialIcon(String text, Color textColor, Color bgColor) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: bgColor == Colors.white ? Border.all(color: Colors.grey.shade300) : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Icon(
                Icons.account_circle,
                size: 100,
                color: Colors.blue.withOpacity(0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.rocket_launch_rounded, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '¡Completa tu perfil!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF005BAC),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _isDataComplete = true),
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Hola $_userName, para postular a los programas vigentes y habilitar tus servicios, es necesario completar tus datos personales.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            // Usar go_router para transición fluida hacia Mis Datos Personales
                            await context.pushNamed(MisDatosPersonalesScreen.name);
                            _checkDataStatus();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005BAC),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'IR A MI PERFIL',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
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
    );
  }
}

/// Sección de medallas OPTIMIZADA - SIN animaciones complejas
class _AchievementsSectionOptimized extends StatelessWidget {
  const _AchievementsSectionOptimized();

  @override
  Widget build(BuildContext context) {
    final achievements = [
      {'label': 'Maestría', 'icon': Icons.emoji_events, 'color': const Color(0xFFFFD700)},
      {'label': 'Diplomado', 'icon': Icons.workspace_premium, 'color': const Color(0xFFC0C0C0)},
      {'label': 'Doctorado', 'icon': Icons.school, 'color': const Color(0xFFCD7F32)},
      {'label': 'Posdoctorado', 'icon': Icons.star, 'color': const Color(0xFF9C27B0)},
      {'label': 'Cursos', 'icon': Icons.menu_book, 'color': const Color(0xFF2196F3)},
    ];

    return Container(
      height: 152,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
              itemCount: achievements.length,
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final item = achievements[index];
                final color = item['color'] as Color;

                return SizedBox(
                  width: 70,
                  height: 95,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Medalla SIMPLE - sin animaciones complejas
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              color.withOpacity(0.3),
                              color.withOpacity(0.15),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: color,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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



