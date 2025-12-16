import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:refactor_template/core/services/biometric_service.dart';

class BotonPrimario extends StatelessWidget {
  const BotonPrimario({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          print('Holaa');
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIcon(
          color: Colors.white,
          child: Icon(
            FontAwesomeIcons.google,
            size: width * 0.06,
            color: const Color(0xFF4285F4),
          ),
        ),
        SizedBox(width: width * 0.04),
        _SocialIcon(
          color: Colors.white,
          child: Icon(
            Icons.facebook,
            size: width * 0.08,
            color: const Color(0xFF3B5998),
          ),
        ),
        SizedBox(width: width * 0.04),
        _SocialIcon(
          color: Colors.white,
          child: Icon(
            FontAwesomeIcons.twitter,
            size: width * 0.06,
            color: const Color(0xFF1DA1F2),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
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
  List<BiometricType> _availableTypes = [];
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
    final isSupported = await _biometricService.isDeviceSupported();
    if (isSupported) {
      final availableTypes = await _biometricService.getAvailableBiometrics();
      // Verificar si hay credenciales guardadas (no solo si está habilitado)
      final hasCredentials =
          await _biometricService.getSavedCredentials() != null;

      if (mounted) {
        setState(() {
          // Mostrar si hay biometría disponible Y hay credenciales guardadas
          _isSupported =
              isSupported && hasCredentials && availableTypes.isNotEmpty;
          _availableTypes = availableTypes;
          _biometricName = _biometricService.getBiometricTypeName(
            availableTypes,
          );
          _biometricIcon = _biometricService.getBiometricIcon(availableTypes);
        });
      }
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
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _isLoading ? 0.6 : 1.0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isLoading
                          ? SizedBox(
                              width: widget.width * 0.08,
                              height: widget.width * 0.08,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color(0xFF1A4C9C),
                                ),
                              ),
                            )
                          : Icon(
                              _biometricIcon,
                              color: const Color(0xFF1A4C9C),
                              size: widget.width * 0.08,
                            ),
                      SizedBox(width: widget.width * 0.02),
                      Text(
                        'Ingresar con $_biometricName',
                        style: TextStyle(
                          color: const Color(0xFF1A4C9C),
                          fontWeight: FontWeight.w600,
                          fontSize: widget.width * 0.04,
                        ),
                      ),
                    ],
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
