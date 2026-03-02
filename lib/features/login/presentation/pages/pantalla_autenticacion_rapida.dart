import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_biometrico.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';

/// Pantalla de autenticación rápida con PIN o Biometría
class PantallaAutenticacionRapida extends StatefulWidget {
  static const name = 'autenticacion-rapida';
  
  const PantallaAutenticacionRapida({super.key});

  @override
  State<PantallaAutenticacionRapida> createState() => _PantallaAutenticacionRapidaState();
}

class _PantallaAutenticacionRapidaState extends State<PantallaAutenticacionRapida> with SingleTickerProviderStateMixin {
  final BiometricService _biometricService = BiometricService();
  String _currentPin = '';
  bool _isAuthenticating = false;
  bool _showError = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    // Intentar biometría automáticamente al entrar
    _tryBiometricOnStart();
  }
  
  Future<void> _tryBiometricOnStart() async {
    // Esperar un momento para que la pantalla se renderice
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (isEnabled) {
      // Intentar autenticación biométrica automáticamente
      await _tryBiometric();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_isAuthenticating) return;
    
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (!isEnabled || !mounted) return;
    setState(() => _isAuthenticating = true);

    // Salvaguarda extra: si por algún motivo la biometría se queda colgada,
    // forzar la cancelación del estado "Verificando..." después de unos segundos.
    Future.delayed(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_isAuthenticating) {
        debugPrint('⏱️ Salvaguarda: forzando fin de estado de verificación biométrica');
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo completar la verificación biométrica. Intenta nuevamente o usa tu PIN.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    try {
      // Agregar timeout de 5 segundos para evitar que se quede colgado
      final authenticated = await _biometricService.authenticate(
        reason: 'Coloca tu dedo en el sensor para ingresar',
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⏱️ Timeout de biometría - cancelando');
          return false;
        },
      );
      
      if (!mounted) return;
      
      if (authenticated) {
        debugPrint('✅ Biometría exitosa - navegando al inicio');
        HapticFeedback.heavyImpact();
        await _loginSuccess();
      } else {
        debugPrint('❌ Biometría fallida o cancelada');
        if (mounted) {
          setState(() => _isAuthenticating = false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error en biometría: $e');
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  Future<void> _loginSuccess() async {
    try {
      debugPrint('🔐 Iniciando proceso de login exitoso...');
      
      // Marcar como autenticado en esta sesión
      final session = await LocalStorageService.getSessionData();
      if (session != null) {
        session['authenticated'] = true;
        await LocalStorageService.saveSessionData(session);
        debugPrint('✅ Sesión actualizada correctamente');
      }
      
      if (!mounted) {
        debugPrint('⚠️ Widget no montado - cancelando navegación');
        return;
      }
      
      // Pequeña pausa para feedback visual
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      debugPrint('🚀 Autenticación rápida exitosa, resolviendo navegación...');

      // Si esta pantalla fue abierta con Navigator.push (por ejemplo desde el login),
      // devolvemos "true" para que la pantalla anterior decida la navegación.
      if (Navigator.canPop(context)) {
        debugPrint('🔙 Cerrando PantallaAutenticacionRapida con resultado TRUE');
        Navigator.of(context).pop(true);
      } else {
        // Si no hay nada que "poppear", navegamos directamente al menú principal.
        debugPrint('➡️ Navegando directamente a PantallaPrincipal desde autenticación rápida');
        context.goNamed(PantallaPrincipal.name);
      }
      
      debugPrint('✅ Flujo de navegación completado tras biometría/PIN');
    } catch (e) {
      debugPrint('❌ Error en _loginSuccess: $e');
      if (mounted) {
        setState(() => _isAuthenticating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al iniciar sesión. Intenta nuevamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _verifyPin() async {
    if (_currentPin.length != 4) return;
    
    setState(() => _isAuthenticating = true);
    
    // Esperar 1 segundo para mostrar el loader
    await Future.delayed(const Duration(milliseconds: 1000));
    
    final isValid = await _biometricService.verifyPin(_currentPin);
    
    if (isValid) {
      HapticFeedback.heavyImpact();
      await _loginSuccess();
    } else {
      HapticFeedback.vibrate();
      setState(() {
        _showError = true;
        _currentPin = '';
        _isAuthenticating = false;
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _showError = false);
      });
    }
  }

  void _addDigit(String digit) {
    if (_currentPin.length < 4 && !_isAuthenticating) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPin += digit;
      });
      
      if (_currentPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _removeDigit() {
    if (_currentPin.isNotEmpty && !_isAuthenticating) {
      HapticFeedback.lightImpact();
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              DesignTokens.primaryBlue,
              DesignTokens.primaryBlue.withOpacity(0.95),
              DesignTokens.primaryBlueLight.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),
              
              // Logo y título minimalista
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    // Logo de Posgrado con animación de pulso
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.05);
                        
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/logoposgrado.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Título simple
                    const Text(
                      'Bienvenido',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: DesignTokens.primaryFont,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Subtítulo discreto
                    Text(
                      _isAuthenticating 
                          ? 'Autenticando...'
                          : 'Ingresa tu PIN',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.8),
                        fontFamily: DesignTokens.primaryFont,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 80),
              
              // Puntos del PIN minimalistas
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                duration: const Duration(milliseconds: 500),
                child: _isAuthenticating
                    ? Column(
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Verificando...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.8),
                              fontFamily: DesignTokens.primaryFont,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          bool isFilled = index < _currentPin.length;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _showError 
                                  ? Colors.red.shade300
                                  : (isFilled 
                                      ? Colors.white 
                                      : Colors.transparent),
                              border: Border.all(
                                color: _showError 
                                    ? Colors.red.shade300
                                    : Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                          );
                        }),
                      ),
              ),
              
              if (_showError) ...[
                const SizedBox(height: 16),
                FadeIn(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'PIN incorrecto',
                    style: TextStyle(
                      color: Colors.red.shade200,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: DesignTokens.primaryFont,
                    ),
                  ),
                ),
              ],
              
              const Spacer(),
              
              // Teclado numérico minimalista
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 60),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.4,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      Widget content;
                      VoidCallback? action;
                      
                      if (index < 9) {
                        final num = index + 1;
                        content = Text(
                          '$num',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: _isAuthenticating 
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.9),
                            fontFamily: DesignTokens.primaryFont,
                          ),
                        );
                        action = _isAuthenticating ? null : () => _addDigit('$num');
                      } else if (index == 9) {
                        content = Icon(
                          Icons.fingerprint_rounded,
                          color: _isAuthenticating 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.7),
                          size: 28,
                        );
                        action = _isAuthenticating ? null : _tryBiometric;
                      } else if (index == 10) {
                        content = Text(
                          '0',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w400,
                            color: _isAuthenticating 
                                ? Colors.white.withOpacity(0.3)
                                : Colors.white.withOpacity(0.9),
                            fontFamily: DesignTokens.primaryFont,
                          ),
                        );
                        action = _isAuthenticating ? null : () => _addDigit('0');
                      } else {
                        content = Icon(
                          Icons.backspace_outlined,
                          color: _isAuthenticating 
                              ? Colors.white.withOpacity(0.2)
                              : Colors.white.withOpacity(0.7),
                          size: 24,
                        );
                        action = _isAuthenticating ? null : _removeDigit;
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: action,
                          borderRadius: BorderRadius.circular(50),
                          splashColor: Colors.white.withOpacity(0.1),
                          highlightColor: Colors.white.withOpacity(0.05),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.transparent,
                            ),
                            child: Center(child: content),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Texto institucional discreto
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Posgrado UPEA',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: DesignTokens.primaryFont,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
