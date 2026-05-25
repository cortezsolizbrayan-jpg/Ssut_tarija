import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../../../config/constants/design_tokens.dart';
import '../../../../../../core/utils/responsive_utils.dart';

class IdentityUploadCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final File? file;
  final VoidCallback onTap;
  final bool isPdfMode;
  final bool isProcessing;
  final String scanningMessage;
  final AnimationController scanController;
  final Widget pdfPreview;

  const IdentityUploadCard({
    super.key,
    required this.title,
    required this.icon,
    this.file,
    required this.onTap,
    this.isPdfMode = false,
    this.isProcessing = false,
    this.scanningMessage = 'Analizando...',
    required this.scanController,
    required this.pdfPreview,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color darkBlue = Color(0xFF1A3A5C);

    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: ResponsiveUtils.docCardHeight(context),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: file != null ? primaryBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              _buildContent(),
              if (isProcessing) _buildOverlay(darkBlue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color darkBlue = Color(0xFF1A3A5C);

    if (file != null) {
      return isPdfMode
          ? pdfPreview
          : Image.file(
              file!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              key: ValueKey(file!.path),
            );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 45, color: primaryBlue.withAlpha(128)),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Toca para capturar',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(Color darkBlue) {
    return Container(
      decoration: BoxDecoration(
        color: darkBlue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          _ScannerLine(controller: scanController),
          _StatusText(message: scanningMessage),
        ],
      ),
    );
  }
}

class _ScannerLine extends StatelessWidget {
  final AnimationController controller;
  const _ScannerLine({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, hijo) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            const barH = 35.0;
            const minBarW = 120.0;
            const maxBarW = 220.0;

            final barW = maxW <= (minBarW + 10) ? maxW - 10 : maxW.clamp(minBarW, maxBarW);
            final dx = (maxW - barW) * controller.value;

            return Align(
              alignment: Alignment.center,
              child: Transform.translate(
                offset: Offset(dx - (maxW - barW) / 2, 0),
                child: SizedBox(
                  width: barW,
                  height: barH,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          DesignTokens.primaryBlueLight.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusText extends StatelessWidget {
  final String message;
  const _StatusText({required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

