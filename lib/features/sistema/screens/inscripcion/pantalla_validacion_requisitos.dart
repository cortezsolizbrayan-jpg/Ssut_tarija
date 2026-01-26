import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:refactor_template/core/services/servicio_validacion_requisitos.dart';
import 'package:refactor_template/features/sistema/domain/entities/requisito_inscripcion.dart';
import 'package:refactor_template/features/sistema/screens/perfil/mis_documentos_personales_screen.dart';

/// Pantalla para validar requisitos de inscripción antes de permitir inscribirse
class PantallaValidacionRequisitos extends StatefulWidget {
  final String tipoPrograma;
  final String nombrePrograma;
  final VoidCallback? onRequisitosCompletos;

  const PantallaValidacionRequisitos({
    super.key,
    required this.tipoPrograma,
    required this.nombrePrograma,
    this.onRequisitosCompletos,
  });

  @override
  State<PantallaValidacionRequisitos> createState() =>
      _PantallaValidacionRequisitosState();
}

class _PantallaValidacionRequisitosState
    extends State<PantallaValidacionRequisitos> {
  final _servicioValidacion = ServicioValidacionRequisitos();
  ResultadoValidacionInscripcion? _resultado;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _validarRequisitos();
  }

  Future<void> _validarRequisitos() async {
    setState(() => _cargando = true);

    try {
      final resultado = await _servicioValidacion.validarRequisitos(
        tipoPrograma: widget.tipoPrograma,
      );

      setState(() {
        _resultado = resultado;
        _cargando = false;
      });

      // Si todos los requisitos están completos, ejecutar callback
      if (resultado.todosLosRequisitosObligatoriosCumplidos) {
        widget.onRequisitosCompletos?.call();
      }
    } catch (e) {
      setState(() => _cargando = false);
      _mostrarError('Error al validar requisitos: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _irADocumentosPersonales() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MisDocumentosPersonalesScreen(),
      ),
    );

    // Revalidar al volver
    if (resultado == true || mounted) {
      _validarRequisitos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Validación de Requisitos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _cargando
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00D9FF)),
              ),
            )
          : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    if (_resultado == null) {
      return const Center(
        child: Text(
          'No se pudo cargar la información',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    final todosCompletos = _resultado!.todosLosRequisitosObligatoriosCumplidos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del programa
          FadeInDown(
            child: _buildEncabezadoPrograma(),
          ),

          const SizedBox(height: 30),

          // Tarjeta de progreso
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: _buildTarjetaProgreso(),
          ),

          const SizedBox(height: 30),

          // Lista de requisitos
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: _buildListaRequisitos(),
          ),

          const SizedBox(height: 30),

          // Botones de acción
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            child: _buildBotonesAccion(todosCompletos),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEncabezadoPrograma() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D9FF), Color(0xFF7B2FF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D9FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.tipoPrograma.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.nombrePrograma,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Verificación de Requisitos de Inscripción',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarjetaProgreso() {
    final porcentaje = _resultado!.porcentajeCompletitudObligatorios;
    final completados = _resultado!.resultados
        .where((r) => r.requisito.esObligatorio && r.estaCumplido)
        .length;
    final total = _resultado!.resultados
        .where((r) => r.requisito.esObligatorio)
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de Requisitos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completados/$total',
                style: const TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje / 100,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                porcentaje == 100
                    ? Colors.green
                    : const Color(0xFF00D9FF),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${porcentaje.toStringAsFixed(0)}% Completado',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaRequisitos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requisitos Obligatorios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ..._resultado!.resultados
            .where((r) => r.requisito.esObligatorio)
            .map((resultado) => _buildRequisitoItem(resultado))
            .toList(),
      ],
    );
  }

  Widget _buildRequisitoItem(ResultadoValidacionRequisito resultado) {
    final icono = _getIconoEstado(resultado.estado);
    final color = _getColorEstado(resultado.estado);
    final textoEstado = _getTextoEstado(resultado.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1E33),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icono,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTituloRequisito(resultado.requisito),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      resultado.requisito.descripcion,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                    if (resultado.mensaje != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          resultado.mensaje!,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  textoEstado,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTituloRequisito(RequisitoInscripcion requisito) {
    switch (requisito.id) {
      case 'pago_matricula':
        return 'Comprobantes de Pago';
      case 'fotografias':
        return 'Fotografías';
      case 'formularios':
        return 'Formularios de Inscripción';
      case 'ci_fotocopias':
        return 'Fotocopia de CI';
      case 'titulo_academico':
        return 'Título Académico';
      case 'carta_inscripcion':
        return 'Carta de Inscripción';
      case 'hoja_vida':
        return 'Hoja de Vida';
      default:
        return 'Requisito';
    }
  }

  IconData _getIconoEstado(EstadoRequisito estado) {
    switch (estado) {
      case EstadoRequisito.completado:
        return Icons.check_circle;
      case EstadoRequisito.conProrroga:
        return Icons.schedule;
      case EstadoRequisito.pendiente:
        return Icons.warning;
      case EstadoRequisito.noAplica:
        return Icons.remove_circle_outline;
    }
  }

  Color _getColorEstado(EstadoRequisito estado) {
    switch (estado) {
      case EstadoRequisito.completado:
        return Colors.green;
      case EstadoRequisito.conProrroga:
        return Colors.orange;
      case EstadoRequisito.pendiente:
        return Colors.red;
      case EstadoRequisito.noAplica:
        return Colors.grey;
    }
  }

  String _getTextoEstado(EstadoRequisito estado) {
    switch (estado) {
      case EstadoRequisito.completado:
        return 'Completo';
      case EstadoRequisito.conProrroga:
        return 'Prórroga';
      case EstadoRequisito.pendiente:
        return 'Pendiente';
      case EstadoRequisito.noAplica:
        return 'N/A';
    }
  }

  Widget _buildBotonesAccion(bool todosCompletos) {
    return Column(
      children: [
        if (!todosCompletos) ...[
          // Botón para ir a documentos personales
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _irADocumentosPersonales,
              icon: const Icon(Icons.folder_open, color: Colors.white),
              label: const Text(
                'Completar Documentos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Botón para continuar (solo si todos están completos)
        if (todosCompletos)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
                widget.onRequisitosCompletos?.call();
              },
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Continuar con Inscripción',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
            ),
          ),

        // Botón para actualizar
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _validarRequisitos,
            icon: const Icon(Icons.refresh, color: Color(0xFF00D9FF)),
            label: const Text(
              'Actualizar Estado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D9FF),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00D9FF), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
