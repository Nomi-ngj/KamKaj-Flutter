import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/tokens.dart';

/// Bottom navigation shell: Home · Explore · Orders · Profile (Dashboard frame).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    (icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (icon: Icons.explore_outlined, active: Icons.explore_rounded, label: 'Explore'),
    (icon: Icons.receipt_long_outlined, active: Icons.receipt_long_rounded, label: 'Orders'),
    (icon: Icons.account_circle_outlined, active: Icons.account_circle_rounded, label: 'Profile'),
  ];

  void _onTap(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
          boxShadow: AppShadows.topBar,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimensions.bottomBarHeight,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: i == navigationShell.currentIndex ? _items[i].active : _items[i].icon,
                      label: _items[i].label,
                      selected: i == navigationShell.currentIndex,
                      onTap: () => _onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.secondary : AppColors.textPrimary;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: AppDimensions.iconLg, color: color),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption2Medium.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
