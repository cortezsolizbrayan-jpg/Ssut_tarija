import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/animations/custom_animations.dart';
import 'package:refactor_template/core/services/biometric_service.dart';
import 'package:refactor_template/features/login/presentation/widgets/widgets.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:rive/rive.dart' hide Image;

import '../../widgets/widgets.dart';

/// Pantalla de inicio de sesión en una sola clase, con animación Rive
/// y navegación a [PantallaPrincipal] cuando el login es correcto.
class PaginaLogin extends ConsumerStatefulWidget {
  static const name = 'pagina-login';
  const PaginaLogin({super.key});

  @override
  ConsumerState<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends ConsumerState<PaginaLogin> {
  late String usuario;
  late String contra;
  bool isShowLoading = false;
  bool isShowConfetti = false;

  SMITrigger? _successTrigger;
  SMITrigger? _confettiTrigger;

  final _biometricService = BiometricService();

  // Inicialización del Rive para el check/error
  void _onCheckRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (controller != null) {
      artboard.addController(controller);
      _successTrigger = controller.findInput<bool>('Check') as SMITrigger?;
    }
  }

  // Inicialización del Rive para el confetti
  void _onConfettiRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (controller != null) {
      artboard.addController(controller);
      _confettiTrigger =
          controller.findInput<bool>('Trigger explosion') as SMITrigger?;
    }
  }

  /// Guarda las credenciales para biometría después de un login exitoso
  Future<void> _saveCredentialsForBiometric(
    String username,
    String password,
  ) async {
    try {
      // Verificar si el dispositivo soporta biometría
      final isSupported = await _biometricService.isDeviceSupported();
      if (isSupported) {
        final availableTypes = await _biometricService.getAvailableBiometrics();
        if (availableTypes.isNotEmpty) {
          // Habilitar biometría y guardar credenciales
          await _biometricService.setBiometricEnabled(true);
          await _biometricService.saveCredentials(
            username: username,
            password: password,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Biometría habilitada. Podrás usar ${_biometricService.getBiometricTypeName(availableTypes)} para iniciar sesión.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error guardando credenciales para biometría: $e');
    }
  }

  void _onLoginPressed({String? username, String? password}) {
    // Usar credenciales de biometría si se proporcionan, sino usar las del formulario
    final loginUsername = username ?? usuario;
    final loginPassword = password ?? contra;

    // ============================================
    // TEMPORAL: Autenticación deshabilitada para desarrollo
    // ============================================
    // Navegación directa sin autenticación
    setState(() {
      isShowLoading = true;
      isShowConfetti = false;
    });

    // Secuencia de animaciones y luego navegación
    Future.delayed(const Duration(seconds: 1), () {
      _successTrigger?.fire();
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() {
          isShowLoading = false;
          isShowConfetti = true;
        });
        _confettiTrigger?.fire();

        // Guardar credenciales para biometría después de login exitoso
        _saveCredentialsForBiometric(loginUsername, loginPassword);

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          setState(() {
            isShowConfetti = false;
          });
          context.go(PantallaPrincipal.name);
        });
      });
    });
    //AQUI SE EEXPLICA LA AUTENTICACION

    // ============================================
    // CÓDIGO ORIGINAL DE AUTENTICACIÓN (COMENTADO)
    // ============================================
    /*
    // Validación sencilla del formulario
    ref
        .read(asyncLoginProvider(usuario, contra).future)
        .then((response) {
          print("""
            Login response: 
            ${response.status}
            ${response.data.token}
            ${response.data.expiresIn}
            ${response.data.nombreUsuario}
            ${response.data.grupos.map((g) => g).toList()}
            ${response.message}
            """);
          setState(() {
            isShowLoading = true;
            // El confeti solo debe mostrarse cuando el login sea exitoso
            isShowConfetti = false;
          });

          // Secuencia de animaciones y luego navegación
          Future.delayed(const Duration(seconds: 1), () {
            _successTrigger?.fire();
            Future.delayed(const Duration(seconds: 2), () {
              if (!mounted) return;
              setState(() {
                isShowLoading = false;
                // Momento en el que el usuario ha pasado la validación (login exitoso)
                // y se muestra el confeti
                isShowConfetti = true;
              });
              _confettiTrigger?.fire();

              Future.delayed(const Duration(seconds: 1), () {
                if (!mounted) return;
                // Ocultamos el confeti al navegar
                setState(() {
                  isShowConfetti = false;
                });
                context.go(PantallaPrincipal.name);
              });
            });
          });
        })
        .catchError((error) {
          _errorTrigger?.fire();
          print(error);
        });
    */
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lightBackground = Color(0xFFF6F8FB);
    const primaryBlue = Color(0xFF305BA4);
    const accentYellow = Color(0xFFFFC900);

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.of(context).size;
            final width = size.width;
            final height = constraints.maxHeight;
            final isSmallHeight = height < 700;

            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  physics: isSmallHeight
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // HEADER AZUL CON CUSTOMPAINTER
                        FondoAzulCurvoWidget(
                          color: primaryBlue,
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: width * 0.08,
                              right: width * 0.08,
                              top: width * 0.08,
                              bottom: isSmallHeight
                                  ? width * 0.14
                                  : width * 0.18,
                            ),
                            child: Column(
                              children: [
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 100),
                                  begin: const Offset(0, -0.5),
                                  curve: Curves.easeOutCubic,
                                  child: ScaleInAnimation(
                                    duration: const Duration(milliseconds: 1000),
                                    delay: const Duration(milliseconds: 100),
                                    curve: Curves.easeOutBack,
                                    child: SizedBox(
                                      width: width * 0.30,
                                      height: width * 0.30,
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.005),
                                        child: Image.asset(
                                          'assets/images/graduation_icon.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 700),
                                  delay: const Duration(milliseconds: 300),
                                  begin: const Offset(0, 0.3),
                                  child: Text(
                                    'Bienvenido(a) a Posgrado UPEA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.052,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(height: width * 0.02),
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 700),
                                  delay: const Duration(milliseconds: 400),
                                  begin: const Offset(0, 0.3),
                                  child: Text(
                                    'Tu trayectoria profesional siempre accesible.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFCC3E),
                                      fontSize: width * 0.03,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                SizedBox(height: width * 0.02),
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 700),
                                  delay: const Duration(milliseconds: 500),
                                  begin: const Offset(0, 0.3),
                                  child: Text(
                                    'Accede a tu registro académico, programas aprobados y documentos pendientes.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: width * 0.033,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: width * 0.03),
                        // TARJETA DE AUTENTICACIÓN + BOTÓN ACCEDER
                        // (todo el bloque se superpone ligeramente al header azul)
                        Transform.translate(
                          offset: Offset(0, -width * 0.14),
                          child: Column(
                            children: [
                              SlideInAnimation(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 600),
                                begin: const Offset(0, 0.5),
                                curve: Curves.easeOutCubic,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: width * 0.06,
                                  ),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: double.infinity,
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Tarjeta blanca
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: width * 0.06,
                                              vertical: isSmallHeight
                                                  ? width * 0.04
                                                  : width * 0.06,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(
                                                32,
                                              ),
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Color(0x1A0D0D0D),
                                                  blurRadius: 24,
                                                  offset: Offset(0, 18),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      FontAwesomeIcons.lock,
                                                      color: primaryBlue,
                                                    ),
                                                    SizedBox(width: width * 0.02),
                                                    Text(
                                                      'INICIAR SESIÓN',
                                                      style: TextStyle(
                                                        // color: primaryBlue,
                                                        fontSize: width * 0.042,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: isSmallHeight
                                                      ? width * 0.04
                                                      : width * 0.06,
                                                ),
                                                SizedBox(height: width * 0.02),

                                                // TextFormField(
                                                //   controller: _userController,
                                                //   validator: (value) =>
                                                //       (value == null ||
                                                //           value.isEmpty)
                                                //       ? ''
                                                //       : null,
                                                //   decoration: _inputDecoration(
                                                //     width,
                                                //     hintText: 'Usuario',
                                                //   ),
                                                // ),
                                                CustomTextFormField(
                                                  label: 'Usuario',
                                                  onChanged: (valor) {
                                                    usuario = valor;
                                                  },
                                                  // errorMessage:
                                                  //     'Usuario Incorrecto',
                                                ),
                                                SizedBox(
                                                  height: isSmallHeight
                                                      ? width * 0.03
                                                      : width * 0.04,
                                                ),

                                                // Contraseña
                                                SizedBox(height: width * 0.02),
                                                CustomTextFormField(
                                                  label: 'Contraseña',
                                                  onChanged: (valor) {
                                                    contra = valor;
                                                  },
                                                  obscureText: true,
                                                  icon: Icon(
                                                    Icons.visibility_outlined,
                                                    color: Colors.black45,
                                                  ),
                                                  // errorMessage:
                                                  //     'Contraseña Incorrecto',
                                                ),
                                                // TextFormField(
                                                //   controller: _passwordController,
                                                //   obscureText: true,
                                                //   validator: (value) =>
                                                //       (value == null ||
                                                //           value.isEmpty)
                                                //       ? ''
                                                //       : null,
                                                //   decoration: _inputDecoration(
                                                //     width,
                                                //     hintText: 'Contraseña',
                                                //     suffixIcon: const Icon(
                                                //       Icons.visibility_outlined,
                                                //       color: Colors.black45,
                                                //     ),
                                                //   ),
                                                // ),
                                                SizedBox(height: width * 0.02),

                                                // Recuperar contraseña
                                                Center(
                                                  child: TextButton(
                                                    onPressed: () {
                                                      // TODO: Implementar recuperación de contraseña
                                                    },
                                                    child: const Text(
                                                      'Recupera tu contraseña de acceso',
                                                      style: TextStyle(
                                                        color: Color(0xFFFF8A00),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: width * 0.07),
                                              ],
                                            ),
                                          ),

                                          // BOTÓN ACCEDER sobrepuesto a la tarjeta
                                          Positioned(
                                            left: width * 0.10,
                                            right: width * 0.10,
                                            bottom: -width * 0.045,
                                            child: ScaleInAnimation(
                                              duration: const Duration(milliseconds: 600),
                                              delay: const Duration(milliseconds: 1000),
                                              curve: Curves.easeOutBack,
                                              child: HoverScaleEffect(
                                                scale: 1.03,
                                                child: SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: _onLoginPressed,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: accentYellow,
                                                      foregroundColor: const Color(
                                                        0xFF0D1730,
                                                      ),
                                                      elevation: 8,
                                                      shadowColor: const Color(
                                                        0x33FFC900,
                                                      ),
                                                      padding: EdgeInsets.symmetric(
                                                        vertical: width * 0.035,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      'ACCEDER',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w800,
                                                        fontSize: width * 0.032,
                                                        letterSpacing: 1.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: isSmallHeight ? width * 0.02 : width * 0.01,
                        ),

                        // Biometría - Widget mejorado con funcionalidad
                        Center(
                          child: BiometriaWidget(
                            width: width,
                            onBiometricSuccess: (username, password) {
                              // Ejecutar login con las credenciales obtenidas de biometría
                              _onLoginPressed(
                                username: username,
                                password: password,
                              );
                            },
                          ),
                        ),

                        SizedBox(
                          height: isSmallHeight ? width * 0.03 : width * 0.08,
                        ),

                        // Botones sociales
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final buttonSize = availableWidth < 200
                                ? 48.0
                                : 56.0;
                            final spacing = availableWidth < 200
                                ? 8.0
                                : width * 0.05;

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 1100),
                                  begin: const Offset(-0.3, 0),
                                  child: HoverScaleEffect(
                                    scale: 1.1,
                                    child: _socialButton(
                                      width,
                                      buttonSize: buttonSize,
                                      icon: Icon(
                                        FontAwesomeIcons.google,
                                        size: buttonSize * 0.4,
                                        color: const Color(0xFF4285F4),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                ScaleInAnimation(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 1200),
                                  curve: Curves.easeOutBack,
                                  child: HoverScaleEffect(
                                    scale: 1.1,
                                    child: _socialButton(
                                      width,
                                      buttonSize: buttonSize,
                                      icon: Icon(
                                        Icons.facebook,
                                        size: buttonSize * 0.4,
                                        color: const Color(0xFF3B5998),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: spacing),
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 1300),
                                  begin: const Offset(0.3, 0),
                                  child: HoverScaleEffect(
                                    scale: 1.1,
                                    child: _socialButton(
                                      width,
                                      buttonSize: buttonSize,
                                      icon: Icon(
                                        FontAwesomeIcons.twitter,
                                        size: buttonSize * 0.4,
                                        color: const Color(0xFF1DA1F2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        SizedBox(
                          height: isSmallHeight ? width * 0.05 : width * 0.10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Overlays Rive
                if (isShowLoading) 
                  Positioned.fill(
                    child: Column(
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: RiveAnimation.asset(
                            'assets/RiveAssets/check.riv',
                            fit: BoxFit.cover,
                            onInit: _onCheckRiveInit,
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
                if (isShowConfetti)
                  Positioned.fill(
                    child: Column(
                      children: [
                        const Spacer(),
                        SizedBox(
                          height: 100,
                          width: 100,
                          child: Transform.scale(
                            scale: 6,
                            child: RiveAnimation.asset(
                              'assets/RiveAssets/confetti.riv',
                              fit: BoxFit.cover,
                              onInit: _onConfettiRiveInit,
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _socialButton(
    double width, {
    required Widget icon,
    double? buttonSize,
  }) {
    final size = buttonSize ?? 56.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Color(0xFFE6E9EF)),
      ),
      child: Center(child: icon),
    );
  }
}
