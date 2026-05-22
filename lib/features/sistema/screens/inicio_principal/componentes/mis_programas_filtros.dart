import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MisProgramasFilters extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final String sortLabel;
  final VoidCallback onShowSortDialog;
  final bool isGridView;
  final VoidCallback onToggleView;
  final bool showOnlyFavorites;
  final VoidCallback onToggleFavorites;

  const MisProgramasFilters({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.sortLabel,
    required this.onShowSortDialog,
    required this.isGridView,
    required this.onToggleView,
    required this.showOnlyFavorites,
    required this.onToggleFavorites,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final PantallaWidth = MediaQuery.of(context).size.width;
            final fontSize = math.max(11.0, math.min(14.0, PantallaWidth * 0.033)).toDouble();
            final iconSize = math.max(16.0, math.min(18.0, PantallaWidth * 0.04)).toDouble();
            final paddingH = math.max(12.0, math.min(20.0, PantallaWidth * 0.045)).toDouble();
            final paddingV = math.max(6.0, math.min(8.0, PantallaWidth * 0.019)).toDouble();
            final spacing = math.max(8.0, math.min(12.0, PantallaWidth * 0.028)).toDouble();

            return SizedBox(
              height: math.max(50.0, math.min(60.0, PantallaWidth * 0.14)).toDouble(),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: math.max(16.0, math.min(20.0, PantallaWidth * 0.045)).toDouble()),
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter;
                  return Padding(
                    padding: EdgeInsets.only(right: spacing),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onFilterSelected(filter);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFC900) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFC900) : Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.grid_view,
                              color: isSelected ? Colors.black87 : Colors.grey.shade600,
                              size: iconSize,
                            ),
                            SizedBox(width: math.max(6.0, PantallaWidth * 0.015).toDouble()),
                            Flexible(
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.black87 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        // Barra de herramientas (ordenar, vista, favoritos)
        LayoutBuilder(
          builder: (context, constraints) {
            final PantallaWidth = MediaQuery.of(context).size.width;
            final paddingH = math.max(16.0, math.min(20.0, PantallaWidth * 0.045)).toDouble();
            final paddingV = math.max(6.0, math.min(8.0, PantallaWidth * 0.019)).toDouble();
            final iconSize = math.max(16.0, math.min(20.0, PantallaWidth * 0.047)).toDouble();
            final fontSize = math.max(10.0, math.min(12.0, PantallaWidth * 0.028)).toDouble();
            final buttonPaddingH = math.max(10.0, math.min(12.0, PantallaWidth * 0.028)).toDouble();
            final buttonPaddingV = math.max(6.0, math.min(8.0, PantallaWidth * 0.019)).toDouble();
            final spacing = math.max(6.0, math.min(8.0, PantallaWidth * 0.019)).toDouble();
            final iconButtonPadding = math.max(6.0, math.min(8.0, PantallaWidth * 0.019)).toDouble();

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: paddingH, vertical: paddingV),
              child: Row(
                children: [
                  // Botón de ordenar
                  Flexible(
                    child: GestureDetector(
                      onTap: onShowSortDialog,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: buttonPaddingH, vertical: buttonPaddingV),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sort, size: iconSize, color: Colors.grey.shade700),
                            SizedBox(width: spacing),
                            Flexible(
                              child: Text(
                                sortLabel,
                                style: TextStyle(fontSize: fontSize, color: Colors.grey.shade700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Botón de favoritos
                  GestureDetector(
                    onTap: onToggleFavorites,
                    child: Container(
                      padding: EdgeInsets.all(iconButtonPadding),
                      decoration: BoxDecoration(
                        color: showOnlyFavorites ? Colors.red.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: showOnlyFavorites ? Colors.red : Colors.grey.shade300),
                      ),
                      child: Icon(
                        showOnlyFavorites ? Icons.favorite : Icons.favorite_border,
                        size: iconSize,
                        color: showOnlyFavorites ? Colors.red : Colors.grey.shade700,
                      ),
                    ),
                  ),
                  SizedBox(width: spacing),
                  // Botón de vista (lista/grilla)
                  GestureDetector(
                    onTap: onToggleView,
                    child: Container(
                      padding: EdgeInsets.all(iconButtonPadding),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        isGridView ? Icons.view_list : Icons.grid_view,
                        size: iconSize,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

