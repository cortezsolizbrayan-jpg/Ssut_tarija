import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';
import 'package:refactor_template/features/sistema/providers/notificaciones_provider.dart';

class _ItemNotificacion {
  _ItemNotificacion({
    required this.title,
    required this.message,
    required this.time,
    required this.wasUnread,
    this.isRead = false,
  });

  final String title;
  final String message;
  final String time;
  final bool wasUnread;
  bool isRead;
}

class NotificacionesPantalla extends ConsumerStatefulWidget {
  static const name = 'notificaciones';
  const NotificacionesPantalla({super.key});

  @override
  ConsumerState<NotificacionesPantalla> createState() =>
      _NotificacionesPantallaState();
}

class _NotificacionesPantallaState extends ConsumerState<NotificacionesPantalla> {
  late List<_ItemNotificacion> _items;

  @override
  void initState() {
    super.initState();
    _items = [
      _ItemNotificacion(
        title: 'Nuevo programa disponible',
        message:
            'Se ha agregado un nuevo diplomado a tu lista de programas.',
        time: 'Hace 2 horas',
        wasUnread: true,
      ),
      _ItemNotificacion(
        title: 'Recordatorio de pago',
        message: 'Tu prÃ³ximo pago vence el 15 de este mes.',
        time: 'Hace 1 dÃ­a',
        wasUnread: true,
      ),
      _ItemNotificacion(
        title: 'ActualizaciÃ³n de documentos',
        message: 'Tus documentos han sido revisados y aprobados.',
        time: 'Hace 3 dÃ­as',
        wasUnread: false,
        isRead: true,
      ),
      _ItemNotificacion(
        title: 'Bienvenido al sistema',
        message: 'Gracias por unirte a Posgrado UPEA.',
        time: 'Hace 1 semana',
        wasUnread: false,
        isRead: true,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ref.read(notificacionesProvider.notifier).clear();
      if (!mounted) return;
      setState(() {
        for (final i in _items) {
          i.isRead = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = ResponsiveUtils.horizontalPadding(context);
    final spacing = ResponsiveUtils.cardSpacing(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            elevation: 0,
            backgroundColor: const Color(0xFF005BAC),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 48, bottom: 14, right: 16),
              title: Text(
                'Notificaciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ResponsiveUtils.subtitleFontSize(context),
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF005BAC),
                      Color(0xFF003F7A),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 48),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      size: 72,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(pad, 20, pad, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return FadeInDown(
                      duration: const Duration(milliseconds: 420),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: spacing),
                        child: Text(
                          'Centro de avisos',
                          style: TextStyle(
                            fontSize: ResponsiveUtils.bodyFontSize(context) * 1.05,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A2744),
                          ),
                        ),
                      ),
                    );
                  }
                  final i = index - 1;
                  if (i >= _items.length) return null;
                  final item = _items[i];
                  return FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: 60 * i),
                    from: 28,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: _buildNotificationItem(context, item),
                    ),
                  );
                },
                childCount: 1 + _items.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    _ItemNotificacion item,
  ) {
    final isRead = item.isRead;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.cardBorderRadius(context),
        ),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : const Color(0xFF005BAC),
          width: isRead ? 1 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            width: ResponsiveUtils.cardSpacing(context),
            height: ResponsiveUtils.cardSpacing(context),
            margin: EdgeInsets.only(
              top: 6,
              right: ResponsiveUtils.cardSpacing(context),
            ),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isRead ? Colors.transparent : const Color(0xFFFFC107),
              border: isRead
                  ? Border.all(color: Colors.grey.shade300)
                  : null,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.bodyFontSize(context) * 1.14,
                    fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                    color: const Color(0xFF005BAC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.bodyFontSize(context),
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.time,
                  style: TextStyle(
                    fontSize: ResponsiveUtils.bodyFontSize(context) * 0.86,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



