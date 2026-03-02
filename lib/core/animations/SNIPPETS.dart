/*
// ═══════════════════════════════════════════════════════════════════════════
// 🎨 SNIPPETS RÁPIDOS DE ANIMACIONES Y TRANSICIONES
// Sistema de Posgrado UPEA
// ═══════════════════════════════════════════════════════════════════════════

// 📦 IMPORTS NECESARIOS:
// ───────────────────────────────────────────────────────────────────────────
// import 'package:refactor_template/core/animations/animations.dart';
// import 'package:refactor_template/core/animations/page_transitions.dart';
// import 'package:go_router/go_router.dart'; // Para GoRouter

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣ ANIMACIÓN DE CARD BÁSICA
// ═══════════════════════════════════════════════════════════════════════════

SlideInAnimation(
  delay: Duration(milliseconds: 100),
  child: Card(
    child: ListTile(
      title: Text('Mi Card'),
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣ CARD CON HOVER EFFECT
// ═══════════════════════════════════════════════════════════════════════════

HoverScaleEffect(
  scale: 1.05,
  elevation: 8.0,
  child: Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Card Interactiva'),
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣ BOTÓN ANIMADO COMPLETO
// ═══════════════════════════════════════════════════════════════════════════

ScaleInAnimation(
  delay: Duration(milliseconds: 500),
  curve: Curves.easeOutBack,
  child: HoverScaleEffect(
    scale: 1.1,
    child: ElevatedButton(
      onPressed: () {},
      child: Text('ACCEDER'),
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 4️⃣ LISTA CON EFECTO STAGGER
// ═══════════════════════════════════════════════════════════════════════════

StaggeredListAnimation(
  delay: Duration(milliseconds: 100),
  children: [
    ProgramaCard(programa1),
    ProgramaCard(programa2),
    ProgramaCard(programa3),
  ],
)

// O con map:
StaggeredListAnimation(
  delay: Duration(milliseconds: 80),
  children: programas.map((p) => ProgramaCard(p)).toList(),
)

// ═══════════════════════════════════════════════════════════════════════════
// 5️⃣ ENTRADA DE PANTALLA COMPLETA
// ═══════════════════════════════════════════════════════════════════════════

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // Header
        SlideInAnimation(
          delay: Duration(milliseconds: 100),
          begin: Offset(0, -0.5),
          child: AppBar(title: Text('Título')),
        ),
        
        // Contenido
        SlideInAnimation(
          delay: Duration(milliseconds: 300),
          begin: Offset(0, 0.3),
          child: ContentWidget(),
        ),
        
        // Botón inferior
        ScaleInAnimation(
          delay: Duration(milliseconds: 500),
          child: ActionButton(),
        ),
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 6️⃣ GRID ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) {
    return SlideInAnimation(
      delay: Duration(milliseconds: index * 100),
      child: HoverScaleEffect(
        child: ItemCard(items[index]),
      ),
    );
  },
)

// ═══════════════════════════════════════════════════════════════════════════
// 7️⃣ LOADING CON SHIMMER
// ═══════════════════════════════════════════════════════════════════════════

ShimmerLoading(
  child: Column(
    children: [
      Container(
        height: 20,
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8),
        color: Colors.white,
      ),
      Container(
        height: 20,
        width: 200,
        margin: EdgeInsets.only(bottom: 8),
        color: Colors.white,
      ),
      Container(
        height: 100,
        width: double.infinity,
        color: Colors.white,
      ),
    ],
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 8️⃣ NOTIFICACIÓN CON PULSE
// ═══════════════════════════════════════════════════════════════════════════

Stack(
  children: [
    Icon(Icons.notifications),
    Positioned(
      top: 0,
      right: 0,
      child: PulseAnimation(
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    ),
  ],
)

// ═══════════════════════════════════════════════════════════════════════════
// 9️⃣ NAVEGACIÓN CON TRANSICIÓN PERSONALIZADA
// ═══════════════════════════════════════════════════════════════════════════

// ── Opción 1: Con extensión (RECOMENDADO) ──────────────────────────────────
// Slide + Fade (más común)
context.pushSlideFade(DetallePage());

// Desde la derecha
context.pushSlideRight(DetallePage());

// Desde abajo (modal style)
context.pushSlideBottom(DetallePage());

// Desde arriba
context.pushSlideTop(DetallePage());

// Desde la izquierda
context.pushSlideLeft(DetallePage());

// Fade simple
context.pushFade(DetallePage());

// Scale (zoom in)
context.pushScale(DetallePage());

// Con opciones personalizadas
context.pushSlideFade(
  DetallePage(),
  begin: Offset(0.5, 0.0), // Desde más lejos
  duration: Duration(milliseconds: 500), // Más lento
  curve: Curves.easeOutBack, // Con rebote
);

// Expansión desde un punto (útil para FAB)
context.pushExpandFrom(
  DetallePage(),
  alignment: Alignment.bottomRight, // Desde donde expandir
);

// Diagonal (dinámico)
context.pushDiagonal(
  DetallePage(),
  begin: Offset(1.0, -1.0), // Desde esquina superior derecha
);

// ── Opción 2: Manual con PageTransitions ───────────────────────────────────
Navigator.of(context).push(
  PageTransitions.slideFromRight(DetallePage()),
);

Navigator.of(context).push(
  PageTransitions.slideFade(
    DetallePage(),
    begin: Offset(0.3, 0.0),
    duration: Duration(milliseconds: 400),
  ),
);

// ── Opción 3: Con GoRouter ──────────────────────────────────────────────────
// Navegación simple
context.go('/detalle');
context.push('/detalle');

// Con parámetros
context.go('/detalle?id=123');
context.push('/detalle', extra: {'id': 123});

// ═══════════════════════════════════════════════════════════════════════════
// 🔟 FORMULARIO CON ANIMACIONES ESCALONADAS
// ═══════════════════════════════════════════════════════════════════════════

Form(
  child: Column(
    children: [
      SlideInAnimation(
        delay: Duration(milliseconds: 100),
        child: TextFormField(
          decoration: InputDecoration(labelText: 'Nombre'),
        ),
      ),
      SlideInAnimation(
        delay: Duration(milliseconds: 200),
        child: TextFormField(
          decoration: InputDecoration(labelText: 'Email'),
        ),
      ),
      SlideInAnimation(
        delay: Duration(milliseconds: 300),
        child: TextFormField(
          decoration: InputDecoration(labelText: 'Password'),
        ),
      ),
      ScaleInAnimation(
        delay: Duration(milliseconds: 400),
        child: ElevatedButton(
          onPressed: () {},
          child: Text('Enviar'),
        ),
      ),
    ],
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣1️⃣ HERO HEADER CON MÚLTIPLES ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════

Stack(
  children: [
    // Background
    SlideInAnimation(
      begin: Offset(0, -0.3),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF005BAC), Color(0xFF0080E0)],
          ),
        ),
      ),
    ),
    
    // Ícono
    Positioned.fill(
      child: ScaleInAnimation(
        delay: Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        child: Center(
          child: Icon(Icons.school, size: 80, color: Colors.white),
        ),
      ),
    ),
    
    // Título
    Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: SlideInAnimation(
        delay: Duration(milliseconds: 500),
        begin: Offset(0, 0.5),
        child: Text(
          'Posgrado UPEA',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    ),
  ],
)

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣2️⃣ CARD DE DIPLOMADO (Ejemplo Completo)
// ═══════════════════════════════════════════════════════════════════════════

class DiplomadoCardAnimated extends StatelessWidget {
  final Diplomado diplomado;
  final int index;

  const DiplomadoCardAnimated({
    required this.diplomado,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInAnimation(
      delay: Duration(milliseconds: index * 100),
      begin: Offset(0, 0.3),
      child: HoverScaleEffect(
        scale: 1.03,
        elevation: 8.0,
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => context.pushSlideFade(
              DetalleDiplomadoPage(diplomado: diplomado),
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ScaleInAnimation(
                        delay: Duration(milliseconds: (index * 100) + 200),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(0xFF005BAC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diplomado.titulo,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              diplomado.tipo,
                              style: TextStyle(
                                color: Color(0xFFFFC900),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    diplomado.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16),
                          SizedBox(width: 4),
                          Text('${diplomado.duracion} meses'),
                        ],
                      ),
                      Icon(Icons.arrow_forward, color: Color(0xFF005BAC)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣3️⃣ MODAL BOTTOM SHEET ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

void showAnimatedBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => SlideInAnimation(
      begin: Offset(0, 0.3),
      duration: Duration(milliseconds: 300),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Opciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              // ... más contenido
            ],
          ),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣4️⃣ FLOATING ACTION BUTTON ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

floatingActionButton: ScaleInAnimation(
  delay: Duration(milliseconds: 800),
  curve: Curves.elasticOut,
  child: HoverScaleEffect(
    scale: 1.15,
    child: FloatingActionButton(
      onPressed: () {},
      backgroundColor: Color(0xFFFFC900),
      child: Icon(Icons.add),
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣5️⃣ SNACKBAR PERSONALIZADO CON ANIMACIÓN
// ═══════════════════════════════════════════════════════════════════════════

void showAnimatedSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SlideInAnimation(
        begin: Offset(-0.3, 0),
        duration: Duration(milliseconds: 300),
        child: Row(
          children: [
            ScaleInAnimation(
              duration: Duration(milliseconds: 400),
              child: Icon(Icons.check_circle, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣6️⃣ LOADING STATES CON ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════

// Loading con shimmer
ShimmerLoading(
  child: Column(
    children: [
      Container(height: 20, width: double.infinity, color: Colors.white),
      SizedBox(height: 8),
      Container(height: 20, width: 200, color: Colors.white),
    ],
  ),
)

// Loading con pulse
PulseAnimation(
  child: CircularProgressIndicator(),
)

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣7️⃣ ERROR STATES CON ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════

ScaleInAnimation(
  curve: Curves.elasticOut,
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.red),
    ),
    child: Column(
      children: [
        Icon(Icons.error_outline, color: Colors.red),
        SizedBox(height: 8),
        Text('Error al cargar datos'),
      ],
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣8️⃣ SUCCESS STATES CON ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════

ScaleInAnimation(
  delay: Duration(milliseconds: 200),
  curve: Curves.elasticOut,
  child: Container(
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.green.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.green),
    ),
    child: Row(
      children: [
        Icon(Icons.check_circle, color: Colors.green),
        SizedBox(width: 8),
        Text('¡Operación exitosa!'),
      ],
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 1️⃣9️⃣ EMPTY STATES CON ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════

Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    ScaleInAnimation(
      delay: Duration(milliseconds: 100),
      child: Icon(Icons.inbox_outlined, size: 80, color: Colors.grey),
    ),
    SizedBox(height: 16),
    SlideInAnimation(
      delay: Duration(milliseconds: 300),
      begin: Offset(0, 0.3),
      child: Text(
        'No hay elementos',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    SizedBox(height: 8),
    SlideInAnimation(
      delay: Duration(milliseconds: 400),
      begin: Offset(0, 0.3),
      child: Text('Intenta agregar algunos elementos'),
    ),
  ],
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣0️⃣ REFRESH INDICATOR ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

RefreshIndicator(
  onRefresh: () async {
    // Tu lógica de refresh
    await Future.delayed(Duration(seconds: 2));
  },
  child: ListView(
    children: [
      // Tu contenido
    ],
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 📚 CHEATSHEET COMPLETO
// ═══════════════════════════════════════════════════════════════════════════

/*

═══════════════════════════════════════════════════════════════════════════
ANIMACIONES BÁSICAS DE WIDGETS
═══════════════════════════════════════════════════════════════════════════

SlideInAnimation    → Deslizamiento + Fade (desde cualquier dirección)
ScaleInAnimation    → Zoom con rebote (entrada suave)
HoverScaleEffect    → Hover interactivo (escala al pasar el mouse/toque)
PulseAnimation      → Pulso continuo (para notificaciones, badges)
RotateAnimation     → Rotación continua (spinners, iconos)
ShimmerLoading      → Skeleton loading (estados de carga)
StaggeredListAnimation → Lista con animación escalonada

═══════════════════════════════════════════════════════════════════════════
TRANSICIONES DE PÁGINA
═══════════════════════════════════════════════════════════════════════════

context.pushSlideFade()      → Slide + Fade (MÁS COMÚN)
context.pushSlideRight()     → Desde la derecha
context.pushSlideBottom()    → Desde abajo (modal style)
context.pushSlideTop()       → Desde arriba
context.pushSlideLeft()      → Desde la izquierda
context.pushFade()           → Solo fade
context.pushScale()          → Zoom in
context.pushExpandFrom()     → Expansión desde un punto
context.pushDiagonal()       → Deslizamiento diagonal
context.pushRotate3D()       → Rotación 3D (especial)

═══════════════════════════════════════════════════════════════════════════
DURACIONES RECOMENDADAS
═══════════════════════════════════════════════════════════════════════════

Hover/Toque:           150-250ms   → Respuesta inmediata
Micro-interacciones:   250-350ms   → Botones, iconos
Entrada de elementos:  400-600ms   → Cards, listas
Entrada de pantalla:   600-800ms   → Transiciones de página
Animaciones complejas: 800-1200ms  → Onboarding, splash

═══════════════════════════════════════════════════════════════════════════
CURVAS DE ANIMACIÓN
═══════════════════════════════════════════════════════════════════════════

ENTRADA (aparecer):
──────────────────
Curves.easeOutCubic      → Suave y natural (RECOMENDADO)
Curves.easeOutQuart      → Rápido y fluido
Curves.easeOutBack       → Con rebote sutil
Curves.elasticOut        → Rebote exagerado (divertido)

SALIDA (desaparecer):
────────────────────
Curves.easeInCubic       → Suave
Curves.easeInQuart       → Rápido

AMBAS DIRECCIONES:
─────────────────
Curves.easeInOutCubic    → Equilibrado (RECOMENDADO)
Curves.easeInOutQuart    → Más rápido
Curves.linear            → Constante (pocas veces)

═══════════════════════════════════════════════════════════════════════════
DELAYS RECOMENDADOS (STAGGER EFFECT)
═══════════════════════════════════════════════════════════════════════════

Header/Navbar:          100-300ms
Título principal:       200-400ms
Contenido principal:    300-500ms
Lista de items:         index * 80-100ms
Botones de acción:      500-700ms
Footer:                 600-800ms

Ejemplo stagger:
────────────────
for (int i = 0; i < items.length; i++) {
  SlideInAnimation(
    delay: Duration(milliseconds: i * 100),
    child: ItemCard(items[i]),
  );
}

═══════════════════════════════════════════════════════════════════════════
CASOS DE USO COMUNES
═══════════════════════════════════════════════════════════════════════════

NAVEGACIÓN:
───────────
• Detalles de item      → context.pushSlideFade()
• Modales               → context.pushSlideBottom()
• Configuración         → context.pushSlideRight()
• Búsqueda              → context.pushFade()

LISTAS:
───────
• Grid de items         → StaggeredListAnimation
• Lista vertical        → SlideInAnimation con delay
• Búsqueda/Filter       → ScaleInAnimation

FORMULARIOS:
────────────
• Campos de entrada     → SlideInAnimation (escalonado)
• Botón submit          → ScaleInAnimation (último)
• Validación            → PulseAnimation (error)

ESTADOS:
────────
• Loading               → ShimmerLoading
• Error                 → ScaleInAnimation + elasticOut
• Success               → ScaleInAnimation + check icon
• Empty                 → SlideInAnimation + icon

═══════════════════════════════════════════════════════════════════════════
MEJORES PRÁCTICAS
═══════════════════════════════════════════════════════════════════════════

✅ HAZ:
───────
• Usa animaciones consistentes en toda la app
• Mantén duraciones cortas (< 500ms para interacciones)
• Usa stagger para listas (mejora percepción de velocidad)
• Anima solo elementos importantes (no todo)
• Usa Curves.easeOutCubic para entradas
• Prueba en dispositivos reales (no solo emulador)

❌ NO HAGAS:
────────────
• No animes todo a la vez (sobrecarga visual)
• No uses duraciones > 1000ms (excepto casos especiales)
• No uses Curves.elasticOut en todo (cansado)
• No animes elementos fuera de pantalla
• No uses animaciones en scroll rápido
• No olvides probar en dispositivos lentos

═══════════════════════════════════════════════════════════════════════════
PERFORMANCE TIPS
═══════════════════════════════════════════════════════════════════════════

• Usa AnimatedBuilder para animaciones complejas
• Evita setState() en cada frame de animación
• Usa RepaintBoundary para widgets complejos
• Prefiere Transform sobre Positioned para animaciones
• Usa const constructors cuando sea posible
• Limita el número de animaciones simultáneas

═══════════════════════════════════════════════════════════════════════════
*/

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣1️⃣ ANIMACIÓN CONDICIONAL (Mostrar/Ocultar)
// ═══════════════════════════════════════════════════════════════════════════

// Mostrar widget con animación cuando cambia un estado
AnimatedSwitcher(
  duration: Duration(milliseconds: 300),
  transitionBuilder: (child, animation) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0, 0.1),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  },
  child: isLoading
      ? CircularProgressIndicator(key: ValueKey('loading'))
      : ContentWidget(key: ValueKey('content')),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣2️⃣ LISTA CON ANIMACIÓN AL AGREGAR/ELIMINAR ITEMS
// ═══════════════════════════════════════════════════════════════════════════

ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return SlideInAnimation(
      delay: Duration(milliseconds: index * 50),
      begin: Offset(0.3, 0),
      child: Dismissible(
        key: Key(items[index].id),
        onDismissed: (direction) {
          setState(() {
            items.removeAt(index);
          });
        },
        child: ItemCard(items[index]),
      ),
    );
  },
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣3️⃣ SEARCH BAR ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOutCubic,
  width: isSearching ? MediaQuery.of(context).size.width : 200,
  child: TextField(
    decoration: InputDecoration(
      hintText: 'Buscar...',
      prefixIcon: Icon(Icons.search),
      suffixIcon: isSearching
          ? IconButton(
              icon: Icon(Icons.close),
              onPressed: () => setState(() => isSearching = false),
            )
          : null,
    ),
    onTap: () => setState(() => isSearching = true),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣4️⃣ CARD DE PROGRAMA CON ANIMACIÓN COMPLETA
// ═══════════════════════════════════════════════════════════════════════════

class ProgramaCardAnimated extends StatelessWidget {
  final Programa programa;
  final int index;
  final VoidCallback onTap;

  const ProgramaCardAnimated({
    required this.programa,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SlideInAnimation(
      delay: Duration(milliseconds: index * 100),
      begin: Offset(0, 0.3),
      child: HoverScaleEffect(
        scale: 1.02,
        elevation: 4.0,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () {
              // Animación de feedback
              HapticFeedback.lightImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con icono animado
                  Row(
                    children: [
                      ScaleInAnimation(
                        delay: Duration(milliseconds: (index * 100) + 200),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xFF1A3A5C),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              programa.nombre,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              programa.tipo,
                              style: TextStyle(
                                color: Color(0xFFFFC900),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Descripción
                  Text(
                    programa.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 12),
                  // Footer con info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('${programa.duracion} meses'),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF1A3A5C),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣5️⃣ BOTÓN DE ACCIÓN FLOTANTE CON ANIMACIÓN
// ═══════════════════════════════════════════════════════════════════════════

floatingActionButton: ScaleInAnimation(
  delay: Duration(milliseconds: 600),
  curve: Curves.elasticOut,
  child: HoverScaleEffect(
    scale: 1.15,
    child: FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.pushExpandFrom(
          NuevaInscripcionPage(),
          alignment: Alignment.bottomRight,
        );
      },
      backgroundColor: Color(0xFFFFC900),
      icon: Icon(Icons.add, color: Colors.white),
      label: Text(
        'Inscribirse',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣6️⃣ TAB BAR CON INDICADOR ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

DefaultTabController(
  length: 3,
  child: Column(
    children: [
      TabBar(
        tabs: [
          Tab(text: 'Diplomados'),
          Tab(text: 'Especialidades'),
          Tab(text: 'Maestrías'),
        ],
        indicatorColor: Color(0xFF1A3A5C),
        labelColor: Color(0xFF1A3A5C),
        unselectedLabelColor: Colors.grey,
      ),
      Expanded(
        child: TabBarView(
          children: [
            // Contenido con animación al cambiar tab
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: DiplomadosList(key: ValueKey('diplomados')),
            ),
            // ... otros tabs
          ],
        ),
      ),
    ],
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣7️⃣ PROGRESS INDICATOR ANIMADO
// ═══════════════════════════════════════════════════════════════════════════

// Barra de progreso con animación suave
AnimatedContainer(
  duration: Duration(milliseconds: 500),
  curve: Curves.easeOutCubic,
  width: MediaQuery.of(context).size.width * (progress / 100),
  height: 4,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Color(0xFF1A3A5C), Color(0xFF4DB5FF)],
    ),
    borderRadius: BorderRadius.circular(2),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣8️⃣ CHIP/TAG ANIMADO CON ELIMINACIÓN
// ═══════════════════════════════════════════════════════════════════════════

Wrap(
  spacing: 8,
  children: filtros.map((filtro) {
    return ScaleInAnimation(
      delay: Duration(milliseconds: filtros.indexOf(filtro) * 50),
      child: Chip(
        label: Text(filtro),
        deleteIcon: Icon(Icons.close, size: 18),
        onDeleted: () {
          setState(() {
            filtros.remove(filtro);
          });
        },
        backgroundColor: Color(0xFF1A3A5C),
        labelStyle: TextStyle(color: Colors.white),
      ),
    );
  }).toList(),
)

// ═══════════════════════════════════════════════════════════════════════════
// 2️⃣9️⃣ EXPANDIBLE/Collapsible CON ANIMACIÓN
// ═══════════════════════════════════════════════════════════════════════════

ExpansionTile(
  leading: ScaleInAnimation(
    child: Icon(Icons.info_outline, color: Color(0xFF1A3A5C)),
  ),
  title: Text('Información del Programa'),
  children: [
    SlideInAnimation(
      begin: Offset(0, -0.2),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(programa.detalleCompleto),
      ),
    ),
  ],
)

// O con AnimatedContainer para más control:
bool isExpanded = false;

GestureDetector(
  onTap: () => setState(() => isExpanded = !isExpanded),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOutCubic,
    height: isExpanded ? 200 : 60,
    child: Column(
      children: [
        // Header siempre visible
        ListTile(
          title: Text('Título'),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: Duration(milliseconds: 300),
            child: Icon(Icons.expand_more),
          ),
        ),
        // Contenido expandible
        if (isExpanded)
          SlideInAnimation(
            begin: Offset(0, -0.2),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Contenido expandible'),
            ),
          ),
      ],
    ),
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣0️⃣ SPLASH SCREEN CON ANIMACIÓN
// ═══════════════════════════════════════════════════════════════════════════

class SplashScreenAnimated extends StatefulWidget {
  @override
  _SplashScreenAnimatedState createState() => _SplashScreenAnimatedState();
}

class _SplashScreenAnimatedState extends State<SplashScreenAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      // Navegar después de la animación
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          context.go('/home');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A3A5C),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logoposgrado.jpg',
                      width: 150,
                      height: 150,
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Sistema de Posgrado',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣1️⃣ PULL TO REFRESH CON ANIMACIÓN PERSONALIZADA
// ═══════════════════════════════════════════════════════════════════════════

RefreshIndicator(
  onRefresh: () async {
    // Mostrar animación de carga
    setState(() => isLoading = true);
    
    await Future.delayed(Duration(seconds: 2));
    
    // Actualizar datos
    await loadData();
    
    setState(() => isLoading = false);
  },
  color: Color(0xFF1A3A5C),
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return SlideInAnimation(
        delay: Duration(milliseconds: index * 50),
        child: ItemCard(items[index]),
      );
    },
  ),
)

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣2️⃣ TOAST/SNACKBAR PERSONALIZADO MEJORADO
// ═══════════════════════════════════════════════════════════════════════════

void showCustomSnackBar(
  BuildContext context,
  String message, {
  bool isSuccess = true,
  Duration duration = const Duration(seconds: 3),
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SlideInAnimation(
        begin: Offset(-0.3, 0),
        duration: Duration(milliseconds: 300),
        child: Row(
          children: [
            ScaleInAnimation(
              duration: Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? Colors.green : Colors.red,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: EdgeInsets.all(16),
      duration: duration,
    ),
  );
}

// Uso:
// showCustomSnackBar(context, 'Operación exitosa', isSuccess: true);
// showCustomSnackBar(context, 'Error al guardar', isSuccess: false);

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣3️⃣ LOADING OVERLAY CON ANIMACIÓN
// ═══════════════════════════════════════════════════════════════════════════

void showLoadingOverlay(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (context) => ScaleInAnimation(
      curve: Curves.elasticOut,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A3A5C)),
              ),
              SizedBox(height: 16),
              Text(
                'Cargando...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣4️⃣ GRID RESPONSIVE CON ANIMACIONES
// ═══════════════════════════════════════════════════════════════════════════

LayoutBuilder(
  builder: (context, constraints) {
    final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
    
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: programas.length,
      itemBuilder: (context, index) {
        return SlideInAnimation(
          delay: Duration(milliseconds: index * 80),
          begin: Offset(0, 0.3),
          child: HoverScaleEffect(
            scale: 1.05,
            child: ProgramaCard(programas[index]),
          ),
        );
      },
    );
  },
)

// ═══════════════════════════════════════════════════════════════════════════
// 3️⃣5️⃣ BOTÓN CON ESTADOS ANIMADOS (Loading, Success, Error)
// ═══════════════════════════════════════════════════════════════════════════
//
// ⚠️ IMPORTANTE: Este código es un SNIPPET de ejemplo.
// Para usarlo, cópialo a un archivo .dart con los siguientes imports:
//
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart'; // Para HapticFeedback (opcional)
//
// El linter mostrará errores aquí porque este archivo no tiene imports.
// Esto es NORMAL en archivos de snippets/documentación.

// ═══════════════════════════════════════════════════════════════════════════
// CÓDIGO DEL SNIPPET (copiar a tu archivo con imports):
// ═══════════════════════════════════════════════════════════════════════════

/*
enum ButtonState { idle, loading, success, error }

class AnimatedButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const AnimatedButton({
    required this.onPressed,
    required this.text,
  });

  @override
  _AnimatedButtonState createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  ButtonState _state = ButtonState.idle;

  void _handlePress() async {
    setState(() => _state = ButtonState.loading);
    
    try {
      await widget.onPressed();
      setState(() => _state = ButtonState.success);
      
      await Future.delayed(Duration(milliseconds: 1500));
      setState(() => _state = ButtonState.idle);
    } catch (e) {
      setState(() => _state = ButtonState.error);
      
      await Future.delayed(Duration(milliseconds: 2000));
      setState(() => _state = ButtonState.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (_state) {
      case ButtonState.loading:
        return ElevatedButton(
          key: ValueKey('loading'),
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF1A3A5C),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        );
      case ButtonState.success:
        return ElevatedButton(
          key: ValueKey('success'),
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Éxito!', style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      case ButtonState.error:
        return ElevatedButton(
          key: ValueKey('error'),
          onPressed: _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Reintentar', style: TextStyle(color: Colors.white)),
            ],
          ),
        );
      default:
        return ElevatedButton(
          key: ValueKey('idle'),
          onPressed: _handlePress,
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFC900),
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: Text(
            widget.text,
            style: TextStyle(
              color: Color(0xFF1A3A5C),
              fontWeight: FontWeight.bold,
            ),
          ),
        );
    }
  }
}
*/

// ═══════════════════════════════════════════════════════════════════════════
// 🎯 FIN DE SNIPPETS
// ═══════════════════════════════════════════════════════════════════════════
*/
