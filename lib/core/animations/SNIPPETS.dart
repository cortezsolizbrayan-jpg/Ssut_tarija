// ═══════════════════════════════════════════════════════════════════════════
// 🎨 SNIPPETS RÁPIDOS DE ANIMACIONES
// Sistema de Posgrado UPEA
// ═══════════════════════════════════════════════════════════════════════════

// IMPORTANTE: Importar primero
// import 'package:refactor_template/core/animations/animations.dart';

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

// 
// 9️⃣ NAVEGACIÓN CON TRANSICIÓN PERSONALIZADA
// ═══════════════════════════════════════════════════════════════════════════

// Opción 1: Con extensión
context.pushSlideFade(DetallePage());

// Opción 2: Manual
Navigator.of(context).push(
  PageTransitions.slideFromRight(DetallePage()),
);

// Opción 3: Con GoRouter (requiere configuración adicional)
context.go('/detalle');

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
// 📚 CHEATSHEET RÁPIDO
// ═══════════════════════════════════════════════════════════════════════════

/*

ANIMACIONES BÁSICAS:
───────────────────
SlideInAnimation    → Slide + Fade
ScaleInAnimation    → Zoom con rebote
HoverScaleEffect    → Hover interactivo
PulseAnimation      → Pulso continuo
RotateAnimation     → Rotación continua
ShimmerLoading      → Skeleton loading

TRANSICIONES:
────────────
context.pushSlideFade()
context.pushSlideRight()
context.pushScale()

DURACIONES:
──────────
- Hover: 150-250ms
- Micro-interacciones: 250-350ms
- Entrada de elementos: 400-600ms
- Entrada de pantalla: 600-800ms

CURVAS COMUNES:
──────────────
- Entrada: Curves.easeOutCubic
- Salida: Curves.easeInCubic
- Rebote: Curves.elasticOut
- Suave: Curves.easeInOutCubic
- Rápido: Curves.easeOutQuart

DELAYS RECOMENDADOS:
───────────────────
- Header: 100-300ms
- Contenido: 300-500ms
- Acciones: 500-700ms
- Lista stagger: index * 80-100ms

*/

// ═══════════════════════════════════════════════════════════════════════════
// 🎯 FIN DE SNIPPETS
// ═══════════════════════════════════════════════════════════════════════════
