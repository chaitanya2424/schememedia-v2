import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/profile_offline_cache_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/eyebrow_label.dart';
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
              child: EyebrowLabel(strings.isHindi ? 'व्यक्तिगत सिफारिशें' : 'Personal recommendations'),
            ),
            TextButton(
              onPressed: () => ref.read(recommendationsNotifierProvider.notifier).reset(),
              child: Text(strings.isHindi ? 'उत्तर बदलें' : 'Edit answers'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings.isHindi ? 'आपकी जरूरतों के अनुसार चयनित।' : 'Made for your next step.',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          strings.isHindi
              ? 'आपकी जानकारी के आधार पर तैयार सूची। यह स्वीकृति का वादा नहीं है।'
              : "A considered shortlist from what you've told us. Nothing here is a promise of approval.",
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (response.profileProvided)
          _WhyTheseMatchesBanner(response: response)
        else
          _InfoBanner(
            icon: Icons.info_outline,
            text: strings.isHindi
                ? 'सटीक व्यक्तिगत पात्रता देखने के लिए प्रोफ़ाइल विवरण जोड़ें।'
                : 'Add some profile details to see personalized eligibility instead of "unknown".',
          ),
        if (ref.watch(profileOfflineCacheRepositoryProvider).isOfflineAvailable) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF065F46).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.offline_pin, color: Color(0xFF059669), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.offlineProfileSchemesCount(
                          response.totalReturned,
                          ref.watch(profileOfflineCacheRepositoryProvider).cachedProfileLabel ??
                              (strings.isHindi ? 'नागरिक' : 'Citizen'),
                        ),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.offlinePocketSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text(
                strings.isHindi ? 'सर्वश्रेष्ठ मिलान' : 'Top matches',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Text(
              strings.isHindi ? 'अभी अपडेट हुआ' : 'Updated just now',
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

/// "Why these matches?" -- real, templated from what the profile actually
/// carried, not the mockup's literal hand-written sentence.
class _WhyTheseMatchesBanner extends ConsumerWidget {
  const _WhyTheseMatchesBanner({required this.response});

  final RecommendationResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(stringsProvider);
    final passLabels = response.recommendations
        .expand((r) => r.eligibilityRules)
        .where((r) => r.state.name == 'pass')
        .map((r) => r.label)
        .toSet()
        .take(3)
        .toList();
    final body = strings.isHindi
        ? (passLabels.isEmpty
            ? 'आपके उत्तरों के आधार पर यह सूची तैयार की गई है।'
            : '${passLabels.join(', ')} के आधार पर यह सूची तैयार हुई।')
        : (passLabels.isEmpty
            ? 'Your answers shaped how these results are ranked.'
            : '${passLabels.join(', ')} shaped this list.');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 18, color: Color(0xFF059669)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.isHindi ? 'यह योजनाएं क्यों?' : 'Why these matches?',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF047857),
                    height: 1.4,
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
