import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:refactor_template/core/widgets/skeleton_loader.dart';

/// Widget optimizado para cargar imágenes
/// Usa caché para imágenes de red y optimiza memoria
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    // Validar dimensiones para evitar Infinity/NaN
    final safeWidth = (width != null && width!.isFinite && !width!.isNaN) ? width : null;
    final safeHeight = (height != null && height!.isFinite && !height!.isNaN) ? height : null;
    final cacheWidth = safeWidth?.toInt();
    final cacheHeight = safeHeight?.toInt();

    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      // Imagen de red con caché
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: safeWidth,
        height: safeHeight,
        fit: fit,
        memCacheWidth: cacheWidth,
        memCacheHeight: cacheHeight,
        placeholder: (context, url) =>
            placeholder ??
            SkeletonLoader(
              width: safeWidth ?? double.infinity,
              height: safeHeight ?? 200,
            ),
        errorWidget: (context, url, error) =>
            errorWidget ??
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      );
    } else if (imageUrl.startsWith('assets/')) {
      // Imagen de assets
      imageWidget = Image.asset(
        imageUrl,
        width: safeWidth,
        height: safeHeight,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ??
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
      );
    } else {
      // Imagen local (archivo)
      imageWidget = Image.file(
        File(imageUrl),
        width: safeWidth,
        height: safeHeight,
        fit: fit,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ??
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.error_outline, color: Colors.grey),
            ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Widget optimizado para avatares circulares
class OptimizedAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final Color? backgroundColor;

  const OptimizedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey[200],
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorWidget: Icon(
            Icons.person,
            size: radius,
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }
}
