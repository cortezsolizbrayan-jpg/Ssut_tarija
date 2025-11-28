import 'package:flutter/material.dart';

class BotonPrimario extends StatelessWidget {
  const BotonPrimario({super.key, required this.width});

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
