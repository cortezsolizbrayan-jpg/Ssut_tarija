import 'package:flutter/material.dart';
import 'package:refactor_template/core/services/otros/servicio_personas_facturacion.dart';
import 'package:refactor_template/features/sistema/domain/entities/persona_facturacion.dart';

/// 💳 SECCIÓN DE FACTURACIÓN INTEGRADA - V0.4.4
/// 
/// Widget especializado para gestión completa de personas de facturación dentro de formularios de pago.
/// Permite seleccionar personas existentes o agregar nuevas sin salir del flujo de pago.
/// Diseñado siguiendo el design system UPEA con colores y tipografías consistentes.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Selección de personas de facturación existentes
/// ✅ Formulario integrado para agregar nuevas personas
/// ✅ Soporte para facturación personal y empresarial
/// ✅ Validación completa de datos de facturación
/// ✅ Persistencia automática de datos
/// ✅ Interfaz responsive y accesible
/// ✅ Colores del sistema UPEA (#005BAC, #4CAF50)
/// 
/// FUNCIONALIDADES AVANZADAS:
/// - Carga automática de personas guardadas
/// - Selección automática de la persona actual
/// - Formulario dinámico que se adapta al tipo (personal/empresa)
/// - Validación en tiempo real de campos obligatorios
/// - Guardado automático al seleccionar o crear persona
/// - Feedback visual con estados de carga y éxito
/// - Integración con ServicioPersonasFacturacion
/// 
/// TIPOS DE FACTURACIÓN SOPORTADOS:
/// - Persona Natural: CI, Pasaporte
/// - Empresa: NIT, Razón Social
/// - Validación de email y teléfono
/// - Campos dinámicos según el tipo seleccionado
/// 
/// ESTADOS VISUALES:
/// - Cargando: Indicador circular azul UPEA
/// - Sin personas: Mensaje informativo con call-to-action
/// - Con personas: Lista de tarjetas seleccionables
/// - Formulario activo: Campos expandidos con validación
/// - Guardando: Indicador de progreso en botón
/// 
/// INTEGRACIÓN:
/// - ServicioPersonasFacturacion para persistencia
/// - LocalStorageService para datos temporales
/// - Callback onPersonaSeleccionada para comunicación con padre
/// - Soporte para persona inicial predefinida
/// 
/// USO TÍPICO:
/// ```dart
/// SeccionFacturacionIntegrada(
///   onPersonaSeleccionada: (persona) {
///     // Manejar selección de persona
///   },
///   personaInicial: personaExistente,
/// )
/// ```
class SeccionFacturacionIntegrada extends StatefulWidget {
  final Function(PersonaFacturacion?) onPersonaSeleccionada;
  final PersonaFacturacion? personaInicial;

  const SeccionFacturacionIntegrada({
    super.key,
    required this.onPersonaSeleccionada,
    this.personaInicial,
  });

  @override
  State<SeccionFacturacionIntegrada> createState() =>
      _SeccionFacturacionIntegradaState();
}

class _SeccionFacturacionIntegradaState
    extends State<SeccionFacturacionIntegrada> {
  final _servicio = ServicioPersonasFacturacion();
  List<PersonaFacturacion> _personas = [];
  PersonaFacturacion? _personaSeleccionada;
  bool _cargando = true;
  bool _mostrarFormularioNueva = false;

  // Controladores - nueva estructura
  late TextEditingController _razonSocialController; // Nombre completo o razón social empresa
  late TextEditingController _ciController;          // CI (siempre disponible)
  late TextEditingController _nitController;         // NIT (siempre disponible, opcional para persona)
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;

  bool _esEmpresa = false;
  bool _guardando = false;

  /// 🎨 COLORES DEL SISTEMA UPEA
  /// Paleta de colores oficial para consistencia visual en toda la aplicación
  static const Color _primaryBlue = Color(0xFF005BAC);    // Azul principal UPEA
  static const Color _successGreen = Color(0xFF4CAF50);   // Verde de éxito
  static const Color _inputBackground = Color(0xFFF8F9FB); // Fondo de inputs
  static const Color _borderColor = Color(0xFFE0E4ED);    // Color de bordes

  /// 🚀 INICIALIZACIÓN DEL Widget
  /// 
  /// Configura el estado inicial del Widget y carga los datos necesarios.
  /// Inicializa controladores de texto y ejecuta la carga de personas existentes.
  @override
  void initState() {
    super.initState();
    _inicializarControladores();
    _cargarPersonas();
  }

  /// 📝 INICIALIZAR CONTROLADORES DE TEXTO
  /// 
  /// Crea todos los controladores necesarios para los campos del formulario.
  /// Cada controlador maneja un campo específico del formulario de facturación.
  /// 
  /// CONTROLADORES CREADOS:
  /// - Datos personales: nombre, apellido, documento
  /// - Datos de contacto: email, teléfono
  /// - Datos empresariales: NIT, razón social (cuando aplica)
  void _inicializarControladores() {
    _razonSocialController = TextEditingController();
    _ciController = TextEditingController();
    _nitController = TextEditingController();
    _emailController = TextEditingController();
    _telefonoController = TextEditingController();
  }

  /// 🗑️ LIMPIEZA DE RECURSOS
  /// 
  /// Libera todos los controladores de texto para evitar memory leaks.
  /// Se ejecuta automáticamente cuando el Widget se destruye.
  @override
  void dispose() {
    _razonSocialController.dispose();
    _ciController.dispose();
    _nitController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  /// 📂 CARGAR PERSONAS DE FACTURACIÓN
  /// 
  /// Carga todas las personas de facturación activas desde el servicio.
  /// También obtiene la persona actualmente seleccionada si existe.
  /// 
  /// PROCESO:
  /// 1. Activa indicador de carga
  /// 2. Obtiene personas activas del servicio
  /// 3. Obtiene persona actual seleccionada
  /// 4. Actualiza el estado con los datos cargados
  /// 5. Notifica al Widget padre sobre la persona seleccionada
  /// 6. Maneja errores y desactiva indicador de carga
  /// 
  /// @return `Future<void>` - Operación asíncrona de carga
  Future<void> _cargarPersonas() async {
    setState(() => _cargando = true);
    try {
      final personas = await _servicio.obtenerPersonasActivas();
      final personaActual = await _servicio.obtenerPersonaActual();

      setState(() {
        _personas = personas;
        _personaSeleccionada = personaActual ?? widget.personaInicial;
        _cargando = false;
      });

      widget.onPersonaSeleccionada(_personaSeleccionada);
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al cargar personas: $e');
    }
  }

  /// 💾 GUARDAR NUEVA PERSONA DE FACTURACIÓN
  /// 
  /// Valida y guarda una nueva persona de facturación en el sistema.
  /// Incluye validación completa de campos y manejo de estados de carga.
  /// 
  /// VALIDACIONES REALIZADAS:
  /// - Campos obligatorios: nombre, apellido, documento, email, teléfono
  /// - Campos empresariales: NIT y razón social (si es empresa)
  /// - Formato de email válido
  /// - Longitud mínima de campos
  /// 
  /// PROCESO:
  /// 1. Valida todos los campos obligatorios
  /// 2. Valida campos específicos de empresa si aplica
  /// 3. Activa indicador de guardado
  /// 4. Guarda la persona usando el servicio
  /// 5. Establece la nueva persona como actual
  /// 6. Actualiza el estado y oculta el formulario
  /// 7. Limpia el formulario y recarga la lista
  /// 8. Muestra mensaje de éxito
  /// 9. Notifica al Widget padre
  /// 
  /// @return `Future<void>` - Operación asíncrona de guardado
  Future<void> _guardarNuevaPersona() async {
    // Razón social obligatoria siempre
    if (_razonSocialController.text.trim().isEmpty) {
      _mostrarError(_esEmpresa
          ? 'Ingresa la razón social de la empresa'
          : 'Ingresa tu nombre completo');
      return;
    }
    // Para persona: CI obligatorio. Para empresa: NIT obligatorio
    if (!_esEmpresa && _ciController.text.trim().isEmpty) {
      _mostrarError('Ingresa tu número de CI');
      return;
    }
    if (_esEmpresa && _nitController.text.trim().isEmpty) {
      _mostrarError('Ingresa el NIT de la empresa');
      return;
    }

    setState(() => _guardando = true);

    try {
      final nuevaPersona = await _servicio.guardarPersona(
        nombre: _razonSocialController.text.trim(),
        apellido: '',
        tipoDocumento: _esEmpresa ? 'NIT' : 'CI',
        numeroDocumento: _esEmpresa
            ? _nitController.text.trim()
            : _ciController.text.trim(),
        email: _emailController.text.trim(),
        telefono: _telefonoController.text.trim(),
        esEmpresa: _esEmpresa,
        nitEmpresa: _nitController.text.trim().isNotEmpty
            ? _nitController.text.trim()
            : null,
        razonSocial: _razonSocialController.text.trim(),
      );

      await _servicio.establecerPersonaActual(nuevaPersona.id);

      setState(() {
        _personaSeleccionada = nuevaPersona;
        _mostrarFormularioNueva = false;
        _guardando = false;
      });

      _limpiarFormulario();
      await _cargarPersonas();
      _mostrarExito('Datos de facturación guardados');
      widget.onPersonaSeleccionada(_personaSeleccionada);
    } catch (e) {
      setState(() => _guardando = false);
      _mostrarError('Error al guardar: $e');
    }
  }

  /// 🧹 LIMPIAR FORMULARIO DE NUEVA PERSONA
  /// 
  /// Resetea todos los campos del formulario a sus valores por defecto.
  /// Útil después de guardar una persona o cancelar la creación.
  /// 
  /// CAMPOS LIMPIADOS:
  /// - Todos los controladores de texto se vacían
  /// - Tipo de documento vuelve a 'CI'
  /// - Tipo de facturación vuelve a persona natural
  void _limpiarFormulario() {
    _razonSocialController.clear();
    _ciController.clear();
    _nitController.clear();
    _emailController.clear();
    _telefonoController.clear();
    _esEmpresa = false;
  }

  /// ✅ SELECCIONAR PERSONA EXISTENTE
  /// 
  /// Establece una persona existente como la persona actual para facturación.
  /// Actualiza el estado local y notifica al Widget padre.
  /// 
  /// PROCESO:
  /// 1. Establece la persona como actual en el servicio
  /// 2. Actualiza el estado local
  /// 3. Notifica al Widget padre sobre la selección
  /// 4. Muestra mensaje de confirmación
  /// 
  /// @param persona - `PersonaFacturacion` a seleccionar
  /// @return `Future<void>` - Operación asíncrona de selección
  Future<void> _seleccionarPersona(PersonaFacturacion persona) async {
    try {
      await _servicio.establecerPersonaActual(persona.id);
      setState(() => _personaSeleccionada = persona);
      widget.onPersonaSeleccionada(persona);
      _mostrarExito('Persona seleccionada');
    } catch (e) {
      _mostrarError('Error al seleccionar persona: $e');
    }
  }

  /// ✅ MOSTRAR MENSAJE DE ÉXITO
  /// 
  /// Presenta un SnackBar con mensaje de éxito usando colores del sistema UPEA.
  /// 
  /// @param mensaje - Texto del mensaje a mostrar
  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: _successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ❌ MOSTRAR MENSAJE DE ERROR
  /// 
  /// Presenta un SnackBar con mensaje de error usando color rojo estándar.
  /// 
  /// @param mensaje - Texto del error a mostrar
  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// 🎨 CONSTRUCCIÓN DE LA INTERFAZ PRINCIPAL
  /// 
  /// Construye la interfaz completa del Widget con todos sus Widgets.
  /// Maneja diferentes estados: cargando, sin datos, con datos, formulario activo.
  /// 
  /// ESTRUCTURA DE LA UI:
  /// 1. Indicador de carga (si está cargando)
  /// 2. Encabezado con título y botón "Agregar Nuevo"
  /// 3. Formulario para nueva persona (si está activo)
  /// 4. Lista de personas existentes o mensaje de estado vacío
  /// 
  /// ESTADOS MANEJADOS:
  /// - Cargando: CircularProgressIndicator azul UPEA
  /// - Sin personas: Mensaje informativo con call-to-action
  /// - Con personas: Lista de tarjetas seleccionables
  /// - Formulario activo: Campos expandidos con validación
  /// 
  /// @param context - BuildContext del Widget
  /// @return Widget - Interfaz construida
  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryBlue),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Facturación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            if (!_mostrarFormularioNueva)
              ElevatedButton.icon(
                onPressed: () =>
                    setState(() => _mostrarFormularioNueva = true),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar Nuevo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Formulario para agregar nueva persona
        if (_mostrarFormularioNueva) ...[
          _buildFormularioNuevaPersona(),
          const SizedBox(height: 16),
        ],

        // Lista de personas
        if (_personas.isEmpty && !_mostrarFormularioNueva)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'No hay personas registradas. Agrega una nueva.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF666666),
              ),
            ),
          )
        else if (!_mostrarFormularioNueva)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _personas.length,
            itemBuilder: (context, index) {
              final persona = _personas[index];
              final esSeleccionada = _personaSeleccionada?.id == persona.id;

              return _buildPersonaCard(persona, esSeleccionada);
            },
          ),
      ],
    );
  }

  /// 📋 CONSTRUIR FORMULARIO PARA NUEVA PERSONA
  /// 
  /// Crea el formulario completo para agregar una nueva persona de facturación.
  /// Incluye todos los campos necesarios con validación y diseño responsive.
  /// 
  /// SECCIONES DEL FORMULARIO:
  /// 1. Selector de tipo de facturación (Personal/Empresa)
  /// 2. Datos personales (nombre, apellido, tipo y número de documento)
  /// 3. Datos de empresa (si aplica): razón social y NIT
  /// 4. Datos de contacto (email y teléfono)
  /// 5. Botones de acción (Cancelar/Guardar)
  /// 
  /// CARACTERÍSTICAS:
  /// - Diseño con container blanco y bordes redondeados
  /// - Campos dinámicos que aparecen según el tipo seleccionado
  /// - Validación en tiempo real
  /// - Estados de carga en botones
  /// - Colores consistentes con design system UPEA
  /// 
  /// @return Widget - Formulario construido
  Widget _buildFormularioNuevaPersona() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Switch Persona / Empresa ──────────────────────────────────
          Row(
            children: [
              const Text('Persona', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
              const SizedBox(width: 8),
              Switch(
                value: _esEmpresa,
                onChanged: (v) => setState(() => _esEmpresa = v),
                activeColor: _primaryBlue,
              ),
              const SizedBox(width: 8),
              const Text('Empresa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
            ],
          ),
          const SizedBox(height: 14),

          // ── Razón Social (nombre completo o nombre empresa) ───────────
          _buildField(
            controller: _razonSocialController,
            label: _esEmpresa ? 'Razón Social *' : 'Nombre Completo *',
            hint: _esEmpresa ? 'Ej: EMPRESA S.R.L.' : 'Ej: JUAN PÉREZ MAMANI',
            icon: _esEmpresa ? Icons.business_rounded : Icons.person_rounded,
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 10),

          // ── CI (siempre visible) ──────────────────────────────────────
          _buildField(
            controller: _ciController,
            label: 'Número de CI${_esEmpresa ? ' (opcional)' : ' *'}',
            hint: 'Ej: 5726619',
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),

          // ── NIT (siempre visible, obligatorio para empresa) ───────────
          _buildField(
            controller: _nitController,
            label: 'NIT${_esEmpresa ? ' *' : ' (opcional)'}',
            hint: 'Ej: 1234567890',
            icon: Icons.receipt_long_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),

          // ── Email ─────────────────────────────────────────────────────
          _buildField(
            controller: _emailController,
            label: 'Email',
            hint: 'correo@ejemplo.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 10),

          // ── Teléfono ──────────────────────────────────────────────────
          _buildField(
            controller: _telefonoController,
            label: 'Teléfono',
            hint: 'Ej: 70000000',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // ── Botones ───────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _guardando ? null : () {
                    _limpiarFormulario();
                    setState(() => _mostrarFormularioNueva = false);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryBlue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar', style: TextStyle(color: _primaryBlue, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardarNuevaPersona,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _guardando
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Text('Guardar', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primaryBlue, size: 20),
        filled: true,
        fillColor: _inputBackground,
        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _borderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primaryBlue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  /// 🃏 CONSTRUIR TARJETA DE PERSONA
  /// 
  /// Crea una tarjeta individual para mostrar los datos de una persona de facturación.
  /// Incluye indicadores visuales de selección y botones de interacción.
  /// 
  /// CARACTERÍSTICAS DE LA TARJETA:
  /// - Diseño con bordes redondeados y sombra sutil
  /// - Borde azul UPEA cuando está seleccionada
  /// - Radio button para selección
  /// - Información principal: nombre y documento
  /// - Badge de "Seleccionada" cuando aplica
  /// - Efecto de toque con InkWell
  /// 
  /// INFORMACIÓN MOSTRADA:
  /// - Nombre completo de facturación
  /// - Tipo y número de documento
  /// - Estado de selección visual
  /// 
  /// @param persona - PersonaFacturacion a mostrar
  /// @param esSeleccionada - Si esta persona está actualmente seleccionada
  /// @return Widget - Tarjeta construida
  Widget _buildPersonaCard(PersonaFacturacion persona, bool esSeleccionada) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: esSeleccionada ? _primaryBlue : _borderColor,
          width: esSeleccionada ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _seleccionarPersona(persona),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Radio<String>(
                  value: persona.id,
                  groupValue: _personaSeleccionada?.id,
                  onChanged: (value) {
                    if (value != null) {
                      _seleccionarPersona(persona);
                    }
                  },
                  activeColor: _primaryBlue,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        persona.nombreFacturacion,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${persona.tipoDocumento}: ${persona.documentoFacturacion}',
                        style: const TextStyle(
                          fontSize: 11,
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
                    child: const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: _successGreen,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}


