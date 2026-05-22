import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/router/app_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import '../datos_personales/mis_datos_personales_screen.dart';
import '../documentos/mis_documentos_personales_screen.dart';

/// ðŸŽ¯ PANTALLA DE PERFIL SIN RULETA - VERSIÃ“N MEJORADA V0.4.4
///
/// Esta es la nueva pantalla de perfil que reemplaza la ruleta de seguridad
/// por un menÃº de botones moderno con diseÃ±o UPEA profesional.
///
/// CARACTERÃSTICAS:
/// âœ… Sin ruleta de seguridad (reemplazada por menÃº 2x2)
/// âœ… Gradientes y animaciones modernas
/// âœ… Colores del sistema UPEA (#005BAC, #4CAF50)
/// âœ… Tarjeta de perfil con estadÃ­sticas
/// âœ… MenÃº de acciones rÃ¡pidas
/// âœ… DiseÃ±o responsive y accesible
///
/// RUTA: /perfil (ruta principal)
/// RUTA ALTERNATIVA CON RULETA: /perfil-con-ruleta
class PerfilPantallaMejorado extends StatefulWidget {
  static const name = 'perfil-mejorado';

  const PerfilPantallaMejorado({super.key});

  @override
  State<PerfilPantallaMejorado> createState() => _PerfilPantallaMejoradoState();
}

class _PerfilPantallaMejoradoState extends State<PerfilPantallaMejorado>
    with TickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _cargando = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const Color _primaryBlue = Color(0xFF005BAC);
  static const Color _lightBlue = Color(0xFF3D8FE0);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _warningOrange = Color(0xFFFF8A00);
  static const Color _purpleAccent = Color(0xFF7B1FA2);
  static const Color _tealAccent = Color(0xFF00ACC1);

  @override
  void initState() {
    super.initState();

    // ðŸŽ¯ DEBUG: Confirmar que estamos usando la pantalla SIN ruleta
    debugPrint(
      'ðŸŽ¯ PERFIL SIN RULETA - PerfilPantallaMejorado cargada correctamente',
    );
    debugPrint('âœ… VersiÃ³n: 0.4.4 - MenÃº de botones (NO ruleta)');

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _cargarDatos();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      // Intentar obtener datos personales primero, luego documentos del participante
      final datosPersonales = await LocalStorageService.getPersonalData();
      final datosDocumentos =
          await LocalStorageService.getParticipantDocumentsData();

      // Combinar ambos conjuntos de datos si existen
      Map<String, dynamic>? datos;
      if (datosPersonales != null || datosDocumentos != null) {
        datos = <String, dynamic>{};
        if (datosPersonales != null) datos.addAll(datosPersonales);
        if (datosDocumentos != null) datos.addAll(datosDocumentos);
      }

      setState(() {
        _userData = datos;
        _cargando = false;
      });
      _animationController.forward();
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint('Error cargando datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mi Perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            SizedBox(width: 8),
            // ðŸŽ¯ Indicador visual de que NO hay ruleta
            Icon(Icons.grid_view, color: Colors.white70, size: 16),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(width * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de Perfil con Gradiente
                    _buildTarjetaPerfilGradiente(),
                    SizedBox(height: height * 0.025),

                    // EstadÃ­sticas RÃ¡pidas
                    _buildEstadisticasRapidas(),
                    SizedBox(height: height * 0.025),

                    // MenÃº Principal de Opciones (Estilo UPEA)
                    _buildMenuPrincipal(),
                    SizedBox(height: height * 0.025),

                    // Acciones RÃ¡pidas
                    _buildAccionesRapidas(),
                    SizedBox(height: height * 0.02),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTarjetaPerfilGradiente() {
    final nombre = _userData?['nombre'] ?? 'Usuario';
    final apellido = _userData?['apellido'] ?? '';
    final email = _userData?['email'] ?? '';
    final ci = _userData?['ci'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryBlue, _lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar con Gradiente
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.3),
                  Colors.white.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          // InformaciÃ³n
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nombre $apellido',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: 'Inter',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'CI: $ci',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasRapidas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4ED), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEstadistica(
            icon: Icons.school_rounded,
            valor: '3',
            label: 'Programas',
            color: _primaryBlue,
          ),
          _buildDivider(),
          _buildEstadistica(
            icon: Icons.check_circle_rounded,
            valor: '85%',
            label: 'Progreso',
            color: _successGreen,
          ),
          _buildDivider(),
          _buildEstadistica(
            icon: Icons.star_rounded,
            valor: '4.8',
            label: 'CalificaciÃ³n',
            color: _warningOrange,
          ),
        ],
      ),
    );
  }

  Widget _buildEstadistica({
    required IconData icon,
    required String valor,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF666666),
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFFE0E4ED));
  }

  Widget _buildMenuPrincipal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opciones Principales',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 16),
        // Grid 2x2 estilo UPEA
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildBotonMenuPrincipal(
              icon: Icons.person_outline_rounded,
              titulo: 'Mis Datos\nPersonales',
              color: _primaryBlue,
              gradientColors: [_primaryBlue, _lightBlue],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MisDatosPersonalesPantalla(),
                  ),
                );
              },
            ),
            _buildBotonMenuPrincipal(
              icon: Icons.description_outlined,
              titulo: 'Mis Documentos\ny Archivos',
              color: _lightBlue,
              gradientColors: [_lightBlue, _tealAccent],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const MisDocumentosPersonalesPantalla(),
                  ),
                );
              },
            ),
            _buildBotonMenuPrincipal(
              icon: Icons.settings_outlined,
              titulo: 'ConfiguraciÃ³n\nde la App',
              color: _warningOrange,
              gradientColors: [_warningOrange, Colors.deepOrange],
              onTap: () {
                context.pushNamed('configuracion');
              },
            ),
            _buildBotonMenuPrincipal(
              icon: Icons.help_outline_rounded,
              titulo: 'Ayuda y\nSoporte',
              color: _successGreen,
              gradientColors: [_successGreen, Colors.teal],
              onTap: () {
                _mostrarAyuda();
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotonMenuPrincipal({
    required IconData icon,
    required String titulo,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccionesRapidas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones RÃ¡pidas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildAccionRapida(
                icon: Icons.edit_outlined,
                titulo: 'Editar Perfil',
                color: _purpleAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MisDatosPersonalesPantalla(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildAccionRapida(
                icon: Icons.logout_rounded,
                titulo: 'Cerrar SesiÃ³n',
                color: Colors.red,
                onTap: _cerrarSesion,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAccionRapida({
    required IconData icon,
    required String titulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333),
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAyuda() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.help_outline_rounded,
              size: 48,
              color: _successGreen,
            ),
            const SizedBox(height: 16),
            const Text(
              'Centro de Ayuda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estamos aquÃ­ para ayudarte. PrÃ³ximamente tendrÃ¡s acceso a preguntas frecuentes, tutoriales y soporte tÃ©cnico.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Cerrar SesiÃ³n'),
          ],
        ),
        content: const Text(
          'Â¿EstÃ¡s seguro de que deseas cerrar sesiÃ³n?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalStorageService.clearSessionAndPin();
              if (mounted) goRouter.go('/start-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Cerrar SesiÃ³n',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}



