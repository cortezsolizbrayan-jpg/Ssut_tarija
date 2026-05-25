import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/icono_notificaciones_widget.dart';

class InicioHeader extends StatelessWidget {
  final String? userName;
  final bool isLoading;
  final VoidCallback? onRefresh;
  
  const InicioHeader({
    super.key, 
    this.userName,
    this.isLoading = false,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final PantallaWidth = MediaQuery.of(context).size.width;
    final isTabletLandscape = isLandscape && PantallaWidth > 1000;
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF005BAC), // Azul institucional
              Color(0xFF0F7BD7), // Azul brillante
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Column(
          children: [
            // Primera fila: MenÃº hamburguesa y iconos de acciÃ³n
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hamburger menu
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.menu_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        // TODO: Abrir menÃº lateral
                      },
                    ),
                  ),
                  // Iconos de acciÃ³n (notificaciones, configuraciÃ³n, avatar)
                  Row(
                    children: [
                      const NotificationIconWidget(
                        size: 44,
                        iconSize: 22,
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          context.push('/configuracion');
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          context.push('/mis-datos-personales');
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF005BAC),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: isTabletLandscape ? 12 : 20),
            
            // SecciÃ³n central: Logo Institucional (CEUB)
            if (isTabletLandscape)
              _buildLandscapeLogo(context)
            else
              _buildPortraitLogo(context),
            
            SizedBox(height: isTabletLandscape ? 12 : 16),
            
            // Nombre del usuario - mÃ¡s prominente con opciÃ³n de editar
            GestureDetector(
              onTap: () async {
                await context.push('/mis-datos-personales');
                // Refrescar datos despuÃ©s de volver
                onRefresh?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else if (userName != null && userName!.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              userName!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isTabletLandscape ? 20 : 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Mascota Digital como Asistente que acompaÃ±a al nombre
                          _PulseIcon(
                            size: 36,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/mascot.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Text(
                            'Bienvenido',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isTabletLandscape ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.person_add_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Toca para completar tu perfil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: isTabletLandscape ? 16 : 24),
            
            // BotÃ³n "Ver Mis Programas" - mÃ¡s destacado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF005BAC),
                    padding: EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: isTabletLandscape ? 12 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                    minimumSize: Size(double.infinity, isTabletLandscape ? 44 : 52),
                  ),
                  onPressed: () {
                    context.pushNamed('diplomados');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ver Mis Programas',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isTabletLandscape ? 14 : 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            SizedBox(height: isTabletLandscape ? 20 : 32),
          ],
        ),
      ),
    );
  }

  /// Logo Institucional CEUB para portrait
  Widget _buildPortraitLogo(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Image.asset(
        'assets/images/ceub.png',
        fit: BoxFit.contain,
      ),
    );
  }

  /// Logo Institucional CEUB para landscape
  Widget _buildLandscapeLogo(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Image.asset(
        'assets/images/ceub.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

/// Widget para el efecto de pulso animado
class _PulseIcon extends StatefulWidget {
  final Widget child;
  final double size;

  const _PulseIcon({required this.child, required this.size});

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // CÃ­rculos de pulso
          ...List.generate(2, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, hijo) {
                final progress = (_controller.value + (index * 0.5)) % 1.0;
                return Container(
                  width: widget.size * (1 + (progress * 0.4)),
                  height: widget.size * (1 + (progress * 0.4)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(1 - progress),
                      width: 2,
                    ),
                  ),
                );
              },
            );
          }),
          widget.child,
        ],
      ),
    );
  }
}


