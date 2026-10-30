import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/profile_offline_cache_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/recommendation.dart';
import '../providers/recommendations_providers.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/recommendations_wizard.dart';

/// Build-order step 4: `POST /recommendations`, real ranked/eligibility-
/// annotated results. "Same to same" fidelity pass: the wizard (one
/// question per screen -- see RecommendationsWizard) and the results view
/// are now separate full-screen states, matching the reference mockups --
/// not the v1 side-by-side form+results layout, which didn't give a
/// step-by-step flow room to breathe. Still built on the same
/// AsyncValueView every other screen uses, so error handling (message per
/// ApiException variant, retry-ability) is the one shared implementation,
/// not reinvented here.
class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recommendationsNotifierProvider);
    final strings = ref.watch(stringsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.navForYou),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: AsyncValueView<RecommendationResponse?>(
          value: state,
          onRetry: () => ref.read(recommendationsNotifierProvider.notifier).retry(),
          loadingBuilder: (context) => ResponsiveContainer(
            child: const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: _ResultsSkeleton()),
          ),
          data: (context, response) {
            if (response == null) {
              // A one-question-at-a-time flow shouldn't stretch
              // edge-to-edge just because the viewport can -- narrower
              // than the default reading width, unlike every other
              // ResponsiveContainer usage in the app.
              return const ResponsiveContainer(maxWidth: 600, child: RecommendationsWizard());
            }
            return ResponsiveContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _ResultsView(response: response),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: SkeletonListTile(),
        ),
      ),
    );
  }
}

class _ResultsView extends ConsumerWidget {
  const _ResultsView({required this.response});

  final RecommendationResponse response;

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
            Expanded(
              child: Text(
                strings.isHindi ? 'आपकी योजनाएं' : 'Top Recommendations',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => ref.read(recommendationsNotifierProvider.notifier).reset(),
              icon: const Icon(Icons.tune, size: 16),
              label: Text(strings.isHindi ? 'फ़िल्टर बदलें' : 'Edit profile'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings.isHindi
              ? '${response.totalReturned} योजनाएं आपकी प्रोफ़ाइल के अनुसार रैंक की गई हैं।'
              : '${response.totalReturned} schemes ranked according to your profile.',
          style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        if (response.profileProvided)
          _WhyTheseMatchesBanner(response: response)
        else
          _InfoBanner(
            icon: Icons.info_outline,
            text: strings.isHindi
                ? 'सटीक व्यक्तिगत पात्रता देखने के लिए प्रोफ़ाइल विवरण जोड़ें।'
                : 'Add some profile details to see personalized eligibility instead of "unknown".',
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.isHindi ? 'सर्वश्रेष्ठ मिलान' : 'All Matches',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              strings.isHindi ? 'ताज़ा अपडेट' : 'Ranked for you',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final rec in response.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RecommendationCard(recommendation: rec),
          ),
      ],
    );
  }
}

/// "Why these matches?" -- sleek, clean, templated from actual profile attributes
class _WhyTheseMatchesBanner extends ConsumerWidget {
  const _WhyTheseMatchesBanner({required this.response});

  final RecommendationResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(stringsProvider);
    final isOffline = ref.watch(profileOfflineCacheRepositoryProvider).isOfflineAvailable;
    final cachedLabel = ref.watch(profileOfflineCacheRepositoryProvider).cachedProfileLabel ??
        (strings.isHindi ? 'नागरिक' : 'Citizen');
    final passLabels = response.recommendations
        .expand((r) => r.eligibilityRules)
        .where((r) => r.state.name == 'pass')
        .map((r) => r.label)
        .toSet()
        .take(3)
        .toList();
    final body = strings.isHindi
        ? (passLabels.isEmpty
            ? 'आपकी जनसांख्यिकीय प्रोफ़ाइल के आधार पर यह सूची तैयार की गई है।'
            : '${passLabels.join(', ')} के आधार पर प्राथमिकता दी गई।')
        : (passLabels.isEmpty
            ? 'Ranked based on your demographic profile attributes.'
            : 'Prioritized by: ${passLabels.join(', ')}');

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.45) : const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 18,
              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        strings.isHindi ? 'सटीक मिलान आधार' : 'Why these matches?',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF065F46),
                        ),
                      ),
                    ),
                    if (isOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_pin, size: 12, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669)),
                            const SizedBox(width: 3),
                            Text(
                              '${strings.offlineReady} · $cachedLabel',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(0xFFD97706)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
