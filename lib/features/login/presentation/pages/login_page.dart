import 'package:flutter/material.dart';

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
                        child: _AuthCard(width: width),
                      ),
                    ],
                  ),
                  SizedBox(height: width * 0.88),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: width * 0.08),
                    child: Column(
                      children: [
                        _TouchIdPrompt(width: width),
                        SizedBox(height: width * 0.06),
                        _SocialButtons(width: width),
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
          Container(
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
          Row(
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
          SizedBox(height: width * 0.02),
          Text(
            'Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(136),
              fontSize: width * 0.04,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: width * 0.06,
            right: width * 0.06,
            top: width * 0.08,
            bottom: width * 0.16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0D0D0D),
                blurRadius: 24,
                offset: Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Iniciar Sesión',
                style: TextStyle(
                  color: const Color(0xFF15223B),
                  fontSize: width * 0.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: width * 0.01),
              Container(
                width: width * 0.25,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFE54D52),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: width * 0.06),
              _LoginField(
                label: 'Usuario',
                width: width,
                icon: Icons.person_outline,
              ),
              SizedBox(height: width * 0.05),
              _LoginField(
                label: 'Contraseña',
                icon: Icons.lock_outline,
                width: width,
                obscureText: true,
                suffix: Icon(
                  Icons.remove_red_eye_outlined,
                  color: const Color(0xFF9AA2B1),
                  size: width * 0.055,
                ),
              ),
              SizedBox(height: width * 0.04),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Olvidaste Contraseña?',
                  style: TextStyle(
                    color: const Color(0xFFFF8A00),
                    fontSize: width * 0.037,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -width * 0.07,
          left: width * 0.09,
          right: width * 0.09,
          child: _PrimaryButton(width: width),
        ),
      ],
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

class _SocialButtons extends StatelessWidget {
  const _SocialButtons({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialIcon(
          color: Colors.white,
          child: Icon(
            Icons.g_mobiledata,
            size: width * 0.08,
            color: const Color(0xFF4285F4),
          ),
        ),
        SizedBox(width: width * 0.04),
        _SocialIcon(
          color: Colors.white,
          child: Icon(
            Icons.facebook,
            size: width * 0.065,
            color: const Color(0xFF3B5998),
          ),
        ),
        SizedBox(width: width * 0.04),
        _SocialIcon(
          color: Colors.white,
          child: Icon(
            Icons.alternate_email,
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
