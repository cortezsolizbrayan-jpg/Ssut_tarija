import 'dart:convert';

import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/features/sistema/screens/perfil/pantalla_firma.dart';

// ══════════════════════════════════════════════════════════════════════════════
// PANTALLA DE RECEPCIÓN - Para personal de atención al cliente
// Lista participantes inscritos y sus documentos desde la API de preinscripción
// ══════════════════════════════════════════════════════════════════════════════

class PantallaRecepcionParticipantes extends StatefulWidget {
  static const name = 'recepcion-participantes';
  const PantallaRecepcionParticipantes({super.key});

  @override
  State<PantallaRecepcionParticipantes> createState() =>
      _PantallaRecepcionParticipantesState();
}

class _PantallaRecepcionParticipantesState
    extends State<PantallaRecepcionParticipantes> {
  static const _blue = Color(0xFF005BAC);
  static const _bg = Color(0xFFEEF1F8);

  final TextEditingController _searchController = TextEditingController();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiPreinscripcionUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  List<Map<String, dynamic>> _participantes = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String? _error;
  String _filtroPrograma = 'TODOS';
  List<String> _programas = ['TODOS'];

  @override
  void initState() {
    super.initState();
    _cargarParticipantes();
    _searchController.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarParticipantes() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      // Endpoint: GET /inscripciones/ObtenerInscripcionPorId o listado general
      // Ajustar según lo que devuelva la API real
      final response = await _dio.get('/inscripciones');
      final data = response.data;

      List<Map<String, dynamic>> lista = [];
      if (data is List) {
        lista = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (data is Map && data['data'] is List) {
        lista = (data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      // Extraer programas únicos para el filtro
      final programasSet = <String>{'TODOS'};
      for (final p in lista) {
        final prog =
            p['programa']?.toString() ??
            p['nombrePrograma']?.toString() ??
            p['tipoPrograma']?.toString() ??
            '';
        if (prog.isNotEmpty) programasSet.add(prog.toUpperCase());
      }

      setState(() {
        _participantes = lista;
        _filtrados = lista;
        _programas = programasSet.toList();
        _cargando = false;
      });
    } on DioException catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error de conexión: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Error: $e';
      });
    }
  }

  void _filtrar() {
    final query = _searchController.text.trim().toUpperCase();
    setState(() {
      _filtrados = _participantes.where((p) {
        final nombre =
            '${p['nombre'] ?? ''} ${p['paterno'] ?? ''} ${p['materno'] ?? ''}'
                .toUpperCase();
        final ci = (p['ci'] ?? '').toString();
        final programa =
            (p['programa'] ?? p['nombrePrograma'] ?? p['tipoPrograma'] ?? '')
                .toString()
                .toUpperCase();

        final matchSearch =
            query.isEmpty ||
            nombre.contains(query) ||
            ci.contains(query) ||
            programa.contains(query);

        final matchPrograma =
            _filtroPrograma == 'TODOS' || programa.contains(_filtroPrograma);

        return matchSearch && matchPrograma;
      }).toList();
    });
  }

  void _verDetalle(Map<String, dynamic> participante) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _PantallaDetalleParticipante(participante: participante),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        title: const Text(
          'Recepción de Participantes',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargarParticipantes,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () {
              Navigator.of(
                context,
              ).pushReplacementNamed('/start-screen'); // O a login-recepcion
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda + filtro ──────────────────────────────
          Container(
            color: _blue,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Buscador
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, CI o programa...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF005BAC),
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _filtrar();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Filtro por programa
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _programas.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final prog = _programas[i];
                      final sel = _filtroPrograma == prog;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _filtroPrograma = prog);
                          _filtrar();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            prog,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: sel ? _blue : Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Contador ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Text(
                  '${_filtrados.length} participante${_filtrados.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),

          // ── Lista ────────────────────────────────────────────────────
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator(color: _blue))
                : _error != null
                ? _buildError()
                : _filtrados.isEmpty
                ? _buildVacio()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: _filtrados.length,
                    itemBuilder: (_, i) => FadeInUp(
                      delay: Duration(milliseconds: 30 * i),
                      duration: const Duration(milliseconds: 350),
                      child: _TarjetaParticipante(
                        participante: _filtrados[i],
                        onTap: () => _verDetalle(_filtrados[i]),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFlujoRapido(context),
        backgroundColor: const Color(0xFF005BAC),
        icon: const Icon(Icons.flash_on_rounded, color: Colors.white),
        label: const Text(
          'Recepción Rápida',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _mostrarFlujoRapido(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FlujoRecepcionRapida(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarParticipantes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No se encontraron participantes',
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta de participante ──────────────────────────────────────────────────

class _TarjetaParticipante extends StatelessWidget {
  final Map<String, dynamic> participante;
  final VoidCallback onTap;

  const _TarjetaParticipante({required this.participante, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre =
        '${participante['nombre'] ?? ''} ${participante['paterno'] ?? ''} ${participante['materno'] ?? ''}'
            .trim();
    final ci =
        participante['ci']?.toString() ??
        participante['numeroCI']?.toString() ??
        '—';
    final programa =
        participante['programa']?.toString() ??
        participante['nombrePrograma']?.toString() ??
        participante['tipoPrograma']?.toString() ??
        '—';
    final estado =
        participante['estado']?.toString() ??
        participante['estadoInscripcion']?.toString() ??
        '';
    final celular = participante['celular']?.toString() ?? '—';

    final esCompleto =
        estado.toUpperCase().contains('COMPLET') ||
        estado.toUpperCase().contains('APROBAD');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esCompleto
                ? const Color(0xFF4CAF50).withOpacity(0.3)
                : const Color(0xFF005BAC).withOpacity(0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Avatar inicial
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005BAC),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Datos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre.isEmpty ? 'Sin nombre' : nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A3A5C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.badge_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'CI: $ci',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          celular,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      programa,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF005BAC),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Estado badge
              if (estado.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: esCompleto
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    esCompleto ? 'Completo' : 'Pendiente',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: esCompleto
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pantalla de detalle del participante ─────────────────────────────────────

class _PantallaDetalleParticipante extends StatelessWidget {
  final Map<String, dynamic> participante;

  const _PantallaDetalleParticipante({required this.participante});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF005BAC);
    final nombre =
        '${participante['nombre'] ?? ''} ${participante['paterno'] ?? ''} ${participante['materno'] ?? ''}'
            .trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        title: Text(
          nombre.isEmpty ? 'Detalle Participante' : nombre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Datos personales ──
          _SeccionDetalle(
            titulo: 'Datos Personales',
            icono: Icons.person_rounded,
            campos: {
              'Nombre completo': nombre,
              'CI':
                  participante['ci']?.toString() ??
                  participante['numeroCI']?.toString() ??
                  '—',
              'Expedido en': participante['expedido']?.toString() ?? '—',
              'Celular': participante['celular']?.toString() ?? '—',
              'Correo': participante['correo']?.toString() ?? '—',
              'Dirección': participante['direccion']?.toString() ?? '—',
              'Ciudad': participante['ciudad']?.toString() ?? '—',
              'Fecha nacimiento':
                  participante['fechaNacimiento']?.toString() ?? '—',
              'Género': participante['genero']?.toString() ?? '—',
            },
          ),
          const SizedBox(height: 12),

          // ── Datos del programa ──
          _SeccionDetalle(
            titulo: 'Programa Inscrito',
            icono: Icons.school_rounded,
            campos: {
              'Programa':
                  participante['programa']?.toString() ??
                  participante['nombrePrograma']?.toString() ??
                  '—',
              'Tipo': participante['tipoPrograma']?.toString() ?? '—',
              'Modalidad': participante['modalidad']?.toString() ?? '—',
              'Estado':
                  participante['estado']?.toString() ??
                  participante['estadoInscripcion']?.toString() ??
                  '—',
              'Fecha inscripción':
                  participante['fechaInscripcion']?.toString() ?? '—',
              'N° Inscripción':
                  participante['numeroInscripcion']?.toString() ??
                  participante['id']?.toString() ??
                  '—',
            },
          ),
          const SizedBox(height: 12),

          // ── Facturación ──
          if (participante['facturacion'] != null ||
              participante['razonSocial'] != null ||
              participante['nit'] != null)
            _SeccionDetalle(
              titulo: 'Datos de Facturación',
              icono: Icons.receipt_long_rounded,
              campos: {
                'Razón Social':
                    participante['razonSocial']?.toString() ??
                    participante['facturacion']?['razonSocial']?.toString() ??
                    '—',
                'NIT':
                    participante['nit']?.toString() ??
                    participante['facturacion']?['nit']?.toString() ??
                    '—',
                'CI Facturación':
                    participante['ciFact']?.toString() ??
                    participante['facturacion']?['ci']?.toString() ??
                    '—',
              },
            ),
          const SizedBox(height: 12),

          // ── Documentos ──
          _SeccionDocumentos(participante: participante),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Sección de campos ────────────────────────────────────────────────────────

class _SeccionDetalle extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Map<String, String> campos;

  const _SeccionDetalle({
    required this.titulo,
    required this.icono,
    required this.campos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header sección
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF005BAC).withOpacity(0.06),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icono, size: 18, color: const Color(0xFF005BAC)),
                const SizedBox(width: 8),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF005BAC),
                  ),
                ),
              ],
            ),
          ),
          // Campos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              children: campos.entries
                  .where((e) => e.value != '—' && e.value.isNotEmpty)
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 130,
                            child: Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF333333),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección de documentos ────────────────────────────────────────────────────

class _SeccionDocumentos extends StatefulWidget {
  final Map<String, dynamic> participante;

  const _SeccionDocumentos({required this.participante});

  @override
  State<_SeccionDocumentos> createState() => _SeccionDocumentosState();
}

class _SeccionDocumentosState extends State<_SeccionDocumentos> {
  final Map<String, bool> _localUploaded = {};

  Future<void> _subirDocumento(String docName) async {
    final method = await showModalBottomSheet<String>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Gestionar $docName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005BAC),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
              ),
              title: const Text('Solo marcar como verificado (Físico)'),
              onTap: () => Navigator.pop(context, 'verify'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF005BAC),
              ),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF005BAC),
              ),
              title: const Text('Seleccionar de galería'),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_rounded,
                color: Color(0xFF005BAC),
              ),
              title: const Text('Seleccionar archivo (PDF/IMG)'),
              onTap: () => Navigator.pop(context, 'file'),
            ),
          ],
        ),
      ),
    );

    if (method == null) return;

    bool fileSelected = false;

    if (method == 'verify') {
      fileSelected = true;
    } else if (method == 'camera' || method == 'gallery') {
      try {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: method == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 80,
        );
        if (image != null) fileSelected = true;
      } catch (e) {
        debugPrint('Error pickImage: $e');
      }
    } else if (method == 'file') {
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        if (result != null) fileSelected = true;
      } catch (e) {
        debugPrint('Error pickFiles: $e');
      }
    }

    if (!fileSelected) return;

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          method == 'verify' ? 'Verificar Documento' : 'Documento seleccionado',
        ),
        content: Text(
          method == 'verify'
              ? '¿Desea marcar el documento $docName como entregado y verificado en físico?'
              : '¿Desea guardar el documento para $docName en el expediente del participante?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF005BAC),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: Icon(
              method == 'verify'
                  ? Icons.check_circle_rounded
                  : Icons.save_rounded,
              size: 18,
            ),
            label: Text(method == 'verify' ? 'Verificar' : 'Guardar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF005BAC)),
        ),
      );

      // Simulamos la subida a la API
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loader
      setState(() {
        _localUploaded[docName] = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $docName guardado exitosamente'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = <String, bool>{};
    final docData =
        widget.participante['documentos'] as Map? ??
        widget.participante['requisitos'] as Map? ??
        {};

    docs['C.I. Anverso'] = _tieneDoc(widget.participante, docData, [
      'ci_front',
      'ciAnverso',
      'ci_front_path',
    ]);
    docs['C.I. Reverso'] = _tieneDoc(widget.participante, docData, [
      'ci_back',
      'ciReverso',
      'ci_back_path',
    ]);
    docs['Fotocopia CI'] = _tieneDoc(widget.participante, docData, [
      'ci_photocopy',
      'fotocopiaCI',
      'ci_photocopy_pdf_path',
    ]);
    docs['Carta Inscripción'] = _tieneDoc(widget.participante, docData, [
      'carta_inscripcion',
      'cartaInscripcion',
    ]);
    docs['Ficha Inscripción'] = _tieneDoc(widget.participante, docData, [
      'ficha_inscripcion',
      'fichaInscripcion',
    ]);
    docs['Título / Prórroga'] = _tieneDoc(widget.participante, docData, [
      'titulo',
      'prorroga',
      'titulo_path',
      'prorroga_path',
    ]);
    docs['Hoja de Vida'] = _tieneDoc(widget.participante, docData, [
      'hoja_vida',
      'hojaVida',
      'cv',
    ]);
    docs['Comprobante Matrícula'] = _tieneDoc(widget.participante, docData, [
      'comprobante_matricula',
      'comprobanteMatricula',
    ]);
    docs['Comprobante Colegiatura'] = _tieneDoc(widget.participante, docData, [
      'comprobante_colegiatura',
      'comprobanteColegiatura',
    ]);

    int completados = 0;
    docs.forEach((key, value) {
      if (value || (_localUploaded[key] ?? false)) completados++;
    });

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF005BAC).withOpacity(0.06),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.folder_rounded,
                  size: 18,
                  color: Color(0xFF005BAC),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Documentos',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF005BAC),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: completados == docs.length
                        ? const Color(0xFF4CAF50).withOpacity(0.1)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completados/${docs.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: completados == docs.length
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFE65100),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: docs.entries.map((e) {
                final isUploaded = e.value || (_localUploaded[e.key] ?? false);
                return GestureDetector(
                  onTap: isUploaded ? null : () => _subirDocumento(e.key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isUploaded
                          ? const Color(0xFF4CAF50).withOpacity(0.08)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUploaded
                            ? const Color(0xFF4CAF50).withOpacity(0.3)
                            : const Color(0xFF005BAC).withOpacity(0.4),
                        width: 1.5,
                      ),
                      boxShadow: isUploaded
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF005BAC).withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUploaded
                              ? Icons.check_circle_rounded
                              : Icons.upload_rounded,
                          size: 16,
                          color: isUploaded
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF005BAC),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          e.key,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isUploaded
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF005BAC),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  bool _tieneDoc(Map<String, dynamic> p, Map docData, List<String> keys) {
    for (final k in keys) {
      if (p[k] != null && p[k].toString().isNotEmpty) return true;
      if (docData[k] != null && docData[k].toString().isNotEmpty) return true;
    }
    return false;
  }
}

// ── Flujo Rápido de Recepción ────────────────────────────────────────────────

class _FlujoRecepcionRapida extends StatefulWidget {
  const _FlujoRecepcionRapida();

  @override
  State<_FlujoRecepcionRapida> createState() => _FlujoRecepcionRapidaState();
}

class _FlujoRecepcionRapidaState extends State<_FlujoRecepcionRapida> {
  int _currentStep = 0;

  String? _nivelSeleccionado;
  final TextEditingController _ciController = TextEditingController();

  bool _buscando = false;
  Map<String, dynamic>? _participanteEncontrado;

  void _buscarParticipante() async {
    final ciBusqueda = _ciController.text.trim();
    if (ciBusqueda.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un número de CI'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _buscando = true);

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: Environment.apiPreinscripcionUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );

      // Buscar en el endpoint general
      final response = await dio.get('/inscripciones');
      final data = response.data;

      List<dynamic> lista = [];
      if (data is List) {
        lista = data;
      } else if (data is Map && data['data'] is List) {
        lista = data['data'];
      }

      // Filtrar por carnet (CI)
      final encontrado = lista.firstWhere(
        (p) =>
            p['ci']?.toString() == ciBusqueda ||
            p['numeroCI']?.toString() == ciBusqueda,
        orElse: () => null,
      );

      if (!mounted) return;

      setState(() {
        _buscando = false;
        if (encontrado != null) {
          _participanteEncontrado = Map<String, dynamic>.from(encontrado);
          _currentStep = 2;
        } else {
          // Si no existe, creamos un registro base con su CI
          _participanteEncontrado = {
            'nombre': 'Usuario',
            'paterno': 'Nuevo',
            'materno': '',
            'ci': ciBusqueda,
            'programa': '$_nivelSeleccionado (Registro Nuevo)',
            'documentos': {},
          };
          _currentStep = 2;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No encontrado en BD. Se habilitará pre-registro con este CI.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        // No cambiar de paso en caso de error, permanecer en búsqueda
        // _participanteEncontrado = null; // Opcional: limpiar resultado previo
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _ciController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFFEEF1F8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recepción Rápida',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005BAC),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stepper(
              type: StepperType.vertical,
              currentStep: _currentStep,
              onStepTapped: (step) {
                if (step < _currentStep) {
                  setState(() => _currentStep = step);
                }
              },
              onStepContinue: () async {
                if (_currentStep == 0) {
                  if (_nivelSeleccionado != null)
                    setState(() => _currentStep = 1);
                } else if (_currentStep == 1) {
                  _buscarParticipante();
                } else {
                  final firmaPath = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PantallaFirma()),
                  );
                  if (!mounted) return;
                  if (firmaPath != null) {
                    Navigator.pop(context); // Cierra el modal inferior
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '✅ Recepción completada exitosamente con firma',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep -= 1);
                } else {
                  Navigator.pop(context);
                }
              },
              controlsBuilder: (context, details) {
                if (_currentStep == 2) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: details.onStepContinue,
                      icon: const Icon(Icons.draw_rounded, size: 20),
                      label: const Text(
                        'Firmar y Finalizar',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        elevation: 4,
                        shadowColor: const Color(0xFF005BAC).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      if (_currentStep == 1)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _buscando ? null : _buscarParticipante,
                            icon: _buscando
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.search_rounded, size: 20),
                            label: Text(
                              _buscando ? 'Buscando...' : 'Buscar Participante',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005BAC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep == 0)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _nivelSeleccionado == null
                                ? null
                                : details.onStepContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005BAC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continuar',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text(
                    'Nivel Académico',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  content: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children:
                        [
                          'Diplomado',
                          'Maestría',
                          'Doctorado',
                          'Especialidad',
                        ].map((nivel) {
                          final isSelected = _nivelSeleccionado == nivel;
                          IconData getIcon(String n) {
                            if (n == 'Diplomado')
                              return Icons.workspace_premium;
                            if (n == 'Maestría') return Icons.emoji_events;
                            if (n == 'Doctorado') return Icons.school;
                            return Icons.star;
                          }

                          return GestureDetector(
                            onTap: () =>
                                setState(() => _nivelSeleccionado = nivel),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width:
                                  (MediaQuery.of(context).size.width - 92) / 2,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF005BAC),
                                          Color(0xFF004182),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : const LinearGradient(
                                        colors: [Colors.white, Colors.white],
                                      ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.transparent
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: const Color(
                                        0xFF005BAC,
                                      ).withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  else
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(
                                    getIcon(nivel),
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade400,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    nivel,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: isSelected
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text(
                    'Identificación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  content: Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _ciController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A3A5C),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Carnet de Identidad (CI)',
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF005BAC),
                        ),
                        hintText: 'Ej. 1234567',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: const Icon(
                          Icons.badge_rounded,
                          color: Color(0xFF005BAC),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: Color(0xFF005BAC),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                ),
                Step(
                  title: const Text(
                    'Requisitos / Documentos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  content: _participanteEncontrado == null
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Text(
                            'Por favor, busque un participante en el paso anterior.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE3F2FD),
                                    Color(0xFFBBDEFB),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withOpacity(0.2),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF005BAC),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      _participanteEncontrado!['nombre'][0]
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_participanteEncontrado!['nombre']} ${_participanteEncontrado!['paterno']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Color(0xFF1A3A5C),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _participanteEncontrado!['programa'],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF005BAC),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _SeccionDocumentos(
                              participante: _participanteEncontrado!,
                            ),
                          ],
                        ),
                  isActive: _currentStep >= 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
