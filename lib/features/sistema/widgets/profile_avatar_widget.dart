import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/servicio_almacenamiento_local.dart';

/// Widget reutilizable para mostrar el avatar del usuario
/// Carga automáticamente la foto de perfil guardada o muestra la imagen por defecto
class ProfileAvatarWidget extends StatefulWidget {
  final double radius;
  final bool showShadow;
  final VoidCallback? onTap;

  const ProfileAvatarWidget({
    super.key,
    this.radius = 24, // Aumentado de 22 a 24 para mejor visibilidad
    this.showShadow = true,
    this.onTap,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> with RouteAware {
  File? _profileImage;
  String? _lastLoadedPath;
  DateTime? _lastModified;

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
        _lastLoadedPath = imageFile?.path;
        _lastModified = imageFile?.existsSync() == true ? imageFile!.lastModifiedSync() : null;
      });
    }
  }

  @override
  void didUpdateWidget(ProfileAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndReloadImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar imagen cuando se vuelve a la pantalla o cambian las dependencias
    _checkAndReloadImage();
  }

  Future<void> _checkAndReloadImage() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (!mounted) return;
    
    // Solo actualizar si cambió el path, si no teníamos imagen antes, o si cambió la fecha de modificación
    final newPath = imageFile?.path;
    final newModified = imageFile?.existsSync() == true ? imageFile!.lastModifiedSync() : null;

    if (newPath != _lastLoadedPath || newModified != _lastModified || (_profileImage == null && imageFile != null)) {
      if (imageFile != null) {
        await FileImage(imageFile).evict();
      }
      setState(() {
        _profileImage = imageFile;
        _lastLoadedPath = newPath;
        _lastModified = newModified;
      });
    }
  }

  /// Método público para recargar la imagen (útil cuando se guarda una nueva)
  void reloadImage() {
    _loadProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    // Determinar si hay imagen de perfil
    final hasProfileImage = _profileImage != null;
    
    Widget avatar;
    
    if (hasProfileImage) {
      // Si hay imagen de perfil, usar fondo blanco con borde sutil para mejor contraste
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE0E0E0), // Borde gris claro
            width: 2,
          ),
          color: Colors.white,
        ),
        child: CircleAvatar(
          key: ValueKey(_lastModified?.millisecondsSinceEpoch.toString() ?? 'profile'),
          radius: widget.radius - 2, // Ajustar por el borde
          backgroundColor: Colors.white,
          backgroundImage: FileImage(_profileImage!),
          onBackgroundImageError: (exception, stackTrace) {
            // Si hay error cargando la imagen, usar icono por defecto
            if (mounted) {
              setState(() {
                _profileImage = null;
              });
            }
          },
        ),
      );
    } else {
      // Si no hay imagen, mostrar icono por defecto con fondo blanco y borde
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF005BAC).withOpacity(0.3), // Borde azul suave
            width: 2,
          ),
          color: Colors.white,
        ),
        child: CircleAvatar(
          radius: widget.radius - 2, // Ajustar por el borde
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            size: widget.radius * 1.1, // Ligeramente más pequeño para el borde
            color: const Color(0xFF005BAC), // Azul institucional
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
                  color: Colors.black.withOpacity(0.2), // Sombra más suave
                  blurRadius: 8,
                  offset: const Offset(0, 2),
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
