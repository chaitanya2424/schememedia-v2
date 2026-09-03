import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../widgets/responsive.dart';
import 'routes.dart';

/// One persistent nav frame for all six top-level screens -- bottom
/// [NavigationBar] on mobile, [NavigationRail] on tablet/web-wide. See the
/// frontend architecture plan's Routing section: "one shell, not per-screen
/// scaffolding."
///
/// Redesign v2: six real destinations (Home/Explore/For You/Saved/
/// Assistant/Profile) -- confirmed against reference mockups to fit
/// comfortably on a mobile bottom bar (two-word labels wrap to two lines)
/// rather than the "5 tabs + avatar" compromise originally spec'd. A soft
/// shadow separates the bar/rail from content instead of v1's hard
/// `Divider`/`VerticalDivider` line.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Explore'),
    (icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome, label: 'For You'),
    (icon: Icons.bookmark_outline, selectedIcon: Icons.bookmark, label: 'Saved'),
    (icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Assistant'),
    (icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile'),
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
              decoration: BoxDecoration(boxShadow: AppShadows.nav(colors.shadow)),
              child: NavigationRail(
                backgroundColor: colors.surface,
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onSelect,
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final d in _destinations)
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
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
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(boxShadow: AppShadows.nav(colors.shadow)),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onSelect,
          // Six items on a phone-width bar leaves each label only
          // ~55-65dp -- at the default (M3) 12sp label size "Assistant"
          // wraps to two lines, which then squeezes every other item's
          // share of the row too. NavigationDestination.label is a plain
          // String (no widget slot to auto-shrink), so the fix is the
          // smaller labelTextStyle on navigationBarTheme below, in
          // AppTheme -- see its own comment.
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
          ],
        ),
      ),
    );
  }
}

/// Distinct in-app "not found" route for bad paths -- separate from the
/// API's own 404, which renders in-page via [AsyncValueView] rather than a
/// route change.
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
