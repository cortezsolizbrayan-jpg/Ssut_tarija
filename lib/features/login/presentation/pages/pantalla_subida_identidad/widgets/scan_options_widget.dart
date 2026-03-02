import 'package:flutter/material.dart';
import 'package:refactor_template/core/services/servicio_ocr_blinkid.dart';
import 'package:refactor_template/config/constants/design_tokens.dart';
import 'package:refactor_template/core/animations/enhanced_animations.dart';

/// Widget que muestra las opciones de escaneo disponibles con animaciones
class ScanOptionsWidget extends StatelessWidget {
  final VoidCallback onBlinkIdScan;
  final VoidCallback onScanbotScan;
  final VoidCallback onMlKitOcrScan;
  final VoidCallback onManualUpload;
  final bool isProcessing;
  final bool isScanbotProcessing;
  final bool isMlKitOcrProcessing;

  const ScanOptionsWidget({
    super.key,
    required this.onBlinkIdScan,
    required this.onScanbotScan,
    required this.onMlKitOcrScan,
    required this.onManualUpload,
    this.isProcessing = false,
    this.isScanbotProcessing = false,
    this.isMlKitOcrProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: DesignTokens.normalAnimation,
      curve: DesignTokens.defaultCurve,
      padding: const EdgeInsets.all(DesignTokens.extraLarge),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
        boxShadow: DesignTokens.defaultCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header animado
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(DesignTokens.small),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.medium),
                ),
                child: const Icon(
                  Icons.document_scanner,
                  color: DesignTokens.primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: DesignTokens.medium),
              const Text(
                'Opciones de Escaneo',
                style: DesignTokens.cardTitle,
              ),
            ],
          ).fadeSlideIn(index: 0),
          
          const SizedBox(height: DesignTokens.large),
          
          const Text(
            'Elige la mejor opción para escanear tu carnet de identidad:',
            style: DesignTokens.cardSubtitle,
          ).fadeSlideIn(index: 0, delay: Duration(milliseconds: 50)),
          
          const SizedBox(height: DesignTokens.xxl),

          // Opciones de escaneo con animaciones escalonadas
          _buildScanOption(
            context: context,
            title: 'BlinkID Scanner',
            subtitle: 'Escaneo automático inteligente (Recomendado)',
            icon: Icons.auto_awesome,
            color: DesignTokens.primaryBlue,
            isEnabled: BlinkIdOcrService.isEnabled && !isProcessing,
            isProcessing: isProcessing,
            onTap: onBlinkIdScan,
            isRecommended: true,
          ).fadeSlideIn(index: 1),


          const SizedBox(height: DesignTokens.medium),

          _buildScanOption(
            context: context,
            title: 'Scanbot Scanner',
            subtitle: 'Escaneo de documentos con detección de bordes',
            icon: Icons.camera_alt,
            color: DesignTokens.lightBlue,
            isEnabled: !isScanbotProcessing,
            isProcessing: isScanbotProcessing,
            onTap: onScanbotScan,
          ).fadeSlideIn(index: 3),

          const SizedBox(height: DesignTokens.medium),

          _buildScanOption(
            context: context,
            title: 'OCR ML Kit avanzado',
            subtitle: 'Reconocimiento de texto mejorado con preprocesamiento',
            icon: Icons.text_fields,
            color: const Color(0xFF4CAF50),
            isEnabled: !isMlKitOcrProcessing && !isProcessing,
            isProcessing: isMlKitOcrProcessing,
            onTap: onMlKitOcrScan,
          ).fadeSlideIn(index: 4),

          const SizedBox(height: DesignTokens.xxl),
          
          // Separador animado
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: DesignTokens.defaultBorder,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.large),
                child: Text(
                  'O',
                  style: DesignTokens.infoLabel.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: DesignTokens.defaultBorder,
                ),
              ),
            ],
          ).fadeSlideIn(index: 4),

          const SizedBox(height: DesignTokens.xxl),

          // Opción manual
          _buildManualOption(
            context: context,
            onTap: onManualUpload,
          ).fadeSlideIn(index: 5),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isEnabled,
    required bool isProcessing,
    required VoidCallback onTap,
    bool isRecommended = false,
    VoidCallback? onTapWhenDisabled,
  }) {
    return AnimatedButton(
      onTap: isEnabled ? onTap : (onTapWhenDisabled ?? () {}),
      backgroundColor: isEnabled ? DesignTokens.cardBackground : DesignTokens.inputBackground,
      borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isRecommended ? color : DesignTokens.defaultBorder,
            width: isRecommended ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
          boxShadow: isRecommended ? [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : [],
        ),
        padding: const EdgeInsets.all(DesignTokens.large),
        child: Row(
          children: [
            // Icono animado
            AnimatedContainer(
              duration: DesignTokens.normalAnimation,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(isEnabled ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
                border: Border.all(
                  color: color.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: isProcessing
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ).pulse(),
                      ),
                    )
                  : Icon(
                      icon,
                      color: isEnabled ? color : color.withOpacity(0.5),
                      size: 24,
                    ),
            ),
            const SizedBox(width: DesignTokens.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: DesignTokens.infoValue.copyWith(
                            fontSize: 16,
                            color: isEnabled ? DesignTokens.primaryText : DesignTokens.secondaryText,
                          ),
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: DesignTokens.small),
                        AnimatedContainer(
                          duration: DesignTokens.normalAnimation,
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.small,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(DesignTokens.medium),
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'RECOMENDADO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              fontFamily: DesignTokens.primaryFont,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: DesignTokens.extraSmall),
                  Text(
                    subtitle,
                    style: DesignTokens.cardSubtitle.copyWith(
                      color: isEnabled ? DesignTokens.secondaryText : DesignTokens.lightText,
                    ),
                  ),
                  if (!isEnabled && !BlinkIdOcrService.isEnabled && title == 'BlinkID Scanner') ...[
                    const SizedBox(height: DesignTokens.extraSmall),
                    Text(
                      'Configura las licencias en el archivo .env',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                        fontStyle: FontStyle.italic,
                        fontFamily: DesignTokens.primaryFont,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.small),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isEnabled ? DesignTokens.secondaryText : DesignTokens.lightText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualOption({
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return AnimatedButton(
      onTap: onTap,
      backgroundColor: DesignTokens.cardBackground,
      borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: DesignTokens.defaultBorder),
          borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
        ),
        padding: const EdgeInsets.all(DesignTokens.large),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: DesignTokens.inputBackground,
                borderRadius: BorderRadius.circular(DesignTokens.largeRadius),
                border: Border.all(
                  color: DesignTokens.defaultBorder,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.upload_file,
                color: DesignTokens.secondaryText,
                size: 24,
              ),
            ),
            const SizedBox(width: DesignTokens.large),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subir Manualmente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.primaryText,
                      fontFamily: DesignTokens.primaryFont,
                    ),
                  ),
                  SizedBox(height: DesignTokens.extraSmall),
                  Text(
                    'Toma fotos con tu cámara o sube desde galería',
                    style: DesignTokens.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: DesignTokens.small),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: DesignTokens.secondaryText,
            ),
          ],
        ),
      ),
    );
  }
}