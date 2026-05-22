import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:refactor_template/core/services/otros/servicio_biometrico.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';

class BotonPrimario extends StatelessWidget {
  const BotonPrimario({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('Holaa');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC900),
          foregroundColor: const Color(0xFF0D1730),
          elevation: 8,
          padding: EdgeInsets.symmetric(vertical: width * 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          shadowColor: const Color(0x33FFC900),
        ),
        child: Text(
          'INICIAR SESIÓN',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: width * 0.04,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class BotonesSociales extends StatelessWidget {
  const BotonesSociales({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final buttonSize = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 48.0,
      tablet: 56.0,
      largeTablet: 64.0,
      desktop: 72.0,
    );

    final spacing = ResponsiveUtils.cardSpacing(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: ResponsiveUtils.valueByDevice(
          context: context,
          mobile: width * 0.8,
          tablet: 400.0,
          largeTablet: 500.0,
          desktop: 600.0,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min, // Evitar overflow
        children: [
          Flexible(
            child: _SocialIcon(
              color: Colors.white,
              size: buttonSize,
              child: Icon(
                FontAwesomeIcons.google,
                size: buttonSize * 0.4,
                color: const Color(0xFF4285F4),
              ),
            ),
          ),
          SizedBox(width: spacing),
          Flexible(
            child: _SocialIcon(
              color: Colors.white,
              size: buttonSize,
              child: Icon(
                Icons.facebook,
                size: buttonSize * 0.45,
                color: const Color(0xFF3B5998),
              ),
            ),
          ),
          SizedBox(width: spacing),
          Flexible(
            child: _SocialIcon(
              color: Colors.white,
              size: buttonSize,
              child: Icon(
                FontAwesomeIcons.twitter,
                size: buttonSize * 0.4,
                color: const Color(0xFF1DA1F2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.child,
    required this.color,
    required this.size,
  });

  final Widget child;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6E9EF)),
      ),
      child: Center(child: child),
    );
  }
}

class BiometriaWidget extends StatefulWidget {
  const BiometriaWidget({
    super.key,
    required this.width,
    this.onBiometricSuccess,
  });

  final double width;
  final Function(String username, String password)? onBiometricSuccess;

  @override
  State<BiometriaWidget> createState() => _BiometriaWidgetState();
}

class _BiometriaWidgetState extends State<BiometriaWidget>
    with SingleTickerProviderStateMixin {
  final _biometricService = BiometricService();
  bool _isLoading = false;
  bool _isSupported = false;
  String _biometricName = 'Biometría';
  IconData _biometricIcon = Icons.fingerprint;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _checkBiometricSupport();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      // Timeout de 3s para no bloquear si el sistema biométrico tarda
      final isSupported = await _biometricService.isDeviceSupported().timeout(
        const Duration(seconds: 3),
        onTimeout: () => false,
      );
      if (!isSupported || !mounted) return;

      final results = await Future.wait([
        _biometricService.getAvailableBiometrics().timeout(
          const Duration(seconds: 3),
          onTimeout: () => [],
        ),
        _biometricService.getSavedCredentials().timeout(
          const Duration(seconds: 3),
          onTimeout: () => null,
        ),
      ]);

      final availableTypes = results[0] as List;
      final hasCredentials = results[1] != null;

      if (mounted) {
        setState(() {
          _isSupported = hasCredentials && availableTypes.isNotEmpty;
          _biometricName = _biometricService.getBiometricTypeName(
            availableTypes.cast(),
          );
          _biometricIcon = _biometricService.getBiometricIcon(
            availableTypes.cast(),
          );
        });
      }
    } catch (_) {
      // Silencioso — biometría no disponible
    }
  }

  Future<void> _authenticateWithBiometric() async {
    if (!_isSupported || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final didAuthenticate = await _biometricService.authenticate(
        reason: 'Autentícate para acceder a tu cuenta',
        useErrorDialogs: true,
        stickyAuth: true,
      );

      if (didAuthenticate) {
        // Obtener credenciales guardadas
        final credentials = await _biometricService.getSavedCredentials();

        if (credentials != null && widget.onBiometricSuccess != null) {
          // Ejecutar callback sin mostrar mensajes - solo animación y entrar a la app
          widget.onBiometricSuccess!(
            credentials['username']!,
            credentials['password']!,
          );
        }
        // Si no hay credenciales, no mostrar nada (fallo silencioso)
      }
      // Si se cancela la autenticación, no mostrar nada (fallo silencioso)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Solo mostrar si está soportado y habilitado
    if (!_isSupported) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _authenticateWithBiometric();
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, hijo) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _isLoading ? 0.6 : 1.0,
              child: Column(
                children: [
                  // Usar ConstrainedBox para limitar el ancho máximo
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveUtils.valueByDevice(
                        context: context,
                        mobile: widget.width * 0.8,
                        tablet: 400.0,
                        largeTablet: 500.0,
                        desktop: 600.0,
                      ),
                    ),
                    child: IntrinsicWidth(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _isLoading
                              ? SizedBox(
                                  width: ResponsiveUtils.mediumIconSize(
                                    context,
                                  ),
                                  height: ResponsiveUtils.mediumIconSize(
                                    context,
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      const Color(
                                        0xFF005BAC,
                                      ), // Color del design system
                                    ),
                                  ),
                                )
                              : Icon(
                                  _biometricIcon,
                                  color: const Color(
                                    0xFF005BAC,
                                  ), // Color del design system
                                  size: ResponsiveUtils.mediumIconSize(context),
                                ),
                          SizedBox(
                            width: ResponsiveUtils.cardSpacing(context) * 0.5,
                          ),
                          // Usar Flexible para que el texto se adapte
                          Flexible(
                            child: Text(
                              'Ingresar con $_biometricName',
                              style: TextStyle(
                                color: const Color(
                                  0xFF005BAC,
                                ), // Color del design system
                                fontWeight: FontWeight.w600,
                                fontSize: ResponsiveUtils.bodyFontSize(context),
                              ),
                              overflow: TextOverflow
                                  .ellipsis, // Evitar overflow de texto
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
