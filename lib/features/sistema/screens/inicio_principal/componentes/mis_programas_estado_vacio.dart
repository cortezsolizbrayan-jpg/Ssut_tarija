import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:refactor_template/core/utils/responsive_utils.dart';

class MisProgramasEmptyState extends StatelessWidget {
  const MisProgramasEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context) * 1.5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(ResponsiveUtils.horizontalPadding(context)),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade200,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.workspace_premium,
                size: ResponsiveUtils.largeIconSize(context) * 1.2,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: ResponsiveUtils.verticalPadding(context) * 1.5),
            Text(
              '¡Aún no tienes programas!',
              style: TextStyle(
                fontSize: ResponsiveUtils.titleFontSize(context),
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.cardSpacing(context)),
            Text(
              'Inscríbete a un programa para comenzar a ganar medallas y avanzar en tu carrera profesional.',
              style: TextStyle(
                fontSize: ResponsiveUtils.bodyFontSize(context),
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveUtils.verticalPadding(context) * 2),
            ElevatedButton.icon(
              onPressed: () => context.go('/sistema/programas-vigentes'),
              icon: Icon(Icons.add_circle_outline, size: ResponsiveUtils.mediumIconSize(context)),
              label: Text(
                'Explorar Programas',
                style: TextStyle(
                  fontSize: ResponsiveUtils.subtitleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A3A5C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

