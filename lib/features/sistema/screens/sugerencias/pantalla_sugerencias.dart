import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:refactor_template/core/services/otros/servicio_sugerencias.dart';
import 'package:refactor_template/core/widgets/ios_dialogs.dart';

class PantallaSugerencias extends StatefulWidget {
  static const name = '/sugerencias';
  const PantallaSugerencias({super.key});

  @override
  State<PantallaSugerencias> createState() => _PantallaSugerenciasState();
}

class _PantallaSugerenciasState extends State<PantallaSugerencias> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedCategory = 'Mejora de App';
  bool _isLocaltionBusy = false;

  final List<String> _categories = [
    'Mejora de App',
    'Error (Bug)',
    'Nueva Función',
    'OCR',
    'Otro',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _enviarSugerencia() async {
    final comentario = _feedbackController.text.trim();
    if (comentario.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe tu sugerencia')),
      );
      return;
    }

    setState(() => _isLocaltionBusy = true);

    try {
      final success = await ServicioSugerencias().enviarSugerencia(
        categoria: _selectedCategory,
        comentario: comentario,
      );

      if (!mounted) return;

      setState(() => _isLocaltionBusy = false);

      if (success) {
        HapticFeedback.mediumImpact();
        showIosAlert(
          context: context,
          title: '¡Gracias!',
          message:
              'Tu sugerencia nos ayuda a mejorar el servicio para todos los posgraduantes.',
          defaultButtonText: 'ACEPTAR',
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        ).then((_) {
          if (mounted) Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al enviar sugerencia. Intenta más tarde.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLocaltionBusy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error inesperado: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Buzón de Sugerencias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF005BAC),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              child: const Text(
                '¿Cómo podemos mejorar?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInDown(
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Tu opinión es fundamental para nosotros. Cuéntanos qué te gustaría ver o qué podemos optimizar.',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 32),

            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: const Text(
                'CATEGORÍA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Color(0xFF005BAC),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 80),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedCategory = cat);
                    },
                    selectedColor: Color(0xFF005BAC).withOpacity(0.1),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF001F3F)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: const Text(
                'TU COMENTARIO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Color(0xFF005BAC),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: 'Describe tu sugerencia o problema aquí...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    contentPadding: const EdgeInsets.all(20),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLocaltionBusy ? null : _enviarSugerencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005BAC),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLocaltionBusy
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'ENVIAR SUGERENCIA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}


