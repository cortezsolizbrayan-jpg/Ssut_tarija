import 'dart:io';
import 'package:flutter/material.dart';
import '../constants.dart';

class ProfilePhotoCard extends StatelessWidget {
  final File? profilePhoto;
  final bool isBusy;
  final VoidCallback? onUpdate;

  const ProfilePhotoCard({
    super.key,
    this.profilePhoto,
    this.isBusy = false,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = profilePhoto != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MisDocumentosConstants.kCardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey.shade100,
              child: hasPhoto
                  ? Image.file(profilePhoto!, fit: BoxFit.cover)
                  : const Icon(Icons.person, color: Colors.grey, size: 40),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto de Perfil',
                  style: TextStyle(
                    fontFamily: MisDocumentosConstants.fontHeading,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: MisDocumentosConstants.kTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Foto 4x4 fondo plomo',
                  style: TextStyle(
                    fontFamily: MisDocumentosConstants.fontBody,
                    fontSize: 12,
                    color: MisDocumentosConstants.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: isBusy ? null : onUpdate,
                      icon: isBusy
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Subir Foto', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MisDocumentosConstants.kPrimaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
