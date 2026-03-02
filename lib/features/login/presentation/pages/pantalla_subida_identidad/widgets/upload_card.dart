import 'dart:io';
import 'package:flutter/material.dart';
import 'package:refactor_template/core/services/servicio_ocr_blinkid.dart';

/// Widget de tarjeta para subir imágenes de documentos
class UploadCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final File? imageFile;
  final VoidCallback onTap;
  final bool isValidating;
  final bool isFrontCard;

  const UploadCard({
    super.key,
    required this.title,
    required this.icon,
    this.imageFile,
    required this.onTap,
    this.isValidating = false,
    required this.isFrontCard,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF305BA4);
    const Color textDark = Color(0xFF1A3A5C);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: imageFile != null ? primaryBlue : const Color(0xFFEEF2F6),
            width: imageFile != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: textDark.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageFile != null)
                Image.file(imageFile!, fit: BoxFit.cover)
              else
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryBlue.withOpacity(0.08),
                        primaryBlue.withOpacity(0.14),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              if (imageFile != null) Container(color: Colors.black26),
              if (imageFile != null)
                const Center(
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              if (imageFile != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.8),
                    radius: 16,
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: primaryBlue,
                    ),
                  ),
                ),
              if (imageFile == null)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 40, color: primaryBlue.withOpacity(0.5)),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isFrontCard && BlinkIdOcrService.isEnabled
                          ? 'Pulsa para escanear o subir'
                          : 'Pulsa para tomar foto o subir',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              if (isValidating)
                Positioned(
                  top: 12,
                  right: 12,
                  child: AnimatedOpacity(
                    opacity: isValidating ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(primaryBlue),
                        ),
                      ),
                    ),
                  ),
                ),
              if (imageFile == null)
                Positioned(
                  bottom: 14,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFrontCard
                            ? Icons.credit_card
                            : Icons.flip_camera_android,
                        color: primaryBlue.withOpacity(0.7),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isFrontCard
                              ? (BlinkIdOcrService.isEnabled
                                  ? 'Toca para escanear o cargar el anverso'
                                  : 'Toca para cargar el anverso')
                              : 'Toca para cargar el reverso',
                          style: TextStyle(
                            color: primaryBlue.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
