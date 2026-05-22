import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'pantalla_programas_vigentes.dart';

/// Pantalla de programas disponibles para invitados (sin autenticación)
/// Reutiliza ProgramasVigentesPantalla pero en modo invitado
class ProgramasDisponiblesPantalla extends StatelessWidget {
  static const name = 'programas-disponibles';
  
  const ProgramasDisponiblesPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return ProgramasVigentesPantalla(
      isGuestMode: true,
      onInscriptionAttempt: () => _showRegisterDialog(context),
    );
  }

  /// Muestra diálogo invitando al usuario a registrarse - RESPONSIVE
  void _showRegisterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.cardBorderRadius(context),
          ),
        ),
        contentPadding: EdgeInsets.all(
          ResponsiveUtils.horizontalPadding(context),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveUtils.valueByDevice(
              context: context,
              mobile: double.infinity,
              tablet: 400,
              largeTablet: 450,
              desktop: 500,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícono - RESPONSIVE
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.horizontalPadding(context),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: ResponsiveUtils.largeIconSize(context),
                  color: const Color(0xFF005BAC),
                ),
              ),
              SizedBox(height: ResponsiveUtils.cardSpacing(context)),
              
              // Título - RESPONSIVE
              Text(
                '¡Regístrate para inscribirte!',
                style: TextStyle(
                  fontSize: ResponsiveUtils.subtitleFontSize(context),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A3A5C),
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveUtils.cardSpacing(context) * 0.5),
              
              // Mensaje con texto destacado en azul - RESPONSIVE
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: ResponsiveUtils.bodyFontSize(context),
                    color: const Color(0xFF666666),
                    fontFamily: 'Intel',
                    height: 1.4,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Para inscribirte en este programa necesitas ',
                    ),
                    TextSpan(
                      text: 'crear una cuenta',
                      style: TextStyle(
                        color: Color(0xFF005BAC),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: ' en la aplicación.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveUtils.cardSpacing(context)),
              
              // Botones - RESPONSIVE
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 12,
                            tablet: 14,
                            largeTablet: 16,
                            desktop: 18,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.buttonBorderRadius(context),
                          ),
                          side: BorderSide(
                            color: Colors.grey[300]!,
                          ),
                        ),
                      ),
                      child: Text(
                        'Ahora no',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Intel',
                          fontSize: ResponsiveUtils.bodyFontSize(context),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.5),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Navegar a pantalla de registro (subida de identidad)
                        context.push('/upload-ci');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveUtils.valueByDevice(
                            context: context,
                            mobile: 12,
                            tablet: 14,
                            largeTablet: 16,
                            desktop: 18,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveUtils.buttonBorderRadius(context),
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Registrarme',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Intel',
                          fontSize: ResponsiveUtils.bodyFontSize(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

