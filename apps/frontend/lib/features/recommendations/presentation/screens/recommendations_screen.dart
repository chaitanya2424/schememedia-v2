import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/eyebrow_label.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('For You')),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: EyebrowLabel('Personal recommendations')),
            TextButton(
              onPressed: () => ref.read(recommendationsNotifierProvider.notifier).reset(),
              child: const Text('Edit answers'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text('Made for your next step.', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          "A considered shortlist from what you've told us. Nothing here is a promise of approval.",
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (response.profileProvided)
          _WhyTheseMatchesBanner(response: response)
        else
          _InfoBanner(
            icon: Icons.info_outline,
            text: 'Add some profile details to see personalized eligibility instead of "unknown".',
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(child: Text('Top matches', style: theme.textTheme.titleMedium)),
            Text('Updated just now', style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
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
class _WhyTheseMatchesBanner extends StatelessWidget {
  const _WhyTheseMatchesBanner({required this.response});

  final RecommendationResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final passLabels = response.recommendations
        .expand((r) => r.eligibilityRules)
        .where((r) => r.state.name == 'pass')
        .map((r) => r.label)
        .toSet()
        .take(3)
        .toList();
    final body = passLabels.isEmpty
        ? 'Your answers shaped how these results are ranked.'
        : '${passLabels.join(', ')} shaped this list.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: colors.brandTint, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome, size: AppSpacing.iconMd, color: colors.brand),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Why these matches?', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                Text(body, style: theme.textTheme.bodySmall),
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
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconMd, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
