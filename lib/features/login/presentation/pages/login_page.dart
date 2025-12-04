import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:refactor_template/features/login/presentation/widgets/widgets.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:rive/rive.dart' hide Image;

/// Pantalla de inicio de sesión en una sola clase, con animación Rive
/// y navegación a [PantallaPrincipal] cuando el login es correcto.
class PaginaLogin extends StatefulWidget {
  static const name = 'pagina-login';
  const PaginaLogin({super.key});

  @override
  State<PaginaLogin> createState() => _PaginaLoginState();
}

class _PaginaLoginState extends State<PaginaLogin> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isShowLoading = false;
  bool isShowConfetti = false;

  SMITrigger? _errorTrigger;
  SMITrigger? _successTrigger;
  SMITrigger? _confettiTrigger;

  // Inicialización del Rive para el check/error
  void _onCheckRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (controller != null) {
      artboard.addController(controller);
      _errorTrigger = controller.findInput<bool>('Error') as SMITrigger?;
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

  void _onLoginPressed() {
    // Validación sencilla del formulario
    if (!_formKey.currentState!.validate()) {
      _errorTrigger?.fire();
      return;
    }

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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PantallaPrincipal()),
          );
        });
      });
    });
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lightBackground = Color(0xFFF6F8FB);
    const primaryBlue = Color(0xFF005BAC);
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
                                SizedBox(
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
                                const SizedBox(height: 4),
                                Text(
                                  'Bienvenido(a) a Posgrado UPEA',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width * 0.052,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: width * 0.02),
                                Text(
                                  'Tu trayectoria profesional siempre accesible.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFFFFCC3E),
                                    fontSize: width * 0.03,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: width * 0.02),
                                Text(
                                  'Accede a tu registro académico, programas aprobados y documentos pendientes.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: width * 0.033,
                                    height: 1.4,
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
                              Padding(
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
                                          child: Form(
                                            key: _formKey,
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
                                                    SizedBox(
                                                      width: width * 0.02,
                                                    ),
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

                                                // Usuario
                                                const Text(
                                                  'Usuario',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: width * 0.02),
                                                TextFormField(
                                                  controller: _userController,
                                                  validator: (value) =>
                                                      (value == null ||
                                                          value.isEmpty)
                                                      ? ''
                                                      : null,
                                                  decoration: _inputDecoration(
                                                    width,
                                                    hintText: 'Usuario',
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: isSmallHeight
                                                      ? width * 0.03
                                                      : width * 0.04,
                                                ),

                                                // Contraseña
                                                const Text(
                                                  'Contraseña',
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                SizedBox(height: width * 0.02),
                                                TextFormField(
                                                  controller:
                                                      _passwordController,
                                                  obscureText: true,
                                                  validator: (value) =>
                                                      (value == null ||
                                                          value.isEmpty)
                                                      ? ''
                                                      : null,
                                                  decoration: _inputDecoration(
                                                    width,
                                                    hintText: 'Contraseña',
                                                    suffixIcon: const Icon(
                                                      Icons.visibility_outlined,
                                                      color: Colors.black45,
                                                    ),
                                                  ),
                                                ),
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
                                                        color: Color(
                                                          0xFFFF8A00,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // BOTÓN ACCEDER sobrepuesto a la tarjeta
                                        Positioned(
                                          left: width * 0.10,
                                          right: width * 0.10,
                                          bottom: -width * 0.045,
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
                                      ],
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

                        // Touch ID
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.fingerprint,
                                color: const Color(0xFF1A4C9C),
                                size: width * 0.10,
                              ),
                              SizedBox(height: width * 0.02),
                              Text(
                                'Acceder con Biometria',
                                style: TextStyle(
                                  color: const Color(0xFF1A4C9C),
                                  fontWeight: FontWeight.w600,
                                  fontSize: width * 0.038,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: isSmallHeight ? width * 0.03 : width * 0.08,
                        ),

                        // Botones sociales
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _socialButton(
                              width,
                              icon: Icon(
                                FontAwesomeIcons.google,
                                size: width * 0.06,
                                color: const Color(0xFF4285F4),
                              ),
                            ),
                            SizedBox(width: width * 0.05),
                            _socialButton(
                              width,
                              icon: Icon(
                                Icons.facebook,
                                size: width * 0.08,
                                color: const Color(0xFF3B5998),
                              ),
                            ),
                            SizedBox(width: width * 0.05),
                            _socialButton(
                              width,
                              icon: Icon(
                                FontAwesomeIcons.twitter,
                                size: width * 0.06,
                                color: const Color(0xFF1DA1F2),
                              ),
                            ),
                          ],
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

  InputDecoration _inputDecoration(
    double width, {
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: Color(0xFFF8F9FB),
      contentPadding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.035,
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF005BAC), width: 1.2),
      ),
    );
  }

  Widget _socialButton(double width, {required Widget icon}) {
    return Container(
      width: 56,
      height: 56,
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
