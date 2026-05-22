import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/debouncer.dart';
import 'package:refactor_template/core/utils/helper_validacion_inscripcion.dart';
import 'package:refactor_template/core/widgets/optimized_image.dart';
import 'package:refactor_template/core/widgets/optimized_fade_in.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/presentation/providers/programa_posgrado_provider.dart';
import 'package:refactor_template/core/widgets/skeleton_loader.dart';
import 'package:refactor_template/features/sistema/screens/contenedor/menu_lateral_scope.dart';
import 'package:url_launcher/url_launcher.dart';

class ProgramasVigentesScreen extends ConsumerStatefulWidget {
  static const name = 'programas-vigentes';

  const ProgramasVigentesScreen({super.key});

  @override
  ConsumerState<ProgramasVigentesScreen> createState() =>
      _ProgramasVigentesScreenState();
}

class _ProgramasVigentesScreenState
    extends ConsumerState<ProgramasVigentesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _vigentesScrollController = ScrollController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 80));

  String _selectedTipo = 'TODOS';
  String _selectedModalidad = 'TODOS';
  bool _showFilters = false; // Controla la visibilidad de los filtros
  bool _isHeaderCollapsed =
      false; // Controla si se oculta la cabecera al hacer scroll

  String _username = 'anon';
  bool _loadingUser = true;
  bool _seededEnrollment = false;
  Set<String> _enrolledProgramIds = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
    _vigentesScrollController.addListener(_onScrollChange);
  }

  @override
  void dispose() {
    _vigentesScrollController.removeListener(_onScrollChange);
    _vigentesScrollController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    super.dispose();
  }

  /// Oculta la cabecera (logo + buscador + filtros) cuando se ha
  /// desplazado lo suficiente hacia abajo y la vuelve a mostrar
  /// al regresar cerca del inicio.
  void _onScrollChange() {
    final offset = _vigentesScrollController.offset;
    // Umbrales mucho más sensibles: "Apenas baje un poco"
    const hideThreshold = 60.0;
    const showThreshold = 20.0;

    if (!_isHeaderCollapsed && offset > hideThreshold) {
      setState(() => _isHeaderCollapsed = true);
    } else if (_isHeaderCollapsed && offset < showThreshold) {
      setState(() => _isHeaderCollapsed = false);
    }
  }

  Future<void> _loadUser() async {
    final session = await LocalStorageService.getSessionData();
    if (!mounted) return;

    final nombreUsuario = (session?['nombreUsuario'] as String?)?.trim();
    setState(() {
      _username = (nombreUsuario != null && nombreUsuario.isNotEmpty)
          ? nombreUsuario
          : 'anon';
      _loadingUser = false;
    });
  }

  Future<void> _ensureEnrollmentSeed(List<ProgramaPosgrado> programas) async {
    if (_loadingUser || _seededEnrollment) return;

    final current = await LocalStorageService.getUserPrograms(_username);
    var enrolled = current;

    if (enrolled.isEmpty && _username != '12865214' && programas.isNotEmpty) {
      enrolled = {programas.first.id};
      await LocalStorageService.setUserPrograms(_username, enrolled);
    }

    if (!mounted) return;

    setState(() {
      _seededEnrollment = true;
      _enrolledProgramIds = enrolled;
    });
  }

  /// Muestra el bottom sheet de pasos y luego inicia el flujo de inscripción.
  Future<void> _onInscribirseTap(ProgramaPosgrado programa) async {
    if (_enrolledProgramIds.contains(programa.id)) {
      _showSnack('Ya estás inscrito en este programa.');
      return;
    }

    // Mostrar bottom sheet de pasos primero
    final continuar = await _mostrarPasosInscripcion(programa);
    if (!continuar || !mounted) return;

    final ok = await HelperValidacionInscripcion.validarYContinuar(
      context: context,
      tipoPrograma: programa.tipo,
      nombrePrograma: programa.titulo,
      idPrograma: programa.id,
      modalidad: programa.modalidad,
      onRequisitosCompletos: () => _doEnrollment(programa),
    );
    if (ok && mounted) {
      _showSnack('\u2705 Inscripción registrada. Revisa tus programas.');
    }
  }

  /// Muestra un bottom sheet con los pasos del proceso de inscripción.
  /// Retorna true si el usuario quiere continuar.
  Future<bool> _mostrarPasosInscripcion(ProgramaPosgrado programa) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PasosInscripcionSheet(programa: programa),
    );
    return result ?? false;
  }

  Future<void> _doEnrollment(ProgramaPosgrado programa) async {
    if (_enrolledProgramIds.contains(programa.id)) return;

    await LocalStorageService.addUserProgram(_username, programa.id);
    if (!mounted) return;

    setState(() {
      _enrolledProgramIds = {..._enrolledProgramIds, programa.id};
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A3A5C),
      ),
    );
  }

  List<ProgramaPosgrado> _filterProgramas(List<ProgramaPosgrado> programas) {
    final search = _normalizeValue(_searchController.text.trim());
    final selTipo = _normalizeValue(_selectedTipo);
    final selModalidad = _normalizeValue(_selectedModalidad);

    return programas.where((programa) {
      final estado = _normalizeValue(programa.estado);
      final vigente =
          estado.contains('INSCRIP') ||
          estado.contains('ABIERTAS') ||
          estado.contains('PUBLICADO');
      if (!vigente) return false;

      final tipo = _normalizeValue(programa.tipo);
      final modalidad = _normalizeValue(programa.modalidad);

      if (_selectedTipo != 'TODOS' && selTipo.isNotEmpty) {
        if (!tipo.contains(selTipo) && !selTipo.contains(tipo)) return false;
      }
      if (_selectedModalidad != 'TODOS' && selModalidad.isNotEmpty) {
        if (!modalidad.contains(selModalidad) &&
            !selModalidad.contains(modalidad)) {
          return false;
        }
      }
      if (search.isNotEmpty &&
          !_normalizeValue(programa.titulo).contains(search)) {
        return false;
      }
      return true;
    }).toList();
  }

  String _normalizeValue(String input) {
    return input
        .toUpperCase()
        .replaceAll('-', '')
        .replaceAll(' ', '')
        .replaceAll('\u00C1', 'A')
        .replaceAll('\u00C9', 'E')
        .replaceAll('\u00CD', 'I')
        .replaceAll('\u00D3', 'O')
        .replaceAll('\u00DA', 'U')
        .replaceAll('\u00DC', 'U')
        .replaceAll('\u00D1', 'N');
  }

  @override
  Widget build(BuildContext context) {
    // Colores alineados con la pantalla de programas para invitados
    const Color headerBlue = Color(0xFF005BAC);
    const Color headerBlueDark = Color(0xFF004A86);
    const Color background = Color(0xFFE9F2F9);

    final programasAsync = ref.watch(programasVigentesProvider);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,
              child: _isHeaderCollapsed
                  ? const SizedBox(width: double.infinity, height: 0)
                  : _buildHeader(headerBlue, headerBlueDark),
            ),
            Expanded(
              child: programasAsync.when(
                data: (programas) {
                  if (!_seededEnrollment && !_loadingUser) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _ensureEnrollmentSeed(programas);
                    });
                  }
                  final vigentes = _filterProgramas(programas);

                  final filtrosKey =
                      '$_selectedTipo|$_selectedModalidad|${_searchController.text.trim()}';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título de sección, centrado como en la vista de invitado
                      OptimizedFadeInDown(
                        from: 12,
                        duration: const Duration(milliseconds: 450),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: const Text(
                            'DIPLOMADOS SEDE CENTRAL',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      OptimizedFadeInUp(
                        delay: const Duration(milliseconds: 180),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.keyboard_double_arrow_down_rounded,
                                size: 18,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Desliza hacia abajo para ver más programas',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 350),
                          transitionBuilder: (child, animation) {
                            final offsetAnimation = Tween<Offset>(
                              begin: const Offset(0, 0.03),
                              end: Offset.zero,
                            ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offsetAnimation,
                                child: child,
                              ),
                            );
                          },
                          child: vigentes.isEmpty
                              ? KeyedSubtree(
                                  key: ValueKey('empty-$filtrosKey'),
                                  child: _buildEmptyState(),
                                )
                              : KeyedSubtree(
                                  key: ValueKey('list-$filtrosKey'),
                                  child: RefreshIndicator(
                                    onRefresh: () async {
                                      final scaffold = ScaffoldMessenger.of(
                                        context,
                                      );
                                      scaffold.showSnackBar(
                                        const SnackBar(
                                          content: Row(
                                            children: [
                                              SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                              SizedBox(width: 12),
                                              Text('Actualizando programas...'),
                                            ],
                                          ),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Color(0xFF1A3A5C),
                                        ),
                                      );
                                      ref.invalidate(programasVigentesProvider);
                                      await ref.read(
                                        programasVigentesProvider.future,
                                      );
                                      if (context.mounted) {
                                        scaffold.hideCurrentSnackBar();
                                        scaffold.showSnackBar(
                                          const SnackBar(
                                            content: Text('Lista actualizada'),
                                            duration: Duration(seconds: 1),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    },
                                    color: const Color(0xFF1A3A5C),
                                    child: Scrollbar(
                                      controller: _vigentesScrollController,
                                      thumbVisibility: true,
                                      radius: const Radius.circular(8),
                                      child: ListView.builder(
                                        controller: _vigentesScrollController,
                                        primary: false,
                                        padding: const EdgeInsets.fromLTRB(
                                          20,
                                          8,
                                          20,
                                          24,
                                        ),
                                        itemCount: vigentes.length + 1,
                                        itemBuilder: (context, index) {
                                          if (index < vigentes.length) {
                                            final programa = vigentes[index];
                                            final isEnrolled =
                                                _enrolledProgramIds.contains(
                                                  programa.id,
                                                );
                                            // Animación de entrada para cada tarjeta
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              child: OptimizedFadeInUp(
                                                from: 20,
                                                delay: Duration(
                                                  milliseconds: 40 * index,
                                                ),
                                                child: _ProgramaVigenteCard(
                                                  programa: programa,
                                                  isEnrolled: isEnrolled,
                                                  onEnroll: () =>
                                                      _onInscribirseTap(
                                                        programa,
                                                      ),
                                                ),
                                              ),
                                            );
                                          }
                                          // Último ítem: indicador de fin de lista
                                          return const _EndOfListIndicator();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                },
                error: (error, stack) => _buildErrorState(),
                loading: () => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  itemCount: 5,
                  itemBuilder: (_, _) => const ProgramaCardSkeleton(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color headerBlue, Color headerBlueDark) {
    final width = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final isSmall = width < 360;
    final chipLabelFont = isSmall ? 12.0 : 13.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 14 + topPadding, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerBlue, headerBlueDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: headerBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Posgrado + botón volver
          OptimizedFadeInDown(
            child: Row(
              children: [
                Icon(Icons.school_rounded, color: Colors.white, size: 34),
                const SizedBox(width: 12),
                const Text(
                  'Posgrado',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                const BotonMenuLateral(),
                const SizedBox(width: 4),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Búsqueda con botón de filtros
          OptimizedFadeInUp(
            duration: const Duration(milliseconds: 400),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) {
                      // Usar debounce para evitar rebuilds excesivos
                      _searchDebouncer(() {
                        setState(() {});
                      });
                    },
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Buscar programa',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                        size: 22,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón de filtros
                Material(
                  color: _showFilters ? const Color(0xFF305BA4) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _showFilters
                              ? const Color(0xFF305BA4)
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            color: _showFilters
                                ? Colors.white
                                : const Color(0xFF305BA4),
                            size: 24,
                          ),
                          if (_selectedTipo != 'TODOS' ||
                              _selectedModalidad != 'TODOS')
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(0xFF4CAF50),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Filtros desplegables (solo si _showFilters es true)
          if (_showFilters) ...[
            const SizedBox(height: 14),
            // Fila Modalidad
            OptimizedFadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Modalidad',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: chipLabelFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterChipSelector(
                      value: _selectedModalidad,
                      options: const [
                        'TODOS',
                        'VIRTUAL',
                        'PRESENCIAL',
                        'SEMI-PRESENCIAL',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedModalidad = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Fila Área
            OptimizedFadeInUp(
              duration: const Duration(milliseconds: 300),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Área',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: chipLabelFont,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterChipSelector(
                      value: _selectedTipo,
                      options: const [
                        'TODOS',
                        'DIPLOMADO',
                        'MAESTRIA',
                        'ESPECIALIDAD',
                        'DOCTORADO',
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTipo = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay programas vigentes con esos filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Prueba con otra busqueda o cambia los filtros.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar los programas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta nuevamente en unos minutos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChipSelector extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _FilterChipSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 360;
    final hPad = isSmall ? 4.0 : 6.0;
    final vPad = isSmall ? 1.5 : 3.0;
    final fontSize = isSmall ? 10.5 : 11.5;
    final iconSize = isSmall ? 13.0 : 15.0;
    final displayValue = options.contains(value)
        ? value
        : (options.isNotEmpty ? options.first : value);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: displayValue,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey.shade700,
            size: iconSize,
          ),
          // Cómo se ve el valor seleccionado en el cuadro blanco
          selectedItemBuilder: (context) {
            return options.map((option) {
              final isPlaceholder = option == 'TODOS';
              final label = isPlaceholder ? 'Seleccionar filtro' : option;
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isPlaceholder
                        ? Colors.grey.shade500.withOpacity(0.9)
                        : Colors.grey.shade800,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList();
          },
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(
                    option,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1A3A5C),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) {
              onChanged(next);
            }
          },
        ),
      ),
    );
  }
}

class _ProgramaVigenteCard extends StatelessWidget {
  final ProgramaPosgrado programa;
  final bool isEnrolled;
  final VoidCallback onEnroll;

  const _ProgramaVigenteCard({
    required this.programa,
    required this.isEnrolled,
    required this.onEnroll,
  });

  static const Color _headerBlue = Color(0xFF0D47A1);

  /// Título para mostrar: "[Tipo] en [Nombre del programa]" (ej. Maestría en Gestión Ambiental).
  static String _displayTitle(ProgramaPosgrado p) {
    final tipo = (p.tipo).trim();
    final nombre = (p.titulo).trim();
    if (nombre.isEmpty) return _capitalizeFirst(tipo);
    final tipoDisplay = _capitalizeFirst(tipo);
    final nombreDisplay = _toTitleCase(nombre);
    if (nombreDisplay.toLowerCase().startsWith(tipoDisplay.toLowerCase()) ||
        nombreDisplay.toLowerCase().startsWith(
          '${tipoDisplay.toLowerCase()} en ',
        )) {
      return nombreDisplay;
    }
    return '$tipoDisplay en $nombreDisplay';
  }

  static String _capitalizeFirst(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String _toTitleCase(String s) {
    if (s.isEmpty) return s;
    final words = s.split(RegExp(r'\s+'));
    return words
        .map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Extrae el número de celular desde el campo responsable (formato \"Nombre · 71234567\").
  static String? _extractPhone(String? responsable) {
    if (responsable == null) return null;
    final parts = responsable.split('·');
    if (parts.length < 2) return null;
    final raw = parts.last.trim();
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;
    return digits;
  }

  /// Extrae solo el nombre de la persona responsable (sin el celular).
  static String? _extractName(String? responsable) {
    if (responsable == null) return null;
    final parts = responsable.split('·');
    final name = parts.first.trim();
    return name.isEmpty ? null : name;
  }

  /// Abre un chat de WhatsApp con el número dado y mensaje prellenado.
  static Future<void> _openWhatsApp(
    BuildContext context,
    String phone,
    String programTitle,
  ) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Número de WhatsApp no válido.')),
      );
      return;
    }
    final message =
        '''
Hola, buen día.

Estoy interesado/a en la $programTitle de Posgrado UPEA.

¿Podrían brindarme más información sobre requisitos, fechas de inicio, costos y modalidad?

Mensaje enviado desde la app móvil de preinscripción.
''';
    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$digits?text=$encodedMessage');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir WhatsApp en este dispositivo.'),
        ),
      );
    }
  }

  /// Construye la URL completa de la imagen (portada) si la API devuelve ruta relativa.
  static String _fullImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = Environment.apiPreinscripcionUrl.replaceFirst(
      RegExp(r'/api/v1/?$'),
      '',
    );
    return base + (u.startsWith('/') ? u : '/$u');
  }

  @override
  Widget build(BuildContext context) {
    final primary = isEnrolled ? Colors.grey.shade400 : _headerBlue;
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = screenWidth < 360
        ? 150.0
        : (screenWidth > 600 ? 200.0 : 170.0);
    final imageUrl = _fullImageUrl(programa.urlFichaTecnica);
    final hasImage = imageUrl.isNotEmpty;
    final rawResponsable = programa.responsable;
    final responsableNombre = _extractName(rawResponsable);
    final telefono = _extractPhone(rawResponsable);
    final programTitle = _displayTitle(programa);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner de imagen (altura responsive según el ancho de pantalla)
          SizedBox(
            height: bannerHeight,
            width: double.infinity,
            child: hasImage
                ? OptimizedImage(
                    imageUrl: imageUrl,
                    width: double.infinity,
                    height: bannerHeight,
                    fit: BoxFit.contain,
                    placeholder: Container(
                      color: const Color(0xFFE8EEF7),
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        color: _headerBlue,
                        strokeWidth: 3,
                      ),
                    ),
                    errorWidget: _buildBannerPlaceholder(),
                  )
                : _buildBannerPlaceholder(),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    programTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Colors.grey.shade900,
                      height: 1.3,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Orden jerárquico: primero Modalidad, luego Responsable y al final Inscripción
                _InfoRow(label: 'Modalidad', value: programa.modalidad),
                const SizedBox(height: 5),
                if (responsableNombre != null) ...[
                  _InfoRow(label: 'Responsable', value: responsableNombre),
                  const SizedBox(height: 5),
                ],
                if (programa.inscripcionHasta != null &&
                    programa.inscripcionHasta!.trim().isNotEmpty) ...[
                  _InfoRow(
                    label: 'Inscripción hasta',
                    value: programa.inscripcionHasta!,
                  ),
                  const SizedBox(height: 5),
                ],
                if (telefono != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _openWhatsApp(context, telefono, programTitle),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                      label: Text(
                        'Contactarse: $telefono',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: isEnrolled ? null : onEnroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isEnrolled ? 'Ya inscrito' : 'Inscribirse',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

  Widget _buildBannerPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          // Badge "INSCRIPCIONES ABIERTAS" arriba a la izquierda
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'INSCRIPCIONES ABIERTAS',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          // Texto centrado
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Aprender es crecer cada día.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.95),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

/// Indicador visual de fin de la lista de programas.
class _EndOfListIndicator extends StatelessWidget {
  const _EndOfListIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 20,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 4),
          Text(
            'Has llegado al final de la oferta vigente',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet que muestra los pasos del proceso de inscripción.
class _PasosInscripcionSheet extends StatefulWidget {
  final ProgramaPosgrado programa;
  const _PasosInscripcionSheet({required this.programa});

  @override
  State<_PasosInscripcionSheet> createState() => _PasosInscripcionSheetState();
}

class _PasosInscripcionSheetState extends State<_PasosInscripcionSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static const _pasos = [
    _PasoData(
      icono: Icons.person_outline_rounded,
      titulo: 'Paso 1 · Datos personales',
      descripcion:
          'Asegúrate de tener tu nombre completo, CI y datos de contacto actualizados en tu perfil.',
      color: Color(0xFF1565C0),
    ),
    _PasoData(
      icono: Icons.folder_copy_outlined,
      titulo: 'Paso 2 · Documentos requeridos',
      descripcion:
          'Prepara tu título académico, hoja de vida y fotocopia de CI en formato PDF o imagen.',
      color: Color(0xFF6A1B9A),
    ),
    _PasoData(
      icono: Icons.description_outlined,
      titulo: 'Paso 3 · Carta de inscripción',
      descripcion:
          'La app generará automáticamente tu carta de solicitud de inscripción con tus datos.',
      color: Color(0xFF00695C),
    ),
    _PasoData(
      icono: Icons.receipt_long_outlined,
      titulo: 'Paso 4 · Comprobante de pago',
      descripcion:
          'Sube el comprobante de depósito bancario de matrícula y colegiatura para completar tu inscripción.',
      color: Color(0xFFE65100),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.programa.tipo.isNotEmpty
        ? widget.programa.tipo[0].toUpperCase() +
              widget.programa.tipo.substring(1).toLowerCase()
        : 'Programa';
    final nombre = widget.programa.titulo.isNotEmpty
        ? widget.programa.titulo
        : widget.programa.tipo;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF005BAC), Color(0xFF003F7A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          tipo.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Proceso de inscripción — 4 pasos',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Lista de pasos
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  ..._pasos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final paso = entry.value;
                    final delay = i * 0.15;
                    final animation = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        delay,
                        delay + 0.5,
                        curve: Curves.easeOut,
                      ),
                    );
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (_, child) => Opacity(
                        opacity: animation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - animation.value)),
                          child: child,
                        ),
                      ),
                      child: _PasoTile(paso: paso, index: i + 1),
                    );
                  }),
                  const SizedBox(height: 8),
                  // Nota informativa
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF005BAC).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFF005BAC),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'La app te guiará en cada paso. Puedes completar los requisitos en cualquier momento y volver a intentar la inscripción.',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12.5,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            // Botones
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: const Text(
                        'Iniciar inscripción',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005BAC),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
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
}

class _PasoData {
  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  const _PasoData({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
  });
}

class _PasoTile extends StatelessWidget {
  final _PasoData paso;
  final int index;
  const _PasoTile({required this.paso, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: paso.color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: paso.color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: paso.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(paso.icono, color: paso.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso.titulo,
                  style: TextStyle(
                    color: paso.color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  paso.descripcion,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12.5,
                    height: 1.4,
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



