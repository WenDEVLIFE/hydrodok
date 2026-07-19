 import 'package:flutter/material.dart';
import '../core/utils/design_system.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class FitFormBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const FitFormBottomNav({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: FitFormDesign.cardBackground(context).withValues(alpha:0.8),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: FitFormDesign.textPrimary(context).withValues(alpha: 0.1),
        ),
        boxShadow: FitFormDesign.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, 0, LucideIcons.map, 'Map'),
          _buildNavItem(context, 1, LucideIcons.messageCircleCheck100, 'Forum'),
          _buildNavItem(context, 2, LucideIcons.bug, 'PEST ID'),
          _buildNavItem(context, 3, LucideIcons.box, 'Pooling'),
          _buildNavItem(context, 4, LucideIcons.user, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    final color = isSelected 
        ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white)
        : FitFormDesign.textPrimary(context).withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onIndexChanged(index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected ? FitFormDesign.primary : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? FitFormDesign.primary : FitFormDesign.textPrimary(context).withValues(alpha: 0.5),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
