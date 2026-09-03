import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/saved_schemes_repository.dart';
import '../../../../core/local/theme_mode_repository.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/profile_providers.dart';

/// A full product screen. Signed out: an honest empty state -- never a
/// fabricated account. Signed in: the real account (name/email from
/// /auth/me), a real eligibility-profile completion count (from
/// /me/profile), and a working sign-out. See the redesign plan's Phase
/// A/B capability table for exactly which pieces are real (theme
/// preference and saved-schemes count are local-only when signed out,
/// account-synced when signed in; account itself and the eligibility
/// profile are always real once signed in) vs. still inert (notification
/// delivery, language -- no infrastructure for either exists yet).
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final savedCount = ref.watch(savedSchemesProvider).length;
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final isSignedIn = authState?.isSignedIn ?? false;
    final user = authState?.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: isSignedIn && user != null
                    ? _SignedInHeader(user: user)
                    : const _SignedOutHeader(),
              ),
              if (isSignedIn) ...[
                const SizedBox(height: AppSpacing.lg),
                Text('Your eligibility profile', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                const AppCard(child: _ProfileCompletionCard()),
              ],
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
                      subtitle: isSignedIn
                          ? '$savedCount saved, synced to your account'
                          : '$savedCount saved on this device',
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
                      subtitle: 'No delivery channel (email/push) exists yet',
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

class _SignedOutHeader extends StatelessWidget {
  const _SignedOutHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Column(
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
    );
  }
}

class _SignedInHeader extends ConsumerWidget {
  const _SignedInHeader({required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final displayName = (user.fullName?.trim().isNotEmpty ?? false) ? user.fullName! : user.email;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.brandTint,
              child: Text(
                initial,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: theme.textTheme.titleMedium),
                  Text(user.email, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout, size: AppSpacing.iconSm),
                label: const Text('Sign out'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Real, from `/me/profile` -- the same "N of 27 answered" metric the
/// wizard already computes locally each session (ProfileFormController.
/// totalAnswered), here surfaced as its persisted, server-side equivalent.
class _ProfileCompletionCard extends ConsumerWidget {
  const _ProfileCompletionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          "Couldn't load your profile right now.",
          style: theme.textTheme.bodySmall,
        ),
      ),
      data: (response) {
        final answered = response?['answered_count'] as int? ?? 0;
        final total = response?['total_count'] as int? ?? 27;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.fact_check_outlined, color: colors.brand),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$answered of $total answered', style: theme.textTheme.bodyMedium),
                    Text(
                      answered == 0
                          ? 'Answer questions in For You to build your profile.'
                          : 'Used to personalize your recommendations.',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.recommendations),
                child: Text(answered == 0 ? 'Start' : 'Update'),
              ),
            ],
          ),
        );
      },
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
