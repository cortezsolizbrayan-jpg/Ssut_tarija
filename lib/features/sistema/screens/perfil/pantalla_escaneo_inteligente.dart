import 'dart:io';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/core/services/servicio_ocr_ia_avanzado.dart';

/// Pantalla de Escaneo Inteligente con IA
class PantallaEscaneoInteligente extends StatefulWidget {
  static const name = 'pantalla-escaneo-inteligente';
  
  final TipoDocumento? tipoEsperado;
  final Function(ResultadoOcrIA)? onResultado;

  const PantallaEscaneoInteligente({
    super.key,
    this.tipoEsperado,
    this.onResultado,
  });

  @override
  State<PantallaEscaneoInteligente> createState() =>
      _PantallaEscaneoInteligenteState();
}

class _PantallaEscaneoInteligenteState
    extends State<PantallaEscaneoInteligente> with SingleTickerProviderStateMixin {
  // --- Colores ---
  static const Color kPrimaryColor = Color(0xFF2563EB);
  static const Color kPrimaryDark = Color(0xFF1E3A8A);
  static const Color kSurfaceColor = Color(0xFFF8FAFC);
  static const Color kCardColor = Colors.white;
  static const Color kTextColor = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kSuccessColor = Color(0xFF10B981);
  static const Color kErrorColor = Color(0xFFEF4444);
  static const Color kWarningColor = Color(0xFFF59E0B);
  static const Color kInfoColor = Color(0xFF3B82F6);

  final ImagePicker _picker = ImagePicker();
  File? _imagenFrente;
  File? _imagenReverso;
  ResultadoOcrIA? _resultado;
  bool _procesando = false;
  bool _mostrarReverso = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto(bool esReverso) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: 2200,
      );

      if (foto == null) return;

      setState(() {
        if (esReverso) {
          _imagenReverso = File(foto.path);
        } else {
          _imagenFrente = File(foto.path);
        }
      });

      // Procesar automáticamente si tenemos la imagen del frente
      if (!esReverso) {
        await _procesarImagenes();
      }
    } catch (e) {
      _mostrarError('Error al tomar la foto: $e');
    }
  }

  Future<void> _seleccionarDeGaleria(bool esReverso) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 2200,
      );

      if (foto == null) return;

      setState(() {
        if (esReverso) {
          _imagenReverso = File(foto.path);
        } else {
          _imagenFrente = File(foto.path);
        }
      });

      // Procesar automáticamente
      if (!esReverso) {
        await _procesarImagenes();
      }
    } catch (e) {
      _mostrarError('Error al seleccionar la imagen: $e');
    }
  }

  Future<void> _procesarImagenes() async {
    if (_imagenFrente == null) {
      _mostrarError('Debes capturar al menos la imagen del frente');
      return;
    }

    setState(() {
      _procesando = true;
      _resultado = null;
    });

    _animationController.repeat();

    try {
      // Realizar OCR en las imágenes
      final textRecognizer = TextRecognizer();
      
      final inputImageFrente = InputImage.fromFile(_imagenFrente!);
      final textoFrente = await textRecognizer.processImage(inputImageFrente);

      RecognizedText? textoReverso;
      if (_imagenReverso != null) {
        final inputImageReverso = InputImage.fromFile(_imagenReverso!);
        textoReverso = await textRecognizer.processImage(inputImageReverso);
      }

      // Analizar con IA
      final resultado = await ServicioOcrIaAvanzado.analizarDocumento(
        textoOcr: textoFrente,
        textoOcrReverso: textoReverso,
        tipoEsperado: widget.tipoEsperado,
      );

      await textRecognizer.close();

      if (!mounted) return;

      setState(() {
        _resultado = resultado;
        _procesando = false;
      });

      _animationController.stop();
      _animationController.reset();

      // Notificar resultado si hay callback
      if (widget.onResultado != null) {
        widget.onResultado!(resultado);
      }

      // Mostrar resultado
      _mostrarResultado(resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() => _procesando = false);
      _animationController.stop();
      _mostrarError('Error al procesar: $e');
    }
  }

  void _mostrarResultado(ResultadoOcrIA resultado) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResultadoModal(resultado: resultado),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: kErrorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurfaceColor,
      appBar: AppBar(
        title: const Text(
          'Escaneo Inteligente',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: kSurfaceColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Instrucciones
              FadeInDown(
                child: _buildInstruccionesCard(),
              ),
              const SizedBox(height: 24),

              // Imagen Frente
              FadeInLeft(
                delay: const Duration(milliseconds: 200),
                child: _buildImagenCard(
                  titulo: 'Documento (Frente)',
                  imagen: _imagenFrente,
                  onCamara: () => _tomarFoto(false),
                  onGaleria: () => _seleccionarDeGaleria(false),
                  onEliminar: () => setState(() => _imagenFrente = null),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle para reverso
              FadeInRight(
                delay: const Duration(milliseconds: 300),
                child: SwitchListTile(
                  value: _mostrarReverso,
                  onChanged: (val) => setState(() => _mostrarReverso = val),
                  title: const Text(
                    '¿Tiene reverso?',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Activa si el documento tiene dos caras'),
                  activeColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: kCardColor,
                ),
              ),

              // Imagen Reverso
              if (_mostrarReverso) ...[
                const SizedBox(height: 16),
                FadeInLeft(
                  delay: const Duration(milliseconds: 400),
                  child: _buildImagenCard(
                    titulo: 'Documento (Reverso)',
                    imagen: _imagenReverso,
                    onCamara: () => _tomarFoto(true),
                    onGaleria: () => _seleccionarDeGaleria(true),
                    onEliminar: () => setState(() => _imagenReverso = null),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botón Procesar
              if (_imagenFrente != null && !_procesando)
                FadeInUp(
                  delay: const Duration(milliseconds: 500),
                  child: ElevatedButton(
                    onPressed: _procesarImagenes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 4,
                      shadowColor: kPrimaryColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.auto_awesome, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Procesar con IA',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Resultado previo
              if (_resultado != null) ...[
                const SizedBox(height: 24),
                FadeInUp(
                  child: _buildResumenResultado(_resultado!),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),

          // Overlay de procesamiento
          if (_procesando)
            Container(
              color: Colors.black54,
              child: Center(
                child: FadeIn(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: kCardColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RotationTransition(
                          turns: _animationController,
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 64,
                            color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Analizando con IA...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Extrayendo y organizando información',
                          style: TextStyle(
                            fontSize: 14,
                            color: kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstruccionesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor.withOpacity(0.1), kInfoColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kPrimaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, color: kPrimaryColor, size: 28),
              SizedBox(width: 12),
              Text(
                'Consejos para mejor escaneo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildConsejo('Asegúrate de tener buena iluminación'),
          _buildConsejo('Coloca el documento sobre una superficie plana'),
          _buildConsejo('Evita sombras y reflejos'),
          _buildConsejo('Captura todo el documento en el encuadre'),
        ],
      ),
    );
  }

  Widget _buildConsejo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: kSuccessColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagenCard({
    required String titulo,
    required File? imagen,
    required VoidCallback onCamara,
    required VoidCallback onGaleria,
    required VoidCallback onEliminar,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
          ),
          if (imagen != null)
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: Image.file(
                    imagen,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: onEliminar,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: kErrorColor,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ],
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: kSurfaceColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: kPrimaryColor.withOpacity(0.3),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 48,
                            color: kTextSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Sin imagen',
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCamara,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Cámara'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: kPrimaryColor),
                            foregroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onGaleria,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galería'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResumenResultado(ResultadoOcrIA resultado) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSuccessColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle, color: kSuccessColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Procesado Exitosamente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _mostrarResultado(resultado),
                child: const Text('Ver detalles'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Tipo',
            _getTipoDocumentoTexto(resultado.tipoDocumento),
          ),
          _buildInfoRow(
            'Confianza',
            '${(resultado.confianza * 100).toStringAsFixed(0)}%',
          ),
          _buildInfoRow(
            'Campos extraídos',
            '${resultado.campos.length}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: kTextSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kTextColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getTipoDocumentoTexto(TipoDocumento tipo) {
    switch (tipo) {
      case TipoDocumento.cedulaIdentidad:
        return 'Cédula de Identidad';
      case TipoDocumento.tituloAcademico:
        return 'Título Académico';
      case TipoDocumento.certificadoEstudios:
        return 'Certificado de Estudios';
      case TipoDocumento.certificadoNacimiento:
        return 'Certificado de Nacimiento';
      case TipoDocumento.cartaProrroga:
        return 'Carta de Prórroga';
      default:
        return 'Documento Genérico';
    }
  }
}

// ============================================================================
// MODAL DE RESULTADO
// ============================================================================

class _ResultadoModal extends StatelessWidget {
  final ResultadoOcrIA resultado;

  const _ResultadoModal({required this.resultado});

  static const Color kPrimaryColor = Color(0xFF2563EB);
  static const Color kSurfaceColor = Color(0xFFF8FAFC);
  static const Color kTextColor = Color(0xFF0F172A);
  static const Color kTextSecondary = Color(0xFF64748B);
  static const Color kSuccessColor = Color(0xFF10B981);
  static const Color kWarningColor = Color(0xFFF59E0B);
  static const Color kErrorColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kSuccessColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: kSuccessColor),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Resultado del Análisis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kTextColor,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Confianza
                _buildConfianzaCard(),
                const SizedBox(height: 16),

                // Campos extraídos
                _buildSeccionTitulo('Campos Extraídos'),
                const SizedBox(height: 12),
                ...resultado.campos.entries.map((entry) {
                  return _buildCampoCard(entry.key, entry.value);
                }).toList(),

                // Advertencias
                if (resultado.advertencias.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSeccionTitulo('Advertencias'),
                  const SizedBox(height: 12),
                  ...resultado.advertencias.map((adv) {
                    return _buildAdvertenciaCard(adv);
                  }).toList(),
                ],

                // Sugerencias
                if (resultado.sugerencias.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildSeccionTitulo('Sugerencias'),
                  const SizedBox(height: 12),
                  ...resultado.sugerencias.map((sug) {
                    return _buildSugerenciaCard(sug);
                  }).toList(),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aceptar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfianzaCard() {
    final confianzaPorcentaje = (resultado.confianza * 100).toInt();
    Color color = kSuccessColor;
    if (confianzaPorcentaje < 60) {
      color = kErrorColor;
    } else if (confianzaPorcentaje < 80) {
      color = kWarningColor;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$confianzaPorcentaje%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nivel de Confianza',
                  style: TextStyle(
                    fontSize: 14,
                    color: kTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getConfianzaTexto(confianzaPorcentaje),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo) {
    return Text(
      titulo.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: kTextSecondary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildCampoCard(String nombre, CampoExtraido campo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatearNombreCampo(nombre),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kTextSecondary,
                  ),
                ),
              ),
              if (campo.corregido)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kWarningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'CORREGIDO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: kWarningColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            campo.valor.isEmpty ? '(vacío)' : campo.valor,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: campo.valor.isEmpty ? kTextSecondary : kTextColor,
            ),
          ),
          if (campo.valorOriginal != null) ...[
            const SizedBox(height: 4),
            Text(
              'Original: ${campo.valorOriginal}',
              style: const TextStyle(
                fontSize: 12,
                color: kTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: campo.confianza,
            backgroundColor: const Color(0xFFE2E8F0),
            color: _getColorConfianza(campo.confianza),
            minHeight: 4,
          ),
          const SizedBox(height: 4),
          Text(
            'Confianza: ${(campo.confianza * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 11,
              color: kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertenciaCard(String advertencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWarningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kWarningColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: kWarningColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              advertencia,
              style: const TextStyle(
                fontSize: 13,
                color: kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSugerenciaCard(String sugerencia) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: kPrimaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sugerencia,
              style: const TextStyle(
                fontSize: 13,
                color: kTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatearNombreCampo(String nombre) {
    // Convertir camelCase o snake_case a texto legible
    final palabras = nombre
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .split(RegExp(r'[_\s]+'));
    
    return palabras
        .map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  String _getConfianzaTexto(int porcentaje) {
    if (porcentaje >= 80) return 'Excelente';
    if (porcentaje >= 60) return 'Bueno';
    if (porcentaje >= 40) return 'Regular';
    return 'Bajo';
  }

  Color _getColorConfianza(double confianza) {
    if (confianza >= 0.8) return kSuccessColor;
    if (confianza >= 0.6) return kWarningColor;
    return kErrorColor;
  }
}
