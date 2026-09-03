import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/saved_schemes_repository.dart';
import '../../../../core/local/theme_mode_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';

/// A full product screen, not a settings page -- but honest: there is no
/// backend auth (no signup/login/session endpoints exist), so this is
/// always the signed-out state, never a fabricated "Riya Shah" account.
/// See the redesign plan's Phase A/B capability table for exactly which
/// pieces below are real (theme preference, saved-schemes count -- both
/// local) vs. inert pending an account (sign-in, notification/language
/// preferences, which need somewhere real to sync to).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final savedCount = ref.watch(savedSchemesProvider).length;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colors.surfaceMuted,
                          child: Icon(Icons.person_outline, color: colors.textSecondary, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Not signed in', style: theme.textTheme.titleMedium),
                              Text(
                                'Sign in to sync your profile and saved schemes across devices.',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton(
                            onPressed: () => context.push(AppRoutes.login),
                            child: const Text('Sign in'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('On this device', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.bookmark_outline,
                      title: 'Saved schemes',
                      subtitle: '$savedCount saved on this device',
                      onTap: () => context.go(AppRoutes.saved),
                    ),
                    const Divider(height: 1),
                    _ThemeRow(mode: themeMode),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Preferences', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InertRow(
                      icon: Icons.notifications_outlined,
                      title: 'Updates about new schemes',
                      subtitle: 'Requires an account to deliver -- coming with sign-in',
                    ),
                    const Divider(height: 1),
                    _InertRow(
                      icon: Icons.language_outlined,
                      title: 'Language',
                      subtitle: 'English (only language available today)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('About', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: colors.textSecondary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('SchemeMedia · Version 1.0.0', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, color: colors.brand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// Real and working, not decorative -- ThemeModeNotifier persists this
/// locally via shared_preferences.
class _ThemeRow extends ConsumerWidget {
  const _ThemeRow({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.dark_mode_outlined, color: colors.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text('Appearance', style: Theme.of(context).textTheme.bodyMedium)),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto, size: AppSpacing.iconSm)),
              ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode, size: AppSpacing.iconSm)),
              ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode, size: AppSpacing.iconSm)),
            ],
            selected: {mode},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(themeModeProvider.notifier).setMode(selection.first),
          ),
        ],
      ),
    );
  }
}

class _InertRow extends StatelessWidget {
  const _InertRow({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, color: colors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
