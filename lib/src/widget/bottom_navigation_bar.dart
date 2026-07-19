import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/utils/typography.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role; // 'staff', 'admin', or 'patient'

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.role = 'staff',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Standard height + cushion for label and icon
    const double navBarHeight = 72.0;

    final navItems = _getNavItems();

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        height: navBarHeight,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha:0.2),
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.15) 
                : Colors.black.withValues(alpha: 0.1),
            width: 1.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(navItems.length, (index) {
                  final item = navItems[index];
                  return _buildNavItem(
                    context: context,
                    icon: item.icon,
                    label: item.label,
                    index: index,
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_NavItemData> _getNavItems() {
      return [
        _NavItemData(icon: LucideIcons.home, label: 'Home'),
        _NavItemData(icon: LucideIcons.dumbbell, label: 'Workout'),
        _NavItemData(icon: LucideIcons.lineChart, label: 'Stats'),
        _NavItemData(icon: LucideIcons.user, label: 'Profile'),
      ];
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer.withValues(alpha:0.3)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: role == 'tenant' ? 22 : 24, // Smaller icons for 6 items
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha:0.6),
                ),
              ),
              const SizedBox(height: 1),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style:
                    AppTypography.caption(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha:0.6),
                    ).copyWith(
                      fontSize: 10,
                    ), // Smaller text for 6 items
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  _NavItemData({required this.icon, required this.label});
}
