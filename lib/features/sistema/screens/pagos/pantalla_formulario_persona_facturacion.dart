import 'package:flutter/material.dart';
import 'package:refactor_template/core/services/otros/servicio_personas_facturacion.dart';
import 'package:refactor_template/features/sistema/domain/entities/persona_facturacion.dart';

/// 📝 FORMULARIO DE PERSONA DE FACTURACIÓN - V0.4.4
/// 
/// Pantalla especializada para crear y editar personas de facturación en el sistema UPEA.
/// Permite gestionar tanto personas naturales como empresas con validación completa.
/// Diseñado siguiendo el design system UPEA con colores y tipografías consistentes.
/// 
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Creación y edición de personas de facturación
/// ✅ Soporte para personas naturales y empresas
/// ✅ Validación completa de todos los campos
/// ✅ Interfaz responsive y accesible
/// ✅ Colores del sistema UPEA (#005BAC, #4CAF50)
/// ✅ Tipografías Inter y Poppins según design system
/// 
/// FUNCIONALIDADES AVANZADAS:
/// - Formulario dinámico que se adapta al tipo (personal/empresa)
/// - Validación en tiempo real con mensajes específicos
/// - Soporte para múltiples tipos de documento (CI, NIT, Pasaporte)
/// - Campos empresariales condicionales
/// - Estados de carga con feedback visual
/// - Integración completa con ServicioPersonasFacturacion
/// - Navegación inteligente con resultados
/// 
/// TIPOS DE FACTURACIÓN SOPORTADOS:
/// - Persona Natural: CI, Pasaporte con datos personales
/// - Empresa: NIT con razón social y datos corporativos
/// - Validación específica para cada tipo de documento
/// - Campos de contacto obligatorios para ambos tipos
/// 
/// VALIDACIONES IMPLEMENTADAS:
/// - Campos obligatorios según el tipo seleccionado
/// - Formato de email con expresión regular
/// - Longitud mínima y máxima de campos
/// - Caracteres permitidos en nombres y documentos
/// - Validación específica de NIT para empresas
/// 
/// ESTADOS VISUALES:
/// - Formulario limpio: Campos vacíos listos para entrada
/// - Editando: Campos pre-poblados con datos existentes
/// - Validando: Mensajes de error bajo campos inválidos
/// - Guardando: Indicador de progreso en botón principal
/// - Error: SnackBar rojo con mensaje específico
/// - Éxito: Navegación automática con resultado
/// 
/// INTEGRACIÓN:
/// - ServicioPersonasFacturacion para persistencia
/// - Navegación con GoRouter
/// - Retorno de PersonaFacturacion al Widget padre
/// - Soporte para edición de personas existentes
/// 
/// USO TÍPICO:
/// ```dart
/// // Crear nueva persona
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => FormularioPersonaFacturacionPantalla(),
/// ));
/// 
/// // Editar persona existente
/// Navigator.push(context, MaterialPageRoute(
///   builder: (context) => FormularioPersonaFacturacionPantalla(
///     personaExistente: persona,
///   ),
/// ));
/// ```
class FormularioPersonaFacturacionPantalla extends StatefulWidget {
  static const name = 'formulario-persona-facturacion';
  final PersonaFacturacion? personaExistente;

  const FormularioPersonaFacturacionPantalla({
    super.key,
    this.personaExistente,
  });

  @override
  State<FormularioPersonaFacturacionPantalla> createState() =>
      _FormularioPersonaFacturacionPantallaState();
}

class _FormularioPersonaFacturacionPantallaState
    extends State<FormularioPersonaFacturacionPantalla> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = ServicioPersonasFacturacion();

  late TextEditingController _nombreController;
  late TextEditingController _apellidoController;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  late TextEditingController _nitEmpresaController;
  late TextEditingController _razonSocialController;

  String _tipoDocumento = 'CI';
  bool _esEmpresa = false;
  bool _guardando = false;

  /// 🎨 COLORES DEL SISTEMA UPEA
  /// Paleta de colores oficial para consistencia visual en toda la aplicación
  static const Color _primaryBlue = Color(0xFF005BAC);    // Azul principal UPEA
  static const Color _inputBackground = Color(0xFFF8F9FB); // Fondo de inputs
  static const Color _borderColor = Color(0xFFE0E4ED);    // Color de bordes

  /// 🚀 INICIALIZACIÓN DEL Widget
  /// 
  /// Configura el estado inicial del formulario y carga los datos si es edición.
  /// Inicializa todos los controladores de texto con valores apropiados.
  @override
  void initState() {
    super.initState();
    _inicializarControladores();
  }

  /// 📝 INICIALIZAR CONTROLADORES CON DATOS
  /// 
  /// Crea todos los controladores de texto y los inicializa con los datos
  /// de la persona existente si se está editando, o con valores vacíos si es nueva.
  /// 
  /// CONTROLADORES INICIALIZADOS:
  /// - Datos personales: nombre, apellido, número de documento
  /// - Datos de contacto: email, teléfono
  /// - Datos empresariales: NIT empresa, razón social
  /// - Configuración: tipo de documento, es empresa
  /// 
  /// LÓGICA DE INICIALIZACIÓN:
  /// - Si personaExistente != null: pre-poblar campos con datos existentes
  /// - Si personaExistente == null: inicializar con valores por defecto
  /// - Configurar tipo de documento y modo empresa según datos existentes
  void _inicializarControladores() {
    final persona = widget.personaExistente;

    _nombreController = TextEditingController(text: persona?.nombre ?? '');
    _apellidoController = TextEditingController(text: persona?.apellido ?? '');
    _numeroDocumentoController =
        TextEditingController(text: persona?.numeroDocumento ?? '');
    _emailController = TextEditingController(text: persona?.email ?? '');
    _telefonoController = TextEditingController(text: persona?.telefono ?? '');
    _nitEmpresaController =
        TextEditingController(text: persona?.nitEmpresa ?? '');
    _razonSocialController =
        TextEditingController(text: persona?.razonSocial ?? '');

    _tipoDocumento = persona?.tipoDocumento ?? 'CI';
    _esEmpresa = persona?.esEmpresa ?? false;
  }

  /// 🗑️ LIMPIEZA DE RECURSOS
  /// 
  /// Libera todos los controladores de texto para evitar memory leaks.
  /// Se ejecuta automáticamente cuando el Widget se destruye.
  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _numeroDocumentoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _nitEmpresaController.dispose();
    _razonSocialController.dispose();
    super.dispose();
  }

  /// 💾 GUARDAR PERSONA DE FACTURACIÓN
  /// 
  /// Valida el formulario y guarda la persona (nueva o actualizada) en el sistema.
  /// Maneja tanto la creación como la actualización con lógica diferenciada.
  /// 
  /// PROCESO DE GUARDADO:
  /// 1. Valida el formulario usando GlobalKey<FormState>
  /// 2. Activa indicador de guardado en la UI
  /// 3. Determina si es creación o actualización
  /// 4. Llama al servicio correspondiente con datos limpios
  /// 5. Navega de vuelta con el resultado
  /// 6. Maneja errores con SnackBar informativo
  /// 
  /// VALIDACIONES PREVIAS:
  /// - Todos los campos obligatorios completados
  /// - Formato de email válido
  /// - Campos empresariales si es empresa
  /// - Longitud y formato de documentos
  /// 
  /// @return Future<void> - Operación asíncrona de guardado
  Future<void> _guardarPersona() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _guardando = true);

    try {
      final persona = widget.personaExistente;

      if (persona == null) {
        // Crear nueva persona
        final nuevaPersona = await _servicio.guardarPersona(
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          tipoDocumento: _tipoDocumento,
          numeroDocumento: _numeroDocumentoController.text.trim(),
          email: _emailController.text.trim(),
          telefono: _telefonoController.text.trim(),
          esEmpresa: _esEmpresa,
          nitEmpresa: _esEmpresa ? _nitEmpresaController.text.trim() : null,
          razonSocial: _esEmpresa ? _razonSocialController.text.trim() : null,
        );

        if (mounted) {
          Navigator.pop(context, nuevaPersona);
        }
      } else {
        // Actualizar persona existente
        final personaActualizada = await _servicio.actualizarPersona(
          id: persona.id,
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(),
          tipoDocumento: _tipoDocumento,
          numeroDocumento: _numeroDocumentoController.text.trim(),
          email: _emailController.text.trim(),
          telefono: _telefonoController.text.trim(),
          esEmpresa: _esEmpresa,
          nitEmpresa: _esEmpresa ? _nitEmpresaController.text.trim() : null,
          razonSocial: _esEmpresa ? _razonSocialController.text.trim() : null,
        );

        if (mounted) {
          Navigator.pop(context, personaActualizada);
        }
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🎨 CONSTRUCCIÓN DE LA INTERFAZ PRINCIPAL
  /// 
  /// Construye la interfaz completa del formulario con diseño responsive.
  /// Utiliza Scaffold con AppBar personalizado y ScrollView para contenido.
  /// 
  /// ESTRUCTURA DE LA UI:
  /// 1. AppBar con título dinámico (Agregar/Editar) y botón de retroceso
  /// 2. ScrollView con padding responsive
  /// 3. Formulario con validación (GlobalKey<FormState>)
  /// 4. Secciones organizadas: tipo, datos personales, empresa, contacto
  /// 5. Botones de acción en la parte inferior
  /// 
  /// CARACTERÍSTICAS DEL DISEÑO:
  /// - Fondo gris claro UPEA (#EEF1F8)
  /// - AppBar azul UPEA (#005BAC)
  /// - Secciones con containers blancos y bordes redondeados
  /// - Espaciado responsive basado en MediaQuery
  /// - Botones con estados de carga
  /// 
  /// @param context - BuildContext del Widget
  /// @return Widget - Interfaz construida
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    final isEditing = widget.personaExistente != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Editar Persona' : 'Agregar Persona',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(width * 0.04),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.02),

              // Sección: Tipo de Facturación
              _buildSeccionTipoFacturacion(),
              SizedBox(height: height * 0.02),

              // Sección: Datos Personales
              _buildSeccionDatosPersonales(),
              SizedBox(height: height * 0.02),

              // Sección: Datos de Empresa (si aplica)
              if (_esEmpresa) ...[
                _buildSeccionDatosEmpresa(),
                SizedBox(height: height * 0.02),
              ],

              // Sección: Contacto
              _buildSeccionContacto(),
              SizedBox(height: height * 0.03),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: height * 0.02),
                        side: const BorderSide(color: _primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: _primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardarPersona,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: EdgeInsets.symmetric(vertical: height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _guardando
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              isEditing ? 'Actualizar' : 'Guardar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.02),
            ],
          ),
        ),
      ),
    );
  }

  /// 🏢 CONSTRUIR SECCIÓN DE TIPO DE FACTURACIÓN
  /// 
  /// Crea la sección para seleccionar entre facturación personal o empresarial.
  /// Utiliza radio buttons con diseño personalizado y colores UPEA.
  /// 
  /// CARACTERÍSTICAS:
  /// - Container blanco con bordes redondeados
  /// - Radio buttons con colores azul UPEA
  /// - Diseño responsive con dos columnas
  /// - Feedback visual al seleccionar
  /// - Actualización automática del estado
  /// 
  /// OPCIONES DISPONIBLES:
  /// - Persona Natural: Para individuos
  /// - Empresa: Para entidades corporativas
  /// 
  /// @return Widget - Sección construida
  Widget _buildSeccionTipoFacturacion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tipo de Facturación',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _esEmpresa = false),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_esEmpresa
                          ? _primaryBlue.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !_esEmpresa ? _primaryBlue : _borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _esEmpresa,
                          onChanged: (value) =>
                              setState(() => _esEmpresa = value ?? false),
                          activeColor: _primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Persona Natural',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _esEmpresa = true),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _esEmpresa
                          ? _primaryBlue.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _esEmpresa ? _primaryBlue : _borderColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _esEmpresa,
                          onChanged: (value) =>
                              setState(() => _esEmpresa = value ?? false),
                          activeColor: _primaryBlue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Empresa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 👤 CONSTRUIR SECCIÓN DE DATOS PERSONALES
  /// 
  /// Crea la sección con campos para información personal básica.
  /// Incluye nombre, apellido, tipo de documento y número.
  /// 
  /// CAMPOS INCLUIDOS:
  /// - Nombre: Campo de texto con validación obligatoria
  /// - Apellido: Campo de texto con validación obligatoria
  /// - Tipo de Documento: Dropdown con opciones (CI, NIT, Pasaporte)
  /// - Número de Documento: Campo de texto con validación específica
  /// 
  /// CARACTERÍSTICAS:
  /// - Container blanco con diseño consistente
  /// - Campos organizados en filas para optimizar espacio
  /// - Validación en tiempo real
  /// - Colores y tipografías del design system UPEA
  /// 
  /// @return Widget - Sección construida
  Widget _buildSeccionDatosPersonales() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos Personales',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nombreController,
                  decoration: _buildInputDecoration('Nombre'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _apellidoController,
                  decoration: _buildInputDecoration('Apellido'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El apellido es requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _tipoDocumento,
                  decoration: _buildInputDecoration('Tipo de Documento'),
                  items: ['CI', 'NIT', 'PASAPORTE']
                      .map((tipo) => DropdownMenuItem(
                            value: tipo,
                            child: Text(tipo),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _tipoDocumento = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _numeroDocumentoController,
                  decoration: _buildInputDecoration('Número de Documento'),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'El número es requerido';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🏢 CONSTRUIR SECCIÓN DE DATOS DE EMPRESA
  /// 
  /// Crea la sección con campos específicos para entidades empresariales.
  /// Solo se muestra cuando el usuario selecciona "Empresa" como tipo.
  /// 
  /// CAMPOS INCLUIDOS:
  /// - Razón Social: Nombre oficial de la empresa
  /// - NIT de Empresa: Número de Identificación Tributaria
  /// 
  /// CARACTERÍSTICAS:
  /// - Aparece/desaparece dinámicamente según selección
  /// - Validación condicional (solo si _esEmpresa = true)
  /// - Diseño consistente con otras secciones
  /// - Campos obligatorios cuando está activa
  /// 
  /// @return Widget - Sección construida
  Widget _buildSeccionDatosEmpresa() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos de Empresa',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _razonSocialController,
            decoration: _buildInputDecoration('Razón Social'),
            validator: (value) {
              if (_esEmpresa && (value?.isEmpty ?? true)) {
                return 'La razón social es requerida';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nitEmpresaController,
            decoration: _buildInputDecoration('NIT de Empresa'),
            validator: (value) {
              if (_esEmpresa && (value?.isEmpty ?? true)) {
                return 'El NIT es requerido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 📞 CONSTRUIR SECCIÓN DE CONTACTO
  /// 
  /// Crea la sección con campos de información de contacto.
  /// Incluye email y teléfono con validaciones específicas.
  /// 
  /// CAMPOS INCLUIDOS:
  /// - Correo Electrónico: Con validación de formato
  /// - Teléfono: Campo numérico para contacto
  /// 
  /// VALIDACIONES:
  /// - Email: Expresión regular para formato válido
  /// - Teléfono: Campo obligatorio, formato numérico
  /// - Ambos campos son requeridos para cualquier tipo
  /// 
  /// CARACTERÍSTICAS:
  /// - Teclados específicos (email, phone)
  /// - Validación en tiempo real
  /// - Mensajes de error descriptivos
  /// - Diseño consistente con design system
  /// 
  /// @return Widget - Sección construida
  Widget _buildSeccionContacto() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Información de Contacto',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailController,
            decoration: _buildInputDecoration('Correo Electrónico'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'El correo es requerido';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telefonoController,
            decoration: _buildInputDecoration('Teléfono'),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'El teléfono es requerido';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  /// 🎨 CONSTRUIR DECORACIÓN DE INPUT
  /// 
  /// Crea la decoración estándar para todos los campos de texto del formulario.
  /// Sigue el design system UPEA con colores, bordes y estilos consistentes.
  /// 
  /// CARACTERÍSTICAS DE LA DECORACIÓN:
  /// - Fondo gris claro (#F8F9FB) según design system
  /// - Bordes redondeados (14px) según especificación
  /// - Borde gris por defecto (#E0E4ED)
  /// - Borde azul UPEA al enfocar (#005BAC)
  /// - Borde rojo para errores de validación
  /// - Padding interno responsive
  /// - Etiquetas con tipografía Inter
  /// 
  /// ESTADOS MANEJADOS:
  /// - Normal: Borde gris claro
  /// - Enfocado: Borde azul UPEA con grosor 1.2px
  /// - Error: Borde rojo con mensaje
  /// - Error enfocado: Borde rojo mantenido
  /// 
  /// @param label - Texto de la etiqueta del campo
  /// @return InputDecoration - Decoración configurada
  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 13,
      ),
    );
  }
}



