import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/animations/custom_animations.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';
import 'package:refactor_template/core/services/otros/servicio_biometrico.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/features/acceso/presentacion/paginas/pantallas/autenticacion/pantalla_autenticacion_rapida.dart';
import 'package:refactor_template/features/acceso/presentacion/componentes/fondo_azul_curvo_widget.dart';
import 'package:refactor_template/features/acceso/presentacion/componentes/botones_widget.dart';
import 'package:refactor_template/features/acceso/presentacion/componentes/custom_text_form_field.dart';
import 'package:refactor_template/features/sistema/screens/entryPoint/entry_point.dart';
import 'package:rive/rive.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';

/// Pantalla de inicio de sesión RESPONSIVE con animación Rive
/// y navegación a [PantallaPrincipal] cuando el login es correcto.
/// Soporta portrait y landscape con layouts optimizados para cada orientación.
class PaginaLoginResponsive extends ConsumerStatefulWidget {
  static const name = 'pagina-login-responsive';
  const PaginaLoginResponsive({super.key});

  @override
  ConsumerState<PaginaLoginResponsive> createState() =>
      _PaginaLoginResponsiveState();
}

class _PaginaLoginResponsiveState extends ConsumerState<PaginaLoginResponsive> {
  late String usuario;
  late String contra;
  bool isShowLoading = false;
  bool isShowConfetti = false;

  String? _lastLoginUser;

  SMITrigger? _successTrigger;
  SMITrigger? _confettiTrigger;

  final _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    usuario = '';
    contra = '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkQuickAuth();
    });
  }

  Future<void> _checkQuickAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPin = prefs.getString('security_pin') != null;

    if (!hasPin || !mounted) return;

    // Si el usuario acaba de cerrar sesión manualmente, no pedir PIN esta vez.
    // Consumir la bandera (solo aplica una vez).
    final justLoggedOut = prefs.getBool('just_logged_out') ?? false;
    if (justLoggedOut) {
      await prefs.remove('just_logged_out');
      return; // Mostrar login normal sin PIN
    }

    // Hay PIN guardado y no es un cierre de sesión manual → pedir PIN
    final authenticated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const PantallaAutenticacionRapida(),
        fullscreenDialog: true,
      ),
    );

    if (authenticated == true && mounted) {
      context.go('/sistema/pantalla_principal');
    }
  }

  void _onCheckRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (controller != null) {
      artboard.addController(controller);
      _successTrigger = controller.findInput<bool>('Check') as SMITrigger?;
    }
  }

  void _onConfettiRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'State Machine 1',
    );
    if (controller != null) {
      artboard.addController(controller);
      _confettiTrigger =
          controller.findInput<bool>('Trigger explosion') as SMITrigger?;
    }
  }

  Future<void> _saveCredentialsForBiometric(
    String username,
    String password,
  ) async {
    try {
      final isSupported = await _biometricService.isDeviceSupported();
      if (isSupported) {
        final availableTypes = await _biometricService.getAvailableBiometrics();
        if (availableTypes.isNotEmpty) {
          await _biometricService.setBiometricEnabled(true);
          await _biometricService.saveCredentials(
            username: username,
            password: password,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Biometría habilitada. Podrás usar ${_biometricService.getBiometricTypeName(availableTypes)} para iniciar sesión.',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error guardando credenciales para biometría: $e');
    }
  }

  void _onLoginPressed({String? username, String? password}) {
    final loginUsername = (username ?? usuario).trim();
    final loginPassword = password ?? contra;

    setState(() {
      isShowLoading = true;
      isShowConfetti = false;
      _lastLoginUser = loginUsername.isNotEmpty ? loginUsername : null;
    });

    // Disparar animación Rive si está disponible (no bloqueante)
    Future.delayed(const Duration(milliseconds: 300), () {
      _successTrigger?.fire();
    });

    // Guardar sesión y navegar después de una animación corta
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      _saveCredentialsForBiometric(loginUsername, loginPassword);

      await LocalStorageService.saveSessionData({
        'nombreUsuario': loginUsername,
        'savedAt': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;
      setState(() {
        isShowLoading = false;
      });

      context.go(PantallaPrincipal.name);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD PRINCIPAL — delega según orientación
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.landscape) {
          return _buildLandscape(context);
        }
        return _buildPortrait(context);
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PORTRAIT LAYOUT
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPortrait(BuildContext context) {
    const lightBackground = Color(0xFFEEF1F8);
    const primaryBlue = Color(0xFF005BAC);
    const accentYellow = Color(0xFFFFC900);

    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.of(context).size;
            final width = size.width;
            final height = constraints.maxHeight;
            final isSmallHeight = height < 700;

            return ResponsiveContainer(
              maxWidth: ResponsiveUtils.maxContentWidth(context),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    physics: isSmallHeight
                        ? const BouncingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: height),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // HEADER AZUL CON CUSTOMPAINTER
                          FondoAzulCurvoWidget(
                            color: primaryBlue,
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: ResponsiveUtils.horizontalPadding(
                                  context,
                                ),
                                right: ResponsiveUtils.horizontalPadding(
                                  context,
                                ),
                                top: ResponsiveUtils.verticalPadding(context),
                                bottom: isSmallHeight
                                    ? ResponsiveUtils.verticalPadding(context) *
                                          1.5
                                    : ResponsiveUtils.verticalPadding(context) *
                                          2,
                              ),
                              child: Column(
                                children: [
                                  SlideInAnimation(
                                    duration: const Duration(milliseconds: 800),
                                    delay: const Duration(milliseconds: 100),
                                    begin: const Offset(0, -0.5),
                                    curve: Curves.easeOutCubic,
                                    child: ScaleInAnimation(
                                      duration: const Duration(
                                        milliseconds: 1000,
                                      ),
                                      delay: const Duration(milliseconds: 100),
                                      curve: Curves.easeOutBack,
                                      child: SizedBox(
                                        width: ResponsiveUtils.valueByDevice(
                                          context: context,
                                          mobile: width * 0.30,
                                          tablet: 120.0,
                                          largeTablet: 140.0,
                                          desktop: 160.0,
                                        ),
                                        height: ResponsiveUtils.valueByDevice(
                                          context: context,
                                          mobile: width * 0.30,
                                          tablet: 120.0,
                                          largeTablet: 140.0,
                                          desktop: 160.0,
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.all(
                                            ResponsiveUtils.cardSpacing(
                                                  context,
                                                ) *
                                                0.25,
                                          ),
                                          child: Image.asset(
                                            'assets/images/graduation_icon.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        ResponsiveUtils.cardSpacing(context) *
                                        0.5,
                                  ),
                                  SlideInAnimation(
                                    duration: const Duration(milliseconds: 700),
                                    delay: const Duration(milliseconds: 300),
                                    begin: const Offset(0, 0.3),
                                    child: Text(
                                      'Bienvenido(a) a Posgrado UPEA',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.titleFontSize(
                                          context,
                                        ),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        ResponsiveUtils.cardSpacing(context) *
                                        0.5,
                                  ),
                                  SlideInAnimation(
                                    duration: const Duration(milliseconds: 700),
                                    delay: const Duration(milliseconds: 400),
                                    begin: const Offset(0, 0.3),
                                    child: Text(
                                      'Tu trayectoria profesional siempre accesible.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFFFFCC3E),
                                        fontSize:
                                            ResponsiveUtils.bodyFontSize(
                                              context,
                                            ) *
                                            1.1,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        ResponsiveUtils.cardSpacing(context) *
                                        0.5,
                                  ),
                                  SlideInAnimation(
                                    duration: const Duration(milliseconds: 700),
                                    delay: const Duration(milliseconds: 500),
                                    begin: const Offset(0, 0.3),
                                    child: Text(
                                      'Accede a tu registro académico, programas aprobados y documentos pendientes.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: ResponsiveUtils.bodyFontSize(
                                          context,
                                        ),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.cardSpacing(context),
                          ),
                          // TARJETA + BOTÓN ACCEDER
                          Transform.translate(
                            offset: Offset(
                              0,
                              -ResponsiveUtils.verticalPadding(context),
                            ),
                            child: Column(
                              children: [
                                SlideInAnimation(
                                  duration: const Duration(milliseconds: 800),
                                  delay: const Duration(milliseconds: 600),
                                  begin: const Offset(0, 0.5),
                                  curve: Curves.easeOutCubic,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal:
                                          ResponsiveUtils.horizontalPadding(
                                            context,
                                          ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth:
                                              ResponsiveUtils.valueByDevice(
                                                context: context,
                                                mobile: double.infinity,
                                                tablet: 500.0,
                                                largeTablet: 600.0,
                                                desktop: 700.0,
                                              ),
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            _buildWhiteCard(
                                              context,
                                              primaryBlue: primaryBlue,
                                            ),
                                            _buildAccederButton(
                                              context,
                                              accentYellow: accentYellow,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.verticalPadding(context),
                          ),
                          // Biometría
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveUtils.horizontalPadding(
                                context,
                              ),
                            ),
                            child: Center(
                              child: BiometriaWidget(
                                width: width,
                                onBiometricSuccess: (username, password) {
                                  _onLoginPressed(
                                    username: username,
                                    password: password,
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            height: ResponsiveUtils.verticalPadding(context),
                          ),
                          _buildSocialButtons(context),
                          SizedBox(
                            height: ResponsiveUtils.verticalPadding(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Overlays Rive
                  ..._buildRiveOverlays(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // LANDSCAPE LAYOUT — dos columnas
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildLandscape(BuildContext context) {
    const primaryBlue = Color(0xFF005BAC);
    const accentYellow = Color(0xFFFFC900);
    const lightBackground = Color(0xFFEEF1F8);

    return Scaffold(
      backgroundColor: lightBackground,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Panel izquierdo azul ──────────────────────────────────
                Expanded(
                  child: Container(
                    color: primaryBlue,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 16.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ScaleInAnimation(
                          duration: const Duration(milliseconds: 900),
                          delay: const Duration(milliseconds: 100),
                          curve: Curves.easeOutBack,
                          child: Image.asset(
                            'assets/images/graduation_icon.png',
                            width: 90,
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SlideInAnimation(
                          duration: const Duration(milliseconds: 700),
                          delay: const Duration(milliseconds: 300),
                          begin: const Offset(0, 0.3),
                          child: Text(
                            'Bienvenido(a) a Posgrado UPEA',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.subtitleFontSize(
                                context,
                              ),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SlideInAnimation(
                          duration: const Duration(milliseconds: 700),
                          delay: const Duration(milliseconds: 400),
                          begin: const Offset(0, 0.3),
                          child: Text(
                            'Tu trayectoria profesional siempre accesible.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accentYellow,
                              fontSize: ResponsiveUtils.bodyFontSize(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SlideInAnimation(
                          duration: const Duration(milliseconds: 700),
                          delay: const Duration(milliseconds: 500),
                          begin: const Offset(0, 0.3),
                          child: Text(
                            'Accede a tu registro académico, programas aprobados y documentos pendientes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize:
                                  ResponsiveUtils.bodyFontSize(context) * 0.9,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Panel derecho: formulario ─────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveUtils.horizontalPadding(context),
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SlideInAnimation(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 600),
                          begin: const Offset(0.3, 0),
                          curve: Curves.easeOutCubic,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildWhiteCard(
                                context,
                                primaryBlue: primaryBlue,
                              ),
                              _buildAccederButton(
                                context,
                                accentYellow: accentYellow,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height:
                              ResponsiveUtils.verticalPadding(context) * 1.5,
                        ),
                        Center(
                          child: BiometriaWidget(
                            width: MediaQuery.of(context).size.width * 0.45,
                            onBiometricSuccess: (username, password) {
                              _onLoginPressed(
                                username: username,
                                password: password,
                              );
                            },
                          ),
                        ),
                        SizedBox(height: ResponsiveUtils.cardSpacing(context)),
                        _buildSocialButtons(context),
                        SizedBox(height: ResponsiveUtils.cardSpacing(context)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Overlays Rive sobre ambas columnas
            ..._buildRiveOverlays(context),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // WIDGETS COMPARTIDOS
  // ─────────────────────────────────────────────────────────────────────────

  /// Tarjeta blanca con campos usuario/contraseña
  Widget _buildWhiteCard(BuildContext context, {required Color primaryBlue}) {
    return Container(
      padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.cardBorderRadius(context) * 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0D0D0D),
            blurRadius: 24,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                FontAwesomeIcons.lock,
                color: primaryBlue,
                size: ResponsiveUtils.mediumIconSize(context) * 0.8,
              ),
              SizedBox(width: ResponsiveUtils.cardSpacing(context)),
              Text(
                'INICIAR SESIÓN',
                style: TextStyle(
                  color: const Color(0xFF333333),
                  fontSize: ResponsiveUtils.subtitleFontSize(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.verticalPadding(context)),
          CustomTextFormField(
            label: 'Usuario',
            onChanged: (valor) => usuario = valor,
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          CustomTextFormField(
            label: 'Contraseña',
            onChanged: (valor) => contra = valor,
            obscureText: true,
            icon: Icon(
              Icons.visibility_outlined,
              color: Colors.black45,
              size: ResponsiveUtils.smallIconSize(context),
            ),
          ),
          SizedBox(height: ResponsiveUtils.cardSpacing(context)),
          Center(
            child: TextButton(
              onPressed: () {
                // TODO: Implementar recuperación de contraseña
              },
              child: Text(
                'Recupera tu contraseña de acceso',
                style: TextStyle(
                  color: const Color(0xFFFF8A00),
                  fontWeight: FontWeight.w600,
                  fontSize: ResponsiveUtils.bodyFontSize(context),
                ),
              ),
            ),
          ),
          SizedBox(height: ResponsiveUtils.verticalPadding(context)),
        ],
      ),
    );
  }

  /// Botón ACCEDER sobrepuesto en la parte inferior de la tarjeta
  Widget _buildAccederButton(
    BuildContext context, {
    required Color accentYellow,
  }) {
    return Positioned(
      left: ResponsiveUtils.horizontalPadding(context),
      right: ResponsiveUtils.horizontalPadding(context),
      bottom: -ResponsiveUtils.buttonHeight(context) * 0.4,
      child: ScaleInAnimation(
        duration: const Duration(milliseconds: 600),
        delay: const Duration(milliseconds: 1000),
        curve: Curves.easeOutBack,
        child: HoverScaleEffect(
          scale: 1.03,
          child: SizedBox(
            width: double.infinity,
            height: ResponsiveUtils.buttonHeight(context),
            child: ElevatedButton(
              onPressed: _onLoginPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentYellow,
                foregroundColor: const Color(0xFF0D1730),
                elevation: 8,
                shadowColor: const Color(0x33FFC900),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              child: Text(
                'ACCEDER',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: ResponsiveUtils.bodyFontSize(context) * 1.1,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Overlays Rive (loading check + confetti) — compartidos por ambas orientaciones
  List<Widget> _buildRiveOverlays(BuildContext context) {
    return [
      if (isShowLoading)
        Positioned.fill(
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                height: 100,
                width: 100,
                child: RiveAnimation.asset(
                  'assets/RiveAssets/check.riv',
                  fit: BoxFit.cover,
                  onInit: _onCheckRiveInit,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      if (isShowConfetti)
        Positioned.fill(
          child: Column(
            children: [
              const Spacer(),
              SizedBox(
                height: 100,
                width: 100,
                child: Transform.scale(
                  scale: 6,
                  child: RiveAnimation.asset(
                    'assets/RiveAssets/confetti.riv',
                    fit: BoxFit.cover,
                    onInit: _onConfettiRiveInit,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_lastLoginUser != null)
                SlideInAnimation(
                  duration: const Duration(milliseconds: 500),
                  begin: const Offset(0, 0.3),
                  curve: Curves.easeOutCubic,
                  child: Text(
                    '¡Bienvenido/a, $_lastLoginUser!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: ResponsiveUtils.subtitleFontSize(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Spacer(flex: 2),
            ],
          ),
        ),
    ];
  }

  /// Botones sociales
  Widget _buildSocialButtons(BuildContext context) {
    final buttonSize = ResponsiveUtils.valueByDevice(
      context: context,
      mobile: 48.0,
      tablet: 56.0,
      largeTablet: 64.0,
      desktop: 72.0,
    );
    final spacing = ResponsiveUtils.cardSpacing(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.horizontalPadding(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SlideInAnimation(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 1100),
              begin: const Offset(-0.3, 0),
              child: HoverScaleEffect(
                scale: 1.1,
                child: _socialButton(
                  buttonSize: buttonSize,
                  icon: Icon(
                    FontAwesomeIcons.google,
                    size: buttonSize * 0.4,
                    color: const Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
          Flexible(
            child: ScaleInAnimation(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 1200),
              curve: Curves.easeOutBack,
              child: HoverScaleEffect(
                scale: 1.1,
                child: _socialButton(
                  buttonSize: buttonSize,
                  icon: Icon(
                    Icons.facebook,
                    size: buttonSize * 0.4,
                    color: const Color(0xFF3B5998),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: spacing),
          Flexible(
            child: SlideInAnimation(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 1300),
              begin: const Offset(0.3, 0),
              child: HoverScaleEffect(
                scale: 1.1,
                child: _socialButton(
                  buttonSize: buttonSize,
                  icon: Icon(
                    FontAwesomeIcons.twitter,
                    size: buttonSize * 0.4,
                    color: const Color(0xFF1DA1F2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({required Widget icon, required double buttonSize}) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE6E9EF)),
      ),
      child: Center(child: icon),
    );
  }
}
