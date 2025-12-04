import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rive/rive.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isShowLoading = false;
  bool isShowConfetti = false;
  SMITrigger? error;
  SMITrigger? success;
  SMITrigger? reset;

  SMITrigger? confetti;

  void _onCheckRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );

    if (controller != null) {
      artboard.addController(controller);
      error = controller.findInput<bool>('Error') as SMITrigger?;
      success = controller.findInput<bool>('Check') as SMITrigger?;
      reset = controller.findInput<bool>('Reset') as SMITrigger?;
    }
  }

  void _onConfettiRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      "State Machine 1",
    );
    if (controller != null) {
      artboard.addController(controller);
      confetti = controller.findInput<bool>("Trigger explosion") as SMITrigger?;
    }
  }

  void singIn(BuildContext context) {
    // Ya validamos el formulario antes de llamar a este método,
    // aquí solo mostramos la animación de éxito y navegamos.
    setState(() {
      isShowConfetti = true;
      isShowLoading = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      success?.fire();
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          isShowLoading = false;
        });
        confetti?.fire();
        // Navega a la pantalla de perfil después del login exitoso
        Future.delayed(const Duration(seconds: 1), () {
          if (!context.mounted) return;
          context.go('/perfil');
        });
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Usuario", style: TextStyle(color: Colors.black54)),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "";
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(hintText: 'Ingresa tu usuario'),
                ),
              ),
              const Text("Contraseña", style: TextStyle(color: Colors.black54)),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: TextFormField(
                  obscureText: true,
                  controller: _passwordController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return "";
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Ingresa tu contraseña',
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Si el formulario no es válido, mostramos la animación de error
                    if (!_formKey.currentState!.validate()) {
                      error?.fire();
                      return;
                    }

                    // TODO: Descomentar cuando el backend o la conexión  esté listo
                    // try {
                    //   final login = LoginDatasourceImpl();
                    //   await login.login(
                    //     _emailController.text.trim(),
                    //     _passwordController.text.trim(),
                    //   );
                    //
                    //   // Si el login en el backend fue correcto, lanzamos la animación de éxito
                    //   singIn(context);
                    // } catch (e) {
                    //   // Error al hacer login (credenciales incorrectas, sin conexión, etc.)
                    //   if (!mounted) return;
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(
                    //       content: Text(
                    //         'No se pudo iniciar sesión. Verifica tus datos.',
                    //       ),
                    //     ),
                    //   );
                    //   error?.fire();
                    // }

                    // Por ahora, navegamos directamente sin validar credenciales
                    singIn(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFC900),
                    minimumSize: const Size(double.infinity, 56),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                        bottomLeft: Radius.circular(25),
                      ),
                    ),
                  ),
                  icon: const SizedBox.shrink(),
                  label: const Text(
                    "ACCEDER",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        isShowLoading
            ? CustomPositioned(
                child: RiveAnimation.asset(
                  'assets/RiveAssets/check.riv',
                  fit: BoxFit.cover,
                  onInit: _onCheckRiveInit,
                ),
              )
            : const SizedBox(),
        isShowConfetti
            ? CustomPositioned(
                scale: 6,
                child: RiveAnimation.asset(
                  "assets/RiveAssets/confetti.riv",
                  onInit: _onConfettiRiveInit,
                  fit: BoxFit.cover,
                ),
              )
            : const SizedBox(),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, this.scale = 1, required this.child});

  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            height: 100,
            width: 100,
            child: Transform.scale(scale: scale, child: child),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
