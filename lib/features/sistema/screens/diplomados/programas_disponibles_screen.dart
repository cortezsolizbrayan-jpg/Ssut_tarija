import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProgramasDisponiblesScreen extends StatefulWidget {
  static const name = 'programas-disponibles';
  const ProgramasDisponiblesScreen({super.key});

  @override
  State<ProgramasDisponiblesScreen> createState() => _ProgramasDisponiblesScreenState();
}

class _ProgramasDisponiblesScreenState extends State<ProgramasDisponiblesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF005BAC);
    const Color lightBlueBg = Color(0xFFE9F2F9);

    return Scaffold(
      backgroundColor: lightBlueBg,
      body: Column(
        children: [
          // Header Azul con Logo
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    FadeInLeft(
                      child: Row(
                        children: [
                          const Icon(Icons.school, color: Colors.white, size: 32),
                          const SizedBox(width: 8),
                          const Text(
                            'Posgrado',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FadeInRight(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: primaryBlue),
                          onPressed: () {
                            // Acción del menú
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Buscador
                FadeInUp(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar programa',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filtros
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      Expanded(child: _buildFilterSelector('Modalidad', 'TODOS')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildFilterSelector('Área', 'TODOS')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeInUp(
                    child: const Text(
                      'DIPLOMADOS SEDE CENTRAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tarjetas de programas
                  _buildProgramCard(
                    title: 'Diplomado en Administración de Servidores GNU/Linux',
                    responsable: 'GISLENE GABY VILLANUEVA VILLCA',
                    fechaLimite: '09-01-2026',
                    modalidad: 'Virtual',
                    imagePath: 'assets/images/banner_placeholder.png', // Placeholder para la imagen de la tarjeta
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildProgramCard(
                    title: 'Diplomado en Gestión de Proyectos de Software',
                    responsable: 'JUAN PEREZ GUTIERREZ',
                    fechaLimite: '15-02-2026',
                    modalidad: 'Presencial',
                    imagePath: 'assets/images/banner_placeholder.png',
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSelector(String label, String value) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            color: Color(0xFF337AB7),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black87, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildProgramCard({
    required String title,
    required String responsable,
    required String fechaLimite,
    required String modalidad,
    required String imagePath,
  }) {
    return FadeInUp(
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Imagen del banner
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 150,
                    width: double.infinity,
                    color: Colors.blueGrey[100],
                    child: const Icon(Icons.image, size: 50, color: Colors.blueGrey),
                    // Nota: En producción usarías una imagen real
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          const Text('Posgrado', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Responsable:', responsable),
                  const SizedBox(height: 8),
                  _buildInfoRow('Inscripcion hasta:', fechaLimite),
                  const SizedBox(height: 8),
                  _buildInfoRow('Modalidad:', modalidad),
                  const SizedBox(height: 20),
                  
                  // Botón Inscribirse
                  SizedBox(
                    width: 200,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () {
                        // Acción de inscripción
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2266B3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Inscribirse', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
