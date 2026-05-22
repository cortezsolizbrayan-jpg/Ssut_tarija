import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/config/router/app_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/features/sistema/screens/inscripcion/componentes/controlador_temporizador_inscripcion.dart';
import '../../widgets/navegacion/icono_notificaciones_widget.dart';

class FormularioPagoCompletoPantalla extends StatefulWidget {
  static const name = 'formulario-pago-completo';
  final String? numeroMatricula;
  final double? monto;
  final String? programaId;
  final String tipoPago; // 'matricula' o 'colegiatura'

  const FormularioPagoCompletoPantalla({
    super.key,
    this.numeroMatricula,
    this.monto,
    this.programaId,
    required this.tipoPago,
  });

  @override
  State<FormularioPagoCompletoPantalla> createState() =>
      _FormularioPagoCompletoPantallaState();
}

class _FormularioPagoCompletoPantallaState
    extends State<FormularioPagoCompletoPantalla> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _comprobanteFile;

  // ─── Estado de validación del comprobante ───────────────────────────────
  // Números de depósito válidos (mock hasta tener la API real)
  static const _numerosValidos = {
    '200215456',
    '123456789',
    '987654321',
    '111222333',
  };
  bool _validando = false; // spinner mientras "llama a la API"
  bool? _comprobanteValidado; // null = no validado, true = OK, false = inválido
  bool get _formDesbloqueado => _comprobanteValidado == true;

  // Controladores para datos del pago
  final TextEditingController _numeroDepositoController =
      TextEditingController();
  final TextEditingController _fechaDepositoController =
      TextEditingController();
  final TextEditingController _montoDepositoController =
      TextEditingController();

  // Controladores para datos de facturación
  final TextEditingController _nombreFacturacionController =
      TextEditingController();
  final TextEditingController _nitController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  String _tipoDocumento = 'CI'; // CI, NIT, PASAPORTE
  bool _facturaEmpresa = false;
  StreamSubscription<String>? _timerSub;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadExistingData();
    // Escuchar vencimiento del temporizador global
    _timerSub = ControladorTemporizadorInscripcion.onTiempoAgotadoGlobal.listen(
      (_) {
        if (!mounted) return;
        _botarAProgramasVigentes();
      },
    );
  }

  void _initializeForm() {
    // Inicializar monto si viene como parámetro
    if (widget.monto != null) {
      _montoDepositoController.text = widget.monto!.toStringAsFixed(0);
    }

    // Fecha actual por defecto
    final now = DateTime.now();
    _fechaDepositoController.text =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  Future<void> _loadExistingData() async {
    // Cargar datos de facturación guardados
    final facturacionData = await LocalStorageService.getFacturacionData();
    if (facturacionData != null) {
      setState(() {
        _nombreFacturacionController.text = facturacionData['nombre'] ?? '';
        _nitController.text = facturacionData['nit'] ?? '';
        _emailController.text = facturacionData['email'] ?? '';
        _telefonoController.text = facturacionData['telefono'] ?? '';
        _tipoDocumento = facturacionData['tipoDocumento'] ?? 'CI';
        _facturaEmpresa = facturacionData['facturaEmpresa'] ?? false;
      });
    }

    // Cargar comprobante existente para este programa y tipo de pago
    if (widget.programaId != null) {
      final key = '${widget.programaId}_${widget.tipoPago}';
      final existingReceiptPath =
          await LocalStorageService.getPaymentReceiptForProgram(key);
      if (existingReceiptPath != null) {
        final file = File(existingReceiptPath);
        if (await file.exists()) {
          setState(() {
            _comprobanteFile = file;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _timerSub?.cancel();
    _numeroDepositoController.dispose();
    _fechaDepositoController.dispose();
    _montoDepositoController.dispose();
    _nombreFacturacionController.dispose();
    _nitController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _botarAProgramasVigentes() {
    LocalStorageService.clearActiveEnrollment();
    // goRouter.go destruye todo el stack y navega directo, sin importar
    // cuántos formularios, dialogs o modals estén abiertos encima
    goRouter.go('/programas-vigentes');
  }

  Future<void> _pickComprobante() async {
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
          _comprobanteFile = file;
        });

        // Guardar comprobante para este programa y tipo de pago específico
        if (widget.programaId != null) {
          final key = '${widget.programaId}_${widget.tipoPago}';
          await LocalStorageService.savePaymentReceiptForProgram(
            key,
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

  Future<void> _saveFacturacionData() async {
    final data = {
      'nombre': _nombreFacturacionController.text,
      'nit': _nitController.text,
      'email': _emailController.text,
      'telefono': _telefonoController.text,
      'tipoDocumento': _tipoDocumento,
      'facturaEmpresa': _facturaEmpresa,
    };
    await LocalStorageService.saveFacturacionData(data);
  }

  /// Simula la llamada a la API de validación de comprobante
  Future<void> _validarComprobante() async {
    final numero = _numeroDepositoController.text.trim();
    final fecha = _fechaDepositoController.text.trim();
    final monto = _montoDepositoController.text.trim();

    if (numero.isEmpty || fecha.isEmpty || monto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa el número, fecha y monto antes de validar.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _validando = true;
      _comprobanteValidado = null;
    });

    // Simular latencia de red (reemplazar con llamada real cuando esté disponible)
    await Future.delayed(const Duration(seconds: 2));

    final esValido = _numerosValidos.contains(numero);

    if (!mounted) return;
    setState(() {
      _validando = false;
      _comprobanteValidado = esValido;
    });

    if (esValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text(
                '✅ Comprobante verificado. Ya puedes completar el formulario.',
              ),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  '❌ Número de depósito no encontrado. Verifica los datos.',
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFC62828),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 5),
        ),
      );
    }
  }

  void _handleSubmit() async {
    if (!_formDesbloqueado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero valida el número de depósito.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (_comprobanteFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debe subir el comprobante de pago'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      // Guardar datos de facturación
      await _saveFacturacionData();

      // Preparar datos para la factura
      final datosFactura = {
        'tipoPago': widget.tipoPago,
        'programaId': widget.programaId,
        'numeroDeposito': _numeroDepositoController.text,
        'fechaDeposito': _fechaDepositoController.text,
        'monto': _montoDepositoController.text,
        'nombreFacturacion': _nombreFacturacionController.text,
        'nit': _nitController.text,
        'email': _emailController.text,
        'telefono': _telefonoController.text,
        'tipoDocumento': _tipoDocumento,
        'facturaEmpresa': _facturaEmpresa,
        'comprobanteFile': _comprobanteFile,
      };

      // Navegar a la pantalla de visualización de factura
      if (mounted) {
        context.push('/visualizar-factura', extra: datosFactura);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    final tipoTexto = widget.tipoPago == 'matricula'
        ? 'Matrícula'
        : 'Colegiatura';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(),
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
              _buildTitle(tipoTexto),
              SizedBox(height: height * 0.03),
              _buildImportantSection(width, height),
              SizedBox(height: height * 0.03),
              // PASO 1: solo campos básicos + botón validar
              _buildPaymentDataSection(width, height),
              SizedBox(height: height * 0.02),
              _buildValidationButton(),
              // PASO 2: resto del formulario, bloqueado hasta validar
              if (_formDesbloqueado) ...[
                SizedBox(height: height * 0.03),
                _buildBillingDataSection(width, height),
                SizedBox(height: height * 0.03),
                _buildReceiptUploadSection(width, height),
                SizedBox(height: height * 0.04),
                _buildActionButtons(width, height),
              ] else ...[
                SizedBox(height: height * 0.04),
                _buildLockedHint(),
              ],
              SizedBox(height: height * 0.03),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(width),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
            color: Theme.of(context).cardColor,
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
    );
  }

  Widget _buildTitle(String tipoTexto) {
    return Row(
      children: [
        Flexible(
          child: Text(
            widget.programaId != null
                ? 'Pago de $tipoTexto - ${widget.programaId}'
                : 'Pago de $tipoTexto',
            style: TextStyle(
              fontSize: ResponsiveUtils.titleFontSize(context),
              fontWeight: FontWeight.bold,
              color: const Color(0xFF005BAC),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImportantSection(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                'IMPORTANTE:',
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
            'El pago debe realizarse con 24 horas de anticipación.',
          ),
          _buildBulletPoint(
            'Solo se aceptan depósitos o transferencias al Banco Unión',
          ),
          _buildBulletPoint(
            'Realiza tu pago exclusivamente a la cuenta institucional del Posgrado UPEA',
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
                    style: TextStyle(fontSize: 11, color: Color(0xFF666666)),
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
                  color: const Color(0xFF005BAC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 30,
                  color: Color(0xFF005BAC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

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

  Widget _buildPaymentDataSection(double width, double height) {
    final statusColor = _comprobanteValidado == true
        ? const Color(0xFF2E7D32)
        : _comprobanteValidado == false
        ? const Color(0xFFC62828)
        : const Color(0xFFE0E4ED);

    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor,
          width: _comprobanteValidado != null ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: const Color(0xFF005BAC), size: 24),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Paso 1 · Datos del Depósito',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
              if (_comprobanteValidado == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Verificado',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (_comprobanteValidado == false)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC62828),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Inválido',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ingresa los datos básicos del depósito para verificar su validez.',
            style: TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          // ── Número con sufijo de estado ──
          Stack(
            alignment: Alignment.centerRight,
            children: [
              _buildFormField(
                label: 'Número de Depósito / Transferencia',
                controller: _numeroDepositoController,
                keyboardType: TextInputType.number,
                hint: 'Ej: 200215456',
                icon: Icons.receipt_long,
                onChanged: (_) {
                  if (_comprobanteValidado != null) {
                    setState(() => _comprobanteValidado = null);
                  }
                },
              ),
              if (_comprobanteValidado == true)
                const Padding(
                  padding: EdgeInsets.only(right: 14, top: 24),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2E7D32),
                    size: 22,
                  ),
                )
              else if (_comprobanteValidado == false)
                const Padding(
                  padding: EdgeInsets.only(right: 14, top: 24),
                  child: Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFC62828),
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFormField(
            label: 'Fecha del Depósito',
            controller: _fechaDepositoController,
            readOnly: true,
            icon: Icons.calendar_today,
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
                  _comprobanteValidado = null;
                });
              }
            },
          ),
          const SizedBox(height: 14),
          _buildFormField(
            label: 'Monto del Depósito',
            controller: _montoDepositoController,
            keyboardType: TextInputType.number,
            prefix: const Text(
              'Bs. ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            icon: Icons.attach_money,
            onChanged: (_) {
              if (_comprobanteValidado != null) {
                setState(() => _comprobanteValidado = null);
              }
            },
          ),
        ],
      ),
    );
  }

  /// Botón de validación + pista de números válidos para pruebas
  Widget _buildValidationButton() {
    if (_comprobanteValidado == true) {
      return const SizedBox.shrink(); // Ya validado, no mostramos el botón
    }
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _validando ? null : _validarComprobante,
            icon: _validando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user_rounded, color: Colors.white),
            label: Text(
              _validando ? 'Verificando...' : 'Validar Comprobante',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAC),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: _validando ? 0 : 3,
            ),
          ),
        ),
        if (_comprobanteValidado == false) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: Color(0xFFC62828), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Número no registrado en el sistema. Verifica el número de depósito e intenta nuevamente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFC62828),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Hint de prueba (remover cuando exista la API real)
        const SizedBox(height: 8),
        const Text(
          '🔬 Números válidos de prueba: 200215456 · 123456789 · 987654321',
          style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Mensaje que se muestra cuando el formulario está bloqueado
  Widget _buildLockedHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBCCEE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: Color(0xFF005BAC), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'El resto del formulario se habilitará una vez que valides el número de depósito.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF444466),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDataSection(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt, color: const Color(0xFF005BAC), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Datos de Facturación',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          SizedBox(height: height * 0.02),

          // Tipo de facturación
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Factura Personal'),
                  value: !_facturaEmpresa,
                  onChanged: (value) {
                    setState(() {
                      _facturaEmpresa = !value!;
                    });
                  },
                  activeColor: const Color(0xFF005BAC),
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Factura Empresa'),
                  value: _facturaEmpresa,
                  onChanged: (value) {
                    setState(() {
                      _facturaEmpresa = value!;
                    });
                  },
                  activeColor: const Color(0xFF005BAC),
                ),
              ),
            ],
          ),

          SizedBox(height: height * 0.02),
          _buildFormField(
            label: _facturaEmpresa ? 'Razón Social' : 'Nombre Completo',
            controller: _nombreFacturacionController,
            icon: _facturaEmpresa ? Icons.business : Icons.person,
            hint: _facturaEmpresa
                ? 'Nombre de la empresa'
                : 'Nombre y apellidos completos',
          ),

          SizedBox(height: height * 0.02),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _tipoDocumento,
                  decoration: InputDecoration(
                    labelText: 'Tipo Documento',
                    filled: true,
                    fillColor: const Color(0xFFF8F9FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF005BAC),
                        width: 1.2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CI', child: Text('CI')),
                    DropdownMenuItem(value: 'NIT', child: Text('NIT')),
                    DropdownMenuItem(
                      value: 'PASAPORTE',
                      child: Text('Pasaporte'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _tipoDocumento = value!;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: _buildFormField(
                  label: _tipoDocumento == 'NIT'
                      ? 'NIT'
                      : 'Número de $_tipoDocumento',
                  controller: _nitController,
                  keyboardType: TextInputType.text,
                  icon: Icons.badge,
                ),
              ),
            ],
          ),

          SizedBox(height: height * 0.02),
          _buildFormField(
            label: 'Email',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            icon: Icons.email,
            hint: 'correo@ejemplo.com',
          ),

          SizedBox(height: height * 0.02),
          _buildFormField(
            label: 'Teléfono',
            controller: _telefonoController,
            keyboardType: TextInputType.phone,
            icon: Icons.phone,
            hint: '70123456',
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptUploadSection(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.cloud_upload,
                color: const Color(0xFF005BAC),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Comprobante de Pago',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info, color: Colors.red, size: 16),
              SizedBox(width: 4),
              Text(
                'Fotografía del comprobante (Obligatorio)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickComprobante,
            child: Container(
              width: double.infinity,
              height: height * 0.25,
              decoration: BoxDecoration(
                color: _comprobanteFile != null
                    ? const Color(0xFF4CAF50).withOpacity(0.1)
                    : const Color(0xFF005BAC).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _comprobanteFile != null
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF005BAC).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: _comprobanteFile != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _comprobanteFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 60,
                          color: const Color(0xFF005BAC).withOpacity(0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Subir Comprobante',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF005BAC).withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toca aquí para seleccionar la foto\ndel comprobante de pago',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    Widget? prefix,
    IconData? icon,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: icon != null
                ? Icon(icon, color: const Color(0xFF005BAC))
                : null,
            prefix: prefix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE0E4ED)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF005BAC),
                width: 1.2,
              ),
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
            if (label.toLowerCase().contains('email') && !value.contains('@')) {
              return 'Ingrese un email válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(double width, double height) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _handleSubmit,
            icon: const Icon(Icons.send, color: Colors.white),
            label: Text(
              'Registrar Pago',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAC),
              padding: EdgeInsets.symmetric(vertical: height * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close, color: Color(0xFF005BAC)),
            label: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF005BAC),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: height * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              side: const BorderSide(color: Color(0xFF005BAC), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

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

class _DottedLinePainter extends CustomPainter {
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

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




