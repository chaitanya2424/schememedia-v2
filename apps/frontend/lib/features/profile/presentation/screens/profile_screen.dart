import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/saved_schemes_repository.dart';
import '../../../../core/local/theme_mode_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../recommendations/domain/citizen_archetype.dart';
import '../../../recommendations/presentation/widgets/archetype_selector_dialog.dart';
import '../../../recommendations/presentation/widgets/digilocker_dialog.dart';
import '../../../recommendations/presentation/widgets/document_scanner_dialog.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/widgets/notification_center_sheet.dart';
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
    final strings = ref.watch(stringsProvider);
    final savedCount = ref.watch(savedSchemesProvider).length;
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final isSignedIn = authState?.isSignedIn ?? false;
    final user = authState?.user;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profileTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: LanguageToggleButton(),
          ),
        ],
      ),
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
                Text(strings.yourEligibilityProfile, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                const AppCard(child: _ProfileCompletionCard()),
              ],
              const SizedBox(height: AppSpacing.lg),
              Text(strings.onThisDevice, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.bookmark_outline,
                      title: strings.savedSchemes,
                      subtitle: isSignedIn
                          ? (strings.isHindi
                              ? '$savedCount सहेजे गए, आपके खाते से सिंक किए गए'
                              : '$savedCount saved, synced to your account')
                          : (strings.isHindi
                              ? '$savedCount इस डिवाइस पर सहेजे गए'
                              : '$savedCount saved on this device'),
                      onTap: () => context.go(AppRoutes.saved),
                    ),
                    const Divider(height: 1),
                    _ThemeRow(mode: themeMode),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(strings.preferences, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.brandTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.notifications_active_outlined, color: colors.brand, size: 20),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              strings.isHindi ? 'योजना सूचनाएं एवं सीट अलर्ट' : 'Welfare Alerts & Quotas',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          Consumer(
                            builder: (context, ref, _) {
                              final count = ref.watch(unreadNotificationsCountProvider);
                              if (count == 0) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      subtitle: Text(
                        strings.isHindi
                            ? 'सीट सीमा, समय सीमा और नई योजनाओं की तत्काल सूचना'
                            : 'Capacity limits, deadlines & new matched schemes',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => NotificationCenterSheet.show(context),
                    ),
                    const Divider(height: 1),
                    const _LanguageRow(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(strings.aboutApp, style: theme.textTheme.titleMedium),
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

class _SignedOutHeader extends ConsumerWidget {
  const _SignedOutHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

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
                  Text(strings.notSignedIn, style: theme.textTheme.titleMedium),
                  Text(
                    strings.signInSubtitle,
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
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.login),
                icon: const Icon(Icons.login_rounded),
                label: Text(strings.signInOrCreate),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primaryAction,
                  foregroundColor: colors.onPrimaryAction,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                label: Text(ref.watch(stringsProvider).signOut),
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
    final strings = ref.watch(stringsProvider);
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          strings.isHindi
              ? 'आपकी प्रोफ़ाइल अभी लोड नहीं हो सकी।'
              : "Couldn't load your profile right now.",
          style: theme.textTheme.bodySmall,
        ),
      ),
      data: (response) {
        final answered = response?['answered_count'] as int? ?? 0;
        final total = response?['total_count'] as int? ?? 27;
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.fact_check_outlined, color: colors.brand),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.isHindi ? '$total में से $answered उत्तर दिए गए' : '$answered of $total answered',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          answered == 0
                              ? (strings.isHindi
                                  ? 'अपनी प्रोफ़ाइल बनाने के लिए "आपके लिए" में प्रश्नों के उत्तर दें।'
                                  : 'Answer questions in For You to build your profile.')
                              : (strings.isHindi
                                  ? 'आपकी सिफारिशों को सटीक बनाने के लिए उपयोग किया जाता है।'
                                  : 'Used to personalize your recommendations.'),
                          style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.recommendations),
                    child: Text(answered == 0 ? strings.startProfile : strings.updateProfile),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF60A5FA)
                            : const Color(0xFF1E3A8A),
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF60A5FA).withValues(alpha: 0.5)
                              : const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onPressed: () => ArchetypeSelectorDialog.show(
                        context,
                        onArchetypeSelected: (CitizenArchetype archetype) async {
                          await ref.read(profileRepositoryProvider).updateProfile(archetype.attributes);
                          ref.invalidate(myProfileProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ ${archetype.title(strings.isHindi)} loaded!'),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                      ),
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: Text(
                        strings.oneTapPresets,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF2DD4BF)
                            : const Color(0xFF0F766E),
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF2DD4BF).withValues(alpha: 0.5)
                              : const Color(0xFF0F766E).withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onPressed: () => context.go(AppRoutes.recommendations),
                      icon: const Icon(Icons.quiz_outlined, size: 18),
                      label: Text(
                        strings.quickQuiz,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF0F766E),
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF34D399).withValues(alpha: 0.5)
                              : const Color(0xFF0F766E).withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onPressed: () => DigiLockerDialog.show(
                        context,
                        onDataFetched: (attrs, kyc) async {
                          await ref.read(profileRepositoryProvider).updateProfile(attrs);
                          ref.invalidate(myProfileProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Profile updated from DigiLocker!'),
                                backgroundColor: Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                      ),
                      icon: const Icon(Icons.verified_user_rounded, size: 16),
                      label: Text(
                        strings.isHindi ? 'डिजिलॉकर' : 'DigiLocker',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.brightness == Brightness.dark
                            ? const Color(0xFF818CF8)
                            : const Color(0xFF2563EB),
                        side: BorderSide(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF818CF8).withValues(alpha: 0.5)
                              : const Color(0xFF2563EB).withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                      ),
                      onPressed: () => DocumentScannerDialog.show(
                        context,
                        onDataExtracted: (attrs, fields) async {
                          await ref.read(profileRepositoryProvider).updateProfile(attrs);
                          ref.invalidate(myProfileProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Profile updated from Document Scanner!'),
                                backgroundColor: Color(0xFF2563EB),
                              ),
                            );
                          }
                        },
                      ),
                      icon: const Icon(Icons.document_scanner_rounded, size: 16),
                      label: Text(
                        strings.isHindi ? 'आधार स्कैन' : 'Scan Aadhaar',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                  ),
                ],
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
          Expanded(
            child: Text(
              ref.watch(stringsProvider).appearanceLabel,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
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


class _LanguageRow extends ConsumerWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final language = ref.watch(languageProvider);
    final strings = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.translate_rounded, color: colors.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.languageLabel, style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  language == AppLanguage.hindi ? 'हिंदी (Hindi) सक्रिय है' : 'English (Active)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          SegmentedButton<AppLanguage>(
            segments: const [
              ButtonSegment(
                value: AppLanguage.english,
                label: Text('EN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              ButtonSegment(
                value: AppLanguage.hindi,
                label: Text('हिं', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ],
            selected: {language},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                ref.read(languageProvider.notifier).setLanguage(selection.first),
          ),
        ],
      ),
    );
  }
}
