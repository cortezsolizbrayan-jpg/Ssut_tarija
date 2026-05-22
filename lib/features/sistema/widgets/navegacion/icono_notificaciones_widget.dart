import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/providers/notificaciones_provider.dart';

/// Widget reutilizable para el icono de notificaciones con badge
class NotificationIconWidget extends ConsumerStatefulWidget {
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color iconColor;

  const NotificationIconWidget({
    super.key,
    this.size = 50,
    this.iconSize = 28,
    this.backgroundColor = const Color(0xFFF0F7FF),
    this.iconColor = const Color(0xFF005BAC),
  });

  @override
  ConsumerState<NotificationIconWidget> createState() =>
      _NotificationIconWidgetState();
}

class _NotificationIconWidgetState
    extends ConsumerState<NotificationIconWidget> {
  @override
  Widget build(BuildContext context) {
    final notificationCount = ref.watch(notificacionesCountProvider);
    final hasNotifications = notificationCount > 0;

    return GestureDetector(
      onTap: () {
        // No limpiar aquí — se marcan como leídas al abrir la pantalla
        if (!context.mounted) return;
        context.push('/notificaciones');
      },
      child: Stack(
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasNotifications
                  ? const LinearGradient(
                      colors: [Color(0xFF005BAC), Color(0xFF64B5F6)],
                    )
                  : null,
              color: hasNotifications ? null : widget.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: hasNotifications
                      ? const Color(0xFF005BAC).withOpacity(0.4)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                  spreadRadius: hasNotifications ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              Icons.notifications_rounded,
              color: hasNotifications ? Colors.white : widget.iconColor,
              size: widget.iconSize,
            ),
          ),
          if (hasNotifications)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: widget.size * 0.4,
                height: widget.size * 0.4,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red,
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    notificationCount > 9 ? '9+' : '$notificationCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: widget.size * 0.22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
