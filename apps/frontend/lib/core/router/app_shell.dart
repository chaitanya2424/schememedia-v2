import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/responsive.dart';
import 'routes.dart';

/// One persistent nav frame for all five top-level screens -- bottom
/// [NavigationBar] on mobile, [NavigationRail] on tablet/web-wide. See the
/// frontend architecture plan's Routing section: "one shell, not per-screen
/// scaffolding."
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    (icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
    (icon: Icons.fact_check_outlined, selectedIcon: Icons.fact_check, label: 'For you'),
    (icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble, label: 'Assistant'),
  ];

  void _onSelect(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) != ScreenSize.mobile;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onSelect,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selectedIcon), label: d.label),
        ],
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
