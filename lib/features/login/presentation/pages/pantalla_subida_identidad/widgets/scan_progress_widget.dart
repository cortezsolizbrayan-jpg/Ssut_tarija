import 'package:flutter/material.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/animations/enhanced_animations.dart';

/// Widget que muestra el progreso del escaneo con animaciones fluidas
class ScanProgressWidget extends StatefulWidget {
  final bool isProcessing;
  final double progress;
  final String? currentStep;

  const ScanProgressWidget({
    super.key,
    required this.isProcessing,
    required this.progress,
    this.currentStep,
  });

  @override
  State<ScanProgressWidget> createState() => _ScanProgressWidgetState();
}

class _ScanProgressWidgetState extends State<ScanProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: DesignTokens.bounceCurve,
    ));

    if (widget.isProcessing) {
      _slideController.forward();
    }
  }

  @override
  void didUpdateWidget(ScanProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isProcessing != oldWidget.isProcessing) {
      if (widget.isProcessing) {
        _slideController.forward();
      } else {
        _slideController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isProcessing) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedContainer(
        duration: DesignTokens.normalAnimation,
        curve: DesignTokens.defaultCurve,
        margin: const EdgeInsets.symmetric(vertical: DesignTokens.large),
        padding: const EdgeInsets.all(DesignTokens.extraLarge),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
          border: Border.all(color: DesignTokens.primaryBlue.withOpacity(0.2)),
          boxShadow: [
            ...DesignTokens.defaultCardShadow,
            BoxShadow(
              color: DesignTokens.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: const AlwaysStoppedAnimation<Color>(DesignTokens.primaryBlue),
                      ),
                    ),
                  ),
                ).pulse(),
                const SizedBox(width: DesignTokens.large),
                const Expanded(
                  child: Text(
                    'Procesando documento...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primaryText,
                      fontFamily: DesignTokens.primaryFont,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.extraLarge),
            
            // Barra de progreso animada
            SmoothProgressIndicator(
              value: widget.progress,
              color: DesignTokens.primaryBlue,
              backgroundColor: DesignTokens.mainBackground,
              height: 8,
            ),
            
            const SizedBox(height: DesignTokens.large),
            
            // Información del paso actual con animación
            if (widget.currentStep != null)
              AnimatedSwitcher(
                duration: DesignTokens.normalAnimation,
                child: Row(
                  key: ValueKey(widget.currentStep),
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: DesignTokens.secondaryText,
                    ),
                    const SizedBox(width: DesignTokens.small),
                    Expanded(
                      child: Text(
                        widget.currentStep!,
                        style: DesignTokens.infoLabel,
                      ),
                    ),
                    TweenAnimationBuilder<int>(
                      duration: DesignTokens.slowAnimation,
                      tween: IntTween(
                        begin: 0,
                        end: (widget.progress * 100).toInt(),
                      ),
                      builder: (context, value, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(DesignTokens.medium),
                          ),
                          child: Text(
                            '$value%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: DesignTokens.primaryBlue,
                              fontFamily: DesignTokens.primaryFont,
                            ),
                          ),
                        );
                      },
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