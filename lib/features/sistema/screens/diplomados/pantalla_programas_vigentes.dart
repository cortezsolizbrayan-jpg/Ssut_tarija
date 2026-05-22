import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/utils/debouncer.dart';
import 'package:refactor_template/core/utils/helper_validacion_inscripcion.dart';
import 'package:refactor_template/core/widgets/optimized_image.dart';
import 'package:refactor_template/core/widgets/optimized_fade_in.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/presentation/providers/programa_posgrado_provider.dart';
import 'package:refactor_template/core/widgets/skeleton_loader.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/features/sistema/widgets/inscripcion/pasos_inscripcion_sheet.dart';

class ProgramasVigentesPantalla extends ConsumerStatefulWidget {
  static const name = 'programas-vigentes';

  final bool isGuestMode;
  final VoidCallback? onInscriptionAttempt;

  const ProgramasVigentesPantalla({
    super.key,
    this.isGuestMode = false,
    this.onInscriptionAttempt,
  });

  @override
  ConsumerState<ProgramasVigentesPantalla> createState() =>
      _ProgramasVigentesPantallaState();
}

class _ProgramasVigentesPantallaState
    extends ConsumerState<ProgramasVigentesPantalla>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _vigentesScrollController = ScrollController();
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 80));

  String _selectedTipo = 'TODOS';
  String _selectedModalidad = 'TODOS';
  bool _showFilters = false;

  // ValueNotifiers para scroll — evitan setState que reconstruye todo el árbol
  final ValueNotifier<bool> _headerCollapsed = ValueNotifier(false);
  final ValueNotifier<bool> _showScrollHint = ValueNotifier(true);

  bool _showTutorial = false;
  int _tutorialStep = 0;

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
    _headerCollapsed.dispose();
    _showScrollHint.dispose();
    super.dispose();
  }

  void _onScrollChange() {
    final offset = _vigentesScrollController.offset;
    const hideThreshold = 60.0;
    const showThreshold = 20.0;
    const hideHintThreshold = 90.0;
    const showHintThreshold = 16.0;

    // ValueNotifier — no dispara setState, solo reconstruye los widgets que escuchan
    if (!_headerCollapsed.value && offset > hideThreshold) {
      _headerCollapsed.value = true;
    } else if (_headerCollapsed.value && offset < showThreshold) {
      _headerCollapsed.value = false;
    }

    if (_showScrollHint.value && offset > hideHintThreshold) {
      _showScrollHint.value = false;
    } else if (!_showScrollHint.value && offset < showHintThreshold) {
      _showScrollHint.value = true;
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

    final sawTutorial = await LocalStorageService.hasSeenVigentesTutorial();
    if (!sawTutorial && mounted) {
      setState(() {
        _showTutorial = true;
        _tutorialStep = 0;
      });
    }
  }

  Future<void> _ensureEnrollmentSeed(List<ProgramaPosgrado> programas) async {
    if (_loadingUser || _seededEnrollment) return;

    final current = await LocalStorageService.getUserPrograms(_username);

    if (!mounted) return;

    setState(() {
      _seededEnrollment = true;
      _enrolledProgramIds = current;
    });
  }

  Future<void> _onInscribirseTap(ProgramaPosgrado programa) async {
    if (widget.isGuestMode) {
      widget.onInscriptionAttempt?.call();
      return;
    }

    if (_enrolledProgramIds.contains(programa.id)) {
      _showSnack('Revisando estado de tu inscripciÃ³n...');
    }

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
      _showSnack('\u2705 InscripciÃ³n registrada. Revisa tus programas.');
    }
  }

  Future<bool> _mostrarPasosInscripcion(ProgramaPosgrado programa) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PasosInscripcionSheet(programa: programa),
    );
    return result ?? false;
  }

  void _iniciarTutorialGuiado() {
    setState(() {
      _showTutorial = true;
      _tutorialStep = 0;
    });
  }

  void _cerrarTutorialGuiado() {
    setState(() => _showTutorial = false);
    LocalStorageService.saveVigentesTutorialSeen();
  }

  static const List<Map<String, dynamic>> _tutorialSteps = [
    {
      'icon': Icons.search_rounded,
      'title': 'Paso 1: Busca tu programa',
      'desc':
          'Escribe palabras como "maestria", "diplomado" o el nombre del area en el buscador.',
      'hint': 'Zona: barra "Buscar programa".',
    },
    {
      'icon': Icons.tune_rounded,
      'title': 'Paso 2: Aplica filtros',
      'desc':
          'Pulsa "Filtros" para elegir tipo y modalidad (virtual, presencial o semipresencial).',
      'hint': 'Zona: boton "Filtros".',
    },
    {
      'icon': Icons.view_agenda_rounded,
      'title': 'Paso 3: Revisa la tarjeta',
      'desc':
          'Verifica fechas, modalidad, responsable y estado de inscripciones abiertas.',
      'hint': 'Zona: tarjeta del programa.',
    },
    {
      'icon': Icons.how_to_reg_rounded,
      'title': 'Paso 4: Toca Inscribirme',
      'desc':
          'Se abrira la guia de requisitos del programa seleccionado para continuar el proceso.',
      'hint': 'Zona: boton de inscripcion del programa.',
    },
    {
      'icon': Icons.description_rounded,
      'title': 'Paso 5: Completa documentos',
      'desc':
          'Genera carta/ficha, sube titulo o prorroga y adjunta comprobantes de pago.',
      'hint': 'Zona: pantalla de validacion de requisitos.',
    },
    {
      'icon': Icons.verified_rounded,
      'title': 'Paso 6: Confirma tu inscripcion',
      'desc':
          'Cuando todo este completo, confirma y revisa el estado final en Mis Programas.',
      'hint': 'Resultado: inscripcion completada.',
    },
  ];

  void _avanzarTutorial() {
    if (_tutorialStep >= _tutorialSteps.length - 1) {
      _cerrarTutorialGuiado();
      return;
    }
    setState(() => _tutorialStep++);
  }

  void _retrocederTutorial() {
    if (_tutorialStep <= 0) return;
    setState(() => _tutorialStep--);
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
        backgroundColor: const Color(0xFF005BAC),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  List<ProgramaPosgrado> _filterProgramas(List<ProgramaPosgrado> programas) {
    final rawSearch = _searchController.text.trim();
    final search = _normalizeValue(rawSearch);
    final selTipo = _normalizeValue(_selectedTipo);
    final selModalidad = _normalizeValue(_selectedModalidad);

    String intelTipo = '';
    if (search.contains('DIPLOMADO')) {
      intelTipo = 'DIPLOMADO';
    } else if (search.contains('MAESTRIA'))
      intelTipo = 'MAESTRIA';
    else if (search.contains('ESPECIALIDAD'))
      intelTipo = 'ESPECIALIDAD';
    else if (search.contains('DOCTORADO'))
      intelTipo = 'DOCTORADO';

    String intelModalidad = '';
    if (search.contains('VIRTUAL')) {
      intelModalidad = 'VIRTUAL';
    } else if (search.contains('PRESENCIAL') &&
        !search.contains('SEMIPRESENCIAL'))
      intelModalidad = 'PRESENCIAL';
    else if (search.contains('SEMIPRESENCIAL'))
      intelModalidad = 'SEMIPRESENCIAL';

    String pureSearch = search
        .replaceAll('DIPLOMADO', '')
        .replaceAll('MAESTRIA', '')
        .replaceAll('ESPECIALIDAD', '')
        .replaceAll('DOCTORADO', '')
        .replaceAll('VIRTUAL', '')
        .replaceAll('PRESENCIAL', '')
        .replaceAll('SEMIPRESENCIAL', '')
        .trim();

    final filtered = programas.where((programa) {
      final estado = _normalizeValue(programa.estado);
      final vigente =
          estado.contains('INSCRIP') ||
          estado.contains('ABIERTAS') ||
          estado.contains('PUBLICADO');
      if (!vigente) return false;

      final tipo = _normalizeValue(programa.tipo);
      final modalidad = _normalizeValue(programa.modalidad);

      // Inteligencia de bÃºsqueda (si escribe "maestria" en el buscador, filtra por tipo automÃ¡ticamente)
      if (intelTipo.isNotEmpty) {
        if (!tipo.contains(intelTipo)) return false;
      } else if (_selectedTipo != 'TODOS' && selTipo.isNotEmpty) {
        if (!tipo.contains(selTipo) && !selTipo.contains(tipo)) return false;
      }

      if (intelModalidad.isNotEmpty) {
        if (!modalidad.contains(intelModalidad)) return false;
      } else if (_selectedModalidad != 'TODOS' && selModalidad.isNotEmpty) {
        if (!modalidad.contains(selModalidad) &&
            !selModalidad.contains(modalidad)) {
          return false;
        }
      }

      final textoAFiltrar = pureSearch.isNotEmpty ? pureSearch : search;
      if (textoAFiltrar.isNotEmpty) {
        final matchTitulo = _normalizeValue(
          programa.titulo,
        ).contains(textoAFiltrar);
        final matchID = _normalizeValue(programa.id).contains(textoAFiltrar);
        if (!matchTitulo && !matchID) return false;
      }

      return true;
    }).toList();

    // ORDEN: Por fecha lÃ­mite de inscripciÃ³n (inscripcionHasta)
    // Formato esperado: DD/MM/YYYY
    filtered.sort((a, b) {
      final fa = a.inscripcionHasta;
      final fb = b.inscripcionHasta;
      if (fa == null && fb == null) return 0;
      if (fa == null) return 1;
      if (fb == null) return -1;

      try {
        final partsA = fa.split('/');
        final partsB = fb.split('/');
        if (partsA.length == 3 && partsB.length == 3) {
          final dateA = DateTime(
            int.parse(partsA[2]),
            int.parse(partsA[1]),
            int.parse(partsA[0]),
          );
          final dateB = DateTime(
            int.parse(partsB[2]),
            int.parse(partsB[1]),
            int.parse(partsB[0]),
          );
          return dateA.compareTo(dateB);
        }
      } catch (_) {}
      return 0;
    });

    return filtered;
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
    super.build(
      context,
    ); // IMPORTANTE: Necesario para AutomaticKeepAliveClientMixin

    const Color headerBlue = Color(0xFF005BAC);
    const Color headerBlueDark = Color(0xFF004A86);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF0D1B2E)
        : const Color(0xFFE9F2F9);

    final programasAsync = ref.watch(programasVigentesProvider);
    final horizontalPadding = ResponsiveUtils.horizontalPadding(context);
    final sectionSpacing = ResponsiveUtils.cardSpacing(context);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        top: false,
        child: Stack(
          children: [
            Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 420),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    );
                    return ClipRect(
                      child: SizeTransition(
                        axisAlignment: -1,
                        sizeFactor: curved,
                        child: FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.06),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _headerCollapsed,
                    builder: (context, isCollapsed, _) => isCollapsed
                        ? const SizedBox.shrink(key: ValueKey('header-hidden'))
                        : KeyedSubtree(
                            key: const ValueKey('header-visible'),
                            child: _buildHeader(headerBlue, headerBlueDark),
                          ),
                  ),
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
                          OptimizedFadeInDown(
                            from: 12,
                            duration: const Duration(milliseconds: 450),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                horizontalPadding,
                                16,
                                horizontalPadding,
                                4,
                              ),
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
                          ValueListenableBuilder<bool>(
                            valueListenable: _showScrollHint,
                            builder: (context, showHint, _) => AnimatedSlide(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeOutCubic,
                              offset: showHint
                                  ? Offset.zero
                                  : const Offset(0, -0.2),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                                opacity: showHint ? 1 : 0,
                                child: OptimizedFadeInUp(
                                  delay: const Duration(milliseconds: 180),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons
                                              .keyboard_double_arrow_down_rounded,
                                          size: 18,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Desliza hacia abajo para ver mÃ¡s programas',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ), // cierre ValueListenableBuilder
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 350),
                              child: vigentes.isEmpty
                                  ? KeyedSubtree(
                                      key: ValueKey('empty-$filtrosKey'),
                                      child: _buildEmptyState(),
                                    )
                                  : RefreshIndicator(
                                      key: ValueKey('list-$filtrosKey'),
                                      onRefresh: () async {
                                        ref.invalidate(
                                          programasVigentesProvider,
                                        );
                                        await ref.read(
                                          programasVigentesProvider.future,
                                        );
                                      },
                                      color: const Color(0xFF005BAC),
                                      child: Scrollbar(
                                        controller: _vigentesScrollController,
                                        thumbVisibility: true,
                                        radius: const Radius.circular(8),
                                        child: ListView.builder(
                                          controller: _vigentesScrollController,
                                          padding: EdgeInsets.fromLTRB(
                                            horizontalPadding,
                                            8,
                                            horizontalPadding,
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
                                              return RepaintBoundary(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: sectionSpacing,
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
                                                ),
                                              );
                                            }
                                            return const _EndOfListIndicator();
                                          },
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
            if (_showTutorial) _buildTutorialOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay() {
    final step = _tutorialSteps[_tutorialStep];
    final bool isLast = _tutorialStep == _tutorialSteps.length - 1;
    return Positioned.fill(
      child: OptimizedFadeIn(
        duration: const Duration(milliseconds: 250),
        child: Container(
          color: Colors.black.withOpacity(0.82),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Tutorial de inscripcion (${_tutorialStep + 1}/${_tutorialSteps.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _cerrarTutorialGuiado,
                        child: const Text(
                          'Saltar',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(step['icon'] as IconData, color: Colors.white),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                step['title'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step['desc'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          step['hint'] as String,
                          style: const TextStyle(
                            color: Color(0xFFB3E5FC),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _tutorialStep == 0
                              ? null
                              : _retrocederTutorial,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withOpacity(0.5),
                            ),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Anterior'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _avanzarTutorial,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF005BAC),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isLast ? 'Finalizar' : 'Siguiente'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color headerBlue, Color headerBlueDark) {
    final width = MediaQuery.of(context).size.width;
    final topPadding = MediaQuery.of(context).padding.top;
    final isSmall = width < 360;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 14 + topPadding, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [headerBlue, headerBlueDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(40)),
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
          OptimizedFadeInDown(
            child: Row(
              children: [
                if (widget.isGuestMode)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          if (widget.isGuestMode) {
                            context.go('/splash');
                          } else if (Navigator.of(context).canPop())
                            Navigator.of(context).pop();
                          else
                            context.goNamed(PantallaPrincipal.name);
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(width: 46, height: 46),
                const Spacer(),
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
                const SizedBox(width: 8),
                Material(
                  color: Colors.white.withOpacity(0.15),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: _iniciarTutorialGuiado,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(
                        Icons.help_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OptimizedFadeInUp(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              child: TextField(
                controller: _searchController,
                onChanged: (val) => _searchDebouncer(() => setState(() {})),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre o ID...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(
                    Icons.search,
                    color: headerBlue.withOpacity(0.7),
                    size: 20,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _showFilters = !_showFilters),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        _showFilters ? 0.3 : 0.15,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Filtros',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: isSmall ? 13 : 14,
                          ),
                        ),
                        if (_selectedTipo != 'TODOS' ||
                            _selectedModalidad != 'TODOS') ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_showFilters) ...[
            const SizedBox(height: 12),
            OptimizedFadeIn(
              child: Row(
                children: [
                  Expanded(
                    child: _FilterChipSelector(
                      value: _selectedModalidad,
                      options: const [
                        'TODOS',
                        'PRESENCIAL',
                        'VIRTUAL',
                        'SEMIPRESENCIAL',
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedModalidad = val),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                      onChanged: (val) => setState(() => _selectedTipo = val),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF005BAC)),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        items: options
            .map(
              (opt) => DropdownMenuItem(
                value: opt,
                child: Text(
                  opt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: (val) => val != null ? onChanged(val) : null,
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

  String _fullImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return 'https://via.placeholder.com/600x400';
    }
    if (path.startsWith('http')) return path;
    String base = Environment.apiPreinscripcionUrl.endsWith('/')
        ? Environment.apiPreinscripcionUrl.substring(
            0,
            Environment.apiPreinscripcionUrl.length - 1,
          )
        : Environment.apiPreinscripcionUrl;
    String u = path.replaceAll('\\', '/');
    return base + (u.startsWith('/') ? u : '/$u');
  }

  @override
  Widget build(BuildContext context) {
    final headerBlue = const Color(0xFF005BAC);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                // Imagen o fallback con gradiente
                programa.imagenPortada != null &&
                        programa.imagenPortada!.isNotEmpty
                    ? OptimizedImage(
                        imageUrl: _fullImageUrl(programa.imagenPortada),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF005BAC),
                              const Color(0xFF3D8FE0),
                            ],
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: Colors.white54,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                programa.titulo,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      programa.tipo.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  programa.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (programa.responsable != null &&
                        programa.responsable!.isNotEmpty)
                      Expanded(
                        child: _IconInfo(
                          icon: Icons.person_rounded,
                          label: programa.responsable!.split('Â·').first.trim(),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: _IconInfo(
                        icon: Icons.location_on_rounded,
                        label: programa.modalidad,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: onEnroll,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEnrolled
                                ? Colors.green.shade600
                                : headerBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isEnrolled ? 'Mi Proceso' : 'Inscribirme',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () async {
                            final cel =
                                programa.celularSoporte?.replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                ) ??
                                '73912003';
                            final text =
                                'Hola, me gustarÃ­a mÃ¡s informaciÃ³n sobre el programa: ${programa.titulo}';
                            final uri = Uri.parse(
                              'https://wa.me/591$cel?text=${Uri.encodeComponent(text)}',
                            );
                            try {
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (e) {
                              debugPrint('Error al abrir WhatsApp: $e');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF25D366),
                            side: const BorderSide(color: Color(0xFF25D366)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.whatsapp,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (programa.inscripcionHasta != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'Cupos hasta: ${programa.inscripcionHasta}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
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
}

class _IconInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _IconInfo({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }
}

class _EndOfListIndicator extends StatelessWidget {
  const _EndOfListIndicator();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 24,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Has llegado al final de la oferta vigente',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
