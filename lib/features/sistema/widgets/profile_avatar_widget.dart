import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/local_storage_service.dart';

/// Widget reutilizable para mostrar el avatar del usuario
/// Carga automáticamente la foto de perfil guardada o muestra la imagen por defecto
class ProfileAvatarWidget extends StatefulWidget {
  final double radius;
  final bool showShadow;
  final VoidCallback? onTap;

  const ProfileAvatarWidget({
    super.key,
    this.radius = 22,
    this.showShadow = true,
    this.onTap,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (mounted) {
      setState(() {
        _profileImage = imageFile;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar imagen cuando se vuelve a la pantalla
    _loadProfileImage();
  }

  /// Método público para recargar la imagen (útil cuando se guarda una nueva)
  void reloadImage() {
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: widget.radius,
      backgroundColor: Colors.white,
      backgroundImage: _profileImage != null
          ? FileImage(_profileImage!)
          : const AssetImage('assets/icons/profile_img.png') as ImageProvider,
      onBackgroundImageError: (_, __) {
        // Si hay error cargando la imagen, usar icono por defecto
        if (mounted) {
          setState(() {
            _profileImage = null;
          });
        }
      },
      child: _profileImage == null
          ? null
          : null, // Si hay imagen, no mostrar icono
    );

    // Si no hay imagen guardada, mostrar icono por defecto
    if (_profileImage == null) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: widget.radius - 2,
          backgroundImage: const AssetImage('assets/icons/profile_img.png'),
          onBackgroundImageError: (_, __) {},
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[300],
            ),
            child: Icon(Icons.person, color: Colors.grey, size: widget.radius),
          ),
        ),
      );
    }

    Widget result = widget.showShadow
        ? Container(
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
            child: avatar,
          )
        : avatar;

    if (widget.onTap != null) {
      return GestureDetector(
        onTap: widget.onTap ?? () => context.push('/mis-datos-personales'),
        child: result,
      );
    }

    return result;
  }
}
