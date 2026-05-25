import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import '../datos_personales/mis_datos_personales_screen.dart';
import '../documentos/mis_documentos_personales_screen.dart';

/// Pantalla de Perfil sin Ruleta - Versión mejorada con menú de botones
class PerfilPantallaSinRuleta extends StatefulWidget {
  static const name = 'perfil-sin-ruleta';

  const PerfilPantallaSinRuleta({super.key});

  @override
  State<PerfilPantallaSinRuleta> createState() => _PerfilPantallaSinRuletaState();
}

class _PerfilPantallaSinRuletaState extends State<PerfilPantallaSinRuleta> {
  Map<String, dynamic>? _userData;
  bool _cargando = true;

  static const Color _primaryBlue = Color(0xFF005BAC);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _warningOrange = Color(0xFFFF8A00);
  static const Color _infoBlue = Color(0xFF3D8FE0);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      // Intentar obtener datos personales primero, luego documentos del participante
      final datosPersonales = await LocalStorageService.getPersonalData();
      final datosDocumentos = await LocalStorageService.getParticipantDocumentsData();
      
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
        title: const Text(
          'Mi Perfil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(color: _primaryBlue),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de Perfil
                  _buildTarjetaPerfil(),
                  SizedBox(height: height * 0.03),

                  // Sección de Logros (sin ruleta)
                  _buildSeccionLogros(),
                  SizedBox(height: height * 0.03),

                  // Menú de Opciones
                  _buildMenuOpciones(),
                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
    );
  }

  Widget _buildTarjetaPerfil() {
    final nombre = _userData?['nombre'] ?? 'Usuario';
    final apellido = _userData?['apellido'] ?? '';
    final email = _userData?['email'] ?? '';
    final ci = _userData?['ci'] ?? '';

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
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: _primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          // Información
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$nombre $apellido',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'CI: $ci',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionLogros() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mis Logros',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE0E4ED), width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeLogro(
                icon: Icons.school_rounded,
                label: 'Programas',
                valor: '3',
                color: _primaryBlue,
              ),
              _buildBadgeLogro(
                icon: Icons.check_circle_rounded,
                label: 'Completados',
                valor: '1',
                color: _successGreen,
              ),
              _buildBadgeLogro(
                icon: Icons.trending_up_rounded,
                label: 'En Progreso',
                valor: '2',
                color: _infoBlue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeLogro({
    required IconData icon,
    required String label,
    required String valor,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          valor,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF666666),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuOpciones() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Opciones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        // Grid 2x2 de opciones
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildBotonOpcion(
              icon: Icons.person_outline_rounded,
              titulo: 'Mis Datos',
              subtitulo: 'Información personal',
              color: _primaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const MisDatosPersonalesPantalla(),
                  ),
                );
              },
            ),
            _buildBotonOpcion(
              icon: Icons.description_outlined,
              titulo: 'Mis Documentos',
              subtitulo: 'Archivos y certificados',
              color: _infoBlue,
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
            _buildBotonOpcion(
              icon: Icons.settings_outlined,
              titulo: 'Configuración',
              subtitulo: 'Preferencias de la app',
              color: _warningOrange,
              onTap: () {
                context.pushNamed('configuracion');
              },
            ),
            _buildBotonOpcion(
              icon: Icons.help_outline_rounded,
              titulo: 'Ayuda',
              subtitulo: 'Preguntas frecuentes',
              color: _successGreen,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sección de Ayuda - Próximamente'),
                    backgroundColor: _successGreen,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotonOpcion({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF666666),
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
}



