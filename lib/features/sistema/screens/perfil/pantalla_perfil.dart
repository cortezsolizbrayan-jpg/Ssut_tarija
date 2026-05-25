import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/config/constants/environment.dart';
import 'package:refactor_template/core/utils/helper_validacion_inscripcion.dart';
import 'package:refactor_template/core/utils/responsive_helper.dart';
import 'package:refactor_template/features/sistema/domain/entities/programa_posgrado.dart';
import 'package:refactor_template/features/sistema/presentation/blocs/perfil/perfil_bloc.dart';
import 'package:refactor_template/features/sistema/presentation/blocs/perfil/perfil_event.dart';
import 'package:refactor_template/features/sistema/presentation/blocs/perfil/perfil_state.dart';
import 'package:refactor_template/features/sistema/presentation/providers/programa_posgrado_provider.dart';
import 'package:refactor_template/core/services/otros/servicio_actualizacion.dart';
import 'package:refactor_template/features/sistema/screens/contenedor/menu_lateral_scope.dart';
import 'package:refactor_template/features/sistema/widgets/inscripcion/pasos_inscripcion_sheet.dart';
import 'package:refactor_template/features/sistema/widgets/navegacion/icono_notificaciones_widget.dart';
import 'package:refactor_template/features/sistema/widgets/perfil/avatar_perfil_widget.dart';

// ==========================================================================
// PERFIL Pantalla - Pantalla principal del postgraduante
// ==========================================================================

class PerfilPantalla extends ConsumerStatefulWidget {
  const PerfilPantalla({super.key});

  @override
  ConsumerState<PerfilPantalla> createState() => _PerfilPantallaState();
}

class _PerfilPantallaState extends ConsumerState<PerfilPantalla>
    with TickerProviderStateMixin {
  //
  // CONTROLADORES Y ESTADO
  //

  final PageController _carouselController = PageController(
    viewportFraction: 0.88,
  );
  int _currentCarouselPage = 0;
  Timer? _carouselTimer;

  late final AnimationController _entryController;

  // Controladores de animacin para cada item del carrusel (efecto burbuja)
  final Map<String, AnimationController> _itemAnimationControllers = {};

  //
  // CONSTANTES DE COLOR
  //

  static const _gradStart = Color(0xFF0D47A1);
  static const _gradEnd = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();
    // Iniciar carga de datos a travs del Bloc
    context.read<PerfilBloc>().add(LoadPerfilData());

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _startCarouselTimer();

    // Verificar actualizaciones disponibles (solo Android)
    _verificarActualizaciones();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    // Limpiar controladores de animacin de items
    for (var controller in _itemAnimationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  //
  // MTODOS AUXILIARES
  //

  String _obtenerSaludo() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buen da! ';
    if (hour < 19) return 'Buenas tardes! ';
    return 'Buenas noches! ';
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_carouselController.hasClients) {
        _carouselController.animateToPage(
          _currentCarouselPage + 1,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  String _fullImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final u = url.trim();
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    final base = Environment.apiPreinscripcionUrl.replaceFirst(
      RegExp(r'/api/v1/?$'),
      '',
    );
    return base + (u.startsWith('/') ? u : '/$u');
  }

  /// Muestra el bottom sheet de pasos y luego inicia el flujo de inscripcin.
  Future<void> _onInscribirseTap(ProgramaPosgrado programa) async {
    // Mostrar bottom sheet de pasos primero
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PasosInscripcionSheet(programa: programa),
    );

    final continuar = result ?? false;
    if (!continuar || !mounted) return;

    // Iniciar flujo de validacin de requisitos
    await HelperValidacionInscripcion.validarYContinuar(
      context: context,
      tipoPrograma: programa.tipo,
      nombrePrograma: programa.titulo,
      idPrograma: programa.id,
      modalidad: programa.modalidad,
      onRequisitosCompletos: () {
        // Al completarse, redirigir a Mis Programas para ver el nuevo estado
        context.push('/diplomados');
      },
    );
  }

  /// Verifica si hay actualizaciones disponibles y muestra dilogo correspondiente
  Future<void> _verificarActualizaciones() async {
    try {
      final servicio = ServicioActualizacion();
      final hayActualizacion = await servicio.verificarActualizacion();

      if (!mounted) return;

      if (hayActualizacion) {
        await servicio.mostrarDialogoActualizacionNormal(context);
      }
    } catch (e) {
      debugPrint('Error en verificacin de actualizaciones: $e');
    }
  }

  //
  // Widget BUILD
  //

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveHelper(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        scrolledUnderElevation: 0,
        leadingWidth: 48,
        leading: const BotonMenuLateral(),
        title: Image.asset(
          'assets/images/logposgrado.png',
          height: rs.logoHeight,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Image.asset(
            'assets/images/logoposgrado.jpg',
            height: rs.logoHeight - 4,
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          NotificationIconWidget(
            size: rs.notificationSize,
            iconSize: rs.iconNotificationSize,
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await context.push('/configuracion');
              if (context.mounted) {
                context.read<PerfilBloc>().add(LoadPerfilData());
              }
            },
            child: Icon(
              Icons.settings_rounded,
              color: Colors.white.withOpacity(0.9),
              size: rs.settingsIconSize,
            ),
          ),
          const SizedBox(width: 12),
          Hero(
            tag: 'avatar_hero_appbar',
            child: ProfileAvatarWidget(
              radius: rs.avatarWidgetRadius,
              showShadow: true,
              onTap: () async {
                await context.push('/mis-datos-personales');
                if (context.mounted) {
                  context.read<PerfilBloc>().add(LoadPerfilData());
                }
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BlocBuilder<PerfilBloc, PerfilState>(
        builder: (context, state) {
          final isLoading =
              state.status == PerfilStatus.loading ||
              state.status == PerfilStatus.initial;
          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    //  Header azul con curva
                    _buildTopSection(context),

                    //  Carrusel
                    const SizedBox(height: 12),
                    _buildCarouselSection(),

                    //  Zona inferior (CEUB + Slogan) flexible
                    _buildBottomSection(context),
                  ],
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.72),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: _gradStart),
                          SizedBox(height: 12),
                          Text(
                            'Cargando informacin...',
                            style: TextStyle(
                              color: Color(0xFF1E3A5F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  //
  // SECCIONES DE LA PANTALLA
  //

  //  TOP SECTION
  Widget _buildTopSection(BuildContext context) {
    final rs = ResponsiveHelper(context);

    return ClipPath(
      clipper: _CurveClipper(),
      child: Container(
        padding: EdgeInsets.only(bottom: rs.topSectionBottomPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_gradStart, _gradEnd],
          ),
        ),
        child: SafeArea(
          bottom: false,
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              top:
                  rs.topSectionPadding.top + MediaQuery.of(context).padding.top,
              bottom: rs.topSectionPadding.bottom,
              left: rs.topSectionPadding.left,
              right: rs.topSectionPadding.right,
            ),
            child: FadeTransition(
              opacity: _entryController,
              child: _buildProfileCard(context),
            ),
          ),
        ),
      ),
    );
  }

  //  PROFILE CARD
  Widget _buildProfileCard(BuildContext context) {
    final rs = ResponsiveHelper(context);

    return Container(
      padding: rs.cardPadding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(rs.cardBorderRadius),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          // Avatar con navegacin heroica
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              await context.push('/mis-datos-personales');
              if (context.mounted) {
                context.read<PerfilBloc>().add(LoadPerfilData());
              }
            },
            child: Hero(
              tag: 'avatar_hero_main',
              child: Container(
                padding: EdgeInsets.all(rs.avatarBorder),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFC107), Color(0xFFFFD54F)],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ProfileAvatarWidget(radius: rs.avatarRadius),
                ),
              ),
            ),
          ),
          SizedBox(width: rs.spacingAvatarInfo),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _obtenerSaludo(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: rs.saludoFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                BlocBuilder<PerfilBloc, PerfilState>(
                  builder: (context, state) {
                    return Text(
                      state.nombreUsuario ?? 'Cargando...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: rs.nombreFontSize,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                const SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs.badgeFontSize + 1,
                    vertical: rs.badgeFontSize - 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC107),
                    borderRadius: BorderRadius.circular(rs.badgeFontSize - 2),
                  ),
                  child: Text(
                    'POSTGRADUANTE ACTIVO',
                    style: TextStyle(
                      color: Color(0xFF1565C0),
                      fontSize: rs.badgeFontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: rs.badgeFontSize + 1),
                // Botn VER MIS PROGRAMAS
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/diplomados');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: rs.botonPadding + 5,
                      vertical: rs.botonPadding,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(rs.badgeFontSize - 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(rs.badgeFontSize - 4),
                          decoration: BoxDecoration(
                            color: _gradStart,
                            borderRadius: BorderRadius.circular(
                              rs.badgeFontSize - 2,
                            ),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: Colors.white,
                            size: rs.iconBtnSize,
                          ),
                        ),
                        SizedBox(width: rs.badgeFontSize - 1),
                        Flexible(
                          child: Text(
                            'VER MIS PROGRAMAS',
                            style: TextStyle(
                              fontSize: rs.botonFontSize,
                              fontWeight: FontWeight.w900,
                              color: _gradStart,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _gradStart,
                          size: rs.iconArrowSize,
                        ),
                      ],
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

  //  CARRUSEL
  // Seccin que muestra los programas destacados con animacin de burbuja
  Widget _buildCarouselSection() {
    final programasAsync = ref.watch(programasVigentesProvider);
    return programasAsync.when(
      data: (programas) {
        final vigentes = programas.where((p) {
          final estado = p.estado.toUpperCase();
          return (estado.contains('INSCRIP') ||
                  estado.contains('ABIERTAS') ||
                  estado.contains('PUBLICADO')) &&
              (p.imagenPortada != null && p.imagenPortada!.isNotEmpty);
        }).toList();
        return _buildCarouselView(
          vigentes.isEmpty ? _obtenerProgramasLocales() : vigentes,
          isFallback: vigentes.isEmpty,
        );
      },
      loading: () => const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator(color: _gradStart)),
      ),
      error: (error, stackTrace) =>
          _buildCarouselView(_obtenerProgramasLocales(), isFallback: true),
    );
  }

  //  PROGRAMAS LOCALES (FALLBACK)
  List<ProgramaPosgrado> _obtenerProgramasLocales() {
    return [
      ProgramaPosgrado(
        id: 'f1',
        titulo: 'Maestra en Educacin Superior y Nuevas Tecnologas',
        tipo: 'MAESTRA',
        modalidad: '100% VIRTUAL',
        duracion: '18 meses',
        cargaHoraria: '2400h',
        creditos: 60,
        estado: 'INSCRIPCIONES ABIERTAS',
        area: 'EDUCACIN',
        urlFichaTecnica: 'assets/images/grupomaestra.png',
      ),
      ProgramaPosgrado(
        id: 'f2',
        titulo: 'Diplomado en Gestin Pblica Plurinacional',
        tipo: 'DIPLOMADO',
        modalidad: 'SEMIPRESENCIAL',
        duracion: '6 meses',
        cargaHoraria: '800h',
        creditos: 20,
        estado: 'INSCRIPCIONES ABIERTAS',
        area: 'GESTIN',
        urlFichaTecnica: 'assets/images/grupodiplomado.png',
      ),
      ProgramaPosgrado(
        id: 'f3',
        titulo: 'Especialidad en Medicina Crtica y Terapia Intensiva',
        tipo: 'ESPECIALIDAD',
        modalidad: 'PRESENCIAL',
        duracion: '12 meses',
        cargaHoraria: '1600h',
        creditos: 40,
        estado: 'INSCRIPCIONES ABIERTAS',
        area: 'SALUD',
        urlFichaTecnica: 'assets/images/grupoespecialidad.png',
      ),
    ];
  }

  //  CARRUSEL VIEW
  // Construye la vista del carrusel con PageView y animaciones
  Widget _buildCarouselView(
    List<ProgramaPosgrado> vigentes, {
    bool isFallback = false,
  }) {
    if (vigentes.isEmpty) return const SizedBox.shrink();

    final rs = ResponsiveHelper(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: rs.topSectionPaddingH),
          child: Row(
            children: [
              Text(
                isFallback ? 'Oferta Disponible' : 'Programas Destacados',
                style: TextStyle(
                  fontSize: rs.ceubSubFontSize + 2,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3A5F),
                ),
              ),
              const Spacer(),
              if (isFallback)
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 14,
                  color: Colors.orange,
                )
              else
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: rs.badgeFontSize - 1,
                    vertical: rs.badgeFontSize - 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(rs.badgeFontSize - 1),
                  ),
                  child: Text(
                    '${vigentes.length} vigentes',
                    style: TextStyle(
                      fontSize: rs.badgeFontSize - 1,
                      fontWeight: FontWeight.w600,
                      color: _gradStart,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: rs.carouselHeight,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: 10000,
            onPageChanged: (i) => setState(() => _currentCarouselPage = i),
            itemBuilder: (context, index) {
              final programa = vigentes[index % vigentes.length];

              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, hijo) {
                  double value = 0.0;
                  if (_carouselController.position.hasContentDimensions) {
                    value = (_carouselController.page! - index).abs();
                  }
                  final scale = (1 - value * 0.07).clamp(0.0, 1.0);
                  return Transform.scale(scale: scale, child: hijo);
                },
                child: _buildCarouselItem(programa, isAsset: isFallback),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(vigentes.length, (index) {
                    final isSelected =
                        (_currentCarouselPage % vigentes.length) == index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: isSelected ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _gradStart
                            : _gradStart.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32), // Espacio debajo de los puntitos
      ],
    );
  }

  //  CARRUSEL ITEM
  // Construye cada tarjeta individual del carrusel
  Widget _buildCarouselItem(ProgramaPosgrado programa, {bool isAsset = false}) {
    final rs = ResponsiveHelper(context);

    final imageUrl = isAsset
        ? programa.imagenPortada ?? programa.urlFichaTecnica ?? ''
        : _fullImageUrl(programa.imagenPortada ?? programa.urlFichaTecnica);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _onInscribirseTap(programa);
      },
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: rs.carouselItemMargin,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(rs.carouselItemBorderRadius),
          color: const Color(0xFF0D47A1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(rs.carouselItemBorderRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              //  Imagen de fondo
              if (isAsset)
                Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildImageFallback(programa),
                )
              else
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFF0D47A1),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      _buildImageFallback(programa),
                ),

              //  Gradiente oscuro inferior
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.65),
                      ],
                      stops: const [0.45, 1.0],
                    ),
                  ),
                ),
              ),

              //  Badge tipo de programa
              Positioned(
                top: rs.badgeFontSize + 3,
                right: rs.badgeFontSize + 3,
                child: Builder(
                  builder: (context) {
                    final tipoColor = _colorPorTipo(programa.tipo);
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: rs.badgeFontSize + 1,
                        vertical: rs.badgeFontSize - 5,
                      ),
                      decoration: BoxDecoration(
                        color: tipoColor,
                        borderRadius: BorderRadius.circular(
                          rs.badgeFontSize - 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        programa.tipo.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: rs.badgeFontSize,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );
                  },
                ),
              ),

              //  Ttulo y modalidad
              Positioned(
                bottom: rs.badgeFontSize + 3,
                left: rs.badgeFontSize + 3,
                right: rs.badgeFontSize + 3,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.38),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        programa.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: rs.ceubSubFontSize,
                          fontWeight: FontWeight.w900,
                          shadows: const [
                            Shadow(blurRadius: 6, color: Colors.black87),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            color: Colors.white.withOpacity(0.95),
                            size: rs.badgeFontSize + 2,
                          ),
                          SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              programa.modalidad,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: rs.badgeFontSize + 1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorPorTipo(String tipo) {
    final t = tipo.toUpperCase();
    if (t.contains('MAESTR')) return const Color(0xFF1565C0);
    if (t.contains('DIPLOMADO')) return const Color(0xFFEF6C00);
    if (t.contains('DOCTOR')) return const Color(0xFF6A1B9A);
    if (t.contains('ESPECIAL')) return const Color(0xFF2E7D32);
    return const Color(0xFF455A64);
  }

  //  IMAGE FALLBACK
  // Pantalla de respaldo cuando no se puede cargar la imagen
  Widget _buildImageFallback(ProgramaPosgrado programa) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.school_rounded,
              color: Colors.white.withOpacity(0.4),
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              programa.tipo,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  BOTTOM SECTION
  // Seccin inferior con CEUB y slogan institucional
  Widget _buildBottomSection(BuildContext context) {
    final rs = ResponsiveHelper(context);

    return Column(
      children: [
        // Bloque Azul: CEUB
        Container(
          width: double.infinity,
          padding: rs.ceubPaddingAll,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_gradStart, _gradEnd],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Busca Nuestros Programas',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: rs.ceubTitleFontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Certificados y Registrados por la CEUB',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: rs.ceubSubFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: rs.badgeFontSize),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: rs.ceubBtnPadding,
                        vertical: rs.ceubBtnPadding - 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          rs.ceubBtnBorderRadius,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.list_alt_rounded,
                            color: _gradStart,
                            size: rs.ceubIconSize,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Verificar programas',
                            style: TextStyle(
                              color: _gradStart,
                              fontSize: rs.ceubBtnFontSize,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: rs.badgeFontSize + 3),
              Image.asset(
                'assets/images/ceub.png',
                height: rs.ceubLogoHeight,
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),

        // Bloque Blanco: Slogan (responsive)
        Container(
          width: double.infinity,
          color: Colors.white,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: rs.sloganPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/19.png',
                    height: rs.sloganLogoHeight,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: rs.sloganSpacing),
                  Flexible(
                    child: Text(
                      '!Democratizando la educación superior por encargo social!',
                      style: TextStyle(
                        fontFamily: 'Parisienne',
                        color: Colors.black87,
                        fontSize: rs.sloganFontSize,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Clipper curva inferior
class _CurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 28)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 18,
        size.width,
        size.height - 28,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
