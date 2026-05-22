import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/otros/servicio_personas_facturacion.dart';
import 'package:refactor_template/features/sistema/domain/entities/persona_facturacion.dart';
import 'pantalla_formulario_persona_facturacion.dart';

/// 👥 GESTOR DE PERSONAS DE FACTURACIÓN - V0.4.4
/// 
/// Pantalla principal para gestionar múltiples personas de facturación en el sistema UPEA.
/// Permite ver, seleccionar, editar y eliminar personas de facturación de manera centralizada.
/// Diseñado siguiendo el design system UPEA con colores y tipografías consistentes.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Gestión completa de múltiples personas de facturación
/// ✅ Vista de persona actualmente seleccionada
/// ✅ Lista de todas las personas registradas
/// ✅ Operaciones CRUD completas (crear, leer, actualizar, eliminar)
/// ✅ Interfaz responsive y accesible
/// ✅ Colores del sistema UPEA (#005BAC, #4CAF50)
/// ✅ FloatingActionButton para agregar nuevas personas
/// 
/// FUNCIONALIDADES AVANZADAS:
/// - Indicador visual de persona actualmente seleccionada
/// - Tarjetas de personas con información completa
/// - Botones de acción contextuales (seleccionar, editar, eliminar)
/// - Confirmación de eliminación con diálogo modal
/// - Estados de carga con feedback visual
/// - Navegación fluida entre pantallas
/// - Actualización automática después de operaciones
/// 
/// INFORMACIÓN MOSTRADA POR PERSONA:
/// - Nombre completo o razón social
/// - Tipo y número de documento
/// - Email de contacto
/// - Teléfono de contacto
/// - Estado de selección visual
/// - Indicadores de tipo (personal/empresa)
/// 
/// OPERACIONES DISPONIBLES:
/// - Ver persona actualmente seleccionada
/// - Seleccionar persona diferente para facturación
/// - Agregar nueva persona (navegación a formulario)
/// - Editar persona existente (navegación a formulario)
/// - Eliminar persona con confirmación
/// - Actualización automática de listas
/// 
/// ESTADOS VISUALES:
/// - Cargando: CircularProgressIndicator azul UPEA
/// - Sin personas: Mensaje informativo con icono
/// - Con personas: Lista de tarjetas organizadas
/// - Persona seleccionada: Badge verde con indicador
/// - Operaciones: Estados de carga en botones
/// 
/// INTEGRACIÓN:
/// - ServicioPersonasFacturacion para todas las operaciones
/// - FormularioPersonaFacturacionPantalla para crear/editar
/// - Navegación con GoRouter
/// - Feedback con SnackBar para operaciones
/// 
/// USO TÍPICO:
/// ```dart
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => GestorPersonasFacturacionPantalla(),
/// ));
/// ```
class GestorPersonasFacturacionPantalla extends StatefulWidget {
  static const name = 'gestor-personas-facturacion';

  const GestorPersonasFacturacionPantalla({super.key});

  @override
  State<GestorPersonasFacturacionPantalla> createState() =>
      _GestorPersonasFacturacionPantallaState();
}

class _GestorPersonasFacturacionPantallaState
    extends State<GestorPersonasFacturacionPantalla> {
  final _servicio = ServicioPersonasFacturacion();
  List<PersonaFacturacion> _personas = [];
  PersonaFacturacion? _personaActual;
  bool _cargando = true;

  static const Color _primaryBlue = Color(0xFF005BAC);
  static const Color _successGreen = Color(0xFF4CAF50);
  static const Color _warningOrange = Color(0xFFFF8A00);

  @override
  void initState() {
    super.initState();
    _cargarPersonas();
  }

  Future<void> _cargarPersonas() async {
    setState(() => _cargando = true);
    try {
      final personas = await _servicio.obtenerPersonasActivas();
      final personaActual = await _servicio.obtenerPersonaActual();
      
      setState(() {
        _personas = personas;
        _personaActual = personaActual;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al cargar personas: $e');
    }
  }

  Future<void> _agregarPersona() async {
    final resultado = await Navigator.of(context).push<PersonaFacturacion>(
      MaterialPageRoute(
        builder: (context) => const FormularioPersonaFacturacionPantalla(),
      ),
    );

    if (resultado != null) {
      await _cargarPersonas();
      _mostrarExito('Persona agregada correctamente');
    }
  }

  Future<void> _editarPersona(PersonaFacturacion persona) async {
    final resultado = await Navigator.of(context).push<PersonaFacturacion>(
      MaterialPageRoute(
        builder: (context) => FormularioPersonaFacturacionPantalla(
          personaExistente: persona,
        ),
      ),
    );

    if (resultado != null) {
      await _cargarPersonas();
      _mostrarExito('Persona actualizada correctamente');
    }
  }

  Future<void> _seleccionarPersona(PersonaFacturacion persona) async {
    try {
      await _servicio.establecerPersonaActual(persona.id);
      setState(() => _personaActual = persona);
      _mostrarExito('Persona seleccionada para facturación');
    } catch (e) {
      _mostrarError('Error al seleccionar persona: $e');
    }
  }

  Future<void> _eliminarPersona(PersonaFacturacion persona) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Persona'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${persona.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _servicio.eliminarPersona(persona.id);
        await _cargarPersonas();
        _mostrarExito('Persona eliminada correctamente');
      } catch (e) {
        _mostrarError('Error al eliminar persona: $e');
      }
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
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
          'Personas de Facturación',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: _primaryBlue))
          : SingleChildScrollView(
              padding: EdgeInsets.all(width * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección: Persona Actual Seleccionada
                  if (_personaActual != null) ...[
                    _buildSeccionPersonaActual(),
                    SizedBox(height: height * 0.02),
                  ],

                  // Sección: Lista de Personas
                  _buildSeccionListaPersonas(),

                  SizedBox(height: height * 0.02),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarPersona,
        backgroundColor: _primaryBlue,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          'Agregar Persona',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSeccionPersonaActual() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _successGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _successGreen.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _successGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: _successGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Persona Seleccionada',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _personaActual!.nombreFacturacion,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_personaActual!.tipoDocumento}: ${_personaActual!.documentoFacturacion}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _personaActual!.email,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionListaPersonas() {
    if (_personas.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0E4ED),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.person_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'No hay personas registradas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega una persona para facturación',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personas Registradas',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _personas.length,
          itemBuilder: (context, index) {
            final persona = _personas[index];
            final esSeleccionada = _personaActual?.id == persona.id;

            return _buildPersonaCard(persona, esSeleccionada);
          },
        ),
      ],
    );
  }

  Widget _buildPersonaCard(PersonaFacturacion persona, bool esSeleccionada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esSeleccionada
              ? _primaryBlue.withOpacity(0.3)
              : const Color(0xFFE0E4ED),
          width: esSeleccionada ? 2 : 1,
        ),
        boxShadow: esSeleccionada
            ? [
                BoxShadow(
                  color: _primaryBlue.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombre y badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona.nombreFacturacion,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${persona.tipoDocumento}: ${persona.documentoFacturacion}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                if (esSeleccionada)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _successGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 12,
                          color: _successGreen,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Seleccionada',
                          style: TextStyle(
                            fontSize: 10,
                            color: _successGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Información de contacto
            Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    persona.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  persona.telefono,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!esSeleccionada)
                  TextButton.icon(
                    onPressed: () => _seleccionarPersona(persona),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Seleccionar'),
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _editarPersona(persona),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: _primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _eliminarPersona(persona),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



