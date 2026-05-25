import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/icono_notificaciones_widget.dart';

class DepositoMatriculaScreen extends StatefulWidget {
  static const name = 'deposito-matricula';
  final String? numeroMatricula;
  final double? monto;

  const DepositoMatriculaScreen({super.key, this.numeroMatricula, this.monto});

  @override
  State<DepositoMatriculaScreen> createState() =>
      _DepositoMatriculaScreenState();
}

class _DepositoMatriculaScreenState extends State<DepositoMatriculaScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _paymentProofFile;

  final TextEditingController _numeroDepositoController = TextEditingController(
    text: '200215456',
  );
  final TextEditingController _fechaDepositoController = TextEditingController(
    text: '08/09/2025',
  );
  final TextEditingController _montoDepositoController = TextEditingController(
    text: '2400',
  );

  @override
  void initState() {
    super.initState();
    if (widget.monto != null) {
      _montoDepositoController.text = widget.monto!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _numeroDepositoController.dispose();
    _fechaDepositoController.dispose();
    _montoDepositoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _paymentProofFile = File(image.path);
        });
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

      // TODO: Implementar envío del depósito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Depósito enviado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          context.pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

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
            const Text(
              'Posgrado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.school, color: Colors.amber, size: 18),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          const SizedBox(width: 8),
          const NotificationIconWidget(size: 40, iconSize: 22),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.push('/mis-datos-personales'),
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              backgroundImage: AssetImage('assets/icons/profile_img.png'),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.02),
              // Título
              Row(
                children: [
                  const Text(
                    'Deposito de Matricula',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005BAC),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(left: 16),
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
                '? IMPORTANTE:',
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


