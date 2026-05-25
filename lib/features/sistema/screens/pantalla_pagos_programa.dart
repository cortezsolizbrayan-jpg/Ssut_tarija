import 'package:flutter/material.dart';
import 'package:refactor_template/features/sistema/widgets/tarjetas/tarjetas_personalizadas.dart';

/// Pantalla de demostración de las tarjetas personalizadas
class ProgramPaymentsPantalla extends StatefulWidget {
  static const String name = 'program-payments';
  
  const ProgramPaymentsPantalla({super.key});

  @override
  State<ProgramPaymentsPantalla> createState() => _ProgramPaymentsPantallaState();
}

class _ProgramPaymentsPantallaState extends State<ProgramPaymentsPantalla> {
  int selectedCardIndex = 1; // Matrículas seleccionada por defecto

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF005BAC);
    const lightBackground = Color(0xFFF6F8FB);

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header azul con información del programa
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue,
                    primaryBlue.withOpacity(0.85),
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Barra superior con menú y notificaciones
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () {},
                          ),
                          const Spacer(),
                          
                          // Logo Banco Unión (placeholder)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'BANCO\nUNIÓN',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: primaryBlue,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 12),
                          
                          // Notificaciones
                          Stack(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {},
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(width: 8),
                          
                          // Avatar del usuario
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/graduation_icon.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.person,
                                    color: primaryBlue,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Título del programa
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 28,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Programa:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'DISEÑO, DESARROLLO Y MANTENIMIENTO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Plan de pagos
                      const Text(
                        'Plan de Pagos del Programa',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Descuento del Programa con %10',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenido con tarjetas (desplazable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Las 3 tarjetas de programa (superpuestas al header)
                    Transform.translate(
                      offset: const Offset(0, -60),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            // Colegiatura
                            Expanded(
                              child: ProgramCard(
                                title: 'Colegiatura',
                                subtitle: '2 de 5 Pagadas',
                                progress: 0.65,
                                isSelected: selectedCardIndex == 0,
                                onTap: () {
                                  setState(() {
                                    selectedCardIndex = 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Matrículas (seleccionada)
                            Expanded(
                              child: ProgramCard(
                                title: 'Matrículas',
                                subtitle: '2 de 3 Cuotas',
                                progress: 0.60,
                                isSelected: selectedCardIndex == 1,
                                onTap: () {
                                  setState(() {
                                    selectedCardIndex = 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            
                            // Monografía/Tesis
                            Expanded(
                              child: ProgramCard(
                                title: 'Monografía\n/ Tesis',
                                subtitle: '',
                                progress: 0.0,
                                isSelected: selectedCardIndex == 2,
                                onTap: () {
                                  setState(() {
                                    selectedCardIndex = 2;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Sección de matrículas
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título y botón de historial
                          Row(
                            children: [
                              const Text(
                                'Matrículas',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFBBBBBB),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const Spacer(),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.receipt_long, size: 18),
                                label: const Text('Ver Historial de Facturas'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Tarjetas de detalle de matrícula
                          MatriculaDetailCard(
                            matriculaNumber: '1',
                            concepto: 'Colegiatura del Programa',
                            fechaVencimiento: DateTime(2025, 8, 12),
                            montoDdeuda: 500,
                            fechaPago: DateTime(2025, 11, 12),
                            coordinador: 'Juan Pérez',
                            isPagado: true,
                            onFacturaPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Descargando factura...'),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Segunda matrícula (ejemplo pendiente)
                          MatriculaDetailCard(
                            matriculaNumber: '2',
                            concepto: 'Segunda Cuota del Programa',
                            fechaVencimiento: DateTime(2025, 12, 15),
                            montoDdeuda: 750,
                            isPagado: false,
                            onFacturaPressed: null,
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Tercera matrícula (ejemplo)
                          MatriculaDetailCard(
                            matriculaNumber: '3',
                            concepto: 'Tercera Cuota del Programa',
                            fechaVencimiento: DateTime(2026, 1, 20),
                            montoDdeuda: 600,
                            isPagado: false,
                            onFacturaPressed: null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


