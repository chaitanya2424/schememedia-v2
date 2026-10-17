import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/responsive.dart';
import 'routes.dart';

/// One persistent nav frame for all six top-level screens -- bottom
/// [NavigationBar] on mobile, [NavigationRail] on tablet/web-wide with
/// National Welfare Portal branding emblem and high-contrast selected indicators.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: 'Explore'),
    (icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome_rounded, label: 'For You'),
    (icon: Icons.bookmark_outline, selectedIcon: Icons.bookmark_rounded, label: 'Saved'),
    (icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble_rounded, label: 'Assistant'),
    (icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: 'Profile'),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) != ScreenSize.mobile;
    final colors = context.colors;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: AppShadows.nav(colors.shadow),
                border: Border(
                  right: BorderSide(
                    color: colors.divider,
                    width: 1,
                  ),
                ),
              ),
              child: NavigationRail(
                backgroundColor: colors.surface,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onSelect,
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.brand,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: colors.brand.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Portal',
                        style: TextStyle(
                          color: colors.brand,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon, color: colors.brand),
                      label: Text(
                        d.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          boxShadow: AppShadows.nav(colors.shadow),
          border: Border(
            top: BorderSide(
              color: colors.divider,
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          backgroundColor: colors.surface,
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          indicatorColor: colors.brandTint,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon, color: colors.brand),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Distinct in-app "not found" route for bad paths.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page not found.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    );
  }
}
