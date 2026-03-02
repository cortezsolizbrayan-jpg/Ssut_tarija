import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';

/// Pantalla de bienvenida estilo Windows 11
class PantallaBienvenidaWindows extends StatefulWidget {
  final String userName;
  final VoidCallback onComplete;
  
  const PantallaBienvenidaWindows({
    super.key,
    required this.userName,
    required this.onComplete,
  });

  @override
  State<PantallaBienvenidaWindows> createState() => _PantallaBienvenidaWindowsState();
}

class _PantallaBienvenidaWindowsState extends State<PantallaBienvenidaWindows> 
    with SingleTickerProviderStateMixin {
  late AnimationController _dotsController;
  
  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    // Navegar después de 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nombre del usuario con fade in
            FadeIn(
              duration: const Duration(milliseconds: 800),
              child: Text(
                'Bienvenido, ${_getFirstName(widget.userName)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFamily: DesignTokens.primaryFont,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 60),
            
            // Puntos de carga animados estilo Windows 11
            FadeIn(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 800),
              child: AnimatedBuilder(
                animation: _dotsController,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      // Calcular el delay para cada punto
                      final delay = index * 0.2;
                      final value = (_dotsController.value - delay).clamp(0.0, 1.0);
                      
                      // Animación de escala y opacidad
                      final scale = value < 0.5 
                          ? 1.0 + (value * 2) * 0.5 
                          : 1.5 - ((value - 0.5) * 2) * 0.5;
                      
                      final opacity = value < 0.5 
                          ? 0.3 + (value * 2) * 0.7 
                          : 1.0 - ((value - 0.5) * 2) * 0.7;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(opacity),
                            ),
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Extrae el primer nombre del usuario
  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Usuario';
    
    // Si es un número (CI), retornar "Usuario"
    if (RegExp(r'^\d+$').hasMatch(fullName.trim())) {
      return 'Usuario';
    }
    
    // Obtener el primer nombre
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }
}
