import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen>
    with SingleTickerProviderStateMixin {
  // Controla las rotaciones de cada medalla
  final List<double> _medalTurns = List<double>.filled(5, 0.0);

  // Animación suave de rebote para la mascota central
  late final AnimationController _mascotController;
  late final Animation<double> _mascotOffset;

  // Ángulo actual de giro del grupo de medallas (ruleta)
  double _wheelAngle = 0;

  void _rotateMedal(int index) {
    setState(() {
      _medalTurns[index] += 1; // una vuelta completa
    });
  }

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _mascotOffset = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _mascotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header azul con curva
            _buildHeader(context),
            // Sección de medallas con mascota
            _buildAchievementsCircle(),
            // Footer azul con CEUB
            _buildFooter(context),
            // Logo JQ19
            _buildBottomLogo(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00448A), // azul más profundo arriba
            Color(0xFF0F7BD7), // azul medio
            Color(0xFF0B5FB4), // azul intenso abajo
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(200),
          bottomRight: Radius.circular(200),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Barra de estado simulada (hora y estado de red)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '9:41 am',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.wifi, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Icon(Icons.battery_full, color: Colors.white, size: 18),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Primera fila: Logo, Banco Union, Notificaciones, Avatar
              Row(
                children: [
                  // Logo
                  Expanded(
                    child: Image.asset(
                      'assets/images/logoposgrado.png',
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Banco Union
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.credit_card,
                          size: 16,
                          color: Color(0xFF1A3A5C),
                        ),
                        SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BANCO UNION',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A3A5C),
                              ),
                            ),
                            Text(
                              'Número de cuenta único',
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Notificaciones
                  Stack(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E293B), Color(0xFF64748B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              '2',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // Configuración
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Avatar
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage(
                        'assets/icons/profile_img.png',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Nombre del usuario
              const Text(
                'Guadalupe Flores Mamani',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Botón "Ver Mis Programas"
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/diplomados');
                  },
                  style: ElevatedButton.styleFrom(
                    elevation: 10,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF004080),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    shadowColor: Colors.black.withOpacity(0.25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF004080),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Ver Mis Programas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsCircle() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F4F8).withOpacity(0.5),
            borderRadius: BorderRadius.circular(200),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Banner "Descuentos Especiales"
              Positioned(top: 0, child: _buildDiscountBanner()),
              // Círculo contenedor de medallas
              SizedBox(
                width: 340,
                height: 340,
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      // Ajusta el factor para controlar la sensibilidad del giro
                      _wheelAngle += details.delta.dx * 0.01;
                    });
                  },
                  child: Stack(
                    children: [
                      // Grupo de medallas que gira como ruleta
                      Transform.rotate(
                        angle: _wheelAngle,
                        child: Stack(
                          children: [
                            // Medalla dorada (Maestría) - izquierda arriba
                            Positioned(
                              left: 10,
                              top: 40,
                              child: _buildMedal(
                                0,
                                'assets/images/grupodorado.png',
                              ),
                            ),
                            // Medalla plateada - derecha arriba
                            Positioned(
                              right: 10,
                              top: 40,
                              child: _buildMedal(
                                1,
                                'assets/images/grupodiplomado.png',
                              ),
                            ),
                            // Medalla plateada - izquierda medio
                            Positioned(
                              left: 0,
                              top: 160,
                              child: _buildMedal(
                                2,
                                'assets/images/grupoplomo.png',
                              ),
                            ),
                            // Medalla plateada - derecha medio
                            Positioned(
                              right: 0,
                              top: 160,
                              child: _buildMedal(
                                3,
                                'assets/images/grupoespecialidad.png',
                              ),
                            ),
                            // Medalla plateada - abajo (único posdoctorado)
                            Positioned(
                              left: 90,
                              bottom: 20,
                              child: _buildMedal(
                                4,
                                'assets/images/grupoplomo.png',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Mascota en el centro (no gira, solo rebota)
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Círculo azul con mascota (con animación de rebote)
                              AnimatedBuilder(
                                animation: _mascotController,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _mascotOffset.value),
                                    child: child,
                                  );
                                },
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF87CEEB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Emoji feliz (representa la mascota)
                                      const Text(
                                        '🎓',
                                        style: TextStyle(fontSize: 80),
                                      ),
                                      // Manos levantadas
                                      Positioned(
                                        left: 0,
                                        top: 40,
                                        child: Text(
                                          '✋',
                                          style: TextStyle(
                                            fontSize: 30,
                                            color: Colors.blue.shade300,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 40,
                                        child: Text(
                                          '✋',
                                          style: TextStyle(
                                            fontSize: 30,
                                            color: Colors.blue.shade300,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.touch_app, size: 16, color: Colors.blueGrey),
            SizedBox(width: 6),
            Text(
              'Arrastra las medallas para girar',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscountBanner() {
    return Transform.rotate(
      angle: -0.1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            // Imagen de \"Descuentos Especiales\" provista en assets
            'assets/images/descuentos .png',
            height: 90,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildMedal(int index, String assetPath) {
    return GestureDetector(
      onTap: () => _rotateMedal(index),
      child: Transform.rotate(
        // Compensa el giro de la ruleta para que la medalla siempre se vea derecha
        angle: -_wheelAngle,
        child: AnimatedRotation(
          turns: _medalTurns[index],
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Imagen de medalla (grupos dorado, diplomado, especialidad, plomo)
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(assetPath, fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        // Degradado azul similar al banner de referencia (CEUB)
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color(0xFF4DB5FF), // azul claro izquierda
            Color(0xFF0861C4), // azul intenso derecha
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0861C4).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Busca Nuestros Programas Certificados y',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Registrados por la CEUB',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Logo CEUB
              // Logo CEUB
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/ceub.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Botón estilo tarjeta blanca como en el diseño de referencia
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF004080),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono dentro de pastilla azul
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF004080),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.fact_check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Verificar programas',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomLogo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/19.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              '"Democratizando la educación superior, por encargo social"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Parisienne',
                color: Colors.black87,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
