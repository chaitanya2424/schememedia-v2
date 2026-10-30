import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../localization/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/language_toggle_button.dart';
import '../widgets/responsive.dart';
import '../../features/notifications/presentation/widgets/notification_bell_button.dart';
import 'routes.dart';

/// One persistent nav frame for all six top-level screens -- bottom
/// [NavigationBar] on mobile, [NavigationRail] on tablet/web-wide with
/// National Welfare Portal branding emblem, high-contrast selected indicators,
/// and reactive Bilingual (English / Hindi) support.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = Breakpoints.of(context) != ScreenSize.mobile;
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    final destinations = [
      (icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: strings.navHome),
      (icon: Icons.search_outlined, selectedIcon: Icons.search_rounded, label: strings.navExplore),
      (icon: Icons.auto_awesome_outlined, selectedIcon: Icons.auto_awesome_rounded, label: strings.navForYou),
      (icon: Icons.bookmark_outline, selectedIcon: Icons.bookmark_rounded, label: strings.navSaved),
      (icon: Icons.chat_bubble_outline, selectedIcon: Icons.chat_bubble_rounded, label: strings.navAssistant),
      (icon: Icons.person_outline, selectedIcon: Icons.person_rounded, label: strings.navProfile),
    ];

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
                      const SizedBox(height: AppSpacing.sm),
                      const LanguageToggleButton(),
                      const SizedBox(height: 6),
                      const NotificationBellButton(),
                    ],
                  ),
                ),
                destinations: [
                  for (final d in destinations)
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
            for (final d in destinations)
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
