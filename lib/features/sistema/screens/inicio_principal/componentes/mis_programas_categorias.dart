import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mapa horizontal de etapas / programas con Rive, scroll al seleccionar y
/// conectores animados. Los iconos Rive usan [icons.riv] igual que el menÃº
/// lateral (`StateMachineController` + input booleano `active`).
class MisProgramasCategories extends StatefulWidget {
  const MisProgramasCategories({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<Map<String, dynamic>> categories;
  final int selectedCategory;
  final ValueChanged<int> onCategorySelected;

  @override
  State<MisProgramasCategories> createState() => _MisProgramasCategoriesState();
}

class _MisProgramasCategoriesState extends State<MisProgramasCategories>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final ScrollController _scrollController;
  late final AnimationController _flowController;
  late final AnimationController _waveController;
  late List<GlobalKey> _nodeKeys;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    // Reducir duración para menos frames por ciclo
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();
    _nodeKeys = List.generate(
      math.max(1, widget.categories.length),
      (_) => GlobalKey(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  // Pausar animaciones cuando la app va a segundo plano
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flowController.stop();
      _waveController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _flowController.repeat();
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(MisProgramasCategories oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _flowController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!mounted) return;
    final key = _nodeKeys[widget.selectedCategory];
    final context = key.currentContext;
    if (context == null) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final scrollable =
        _scrollController.position.context.storageContext.findRenderObject()
            as RenderBox?;
    if (scrollable == null) return;
    final offset = position.dx - (scrollable.size.width - box.size.width) / 2;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final PantallaWidth = MediaQuery.of(context).size.width;
    final isTablet = PantallaWidth > 600;
    final iconSize = isTablet ? 56.0 : 44.0;
    final iconInner = iconSize * 0.5;
    final labelMaxWidth = iconSize * 2.2;

    // Espaciado entre nodos
    final spacing = iconSize * 0.5; // Reducido para parecer mÃ¡s conectados
    final lineWidth = spacing * 0.6; // LÃ­nea mÃ¡s corta, no toca los cÃ­rculos
    final lineHeight = 3.0;
    return SizedBox(
      height: iconSize * 1.9, // espacio para icono + etiqueta + animaciÃ³n
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: spacing),
        children: List.generate(widget.categories.length, (index) {
          final category = widget.categories[index];
          final isSelected = widget.selectedCategory == index;
          final isLast = index == widget.categories.length - 1;
          final bool esActivo = (category['activo'] as bool?) ?? false;
          // 40% para seleccionado, 60% para completado â†’ siempre hay espacio para ondas
          final waterLevel = esActivo ? (isSelected ? 0.40 : 0.60) : 0.0;
          final isCompleted =
              waterLevel > 0; // Conector activo si hay agua en este nodo

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KeyedSubtree(
                key: _nodeKeys[index],
                child: _CategoryMapNode(
                  category: category,
                  isSelected: isSelected,
                  iconSize: iconSize,
                  iconInnerSize: iconInner,
                  PantallaWidth: PantallaWidth,
                  labelMaxWidth: labelMaxWidth,
                  waveAnimation: _waveController,
                  waterLevel: waterLevel,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onCategorySelected(index);
                  },
                ),
              ),
              if (!isLast)
                Padding(
                  padding: EdgeInsets.only(top: iconSize * 0.42),
                  child: _FlowingConnector(
                    animation: _flowController,
                    lineWidth: lineWidth,
                    lineHeight: lineHeight,
                    // Color del conector = color del nodo DESTINO (siguiente)
                    accent: widget.categories[index + 1]['color'] as Color,
                    isCompleted: isCompleted,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}

/// Nodo del mapa de progreso acadÃ©mico: cÃ­rculo con icono Rive, borde
/// y onda de agua interna cuando estÃ¡ activo.
class _CategoryMapNode extends StatefulWidget {
  const _CategoryMapNode({
    required this.category,
    required this.isSelected,
    required this.iconSize,
    required this.iconInnerSize,
    required this.PantallaWidth,
    required this.labelMaxWidth,
    required this.waveAnimation,
    required this.waterLevel,
    required this.onTap,
  });

  final Map<String, dynamic> category;
  final bool isSelected;
  final double iconSize;
  final double iconInnerSize;
  final double PantallaWidth;
  final double labelMaxWidth;
  final Animation<double> waveAnimation;
  final double waterLevel;
  final VoidCallback onTap;

  @override
  State<_CategoryMapNode> createState() => _CategoryMapNodeState();
}

class _CategoryMapNodeState extends State<_CategoryMapNode>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.selectionClick();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category['color'] as Color;
    final label = widget.category['label'] as String;
    final icon = widget.category['icon'] as IconData;

    return GestureDetector(
      onTap: _onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // CÃ­rculo con icono y agua
            Stack(
              alignment: Alignment.center,
              children: [
                // CÃ­rculo de fondo
                Container(
                  width: widget.iconSize,
                  height: widget.iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
                // Onda de agua (solo si waterLevel > 0)
                if (widget.waterLevel > 0)
                  Positioned.fill(
                    child: ClipOval(
                      child: CustomPaint(
                        painter: _WavePainter(
                          animation: widget.waveAnimation,
                          waterLevel: widget.waterLevel,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                // Icono centrado
                Icon(
                  icon,
                  size: widget.iconInnerSize,
                  color: widget.isSelected
                      ? color
                      : Colors.white.withValues(alpha: 0.9),
                ),
                // Borde seleccionado
                if (widget.isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 3),
                      ),
                    ),
                  ),
                // Brillo hover
                if (_isHovered && !widget.isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Etiqueta
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.labelMaxWidth),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: widget.isSelected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: widget.isSelected ? color : Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter de ondas de agua dentro del cÃ­rculo
class _WavePainter extends CustomPainter {
  final Animation<double> animation;
  final double waterLevel; // 0.0 = vacÃ­o, 1.0 = lleno
  final Color color;

  _WavePainter({
    required this.animation,
    required this.waterLevel,
    required this.color,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (waterLevel <= 0) return;

    final fillY = size.height * (1.0 - waterLevel);
    final amplitude = size.width * 0.25;
    final freq = 0.02;

    final path = Path();
    path.moveTo(0, fillY);

    for (double x = 0; x <= size.width; x += 1) {
      final y =
          fillY +
          amplitude * math.sin(freq * x + animation.value * 2 * math.pi);
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0.7),
          color.withOpacity(0.9),
          color.withOpacity(1.0),
          color.withOpacity(0.9),
          color.withOpacity(0.7),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.animation.value != animation.value || old.waterLevel != waterLevel;
}

/// Conector animado entre nodos - muestra agua fluyendo cuando estÃ¡ activo.
/// El color es el del nodo DESTINO para indicar hacia dÃ³nde va el progreso.
class _FlowingConnector extends StatelessWidget {
  const _FlowingConnector({
    required this.animation,
    required this.lineWidth,
    required this.lineHeight,
    required this.accent,
    required this.isCompleted,
  });

  final Animation<double> animation;
  final double lineWidth;
  final double lineHeight;
  final Color accent; // Color del nodo destino
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final h = lineHeight * 2.5;

    return SizedBox(
      width: lineWidth,
      height: h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(h / 2),
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            if (!isCompleted) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(h / 2),
                ),
              );
            }

            final t = animation.value;
            return Stack(
              children: [
                Container(color: accent.withValues(alpha: 0.18)),
                CustomPaint(
                  size: Size(lineWidth, h),
                  painter: _ConnectorWaterPainter(progress: t, color: accent),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: accent.withValues(alpha: 0.4),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 1,
                    color: accent.withValues(alpha: 0.4),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ConnectorWaterPainter extends CustomPainter {
  const _ConnectorWaterPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0.45),
          color.withValues(alpha: 0.95),
          color.withValues(alpha: 0.65),
        ],
        stops: const [0.0, 0.5, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bodyPaint);

    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..isAntiAlias = true;

    final yMid = size.height * 0.52;
    final amp = size.height * 0.16;
    final wavePath = Path()..moveTo(0, yMid);
    for (double x = 0; x <= size.width; x += 1) {
      final phase = (x / size.width) * (2 * math.pi) + (progress * 2 * math.pi);
      wavePath.lineTo(x, yMid + math.sin(phase) * amp);
    }
    canvas.drawPath(wavePath, wavePaint);

    final flowGlow = Paint()
      ..shader =
          LinearGradient(
            colors: [
              Colors.transparent,
              Colors.white.withValues(alpha: 0.95),
              Colors.transparent,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(
            Rect.fromLTWH(
              (size.width * progress) - (size.width * 0.35),
              0,
              size.width * 0.7,
              size.height,
            ),
          );
    canvas.drawRect(Offset.zero & size, flowGlow);
  }

  @override
  bool shouldRepaint(covariant _ConnectorWaterPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
