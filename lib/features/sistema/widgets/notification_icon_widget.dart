import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/providers/notificaciones_provider.dart';

/// Widget reutilizable para el icono de notificaciones con badge
class NotificationIconWidget extends ConsumerStatefulWidget {
  final double size;
  final double iconSize;

  const NotificationIconWidget({super.key, this.size = 50, this.iconSize = 28});

  @override
  ConsumerState<NotificationIconWidget> createState() =>
      _NotificationIconWidgetState();
}

class _NotificationIconWidgetState
    extends ConsumerState<NotificationIconWidget> {
  @override
  Widget build(BuildContext context) {
    // Leer el estado actual del provider
    final state = ref.watch(notificacionesProvider);
    final notificationCount = state.count;
    final hasNotifications = notificationCount > 0;

    return GestureDetector(
      onTap: () {
        // Marcar como leídas antes de navegar
        state.count = 0;
        // Forzar reconstrucción
        setState(() {});
        context.push('/notificaciones').then((_) {
          // Actualizar después de volver si es necesario
          if (mounted) {
            setState(() {});
          }
        });
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
                      colors: [
                        Color(0xFFFFC107), // Amarillo dorado
                        Color(0xFF005BAC), // Naranja
                      ],
                    )
                  : null,
              color: hasNotifications ? null : Colors.white,
              boxShadow: hasNotifications
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFC107).withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(
              Icons.notifications,
              color: hasNotifications ? Colors.white : Colors.grey.shade600,
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
