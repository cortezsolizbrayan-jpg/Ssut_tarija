import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import '../../widgets/navegacion/icono_notificaciones_widget.dart';

class VisualizarFacturaPantalla extends StatelessWidget {
  static const name = 'visualizar-factura';
  
  final Map<String, dynamic> datosFactura;

  const VisualizarFacturaPantalla({
    super.key,
    required this.datosFactura,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.horizontalPadding(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: ResponsiveUtils.verticalPadding(context)),
            _buildTitle(),
            SizedBox(height: height * 0.03),
            _buildFacturaCard(width, height, context),
            SizedBox(height: height * 0.03),
            _buildActionButtons(width, height, context),
            SizedBox(height: height * 0.03),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF005BAC),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Row(
        children: [
          Text(
            'Factura',
            style: TextStyle(
              color: Colors.white,
              fontSize: ResponsiveUtils.subtitleFontSize(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: ResponsiveUtils.cardSpacing(context) * 0.33),
          Icon(Icons.receipt_long, color: Colors.amber, size: ResponsiveUtils.smallIconSize(context)),
        ],
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: ResponsiveUtils.cardSpacing(context) * 0.67),
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

  Widget _buildTitle() {
    return Row(
      children: [
        const Icon(Icons.receipt, color: Color(0xFF005BAC), size: 28),
        const SizedBox(width: 12),
        const Flexible(
          child: Text(
            'Comprobante de Pago',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005BAC),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFacturaCard(double width, double height, BuildContext context) {
    final tipoPago = datosFactura['tipoPago'] ?? 'matricula';
    final tipoTexto = tipoPago == 'matricula' ? 'Matrícula' : 'Colegiatura';
    
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF005BAC), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF005BAC).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con logo y título
          _buildFacturaHeader(tipoTexto),
          
          const Divider(height: 40, thickness: 2, color: Color(0xFFE0E4ED)),
          
          // Información del pago
          _buildSection(
            title: 'Información del Pago',
            icon: Icons.payment,
            children: [
              _buildInfoRow('Tipo de Pago:', tipoTexto),
              if (datosFactura['programaId'] != null)
                _buildInfoRow('Programa:', datosFactura['programaId']),
              _buildInfoRow('Número de Depósito:', datosFactura['numeroDeposito'] ?? 'N/A'),
              _buildInfoRow('Fecha de Pago:', datosFactura['fechaDeposito'] ?? 'N/A'),
              _buildInfoRow(
                'Monto:',
                'Bs. ${datosFactura['monto'] ?? '0'}',
                isHighlighted: true,
              ),
            ],
          ),
          
          const Divider(height: 32, thickness: 1, color: Color(0xFFE0E4ED)),
          
          // Datos de facturación
          _buildSection(
            title: 'Datos de Facturación',
            icon: Icons.person,
            children: [
              _buildInfoRow(
                'Tipo:',
                datosFactura['facturaEmpresa'] == true ? 'Factura Empresa' : 'Factura Personal',
              ),
              _buildInfoRow(
                datosFactura['facturaEmpresa'] == true ? 'Razón Social:' : 'Nombre:',
                datosFactura['nombreFacturacion'] ?? 'N/A',
              ),
              _buildInfoRow(
                '${datosFactura['tipoDocumento'] ?? 'CI'}:',
                datosFactura['nit'] ?? 'N/A',
              ),
              _buildInfoRow('Email:', datosFactura['email'] ?? 'N/A'),
              _buildInfoRow('Teléfono:', datosFactura['telefono'] ?? 'N/A'),
            ],
          ),
          
          const Divider(height: 32, thickness: 1, color: Color(0xFFE0E4ED)),
          
          // Comprobante
          _buildSection(
            title: 'Comprobante de Pago',
            icon: Icons.image,
            children: [
              const SizedBox(height: 12),
              _buildComprobantePreview(datosFactura['comprobanteFile'], height),
            ],
          ),
          
          const Divider(height: 32, thickness: 1, color: Color(0xFFE0E4ED)),
          
          // Footer con información bancaria
          _buildBankInfo(),
          
          const SizedBox(height: 20),
          
          // Estado del pago
          _buildPaymentStatus(),
        ],
      ),
    );
  }

  Widget _buildFacturaHeader(String tipoTexto) {
    return Row(
      children: [
        Image.asset(
          'assets/images/logoposgrado.jpg',
          height: 60,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'UNIVERSIDAD PÚBLICA DE EL ALTO',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005BAC),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'DIRECCIÓN DE POSGRADO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF005BAC)),
                ),
                child: Text(
                  'COMPROBANTE DE $tipoTexto',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAC),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF005BAC), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isHighlighted ? const Color(0xFF005BAC) : const Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlighted ? 18 : 14,
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                color: isHighlighted ? const Color(0xFF005BAC) : const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobantePreview(dynamic comprobanteFile, double height) {
    if (comprobanteFile == null) {
      return Container(
        height: height * 0.2,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Sin comprobante',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    File? file;
    if (comprobanteFile is File) {
      file = comprobanteFile;
    } else if (comprobanteFile is String) {
      file = File(comprobanteFile);
    }

    if (file == null) {
      return const Text('Error al cargar comprobante');
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        file,
        height: height * 0.3,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildBankInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF005BAC).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF005BAC).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance, color: Color(0xFF005BAC), size: 20),
              SizedBox(width: 8),
              Text(
                'Información Bancaria',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005BAC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Banco:', 'BANCO UNIÓN'),
          _buildInfoRow('Cuenta:', '100 000 047 130 25'),
          _buildInfoRow('Titular:', 'DIRECCIÓN DE POSGRADO UPEA'),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pago Registrado',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Su pago ha sido registrado correctamente y está en proceso de verificación.',
                  style: TextStyle(
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

  Widget _buildActionButtons(double width, double height, BuildContext context) {
    return Column(
      children: [
        // Botón principal: Ver como documento
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              context.push('/vista-previa-factura-webview', extra: datosFactura);
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: const Text(
              'Ver como Documento',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              padding: EdgeInsets.symmetric(vertical: height * 0.02),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
            ),
          ),
        ),
        SizedBox(height: height * 0.02),
        // Botones secundarios
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar descarga de PDF
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de descarga en desarrollo'),
                      backgroundColor: Color(0xFF005BAC),
                    ),
                  );
                },
                icon: const Icon(Icons.download, color: Colors.white),
                label: const Text(
                  'Descargar PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF005BAC),
                  padding: EdgeInsets.symmetric(vertical: height * 0.018),
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
                onPressed: () {
                  // TODO: Implementar compartir
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de compartir en desarrollo'),
                      backgroundColor: Color(0xFF005BAC),
                    ),
                  );
                },
                icon: const Icon(Icons.share, color: Color(0xFF005BAC)),
                label: const Text(
                  'Compartir',
                  style: TextStyle(
                    color: Color(0xFF005BAC),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: height * 0.018),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0xFF005BAC), width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}




