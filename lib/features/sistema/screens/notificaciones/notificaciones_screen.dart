import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:refactor_template/features/sistema/providers/notificaciones_provider.dart';

class NotificacionesScreen extends ConsumerStatefulWidget {
  static const name = 'notificaciones';
  const NotificacionesScreen({super.key});

  @override
  ConsumerState<NotificacionesScreen> createState() =>
      _NotificacionesScreenState();
}

class _NotificacionesScreenState extends ConsumerState<NotificacionesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Marcar todas como leídas al abrir
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificacionesProvider.notifier).marcarTodasLeidas();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(notificacionesProvider);

    final todas = state.items;
    final noLeidas = todas.where((n) => !n.leida).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005BAC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
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
        actions: [
          if (todas.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: isDark ? const Color(0xFF1A2E47) : Colors.white,
              onSelected: (value) {
                HapticFeedback.selectionClick();
                if (value == 'leer_todas') {
                  ref.read(notificacionesProvider.notifier).marcarTodasLeidas();
                } else if (value == 'limpiar_leidas') {
                  ref.read(notificacionesProvider.notifier).limpiarLeidas();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'leer_todas',
                  child: Row(
                    children: [
                      Icon(
                        Icons.done_all,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Marcar todas como leídas',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'limpiar_leidas',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.delete_sweep_outlined,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Eliminar leídas',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFC900),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: [
            Tab(text: 'Todas (${todas.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No leídas'),
                  if (noLeidas.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC900),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${noLeidas.length}',
                        style: const TextStyle(
                          color: Color(0xFF0D1730),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: state.cargando
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF005BAC)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _ListaNotificaciones(items: todas, isDark: isDark),
                _ListaNotificaciones(items: noLeidas, isDark: isDark),
              ],
            ),
    );
  }
}

// ── Lista de notificaciones ───────────────────────────────────────────────────

class _ListaNotificaciones extends ConsumerWidget {
  final List<AppNotificacion> items;
  final bool isDark;

  const _ListaNotificaciones({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const _EstadoVacio();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notif = items[index];
        return _NotificacionTile(
          key: ValueKey(notif.id),
          notif: notif,
          isDark: isDark,
          onDismiss: () {
            HapticFeedback.mediumImpact();
            ref.read(notificacionesProvider.notifier).eliminar(notif.id);
          },
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(notificacionesProvider.notifier).marcarLeida(notif.id);
            _navegarDesdePayload(context, notif.payload);
          },
        );
      },
    );
  }

  void _navegarDesdePayload(BuildContext context, String? payload) {
    if (payload == null) return;
    switch (payload) {
      case 'perfil_incompleto':
        context.push('/mis-datos-personales');
        break;
      case 'programas_vigentes':
        context.push('/programas-vigentes');
        break;
      case 'inscripcion_exitosa':
      case 'inscripcion_aprobada':
        context.push('/diplomados');
        break;
      case 'recordatorio_comprobante':
      case 'pago_recibido':
        context.push('/mis-documentos-personales');
        break;
    }
  }
}

// ── Tile de notificación con swipe ────────────────────────────────────────────

class _NotificacionTile extends StatelessWidget {
  final AppNotificacion notif;
  final bool isDark;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _NotificacionTile({
    super.key,
    required this.notif,
    required this.isDark,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(color: Colors.white, fontSize: 11),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: notif.leida
                ? (isDark ? const Color(0xFF1A2E47) : Colors.white)
                : (isDark ? const Color(0xFF1F3554) : const Color(0xFFEEF5FF)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notif.leida
                  ? (isDark ? const Color(0xFF2A4A6B) : Colors.grey.shade200)
                  : const Color(0xFF005BAC).withOpacity(0.4),
              width: notif.leida ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del tipo
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _colorTipo(notif.tipo).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconoTipo(notif.tipo),
                  color: _colorTipo(notif.tipo),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notif.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: notif.leida
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: isDark
                                  ? (notif.leida
                                        ? const Color(0xFF8BAFD4)
                                        : const Color(0xFFE8F0FA))
                                  : (notif.leida
                                        ? Colors.black54
                                        : const Color(0xFF1A2E47)),
                            ),
                          ),
                        ),
                        if (!notif.leida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF005BAC),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (notif.mensaje.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notif.mensaje,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? const Color(0xFF8BAFD4)
                              : Colors.black54,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatearFecha(notif.fecha),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF4A6A8A)
                            : Colors.grey.shade500,
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

  IconData _iconoTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.inscripcion:
        return Icons.school_rounded;
      case TipoNotificacion.pago:
        return Icons.payment_rounded;
      case TipoNotificacion.documento:
        return Icons.description_rounded;
      case TipoNotificacion.recordatorio:
        return Icons.alarm_rounded;
      case TipoNotificacion.general:
        return Icons.notifications_rounded;
    }
  }

  Color _colorTipo(TipoNotificacion tipo) {
    switch (tipo) {
      case TipoNotificacion.inscripcion:
        return const Color(0xFF005BAC);
      case TipoNotificacion.pago:
        return const Color(0xFF4CAF50);
      case TipoNotificacion.documento:
        return const Color(0xFFFF9800);
      case TipoNotificacion.recordatorio:
        return const Color(0xFF9C27B0);
      case TipoNotificacion.general:
        return const Color(0xFF607D8B);
    }
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diff = ahora.difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} días';
    return DateFormat('d MMM yyyy', 'es').format(fecha);
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF005BAC).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 56,
              color: isDark ? const Color(0xFF4DA6FF) : const Color(0xFF005BAC),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sin notificaciones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFFE8F0FA) : const Color(0xFF1A2E47),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aquí aparecerán tus alertas\nde inscripciones, pagos y documentos.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF8BAFD4) : Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
