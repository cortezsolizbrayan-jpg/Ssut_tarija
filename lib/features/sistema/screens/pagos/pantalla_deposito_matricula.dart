import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/config/router/app_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/features/sistema/screens/inscripcion/componentes/controlador_temporizador_inscripcion.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/icono_notificaciones_widget.dart';

/// 💰 PANTALLA DE DEPÓSITO DE MATRÍCULA - V0.4.4
///
/// Pantalla especializada para el registro de depósitos de matrícula en el sistema UPEA.
/// Permite a los estudiantes registrar sus pagos de matrícula con comprobante fotográfico.
///
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Formulario de registro de depósito con validación
/// ✅ Carga de comprobante fotográfico obligatorio
/// ✅ Información bancaria institucional (Banco Unión)
/// ✅ Persistencia de comprobantes por programa específico
/// ✅ Validación de campos obligatorios
/// ✅ Interfaz responsive con colores UPEA
/// ✅ Navegación inferior integrada
///
/// FLUJO DE TRABAJO:
/// 1. Usuario ingresa datos del depósito (número, fecha, monto)
/// 2. Selecciona comprobante fotográfico desde galería
/// 3. Sistema valida información y comprobante
/// 4. Guarda comprobante asociado al programa específico
/// 5. Envía registro de depósito al sistema
///
/// INTEGRACIÓN:
/// - Conectado con LocalStorageService para persistencia
/// - Usado desde pantallas de inscripción y pagos
/// - Navegación con GoRouter para flujo completo
/// - Responsive design para múltiples dispositivos
///
/// DATOS BANCARIOS INSTITUCIONALES:
/// - Banco: BANCO UNIÓN
/// - Cuenta: 100 000 047 130 25
/// - Titular: Posgrado UPEA
class DepositoMatriculaPantalla extends StatefulWidget {
  static const name = 'deposito-matricula';

  /// Número de matrícula del estudiante (opcional)
  final String? numeroMatricula;

  /// Monto del depósito a registrar (opcional, se puede editar)
  final double? monto;

  /// ID del programa académico específico para asociar el comprobante
  final String? programaId;

  const DepositoMatriculaPantalla({
    super.key,
    this.numeroMatricula,
    this.monto,
    this.programaId,
  });

  @override
  State<DepositoMatriculaPantalla> createState() =>
      _DepositoMatriculaPantallaState();
}

class _DepositoMatriculaPantallaState extends State<DepositoMatriculaPantalla> {
  // 📋 FORMULARIO Y VALIDACIÓN
  final _formKey =
      GlobalKey<FormState>(); // Clave global para validación del formulario

  // 📷 SELECTOR DE IMÁGENES
  final ImagePicker _picker =
      ImagePicker(); // Servicio para seleccionar imágenes

  // 🖼️ ARCHIVO DE COMPROBANTE
  File? _paymentProofFile;
  StreamSubscription<String>?
  _timerSub; // Archivo de imagen del comprobante de pago

  // 🎛️ CONTROLADORES DE CAMPOS DE TEXTO
  /// Controlador para el número de depósito (prellenado con ejemplo)
  final TextEditingController _numeroDepositoController = TextEditingController(
    text: '200215456',
  );

  /// Controlador para la fecha de depósito (prellenado con fecha actual)
  final TextEditingController _fechaDepositoController = TextEditingController(
    text: '08/09/2025',
  );

  /// Controlador para el monto del depósito (prellenado con ejemplo)
  final TextEditingController _montoDepositoController = TextEditingController(
    text: '2400',
  );

  /// 🚀 INICIALIZACIÓN DEL Widget
  ///
  /// Configura el estado inicial de la pantalla:
  /// 1. Establece el monto si se proporciona desde Widget padre
  /// 2. Carga comprobante de pago existente para el programa específico
  /// 3. Inicializa controladores con valores por defecto
  @override
  void initState() {
    super.initState();
    if (widget.monto != null) {
      _montoDepositoController.text = widget.monto!.toStringAsFixed(0);
    }
    _loadExistingPaymentReceipt();
    // Escuchar vencimiento del temporizador global
    _timerSub = ControladorTemporizadorInscripcion.onTiempoAgotadoGlobal.listen(
      (_) {
        if (!mounted) return;
        _botarAProgramasVigentes();
      },
    );
  }

  /// 📂 CARGAR COMPROBANTE DE PAGO EXISTENTE
  ///
  /// Busca y carga un comprobante de pago previamente guardado para el programa específico.
  /// Esto permite que el usuario vea su comprobante anterior si ya lo había subido.
  ///
  /// PROCESO:
  /// 1. Verifica que existe un programaId
  /// 2. Busca el path del comprobante en almacenamiento local
  /// 3. Verifica que el archivo existe físicamente
  /// 4. Actualiza el estado con el archivo encontrado
  ///
  /// @return Future<void> - Operación asíncrona de carga
  Future<void> _loadExistingPaymentReceipt() async {
    if (widget.programaId != null) {
      final existingReceiptPath =
          await LocalStorageService.getPaymentReceiptForProgram(
            widget.programaId!,
          );
      if (existingReceiptPath != null) {
        final file = File(existingReceiptPath);
        if (await file.exists()) {
          setState(() {
            _paymentProofFile = file;
          });
        }
      }
    }
  }

  /// 🧹 LIMPIEZA DE RECURSOS
  ///
  /// Libera los controladores de texto para evitar memory leaks.
  /// Se ejecuta automáticamente cuando el Widget se destruye.
  @override
  void dispose() {
    _timerSub?.cancel();
    _numeroDepositoController.dispose();
    _fechaDepositoController.dispose();
    _montoDepositoController.dispose();
    super.dispose();
  }

  void _botarAProgramasVigentes() {
    LocalStorageService.clearActiveEnrollment();
    goRouter.go('/programas-vigentes');
  }

  /// 📷 SELECCIONAR IMAGEN DE COMPROBANTE
  ///
  /// Permite al usuario seleccionar una imagen del comprobante de pago desde la galería.
  /// La imagen se optimiza automáticamente para reducir el tamaño del archivo.
  ///
  /// CARACTERÍSTICAS:
  /// - Resolución máxima: 1920x1920 px para balance calidad/tamaño
  /// - Calidad de compresión: 85% para optimizar almacenamiento
  /// - Guarda automáticamente el path asociado al programa específico
  /// - Manejo robusto de errores con SnackBar informativo
  ///
  /// PROCESO:
  /// 1. Abre selector de galería con parámetros optimizados
  /// 2. Convierte XFile a File para manipulación local
  /// 3. Actualiza estado de la UI con la imagen seleccionada
  /// 4. Persiste el path del comprobante para el programa específico
  /// 5. Maneja errores y notifica al usuario si ocurren problemas
  ///
  /// @return Future<void> - Operación asíncrona de selección
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        final file = File(image.path);
        setState(() {
          _paymentProofFile = file;
        });

        // Guardar el comprobante para este programa específico
        if (widget.programaId != null) {
          await LocalStorageService.savePaymentReceiptForProgram(
            widget.programaId!,
            file.path,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ✅ MANEJAR ENVÍO DEL FORMULARIO
  ///
  /// Procesa el envío del formulario de depósito con validaciones completas.
  /// Verifica que todos los campos estén completos y que se haya subido el comprobante.
  ///
  /// VALIDACIONES:
  /// - Formulario válido según reglas definidas
  /// - Comprobante de pago obligatorio subido
  /// - Campos de texto no vacíos y con formato correcto
  ///
  /// FLUJO DE ÉXITO:
  /// 1. Valida formulario completo
  /// 2. Verifica existencia de comprobante fotográfico
  /// 3. Muestra mensaje de éxito con información del programa
  /// 4. Navega de vuelta después de 1 segundo
  ///
  /// FLUJO DE ERROR:
  /// - Muestra SnackBar rojo con mensaje específico del error
  /// - Mantiene al usuario en la pantalla para corrección
  ///
  /// TODO: Implementar envío real al backend con datos del programa
  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_paymentProofFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes subir una fotografía del comprobante de pago'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // TODO: Implementar envío del depósito con programa específico
      final programInfo = widget.programaId != null
          ? ' para el programa ${widget.programaId}'
          : '';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Depósito enviado correctamente$programInfo'),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.pop();
        }
      });
    }
  }

  /// 🎨 CONSTRUCCIÓN DE LA INTERFAZ PRINCIPAL
  ///
  /// Construye la interfaz completa de la pantalla de depósito de matrícula.
  /// Utiliza diseño responsive y colores del sistema UPEA.
  ///
  /// ESTRUCTURA DE LA UI:
  /// 1. Scaffold con color de fondo institucional (#F6F8FB)
  /// 2. AppBar personalizada con branding UPEA y navegación
  /// 3. Formulario scrolleable con validación
  /// 4. Sección de información importante con datos bancarios
  /// 5. Campos de entrada para datos del depósito
  /// 6. Sección de carga de comprobante fotográfico
  /// 7. Botones de acción (Enviar/Cancelar)
  /// 8. Navegación inferior integrada
  ///
  /// CARACTERÍSTICAS RESPONSIVE:
  /// - Espaciado adaptativo según tamaño de pantalla
  /// - Fuentes escalables con ResponsiveUtils
  /// - Padding y márgenes proporcionales
  /// - Widgets que se adaptan a diferentes dispositivos
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BAC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            // TODO: Abrir menú lateral
          },
        ),
        title: Row(
          children: [
            Text(
              'Posgrado',
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.subtitleFontSize(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.33),
            Icon(
              Icons.school,
              color: Colors.amber,
              size: ResponsiveUtils.smallIconSize(context),
            ),
          ],
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(
              right: ResponsiveUtils.cardSpacing(context) * 0.67,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.cardSpacing(context) * 0.67,
              vertical: ResponsiveUtils.cardSpacing(context) * 0.33,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'BANCO UNION',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005BAC),
              ),
            ),
          ),
          SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.67),
          const NotificationIconWidget(size: 40, iconSize: 22),
          SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.67),
          GestureDetector(
            onTap: () => context.push('/mis-datos-personales'),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/icons/profile_img.png'),
            ),
          ),
          SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.67),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveUtils.horizontalPadding(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: ResponsiveUtils.verticalPadding(context)),
              // Título
              Row(
                children: [
                  Text(
                    widget.programaId != null
                        ? 'Depósito de Matrícula - ${widget.programaId}'
                        : 'Depósito de Matrícula',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.titleFontSize(context),
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF005BAC),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        left: ResponsiveUtils.horizontalPadding(context),
                      ),
                      height: 2,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.shade300,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: CustomPaint(painter: _DottedLinePainter()),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.03),
              // Sección importante
              _buildImportantSection(width, height),
              SizedBox(height: height * 0.03),
              // Formulario
              _buildFormField(
                label: 'Numero de Deposito',
                controller: _numeroDepositoController,
                width: width,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: height * 0.02),
              _buildFormField(
                label: 'Fecha de Deposito',
                controller: _fechaDepositoController,
                width: width,
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _fechaDepositoController.text =
                          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                    });
                  }
                },
              ),
              SizedBox(height: height * 0.02),
              _buildFormField(
                label: 'Monto del Deposito',
                controller: _montoDepositoController,
                width: width,
                keyboardType: TextInputType.number,
                prefix: const Text('Bs. '),
              ),
              SizedBox(height: height * 0.03),
              // Sección de carga de archivo
              _buildFileUploadSection(width, height),
              SizedBox(height: height * 0.04),
              // Botones
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSubmit,
                      icon: const Icon(Icons.pan_tool, color: Colors.white),
                      label: const Text(
                        'Enviar Deposito',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        padding: EdgeInsets.symmetric(vertical: height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                  SizedBox(width: width * 0.03),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        padding: EdgeInsets.symmetric(vertical: height * 0.02),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.03),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(width),
    );
  }

  /// ⚠️ CONSTRUIR SECCIÓN DE INFORMACIÓN IMPORTANTE
  ///
  /// Crea una tarjeta destacada con información crítica sobre el proceso de pago.
  /// Incluye datos bancarios institucionales y requisitos importantes.
  ///
  /// INFORMACIÓN MOSTRADA:
  /// - Requisitos de tiempo (24 horas de anticipación)
  /// - Banco autorizado (BANCO UNIÓN únicamente)
  /// - Datos de la cuenta institucional
  /// - Restricciones de elegibilidad
  ///
  /// DISEÑO:
  /// - Borde rojo para llamar la atención
  /// - Fondo blanco para contraste
  /// - Bullets rojos para cada punto importante
  /// - Logo institucional y datos bancarios destacados
  /// - Icono de perfil para identificación visual
  ///
  /// DATOS BANCARIOS INCLUIDOS:
  /// - Banco: BANCO UNIÓN
  /// - Cuenta: 100 000 047 130 25
  /// - Titular: Posgrado UPEA
  ///
  /// @param width - Ancho de pantalla para responsive design
  /// @param height - Alto de pantalla para espaciado proporcional
  /// @return Widget con la sección de información importante
  Widget _buildImportantSection(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.shade300,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '▲ IMPORTANTE:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.015),
          _buildBulletPoint(
            'El pago debe realizarse con 24 horas de anticipación para poder registrarlo.',
          ),
          _buildBulletPoint(
            'Solo se aceptan depósitos o transferencias al Banco Unión',
          ),
          _buildBulletPoint(
            'Realiza tu pago exclusivamente a la cuenta institucional del Posgrado UPEA:',
          ),
          _buildBulletPoint(
            'Solo las personas inscritas en el programa pueden realizar este pago.',
          ),
          SizedBox(height: height * 0.02),
          Row(
            children: [
              Image.asset(
                'assets/images/logoposgrado.jpg',
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BANCO UNION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005BAC),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Número de cuenta único',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '100 000 047 130 25',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005BAC),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔸 CONSTRUIR PUNTO DE INFORMACIÓN
  ///
  /// Crea un elemento de lista con bullet point rojo para información importante.
  /// Usado dentro de la sección de información importante para destacar cada requisito.
  ///
  /// CARACTERÍSTICAS:
  /// - Bullet point rojo para llamar la atención
  /// - Texto en color rojo para consistencia
  /// - Espaciado adecuado entre elementos
  /// - Texto expandible para contenido largo
  ///
  /// @param text - Texto del punto de información a mostrar
  /// @return Widget con el punto de información formateado
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.red,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 CONSTRUIR CAMPO DE FORMULARIO
  ///
  /// Crea un campo de entrada de texto personalizado con validación y estilo UPEA.
  /// Soporta diferentes tipos de entrada y comportamientos especiales.
  ///
  /// CARACTERÍSTICAS:
  /// - Label superior con color azul institucional
  /// - Campo de texto con fondo blanco y bordes redondeados
  /// - Validación automática de campos obligatorios
  /// - Soporte para campos de solo lectura con callback onTap
  /// - Prefijos opcionales (ej: "Bs." para montos)
  /// - Tipos de teclado específicos (numérico, texto, etc.)
  ///
  /// ESTADOS VISUALES:
  /// - Normal: Borde gris claro (#E0E0E0)
  /// - Enfocado: Borde azul institucional (#005BAC) con grosor 2px
  /// - Error: Mensaje de validación en rojo
  ///
  /// @param label - Etiqueta descriptiva del campo
  /// @param controller - Controlador de texto para manejar el valor
  /// @param width - Ancho de pantalla para responsive design
  /// @param keyboardType - Tipo de teclado a mostrar (opcional)
  /// @param readOnly - Si el campo es de solo lectura (opcional)
  /// @param onTap - Callback para campos de solo lectura (opcional)
  /// @param prefix - Widget prefijo como "Bs." (opcional)
  /// @return Widget con el campo de formulario completo
  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required double width,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF005BAC),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            prefix: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF005BAC), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Este campo es obligatorio';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 📤 CONSTRUIR SECCIÓN DE CARGA DE ARCHIVO
  ///
  /// Crea la sección para subir el comprobante de pago fotográfico.
  /// Maneja dos estados: sin archivo y con archivo cargado.
  ///
  /// ESTADOS:
  /// 1. SIN ARCHIVO: Muestra área de drop/click con instrucciones
  /// 2. CON ARCHIVO: Muestra preview de la imagen cargada
  ///
  /// CARACTERÍSTICAS:
  /// - Título destacado "Respaldo de Pago"
  /// - Nota obligatoria en rojo para enfatizar importancia
  /// - Área de carga con diseño atractivo (color púrpura)
  /// - Preview de imagen cuando se selecciona archivo
  /// - Icono de nube para indicar funcionalidad de carga
  /// - Texto instructivo bilingüe (inglés técnico)
  ///
  /// DISEÑO:
  /// - Fondo púrpura suave (#purple.shade50)
  /// - Borde púrpura para delimitar área (#purple.shade200)
  /// - Bordes redondeados para consistencia visual
  /// - Altura fija (25% de pantalla) para proporción adecuada
  ///
  /// @param width - Ancho de pantalla para responsive design
  /// @param height - Alto de pantalla para dimensionado proporcional
  /// @return Widget con la sección completa de carga de archivo
  Widget _buildFileUploadSection(double width, double height) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Respaldo de Pago',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005BAC),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Text(
              '• ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            Text(
              '(La fotografía de forma Obligatoria)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: double.infinity,
            height: height * 0.25,
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.purple.shade200,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _paymentProofFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_paymentProofFile!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 60,
                        color: Colors.purple.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Drop or select file',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drop files here or click to browse\nthrough your machine.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// 🧭 CONSTRUIR BARRA DE NAVEGACIÓN INFERIOR
  ///
  /// Crea la barra de navegación inferior con diseño UPEA y funcionalidad completa.
  /// Incluye 4 secciones principales con indicador de sección activa.
  ///
  /// SECCIONES:
  /// - Lista: Navegación a listados
  /// - Perfil: Acceso al perfil de usuario
  /// - Pagos: Sección actual (marcada como activa)
  /// - Descargas: Acceso a descargas
  ///
  /// DISEÑO:
  /// - Fondo azul institucional (#005BAC)
  /// - Bordes redondeados superiores para estética moderna
  /// - Sombra superior para efecto de elevación
  /// - Altura fija de 70px para consistencia
  ///
  /// INDICADOR ACTIVO:
  /// - Círculo amarillo (#FFC107) para sección activa
  /// - Icono más grande y texto en negrita
  /// - Color de icono azul sobre fondo amarillo
  ///
  /// @param width - Ancho de pantalla para responsive design
  /// @return Widget con la barra de navegación completa
  Widget _buildBottomNavBar(double width) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF005BAC),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.list, 'Lista', width),
          _buildNavItem(Icons.person, 'Perfil', width),
          _buildNavItem(Icons.attach_money, 'Pagos', width, isActive: true),
          _buildNavItem(Icons.download, 'Descargas', width),
        ],
      ),
    );
  }

  /// 🎯 CONSTRUIR ELEMENTO DE NAVEGACIÓN
  ///
  /// Crea un elemento individual de la barra de navegación inferior.
  /// Maneja estados activo e inactivo con diferentes estilos visuales.
  ///
  /// ESTADOS:
  /// - ACTIVO: Círculo amarillo, icono grande, texto en negrita
  /// - INACTIVO: Fondo transparente, icono normal, texto regular
  ///
  /// CARACTERÍSTICAS:
  /// - Icono y texto centrados verticalmente
  /// - Transiciones suaves entre estados
  /// - Colores consistentes con design system UPEA
  /// - Tamaños adaptativos según estado
  ///
  /// COLORES:
  /// - Activo: Fondo amarillo (#FFC107), icono azul (#005BAC)
  /// - Inactivo: Fondo transparente, iconos y texto blancos
  ///
  /// @param icon - Icono de Material Design a mostrar
  /// @param label - Texto descriptivo del elemento
  /// @param width - Ancho de pantalla para responsive design
  /// @param isActive - Si este elemento está actualmente seleccionado
  /// @return Widget con el elemento de navegación completo
  Widget _buildNavItem(
    IconData icon,
    String label,
    double width, {
    bool isActive = false,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isActive ? 50 : 40,
          height: isActive ? 50 : 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFFC107) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? const Color(0xFF005BAC) : Colors.white,
            size: isActive ? 28 : 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

/// 🎨 PAINTER PARA LÍNEA PUNTEADA
///
/// CustomPainter que dibuja una línea punteada horizontal decorativa.
/// Usado en el título de la pantalla para separación visual elegante.
///
/// CARACTERÍSTICAS:
/// - Línea horizontal con patrón de puntos
/// - Color gris claro para sutileza visual
/// - Espaciado uniforme entre puntos
/// - Grosor de línea de 2px para visibilidad
///
/// PARÁMETROS DE DIBUJO:
/// - Ancho de punto: 5px
/// - Espacio entre puntos: 3px
/// - Color: gris claro (#grey.shade300)
/// - Posición: Centro vertical del área disponible
///
/// OPTIMIZACIÓN:
/// - shouldRepaint retorna false para mejor rendimiento
/// - Cálculo eficiente de posiciones de puntos
class _DottedLinePainter extends CustomPainter {
  /// 🎨 MÉTODO DE DIBUJO PRINCIPAL
  ///
  /// Dibuja la línea punteada horizontal en el canvas proporcionado.
  /// Calcula automáticamente las posiciones de los puntos basado en el ancho disponible.
  ///
  /// ALGORITMO:
  /// 1. Configura el pincel con color gris y grosor de 2px
  /// 2. Define constantes para ancho de punto (5px) y espacio (3px)
  /// 3. Itera desde el inicio hasta el final del ancho disponible
  /// 4. Dibuja cada segmento de línea con el espaciado definido
  /// 5. Incrementa la posición para el siguiente punto
  ///
  /// @param canvas - Canvas donde dibujar la línea
  /// @param size - Tamaño del área disponible para dibujo
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  /// 🔄 OPTIMIZACIÓN DE REPINTADO
  ///
  /// Indica si el painter necesita repintarse cuando cambia.
  /// Retorna false porque la línea punteada es estática y no cambia.
  /// Esto optimiza el rendimiento evitando repintados innecesarios.
  ///
  /// @param oldDelegate - Instancia anterior del painter
  /// @return false - No necesita repintado, es contenido estático
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}



