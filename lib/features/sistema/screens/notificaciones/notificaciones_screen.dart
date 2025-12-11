import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/features/sistema/providers/notificaciones_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  static const name = 'notificaciones';
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen> {
  @override
  void initState() {
    super.initState();
    // Marcar notificaciones como leídas cuando se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(notificacionesProvider);
      state.count = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3A5C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(width * 0.05),
        children: [
          _buildNotificationItem(
            context,
            title: 'Nuevo programa disponible',
            message:
                'Se ha agregado un nuevo diplomado a tu lista de programas.',
            time: 'Hace 2 horas',
            isRead: false,
          ),
          _buildNotificationItem(
            context,
            title: 'Recordatorio de pago',
            message: 'Tu próximo pago vence el 15 de este mes.',
            time: 'Hace 1 día',
            isRead: false,
          ),
          _buildNotificationItem(
            context,
            title: 'Actualización de documentos',
            message: 'Tus documentos han sido revisados y aprobados.',
            time: 'Hace 3 días',
            isRead: true,
          ),
          _buildNotificationItem(
            context,
            title: 'Bienvenido al sistema',
            message: 'Gracias por unirte a Posgrado UPEA.',
            time: 'Hace 1 semana',
            isRead: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context, {
    required String title,
    required String message,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : const Color(0xFF1A3A5C),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRead ? Colors.transparent : const Color(0xFFFFC900),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    color: const Color(0xFF1A3A5C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
