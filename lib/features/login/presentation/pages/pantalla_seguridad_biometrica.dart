import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/animations/enhanced_animations.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/servicio_biometrico.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricSetupScreen extends StatefulWidget {
  static const name = 'biometric-setup-screen';
  const BiometricSetupScreen({super.key});

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  final BiometricService _biometricService = BiometricService();
  bool _isProcessing = false;
  bool _isAutoLoginDone = false;
  bool _showEpicIntro = false;
  String _introMessage = 'ACCESO CONCEDIDO';
  bool _pinConfigured = false;
  bool _biometricConfigured = false;

  @override
  void initState() {
    super.initState();
    _performAutoLoginPersistence();
  }

  /// Asegura que la sesión esté guardada antes de configurar biometría
  Future<void> _performAutoLoginPersistence() async {
    final personalData = await LocalStorageService.getPersonalData();
    final nombre = personalData?['nombre'] ?? 'Usuario';
    final ci = personalData?['numeroCI'] ?? '';

    await LocalStorageService.saveSessionData({
      'nombreUsuario': ci,
      'nombreCompleto': nombre,
      'rol': 'participante',
      'loginDate': DateTime.now().toIso8601String(),
    });
    setState(() => _isAutoLoginDone = true);
  }

  Future<void> _setupBiometrics({bool showAnimation = false}) async {
    if (!_isAutoLoginDone) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final isSupported = await _biometricService.isDeviceSupported();
      if (!isSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu dispositivo no soporta autenticación biométrica'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      // Si se llama manualmente (sin animación previa), mostrar la animación
      if (showAnimation && mounted) {
        // Mostrar diálogo sin await para que se vea mientras se autentica
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animación de huella pulsante
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF305BA4).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              size: 60,
                              color: Color(0xFF305BA4),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // Repetir la animación
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Registra tu Huella',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005BAC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Coloca tu dedo en el sensor biométrico',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF305BA4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
        // Pequeño delay para que el diálogo se muestre
        await Future.delayed(const Duration(milliseconds: 300));
      }

      final personalData = await LocalStorageService.getPersonalData();
      final ci = personalData?['numeroCI']?.toString() ?? '';
      
      final authenticated = await _biometricService.authenticate(
        reason: 'Confirma tu identidad para habilitar el acceso rápido',
        isSetup: true, // Indicar que es configuración inicial
      );

      // Cerrar diálogo de animación
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (authenticated) {
        await _biometricService.setBiometricEnabled(true);
        setState(() => _biometricConfigured = true);
        
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Biometría configurada correctamente'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Usuario canceló o falló la autenticación
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometría no configurada. Podrás usar solo el PIN.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error en configuración biométrica: $e');
      
      // Cerrar diálogo de animación si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al configurar biometría: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _setupPin() async {
    String currentPin = '';
    
    if (!mounted) return;

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 40),
              const Icon(Icons.lock_person_rounded, size: 60, color: Color(0xFF305BA4)),
              const SizedBox(height: 20),
              const Text('Crea tu PIN Seguro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF005BAC))),
              const SizedBox(height: 10),
              const Text('Usa un código de 4 dígitos que recuerdes fácilmente.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(height: 40),
              
              // Visualización de los puntos del PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  bool isFilled = index < currentPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? const Color(0xFF305BA4) : Colors.grey[200],
                      border: Border.all(color: isFilled ? const Color(0xFF305BA4) : Colors.grey[300]!, width: 2),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Teclado Numérico Custom
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  Widget content;
                  VoidCallback? action;
                  
                  if (index < 9) {
                    final num = index + 1;
                    content = Text('$num', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600));
                    action = () {
                      if (currentPin.length < 4) {
                        setModalState(() => currentPin += '$num');
                        if (currentPin.length == 4) {
                          HapticFeedback.mediumImpact();
                        } else {
                          HapticFeedback.lightImpact();
                        }
                      }
                    };
                  } else if (index == 9) {
                    content = const Icon(Icons.close_rounded, color: Colors.grey);
                    action = () => Navigator.pop(context);
                  } else if (index == 10) {
                    content = const Text('0', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600));
                    action = () {
                      if (currentPin.length < 4) {
                        setModalState(() => currentPin += '0');
                        HapticFeedback.lightImpact();
                      }
                    };
                  } else {
                    content = const Icon(Icons.backspace_outlined, color: Colors.redAccent);
                    action = () {
                      if (currentPin.isNotEmpty) {
                        setModalState(() => currentPin = currentPin.substring(0, currentPin.length - 1));
                        HapticFeedback.lightImpact();
                      }
                    };
                  }

                  return InkWell(
                    onTap: action,
                    borderRadius: BorderRadius.circular(20),
                    child: Center(child: content),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              FadeInUp(
                duration: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: currentPin.length < 4 ? null : () async {
                      // Guardar PIN usando el servicio biométrico
                      await _biometricService.savePin(currentPin);
                      if (context.mounted) Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF305BA4),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('CONFIRMAR PIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      setState(() => _pinConfigured = true);
      
      // Verificar si el dispositivo soporta biometría ANTES de mostrar la animación
      final isSupported = await _biometricService.isDeviceSupported();
      
      if (isSupported && mounted) {
        // Mostrar diálogo de animación sin await
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animación de huella pulsante
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeInOut,
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: const Color(0xFF305BA4).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fingerprint,
                              size: 60,
                              color: Color(0xFF305BA4),
                            ),
                          ),
                        );
                      },
                      onEnd: () {
                        // Repetir la animación
                        if (mounted) {
                          setState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Registra tu Huella',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005BAC),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Coloca tu dedo en el sensor biométrico',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF305BA4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        
        // Pequeño delay para que el diálogo se muestre
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Intentar configurar biometría (esto cerrará el diálogo)
        await _setupBiometrics();
        
        if (_biometricConfigured && mounted) {
          _startEpicIntro(message: 'SEGURIDAD COMPLETA');
        } else if (mounted) {
          _startEpicIntro(message: 'PIN CONFIGURADO');
        }
      } else if (mounted) {
        // Si no tiene biometría, solo mostrar PIN configurado sin intentar biometría
        _startEpicIntro(message: 'PIN CONFIGURADO');
      }
    }
  }

  Future<void> _showBiometricRegistrationAnimation() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animación de huella pulsante
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.2),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: const Color(0xFF305BA4).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 60,
                          color: Color(0xFF305BA4),
                        ),
                      ),
                    );
                  },
                  onEnd: () {
                    // Repetir la animación
                    if (mounted) {
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registra tu Huella',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAC),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Coloca tu dedo en el sensor biométrico para registrar tu huella',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF305BA4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showBiometricPrompt() async {
    final isSupported = await _biometricService.isDeviceSupported();
    if (!isSupported) return false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF305BA4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.fingerprint, color: Color(0xFF305BA4), size: 32),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                '¿Activar Biometría?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Tu dispositivo soporta autenticación biométrica. ¿Deseas activarla para un acceso más rápido?\n\nPodrás usar tu huella o reconocimiento facial además del PIN.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ahora no', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF305BA4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );
  }

  void _startEpicIntro({required String message}) {
    setState(() {
      _showEpicIntro = true;
      _introMessage = message;
    });
    
    HapticFeedback.vibrate();
    
    // El router disparará la navegación después de la animación épica
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _goToMainScreen();
    });
  }

  void _goToMainScreen() {
    context.go('/sistema/pantalla_principal');
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF005BAC);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(),
                  
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryBlue.withOpacity(0.1), width: 2),
                      ),
                      child: Hero(
                        tag: 'security_icon',
                        child: Icon(
                          Icons.security_rounded,
                          size: 70,
                          color: primaryBlue.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: const Text(
                      'Protege tu Cuenta',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  FadeInUp(
                    duration: const Duration(milliseconds: 700),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'Configura tu PIN de seguridad. También puedes activar la biometría para un acceso más rápido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[500],
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Opción PIN (Obligatorio)
                          _buildSecurityOption(
                            icon: Icons.dialpad_rounded,
                            title: 'PIN de Seguridad',
                            subtitle: _pinConfigured ? '✓ Configurado' : 'Obligatorio - 4 dígitos',
                            onTap: _pinConfigured ? null : _setupPin,
                            isPrimary: true,
                            isRequired: true,
                            isConfigured: _pinConfigured,
                          ),
                          const SizedBox(height: 12),
                          // Opción Biometría (Opcional)
                          _buildSecurityOption(
                            icon: Icons.fingerprint_rounded,
                            title: 'Biometría',
                            subtitle: _biometricConfigured ? '✓ Configurado' : 'Opcional - Huella o Rostro',
                            onTap: (_isProcessing || _biometricConfigured) ? null : () => _setupBiometrics(showAnimation: true),
                            isConfigured: _biometricConfigured,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Botón para continuar (solo si configuró PIN)
                  if (_pinConfigured)
                    FadeInUp(
                      duration: const Duration(milliseconds: 900),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _startEpicIntro(
                            message: _biometricConfigured 
                              ? 'SEGURIDAD COMPLETA' 
                              : 'PIN CONFIGURADO'
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'CONTINUAR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  FadeIn(
                    delay: const Duration(seconds: 1),
                    child: TextButton(
                      onPressed: _pinConfigured ? null : _goToMainScreen,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[400],
                      ),
                      child: Text(
                        _pinConfigured ? 'Configuración completada' : 'Configurar después',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // OVERLAY ÉPICO
          if (_showEpicIntro)
            Positioned.fill(
              child: Container(
                color: primaryBlue,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BounceInAnimation(
                      duration: const Duration(milliseconds: 800),
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 120,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    FadeInUp(
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        _introMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    FadeInUp(
                      delay: const Duration(milliseconds: 600),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'INICIANDO SISTEMA...',
                          style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    // Línea de escaneo animada
                    ElasticInLeft(
                      child: Container(
                        width: 200,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              Colors.white,
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isPrimary = false,
    bool isRequired = false,
    bool isConfigured = false,
  }) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color successGreen = Color(0xFF4CAF50);
    
    return Material(
      color: isConfigured 
          ? successGreen.withOpacity(0.1)
          : (isPrimary ? primaryBlue : Colors.white),
      borderRadius: BorderRadius.circular(20),
      elevation: (isPrimary && !isConfigured) ? 8 : 0,
      shadowColor: primaryBlue.withOpacity(0.3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isConfigured
                ? Border.all(color: successGreen, width: 2)
                : (isPrimary ? null : Border.all(color: const Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConfigured
                      ? successGreen.withOpacity(0.2)
                      : (isPrimary ? Colors.white.withOpacity(0.15) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isConfigured ? Icons.check_circle : icon,
                  color: isConfigured
                      ? successGreen
                      : (isPrimary ? Colors.white : primaryBlue),
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: isConfigured
                                  ? successGreen
                                  : (isPrimary ? Colors.white : const Color(0xFF005BAC)),
                            ),
                          ),
                        ),
                        if (isRequired && !isConfigured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'REQUERIDO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isConfigured
                            ? successGreen
                            : (isPrimary ? Colors.white.withOpacity(0.9) : Colors.grey[600]),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isConfigured ? Icons.check_circle : Icons.chevron_right_rounded,
                color: isConfigured
                    ? successGreen
                    : (isPrimary ? Colors.white.withOpacity(0.9) : Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
