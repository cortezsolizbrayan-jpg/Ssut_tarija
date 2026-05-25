import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:refactor_template/core/services/storage/servicio_usuarios_recepcion.dart';

import 'package:refactor_template/features/sistema/screens/recepcion/pantalla_recepcion_participantes.dart';

/// Pantalla de login exclusiva para el personal de atención al cliente.
/// Acceso: desde la pantalla inicial → botón "Acceso Personal"
class PantallaLoginRecepcion extends StatefulWidget {
  static const name = 'login-recepcion';
  const PantallaLoginRecepcion({super.key});

  @override
  State<PantallaLoginRecepcion> createState() => _PantallaLoginRecepcionState();
}

class _PantallaLoginRecepcionState extends State<PantallaLoginRecepcion> {
  static const _blue = Color(0xFF005BAC);

  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _verPass = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _ingresar() {
    setState(() {
      _error = null;
      _cargando = true;
    });

    final usuario = ServicioUsuariosRecepcion.verificarCredenciales(
      _usuarioCtrl.text,
      _passCtrl.text,
    );

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _cargando = false);

      if (usuario == null) {
        setState(() => _error = 'Usuario o contraseña incorrectos');
        return;
      }

      // Navegar al panel de recepción (que tiene los pasos y captura rápida)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PantallaRecepcionParticipantes(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo + título
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _blue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Panel de Recepción',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Acceso exclusivo para personal de atención',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Formulario
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                duration: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campo usuario
                      const Text(
                        'Usuario',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF005BAC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _usuarioCtrl,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDeco(
                          'Ej: maribel',
                          Icons.person_outline,
                        ),
                        onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      ),
                      const SizedBox(height: 16),

                      // Campo contraseña
                      const Text(
                        'Contraseña',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF005BAC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passCtrl,
                        obscureText: !_verPass,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: Colors.black87),
                        decoration: _inputDeco('••••••••', Icons.lock_outline)
                            .copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _verPass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () =>
                                    setState(() => _verPass = !_verPass),
                              ),
                            ),
                        onSubmitted: (_) => _ingresar(),
                      ),

                      // Error
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Botón ingresar
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _cargando ? null : _ingresar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _cargando
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Ingresar',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Volver
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                label: const Text('Volver'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    prefixIcon: Icon(icon, color: const Color(0xFF005BAC), size: 20),
    filled: true,
    fillColor: const Color(0xFFF8F9FB),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF005BAC), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}


