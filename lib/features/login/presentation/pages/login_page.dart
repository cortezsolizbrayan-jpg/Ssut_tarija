import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:refactor_template/features/login/presentation/widgets/widgets.dart';

class LoginPage extends StatelessWidget {
  static const name = 'login-page';
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    const lightBackground = Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: lightBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = constraints.maxHeight;

          return SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: maxHeight),
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _TopHero(width: width),
                      Positioned(
                        bottom: -width * 0.75,
                        left: width * 0.04,
                        right: width * 0.04,
                        child: SlideInUp(
                          duration: const Duration(milliseconds: 1000),
                          delay: const Duration(milliseconds: 300),
                          child: TarjetaAutenticacionWidget(width: width),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: width * 0.88),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 1300),
                          child: _TouchIdPrompt(width: width),
                        ),
                        SizedBox(height: width * 0.06),
                        FadeInUp(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 1500),
                          child: BotonesSociales(width: width),
                        ),
                        SizedBox(height: width * 0.10),
                      ],
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

class _TopHero extends StatelessWidget {
  const _TopHero({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: width * 0.08,
        right: width * 0.08,
        top: width * 0.08,
        bottom: width * 0.18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF113A82), Color(0xFF0B2A5C)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(90)),
      ),
      child: Column(
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: width * 0.3,
              height: width * 0.3,
              // decoration: BoxDecoration(
              //   // color: Colors.white.withOpacity(0.15),
              //   color: Colors.white.withAlpha(38),
              //   shape: BoxShape.circle,
              // ),
              child: Padding(
                padding: EdgeInsets.all(width * 0.001),
                child: Image.asset(
                  'assets/images/graduation_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 200),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.09,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  Icons.emoji_people_outlined,
                  color: Colors.white,
                  size: width * 0.09,
                ),
              ],
            ),
          ),
          SizedBox(height: width * 0.02),
          FadeInDown(
            duration: const Duration(milliseconds: 800),
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withAlpha(136),
                fontSize: width * 0.04,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.width,
    this.icon,
    this.obscureText = false,
    this.suffix,
  });

  final String label;
  final IconData? icon;
  final double width;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFFE6E9EF);

    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: TextStyle(
          color: const Color(0xFF9AA2B1),
          fontSize: width * 0.04,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: width * 0.06, color: const Color(0xFF9AA2B1)),
        suffixIcon: suffix,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding: EdgeInsets.symmetric(vertical: width * 0.045),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFF1A4C9C)),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC727),
          foregroundColor: const Color(0xFF0D1730),
          elevation: 8,
          padding: EdgeInsets.symmetric(vertical: width * 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
          ),
          shadowColor: const Color(0x33FFC727),
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

class _TouchIdPrompt extends StatelessWidget {
  const _TouchIdPrompt({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              color: const Color(0xFF1A4C9C),
              size: width * 0.08,
            ),
            SizedBox(width: width * 0.02),
            Text(
              'Ingresar con biometría',
              style: TextStyle(
                color: const Color(0xFF1A4C9C),
                fontWeight: FontWeight.w600,
                fontSize: width * 0.04,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
