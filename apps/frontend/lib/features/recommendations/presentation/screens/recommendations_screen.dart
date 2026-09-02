import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/recommendation.dart';
import '../providers/profile_form_provider.dart';
import '../providers/recommendations_providers.dart';
import '../widgets/attribute_groups.dart';
import '../widgets/profile_form.dart';
import '../widgets/profile_form_controller.dart';
import '../widgets/recommendation_card.dart';

/// Derived from the same `kAttributeGroups` the form itself renders, not a
/// hardcoded count that could drift if an attribute is ever added/removed.
final _totalAttributes = kAttributeGroups.fold(0, (sum, g) => sum + g.attributes.length);

/// Build-order step 4: profile form (26 optional attributes, grouped) +
/// `POST /recommendations` + ranked, eligibility-annotated results. See the
/// frontend architecture plan's Recommendations + eligibility explanations
/// section.
class RecommendationsScreen extends ConsumerStatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  ConsumerState<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends ConsumerState<RecommendationsScreen> {
  final _queryController = TextEditingController();
  String? _queryError;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _submit() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _queryError = 'Enter what you\'re looking for, e.g. "farmer subsidy".');
      return;
    }
    if (_queryError != null) setState(() => _queryError = null);
    final formController = ref.read(profileFormControllerProvider);
    final profile = formController.isEmpty ? null : formController.toProfileJson();
    ref.read(recommendationsNotifierProvider.notifier).fetch(query: query, profile: profile);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recommendationsNotifierProvider);
    final formController = ref.watch(profileFormControllerProvider);
    final wide = Breakpoints.of(context) == ScreenSize.wide;

    final formPane = _FormPane(
      queryController: _queryController,
      queryError: _queryError,
      formController: formController,
      onSubmit: _submit,
      loading: state.isLoading,
    );

    final resultsPane = AsyncValueView<RecommendationResponse?>(
      value: state,
      onRetry: _submit,
      isEmpty: (r) => r != null && r.recommendations.isEmpty,
      emptyBuilder: (context) => const EmptyState(
        icon: Icons.search_off,
        title: 'No schemes matched this search.',
        subtitle: 'Try a different or more general term.',
      ),
      loadingBuilder: (context) => const _ResultsSkeleton(),
      data: (context, response) {
        if (response == null) {
          return const _StartPrompt();
        }
        return _ResultsList(response: response);
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: wide ? AppSpacing.maxWideContentWidth : AppSpacing.maxContentWidth,
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 380,
                      child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpacing.lg), child: formPane),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: resultsPane,
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      formPane,
                      const SizedBox(height: AppSpacing.lg),
                      const Divider(),
                      const SizedBox(height: AppSpacing.md),
                      resultsPane,
                    ],
                  ),
                ),
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

class _FormPane extends StatelessWidget {
  const _FormPane({
    required this.queryController,
    required this.queryError,
    required this.formController,
    required this.onSubmit,
    required this.loading,
  });

  final TextEditingController queryController;
  final String? queryError;
  final ProfileFormController formController;
  final VoidCallback onSubmit;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('What are you looking for?', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('recommendations_query_field'),
          controller: queryController,
          decoration: InputDecoration(hintText: 'e.g. farmer subsidy, scholarship', errorText: queryError),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Tell us about yourself (optional)', style: theme.textTheme.titleMedium),
            ),
            ListenableBuilder(
              listenable: formController,
              builder: (context, _) => Text(
                '${formController.totalAnswered} of $_totalAttributes answered',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        ListenableBuilder(
          listenable: formController,
          builder: (context, _) => ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: formController.totalAnswered / _totalAttributes,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Every field below is optional. Answering more helps us tell you whether '
          'you\'re actually eligible instead of "unknown".',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        ProfileForm(controller: formController),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          key: const ValueKey('recommendations_submit_button'),
          onPressed: loading ? null : onSubmit,
          child: loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Show recommendations'),
        ),
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.response});

  final RecommendationResponse response;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${response.totalReturned} result${response.totalReturned == 1 ? '' : 's'} for "${response.query}"'
          '${response.profileProvided ? ', ranked for your profile' : ''}',
          style: theme.textTheme.bodyMedium,
        ),
        if (!response.profileProvided) ...[
          const SizedBox(height: AppSpacing.sm),
          _InfoBanner(
            icon: Icons.info_outline,
            text: 'Add some profile details to see personalized eligibility instead of "unknown".',
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        for (final rec in response.recommendations)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RecommendationCard(recommendation: rec),
          ),
      ],
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
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconMd, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _StartPrompt extends StatelessWidget {
  const _StartPrompt();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'Tell us what you\'re looking for and, optionally, a bit about yourself, '
          'then tap "Show recommendations".',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
