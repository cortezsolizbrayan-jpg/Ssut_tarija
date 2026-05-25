import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/services/storage/servicio_almacenamiento_local.dart';

/// 👤 Widget DE AVATAR DE PERFIL REUTILIZABLE - V0.4.4
///
/// Widget especializado para mostrar el avatar del usuario en toda la aplicación.
/// Carga automáticamente la foto de perfil guardada o muestra un icono por defecto.
/// Incluye funcionalidades avanzadas de recarga automática y gestión de caché.
///
/// CARACTERÍSTICAS PRINCIPALES:
/// ✅ Carga automática de foto de perfil desde almacenamiento local
/// ✅ Fallback a icono por defecto si no hay foto
/// ✅ Recarga automática cuando cambia la imagen
/// ✅ Gestión inteligente de caché de imágenes
/// ✅ Sombra opcional para mejor presentación
/// ✅ Callback personalizable para interacciones
/// ✅ Diseño responsive con radio configurable
/// ✅ Colores del sistema UPEA
///
/// FUNCIONALIDADES AVANZADAS:
/// - Detección automática de cambios en la imagen de perfil
/// - Limpieza de caché cuando se actualiza la imagen
/// - Manejo robusto de errores de carga de imagen
/// - Bordes y sombras personalizables
/// - Integración con RouteAware para recargas automáticas
/// - Método público para recarga manual
///
/// ESTADOS VISUALES:
/// - Con foto: Imagen circular con borde gris claro
/// - Sin foto: Icono de persona con borde azul UPEA
/// - Con sombra: BoxShadow suave para profundidad
/// - Sin sombra: Diseño plano para contextos específicos
///
/// USO TÍPICO:
/// ```dart
/// ProfileAvatarWidget(
///   radius: 30,
///   showShadow: true,
///   onTap: () => context.push('/perfil'),
/// )
/// ```
class ProfileAvatarWidget extends StatefulWidget {
  /// Radio del avatar en píxeles (por defecto 24 para buena visibilidad)
  final double radius;

  /// Si debe mostrar sombra para dar profundidad visual
  final bool showShadow;

  /// Callback opcional para manejar toques en el avatar
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  const ProfileAvatarWidget({
    super.key,
    this.radius = 24, // Aumentado de 22 a 24 para mejor visibilidad
    this.showShadow = true,
    this.onTap,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget>
    with RouteAware {
  // 🖼️ GESTIÓN DE IMAGEN DE PERFIL
  /// Archivo de imagen de perfil actual
  File? _profileImage;

  /// Ruta de la última imagen cargada para detectar cambios
  String? _lastLoadedPath;

  /// Fecha de última modificación para detectar actualizaciones
  DateTime? _lastModified;

  /// 🚀 INICIALIZACIÓN DEL Widget
  ///
  /// Configura el estado inicial y carga la imagen de perfil.
  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// 📂 CARGAR IMAGEN DE PERFIL
  ///
  /// Carga la imagen de perfil desde el almacenamiento local y actualiza el estado.
  /// Guarda metadatos para detectar cambios futuros en la imagen.
  ///
  /// PROCESO:
  /// 1. Obtiene el archivo de imagen desde LocalStorageService
  /// 2. Verifica que el Widget esté montado antes de actualizar estado
  /// 3. Actualiza la imagen, ruta y fecha de modificación
  /// 4. Permite detección de cambios para recargas automáticas
  ///
  /// @return `Future<void>` - Operación asíncrona de carga
  Future<void> _loadProfileImage() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (mounted) {
      setState(() {
        _profileImage = imageFile;
        _lastLoadedPath = imageFile?.path;
        _lastModified = imageFile?.existsSync() == true
            ? imageFile!.lastModifiedSync()
            : null;
      });
    }
  }

  /// 🔄 ACTUALIZACIÓN DEL Widget
  ///
  /// Se ejecuta cuando el Widget padre se actualiza.
  /// Verifica si necesita recargar la imagen de perfil.
  @override
  void didUpdateWidget(ProfileAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndReloadImage();
  }

  /// 🔄 CAMBIO DE DEPENDENCIAS
  ///
  /// Se ejecuta cuando cambian las dependencias del Widget.
  /// Útil para recargar la imagen cuando se vuelve a la pantalla.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar imagen cuando se vuelve a la pantalla o cambian las dependencias
    _checkAndReloadImage();
  }

  /// 🔍 VERIFICAR Y RECARGAR IMAGEN
  ///
  /// Verifica si la imagen de perfil ha cambiado y la recarga si es necesario.
  /// Compara rutas y fechas de modificación para detectar cambios.
  ///
  /// CONDICIONES DE RECARGA:
  /// - Cambió la ruta del archivo
  /// - Cambió la fecha de modificación
  /// - No teníamos imagen antes y ahora sí hay una
  ///
  /// OPTIMIZACIONES:
  /// - Limpia el caché de la imagen anterior antes de cargar la nueva
  /// - Solo actualiza si realmente hay cambios
  /// - Verifica que el Widget esté montado antes de actualizar
  ///
  /// @return `Future<void>` - Operación asíncrona de verificación
  Future<void> _checkAndReloadImage() async {
    final imageFile = await LocalStorageService.getProfileImageFile();
    if (!mounted) return;

    // Solo actualizar si cambió el path, si no teníamos imagen antes, o si cambió la fecha de modificación
    final newPath = imageFile?.path;
    final newModified = imageFile?.existsSync() == true
        ? imageFile!.lastModifiedSync()
        : null;

    if (newPath != _lastLoadedPath ||
        newModified != _lastModified ||
        (_profileImage == null && imageFile != null)) {
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

    if (hasProfileImage && _profileImage!.existsSync()) {
      // Verificar que el archivo existe antes de intentar cargar
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
              : Border.all(color: const Color(0xFFE0E0E0), width: 1),
          color: Colors.white,
        ),
        child: CircleAvatar(
          key: ValueKey(
            _lastModified?.millisecondsSinceEpoch.toString() ?? 'profile',
          ),
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
      // Si no existe el archivo, limpiar y mostrar icono por defecto
      if (mounted && _profileImage != null) {
        _profileImage = null;
      }
      // Si no hay imagen, mostrar icono por defecto con fondo blanco y borde
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: widget.borderColor != null
              ? Border.all(color: widget.borderColor!, width: widget.borderWidth)
              : Border.all(color: const Color(0xFF005BAC).withOpacity(0.3), width: 1),
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

    if (widget.onTap != null || !hasProfileImage) {
      return GestureDetector(
        onTap:
            widget.onTap ??
            () {
              // Si no hay foto, invitar a completar el perfil académico
              context.push('/mis-datos-personales');
            },
        child: result,
      );
    }

    return result;
  }
}

