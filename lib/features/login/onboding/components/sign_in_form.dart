import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isShowLoading = false;
  bool isShowSuccess = false;
  bool isShowError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  void singIn(BuildContext context) {
    // Ya validamos el formulario antes de llamar a este método,
    // aquí solo mostramos la animación de éxito y navegamos.
    setState(() {
      isShowLoading = true;
      isShowError = false;
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        isShowLoading = false;
        isShowSuccess = true;
      });
      _animationController.forward();
      
      // Navega a la pantalla de perfil después del login exitoso
      Future.delayed(const Duration(seconds: 2), () {
        if (!context.mounted) return;
        context.go('/perfil');
      });
    });
  }
  
  void showError() {
    setState(() {
      isShowError = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isShowError = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
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
                      showError();
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
                    //   showError();
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
        if (isShowLoading)
          CustomPositioned(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC900)),
                strokeWidth: 3,
              ),
            ),
          ),
        if (isShowSuccess)
          CustomPositioned(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 60,
                ),
              ),
            ),
          ),
        if (isShowError)
          CustomPositioned(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.all(20),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
      ],
    );
  }
}

class CustomPositioned extends StatelessWidget {
  const CustomPositioned({super.key, required this.child});

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
            child: child,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
