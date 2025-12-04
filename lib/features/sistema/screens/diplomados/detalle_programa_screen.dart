import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DetalleProgramaScreen extends StatelessWidget {
  final String titulo;
  final String tipo;

  const DetalleProgramaScreen({
    super.key,
    required this.titulo,
    required this.tipo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header azul
            _buildHeader(context),
            // Información del programa y tarjetas de progreso
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del programa
                    _buildProgramInfo(),
                    // Tarjetas de progreso (Colegiatura, Matrículas, Tesis)
                    _buildProgressCards(),
                    // Sección Colegiatura
                    _buildColegiaturaSection(),
                    // Lista de pagos
                    _buildPaymentsList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Barra de navegación inferior
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00448A), Color(0xFF0F7BD7), Color(0xFF0B5FB4)],
          stops: [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Primera fila: Botón regreso, Logo, Banco Union, Notificaciones, Avatar
            Row(
              children: [
                // Botón de regreso
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                // Logo Posgrado
                Expanded(
                  child: Image.asset(
                    'assets/images/logposgrado.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 6),
                // Banco Union (más compacto)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.credit_card,
                          size: 14,
                          color: Color(0xFF1A3A5C),
                        ),
                        SizedBox(width: 4),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'BANCO UNION',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A3A5C),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Número de cuenta único',
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Notificaciones
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage('assets/icons/profile_img.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Información del programa
            Row(
              children: [
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Programa:',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        titulo,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Plan de Pagos del Programa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Descuento del Programa con %10',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo de programa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3A5C),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tipo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Título del programa
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProgressCards() {
    return Container(
      margin: const EdgeInsets.only(top: -40, left: 20, right: 20),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _ProgressCard(
              titulo: 'Colegiatura',
              pagadas: 2,
              total: 5,
              porcentaje: 65,
              isHighlighted: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _ProgressCard(
              titulo: 'Matrículas',
              pagadas: 2,
              total: 3,
              porcentaje: 66,
              isHighlighted: false,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 1,
            child: _ProgressCard(
              titulo: 'Monografía / Tesis',
              pagadas: 0,
              total: 1,
              porcentaje: 0,
              isHighlighted: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColegiaturaSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Colegiatura',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Ver historial de facturas
            },
            icon: const Icon(Icons.description, size: 18),
            label: const Text('Ver Historial de Facturas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList() {
    final payments = [
      {
        'numero': 1,
        'concepto': 'Colegiatura del Programa',
        'fechaVencimiento': '12/08/25',
        'montoDeuda': 1200.0,
        'fechaPago': '12/11/2025',
        'responsable': 'Coordinador: Juan Pérez',
        'estaPagado': true,
      },
      {
        'numero': 2,
        'concepto': 'Colegiatura del Programa',
        'fechaVencimiento': '12/08/25',
        'montoDeuda': 1200.0,
        'fechaPago': '12/11/2025',
        'responsable': 'Usuario: Guadalupe Flores Mamani',
        'estaPagado': true,
      },
      {
        'numero': 3,
        'concepto': 'Colegiatura del Programa',
        'fechaVencimiento': '15/09/25',
        'montoDeuda': 1200.0,
        'fechaPago': null,
        'responsable': null,
        'estaPagado': false,
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: payments.map((payment) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _PaymentCard(
              numero: payment['numero'] as int,
              concepto: payment['concepto'] as String,
              fechaVencimiento: payment['fechaVencimiento'] as String,
              montoDeuda: payment['montoDeuda'] as double,
              fechaPago: payment['fechaPago'] as String?,
              responsable: payment['responsable'] as String?,
              estaPagado: payment['estaPagado'] as bool,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A3A5C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavBarItem(
              icon: Icons.list,
              label: 'Mis Notas',
              isSelected: false,
            ),
            _NavBarItem(
              icon: Icons.person,
              label: 'Mis Matrículas',
              isSelected: false,
            ),
            _NavBarItem(
              icon: Icons.account_balance_wallet,
              label: 'Mi Seguimiento de Pagos',
              isSelected: true,
            ),
            _NavBarItem(
              icon: Icons.description,
              label: 'Mis Documentos del Programa',
              isSelected: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String titulo;
  final int pagadas;
  final int total;
  final double porcentaje;
  final bool isHighlighted;

  const _ProgressCard({
    required this.titulo,
    required this.pagadas,
    required this.total,
    required this.porcentaje,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFF2196F3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: isHighlighted ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            '$pagadas de $total ${total > 1 ? (titulo.contains('Matrícula') ? 'Cuotas' : 'Pagadas') : (titulo.contains('Matrícula') ? 'Cuota' : 'Pagada')}',
            style: TextStyle(
              color: isHighlighted ? Colors.white70 : Colors.grey.shade600,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: porcentaje / 100,
                    strokeWidth: 5,
                    backgroundColor: isHighlighted
                        ? Colors.white.withOpacity(0.3)
                        : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isHighlighted ? Colors.white : const Color(0xFF2196F3),
                    ),
                  ),
                ),
                Text(
                  '${porcentaje.toInt()}%',
                  style: TextStyle(
                    color: isHighlighted ? Colors.white : Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final int numero;
  final String concepto;
  final String fechaVencimiento;
  final double montoDeuda;
  final String? fechaPago;
  final String? responsable;
  final bool estaPagado;

  const _PaymentCard({
    required this.numero,
    required this.concepto,
    required this.fechaVencimiento,
    required this.montoDeuda,
    this.fechaPago,
    this.responsable,
    required this.estaPagado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'N.º de Pago: $numero',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Concepto de Pago: $concepto',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fecha de Vencimiento: $fechaVencimiento',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Monto de deuda: ${montoDeuda.toInt()} bs.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                if (fechaPago != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Fecha de Pago: $fechaPago',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
                if (responsable != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Responsable del Registro de pago: $responsable',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botones de acción
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (estaPagado) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Pagado',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Pagado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.payments, size: 16),
                    label: const Text('Pagar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('Factura'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2196F3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFF2196F3)),
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
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected
                ? const Color(0xFF87CEEB).withOpacity(0.3)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white70,
            size: 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
