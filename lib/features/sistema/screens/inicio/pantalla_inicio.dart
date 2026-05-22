import 'package:flutter/material.dart';

import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'componentes/encabezado_inicio.dart';
import 'componentes/tarjeta_programa.dart';
import 'componentes/pestanas_tipo_programa.dart';
import 'componentes/acciones_rapidas.dart';

class InicioPantalla extends StatefulWidget {
  const InicioPantalla({super.key});

  @override
  State<InicioPantalla> createState() => _InicioPantallaState();
}

class _InicioPantallaState extends State<InicioPantalla> {
  ProgramTypeTab _selectedTab = ProgramTypeTab.todos;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Intentar obtener datos personales primero
      final personalData = await LocalStorageService.getPersonalData();

      if (personalData != null) {
        final nombre = personalData['nombres']?.toString().trim() ?? '';
        final apPaterno = personalData['apellidos']?.toString().trim() ?? '';

        if (nombre.isNotEmpty) {
          setState(() {
            _userName = '$nombre $apPaterno'.trim();
            _isLoading = false;
          });
          return;
        }
      }

      // Si no hay datos personales, intentar con datos de sesión
      final sessionData = await LocalStorageService.getSessionData();
      if (sessionData != null) {
        final nombreCompleto =
            sessionData['nombreCompleto']?.toString().trim() ?? '';

        // Verificar si es un CI (solo números)
        if (nombreCompleto.isNotEmpty &&
            !RegExp(r'^\d+$').hasMatch(nombreCompleto)) {
          setState(() {
            _userName = nombreCompleto;
            _isLoading = false;
          });
          return;
        }
      }

      // Si no hay nombre válido, dejar null
      setState(() {
        _userName = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = null;
        _isLoading = false;
      });
    }
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
      backgroundColor: const Color(
        0xFFEEF1F8,
      ), // Main background from design system
      body: SafeArea(
        bottom: false,
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header azul oscuro con curva
              InicioHeader(
                userName: _userName,
                isLoading: _isLoading,
                onRefresh: _loadUserData,
              ),
              // Selector de tipo de programa (tabs)
              ProgramTypeTabs(
                onTabChanged: (tab) {
                  setState(() {
                    _selectedTab = tab;
                  });
                },
              ),
              // Banner de descuentos - Solo visible en tablet
              _buildResponsiveDiscountBanner(context),
              ResponsiveContainer(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveUtils.horizontalPadding(context),
                    vertical: ResponsiveUtils.verticalPadding(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sección de Acciones Rápidas (Sustituye a medallas)
                      const QuickActions(),
                      SizedBox(height: ResponsiveUtils.cardSpacing(context)),
                      // Grid de tarjetas de programas filtradas - RESPONSIVE con Glassmorphism
                      GridView.count(
                        crossAxisCount: ResponsiveUtils.programGridColumns(
                          context,
                        ),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: ResponsiveUtils.valueByDevice(
                          context: context,
                          mobile: 1.1,
                          tablet: 1.25,
                          largeTablet: 1.35,
                          desktop: 1.45,
                        ),
                        children: filteredPrograms
                            .map(
                              (program) => ProgramCard(
                                title: program['title'],
                                progress: program['progress'].toDouble(),
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalPadding(context),
                      ),
                      // Redes sociales - RESPONSIVE
                      Container(
                        padding: EdgeInsets.all(
                          ResponsiveUtils.horizontalPadding(context),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.cardBorderRadius(context),
                          ),
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
                            _buildSocialIcon(
                              context,
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.valueByDevice(
                                    context: context,
                                    mobile: 24,
                                    tablet: 28,
                                    largeTablet: 32,
                                    desktop: 36,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: ResponsiveUtils.cardSpacing(context),
                            ),
                            // Facebook
                            _buildSocialIcon(
                              context,
                              backgroundColor: const Color(0xFF1877F2),
                              child: Text(
                                'f',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.valueByDevice(
                                    context: context,
                                    mobile: 24,
                                    tablet: 28,
                                    largeTablet: 32,
                                    desktop: 36,
                                  ),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: ResponsiveUtils.cardSpacing(context),
                            ),
                            // Twitter
                            _buildSocialIcon(
                              context,
                              backgroundColor: const Color(0xFF1DA1F2),
                              child: Icon(
                                Icons.alternate_email,
                                color: Colors.white,
                                size: ResponsiveUtils.mediumIconSize(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: ResponsiveUtils.verticalPadding(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// asistente para construir íconos sociales responsive
  Widget _buildSocialIcon(
    BuildContext context, {
    Color? backgroundColor,
    required Widget child,
  }) {
    final size = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 50.0,
      tablet: 60.0,
      largeTablet: 70.0,
      desktop: 80.0,
    );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
        border: backgroundColor == null
            ? Border.all(color: Colors.grey.shade300, width: 1)
            : null,
      ),
      child: Center(child: child),
    );
  }

  /// Banner de descuentos responsive - DESACTIVADO EN LANDSCAPE DE TABLET
  Widget _buildResponsiveDiscountBanner(BuildContext context) {
    final PantallaSize = MediaQuery.of(context).size;
    final PantallaWidth = PantallaSize.width;
    final PantallaHeight = PantallaSize.height;
    final isLandscape = PantallaWidth > PantallaHeight;

    // Determinar si es tablet basado en la dimensión mayor
    final largerDimension = isLandscape ? PantallaWidth : PantallaHeight;

    // Solo mostrar en tablet portrait - NUNCA en landscape
    final isTabletSize =
        largerDimension > 1000 || (!isLandscape && PantallaWidth > 600);

    // NO mostrar si es landscape de tablet (DESACTIVADO COMPLETAMENTE)
    if (!isTabletSize || isLandscape) {
      return const SizedBox.shrink();
    }

    // Solo para portrait - altura responsive
    final bannerHeight = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 100.0,
      tablet: 130.0,
      largeTablet: 150.0, // Para 1200x1920 portrait
      desktop: 170.0,
    );

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
        vertical: ResponsiveUtils.cardSpacing(context) * 0.75,
      ),
      child: Container(
        width: double.infinity,
        height: bannerHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.cardBorderRadius(context),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.cardBorderRadius(context),
          ),
          child: Image.asset(
            'assets/images/banerdescuento.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF005BAC).withOpacity(0.1),
                      const Color(0xFF3D8FE0).withOpacity(0.1),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_offer,
                        size: ResponsiveUtils.mediumIconSize(context),
                        color: const Color(0xFF005BAC),
                      ),
                      SizedBox(
                        height: ResponsiveUtils.cardSpacing(context) * 0.5,
                      ),
                      Text(
                        'Convenios Especiales',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.subtitleFontSize(context),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF005BAC),
                        ),
                      ),
                      Text(
                        'Descuentos disponibles',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.bodyFontSize(context),
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

