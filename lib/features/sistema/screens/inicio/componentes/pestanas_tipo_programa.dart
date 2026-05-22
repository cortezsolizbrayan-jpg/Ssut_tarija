import 'package:flutter/material.dart';

enum ProgramTypeTab { todos, diplomado, maestria, especialidades }

class ProgramTypeTabs extends StatefulWidget {
  final Function(ProgramTypeTab)? onTabChanged;

  const ProgramTypeTabs({super.key, this.onTabChanged});

  @override
  State<ProgramTypeTabs> createState() => _ProgramTypeTabsState();
}

class _ProgramTypeTabsState extends State<ProgramTypeTabs> {
  ProgramTypeTab _selectedTab = ProgramTypeTab.todos;

  void _selectTab(ProgramTypeTab tab) {
    setState(() {
      _selectedTab = tab;
    });
    widget.onTabChanged?.call(tab);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TabItem(
            label: 'Todos',
            icon: Icons.grid_view_rounded,
            isSelected: _selectedTab == ProgramTypeTab.todos,
            onTap: () => _selectTab(ProgramTypeTab.todos),
          ),
          _TabItem(
            label: 'Maestrias',
            icon: Icons.school_rounded,
            isSelected: _selectedTab == ProgramTypeTab.maestria,
            onTap: () => _selectTab(ProgramTypeTab.maestria),
          ),
          _TabItem(
            label: 'Diplomados',
            icon: Icons.military_tech_rounded,
            isSelected: _selectedTab == ProgramTypeTab.diplomado,
            onTap: () => _selectTab(ProgramTypeTab.diplomado),
          ),
          _TabItem(
            label: 'Especialid.',
            icon: Icons.auto_awesome_rounded,
            isSelected: _selectedTab == ProgramTypeTab.especialidades,
            onTap: () => _selectTab(ProgramTypeTab.especialidades),
          ),
        ],
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2196F3).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          // Texto
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF2196F3)
                  : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          // Indicador inferior (underline)
          Container(
            width: 40,
            height: 2,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }
}

