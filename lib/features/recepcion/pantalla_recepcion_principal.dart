import 'package:animate_do/animate_do.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/environment.dart';

/// Panel principal de recepción - exclusivo para personal de atención al cliente.
/// Lista participantes inscritos con sus documentos y datos de programa.
class PantallaRecepcionPrincipal extends StatefulWidget {
  final String nombreUsuario;
  const PantallaRecepcionPrincipal({super.key, required this.nombreUsuario});

  @override
  State<PantallaRecepcionPrincipal> createState() => _PantallaRecepcionPrincipalState();
}

class _PantallaRecepcionPrincipalState extends State<PantallaRecepcionPrincipal> {
  static const _blue = Color(0xFF005BAC);
  static const _bg = Color(0xFFEEF1F8);

  final TextEditingController _searchCtrl = TextEditingController();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Environment.apiPreinscripcionUrl,
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _filtrados = [];
  bool _cargando = true;
  String? _error;
  String _filtroPrograma = 'TODOS';
  List<String> _programas = ['TODOS'];

  int get _totalParticipantes => _filtrados.length;
  int get _completos => _filtrados.where((p) {
    final estado = (p['estado'] ?? p['estadoInscripcion'] ?? '').toString().toUpperCase();
    return estado.contains('COMPLET') || estado.contains('APROBAD');
  }).length;
  int get _pendientes => (_totalParticipantes - _completos).clamp(0, _totalParticipantes);

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      // Endpoint principal - ajustar según la API real de UPEA
      final response = await _dio.get('/inscripciones');
      final data = response.data;

      List<Map<String, dynamic>> lista = [];
      if (data is List) {
        lista = data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (data is Map && data['data'] is List) {
        lista = (data['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      } else if (data is Map && data['inscripciones'] is List) {
        lista = (data['inscripciones'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }

      final progsSet = <String>{'TODOS'};
      for (final p in lista) {
        final prog = _extraerPrograma(p);
        if (prog.isNotEmpty) progsSet.add(prog);
      }

      setState(() {
        _todos = lista;
        _filtrados = lista;
        _programas = progsSet.toList();
        _cargando = false;
      });
    } on DioException catch (e) {
      setState(() {
        _cargando = false;
        _error = 'Sin conexión al servidor.\n${e.message}';
      });
    } catch (e) {
      setState(() { _cargando = false; _error = 'Error: $e'; });
    }
  }

  String _extraerPrograma(Map<String, dynamic> p) =>
      (p['programa'] ?? p['nombrePrograma'] ?? p['tipoPrograma'] ?? '').toString().toUpperCase();

  String _extraerNombre(Map<String, dynamic> p) =>
      '${p['nombre'] ?? ''} ${p['paterno'] ?? ''} ${p['materno'] ?? ''}'.trim();

  void _filtrar() {
    final q = _searchCtrl.text.trim().toUpperCase();
    setState(() {
      _filtrados = _todos.where((p) {
        final nombre = _extraerNombre(p).toUpperCase();
        final ci = (p['ci'] ?? p['numeroCI'] ?? '').toString();
        final prog = _extraerPrograma(p);
        final matchQ = q.isEmpty || nombre.contains(q) || ci.contains(q) || prog.contains(q);
        final matchProg = _filtroPrograma == 'TODOS' || prog.contains(_filtroPrograma);
        return matchQ && matchProg;
      }).toList();
    });
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Deseas salir del panel de recepción?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.of(context).pop(); // Volver al login de recepción
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;
    final hPad = isSmall ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Panel de Recepción',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Hola, ${widget.nombreUsuario}',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Buscador + filtros ──────────────────────────────────────
          Container(
            color: _blue,
            padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 12),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, CI o programa...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Icon(Icons.search, color: _blue),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchCtrl.clear(); _filtrar(); })
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                if (_programas.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _programas.length,
                      separatorBuilder: (_, itemIndex) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final prog = _programas[i];
                        final sel = _filtroPrograma == prog;
                        return GestureDetector(
                          onTap: () { setState(() => _filtroPrograma = prog); _filtrar(); },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: sel ? Colors.white : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: sel ? Colors.white : Colors.white.withOpacity(0.4)),
                            ),
                            child: Text(prog,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                                color: sel ? _blue : Colors.white)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Resumen rápido ──────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoBadge(
                  label: 'Total',
                  value: _totalParticipantes.toString(),
                  color: const Color(0xFF005BAC),
                ),
                _InfoBadge(
                  label: 'Completos',
                  value: _completos.toString(),
                  color: const Color(0xFF2E7D32),
                ),
                _InfoBadge(
                  label: 'Pendientes',
                  value: _pendientes.toString(),
                  color: const Color(0xFFE65100),
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
                        : RefreshIndicator(
                            color: _blue,
                            onRefresh: _cargar,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 24),
                              itemCount: _filtrados.length,
                              itemBuilder: (_, i) => FadeInUp(
                                delay: Duration(milliseconds: 20 * i),
                                duration: const Duration(milliseconds: 260),
                                child: _TarjetaParticipante(
                                  participante: _filtrados[i],
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => _DetalleParticipante(participante: _filtrados[i]),
                                  )),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _cargar,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
          ),
        ],
      ),
    ),
  );

  Widget _buildVacio() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.people_outline, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No se encontraron participantes', style: TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    ),
  );
}

// ── Tarjeta participante ─────────────────────────────────────────────────────

class _TarjetaParticipante extends StatelessWidget {
  final Map<String, dynamic> participante;
  final VoidCallback onTap;
  const _TarjetaParticipante({required this.participante, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nombre = '${participante['nombre'] ?? ''} ${participante['paterno'] ?? ''} ${participante['materno'] ?? ''}'.trim();
    final ci = participante['ci']?.toString() ?? participante['numeroCI']?.toString() ?? '—';
    final programa = (participante['programa'] ?? participante['nombrePrograma'] ?? participante['tipoPrograma'] ?? '—').toString();
    final estado = (participante['estado'] ?? participante['estadoInscripcion'] ?? '').toString();
    final celular = participante['celular']?.toString() ?? '—';
    final esCompleto = estado.toUpperCase().contains('COMPLET') || estado.toUpperCase().contains('APROBAD');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: esCompleto
              ? const Color(0xFF4CAF50).withOpacity(0.25)
              : const Color(0xFF005BAC).withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF005BAC).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF005BAC)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nombre.isEmpty ? 'Sin nombre' : nombre,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A3A5C)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _MiniData(icon: Icons.badge_outlined, text: 'CI: $ci'),
                        _MiniData(icon: Icons.phone_outlined, text: celular),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005BAC).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(programa,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF005BAC), fontWeight: FontWeight.w700),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
              if (estado.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: esCompleto ? const Color(0xFF4CAF50).withOpacity(0.1) : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    esCompleto ? 'Completo' : 'Pendiente',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                      color: esCompleto ? const Color(0xFF4CAF50) : const Color(0xFFE65100)),
                  ),
                ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniData extends StatelessWidget {
  final IconData icon;
  final String text;
  const _MiniData({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: Colors.grey),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

// ── Detalle participante ─────────────────────────────────────────────────────

class _DetalleParticipante extends StatelessWidget {
  final Map<String, dynamic> participante;
  const _DetalleParticipante({required this.participante});

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF005BAC);
    final nombre = '${participante['nombre'] ?? ''} ${participante['paterno'] ?? ''} ${participante['materno'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1F8),
      appBar: AppBar(
        backgroundColor: blue,
        elevation: 0,
        title: Text(nombre.isEmpty ? 'Detalle' : nombre,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Seccion(titulo: 'Datos Personales', icono: Icons.person_rounded, campos: {
            'Nombre': nombre,
            'CI': participante['ci']?.toString() ?? participante['numeroCI']?.toString() ?? '—',
            'Expedido': participante['expedido']?.toString() ?? '—',
            'Celular': participante['celular']?.toString() ?? '—',
            'Correo': participante['correo']?.toString() ?? '—',
            'Dirección': participante['direccion']?.toString() ?? '—',
            'Ciudad': participante['ciudad']?.toString() ?? '—',
            'Fecha Nac.': participante['fechaNacimiento']?.toString() ?? '—',
            'Género': participante['genero']?.toString() ?? '—',
          }),
          const SizedBox(height: 12),
          _Seccion(titulo: 'Programa', icono: Icons.school_rounded, campos: {
            'Programa': (participante['programa'] ?? participante['nombrePrograma'] ?? '—').toString(),
            'Tipo': participante['tipoPrograma']?.toString() ?? '—',
            'Modalidad': participante['modalidad']?.toString() ?? '—',
            'Estado': (participante['estado'] ?? participante['estadoInscripcion'] ?? '—').toString(),
            'Fecha Inscripción': participante['fechaInscripcion']?.toString() ?? '—',
            'N° Inscripción': (participante['numeroInscripcion'] ?? participante['id'] ?? '—').toString(),
          }),
          const SizedBox(height: 12),
          _SeccionDocumentos(participante: participante),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Map<String, String> campos;
  const _Seccion({required this.titulo, required this.icono, required this.campos});

  @override
  Widget build(BuildContext context) {
    final visibles = campos.entries.where((e) => e.value != '—' && e.value.isNotEmpty).toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF005BAC).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              Icon(icono, size: 16, color: const Color(0xFF005BAC)),
              const SizedBox(width: 8),
              Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF005BAC))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: visibles.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 120, child: Text(e.key,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF666666), fontWeight: FontWeight.w600))),
                  Expanded(child: Text(e.value,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF333333), fontWeight: FontWeight.w500))),
                ]),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionDocumentos extends StatelessWidget {
  final Map<String, dynamic> participante;
  const _SeccionDocumentos({required this.participante});

  bool _tiene(List<String> keys) {
    final docData = participante['documentos'] as Map? ?? participante['requisitos'] as Map? ?? {};
    for (final k in keys) {
      if (participante[k] != null && participante[k].toString().isNotEmpty) return true;
      if (docData[k] != null && docData[k].toString().isNotEmpty) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final docs = <String, bool>{
      'C.I. Anverso': _tiene(['ci_front', 'ciAnverso', 'ci_front_path']),
      'C.I. Reverso': _tiene(['ci_back', 'ciReverso', 'ci_back_path']),
      'Fotocopia CI': _tiene(['ci_photocopy', 'fotocopiaCI']),
      'Carta Inscripción': _tiene(['carta_inscripcion', 'cartaInscripcion']),
      'Ficha Inscripción': _tiene(['ficha_inscripcion', 'fichaInscripcion']),
      'Título / Prórroga': _tiene(['titulo', 'prorroga', 'titulo_path']),
      'Hoja de Vida': _tiene(['hoja_vida', 'hojaVida', 'cv']),
      'Comprobante Matrícula': _tiene(['comprobante_matricula', 'comprobanteMatricula']),
      'Comprobante Colegiatura': _tiene(['comprobante_colegiatura', 'comprobanteColegiatura']),
    };
    final completados = docs.values.where((v) => v).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF005BAC).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(children: [
              const Icon(Icons.folder_rounded, size: 16, color: Color(0xFF005BAC)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Documentos',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF005BAC)))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: completados == docs.length
                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                      : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$completados/${docs.length}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                    color: completados == docs.length ? const Color(0xFF4CAF50) : const Color(0xFFE65100))),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Wrap(
              spacing: 8, runSpacing: 8,
              children: docs.entries.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: e.value ? const Color(0xFF4CAF50).withOpacity(0.08) : Colors.grey.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: e.value
                      ? const Color(0xFF4CAF50).withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(e.value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 13, color: e.value ? const Color(0xFF4CAF50) : Colors.grey),
                  const SizedBox(width: 5),
                  Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: e.value ? const Color(0xFF2E7D32) : Colors.grey)),
                ]),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


