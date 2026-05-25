import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'datos_personales_validators.dart';

class PersonalDataPerfilCard extends StatelessWidget {
  final File? profileImage;
  final String nombre;
  final String apPaterno;
  final String apMaterno;
  final String? signatureImagePath;
  final VoidCallback onTapCamera;
  final VoidCallback onTapSignature;
  final VoidCallback? onTapImage;

  const PersonalDataPerfilCard({
    super.key,
    required this.profileImage,
    required this.nombre,
    required this.apPaterno,
    required this.apMaterno,
    this.signatureImagePath,
    required this.onTapCamera,
    required this.onTapSignature,
    this.onTapImage,
  });

  String get _nombreCompleto {
    final parts = [
      nombre.trim(),
      apPaterno.trim(),
      apMaterno.trim(),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? 'Usuario de Posgrado' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, const Color(0xFFF0F4F8)],
        ),
        boxShadow: [
          BoxShadow(
            color: DatosPersonalesConstants.primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Hero(
                tag: 'avatar_hero_main',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        DatosPersonalesConstants.primaryBlue,
                        const Color(0xFF0F7BD7),
                      ],
                    ),
                  ),
                  child: GestureDetector(
                    onTap: profileImage != null ? onTapImage : onTapCamera,
                    onLongPress: onTapCamera,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: CircleAvatar(
                        key: ValueKey(
                          '${profileImage?.path ?? 'empty'}_${profileImage?.existsSync() == true ? profileImage!.lastModifiedSync().millisecondsSinceEpoch : ''}',
                        ),
                        radius: 54,
                        backgroundColor: Colors.white,
                        backgroundImage: profileImage != null
                            ? FileImage(profileImage!)
                            : null,
                        child: profileImage == null
                            ? Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: DatosPersonalesConstants.primaryBlue
                                    .withOpacity(0.2),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onTapCamera,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DatosPersonalesConstants.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _nombreCompleto,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF005BAC),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Gestione su información personal y firma digital',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              onTapSignature();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: signatureImagePath != null
                    ? const Color(0xFFE8F4F8)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: signatureImagePath != null
                      ? DatosPersonalesConstants.primaryBlue
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Icon(
                        Icons.draw_rounded,
                        color: signatureImagePath != null
                            ? DatosPersonalesConstants.primaryBlue
                            : Colors.grey.shade700,
                        size: 24,
                      ),
                      if (signatureImagePath != null)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.green,
                          size: 12,
                        ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    signatureImagePath != null
                        ? 'Firma Configurada'
                        : 'Configurar Mi Firma',
                    style: TextStyle(
                      color: signatureImagePath != null
                          ? DatosPersonalesConstants.primaryBlue
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


