import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../recommendations/domain/recommendation.dart';
import '../../../recommendations/presentation/providers/profile_form_provider.dart';
import '../../../recommendations/presentation/providers/recommendations_providers.dart';
import '../../../recommendations/presentation/widgets/recommendation_card.dart';

const _totalAttributes = 27;
const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _todayLabel() {
  final now = DateTime.now();
  return '${_weekdays[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]}';
}

/// Search entry point + a real snapshot of the user's current session
/// state -- never fabricated. The hero card and "Profile confidence"
/// stat both read directly from providers that are already the real
/// source of truth elsewhere in the app (recommendationsNotifierProvider,
/// profileFormControllerProvider), so what Home shows always matches
/// what For You would show if you went there right now.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;
    context.push(AppRoutes.searchPath(query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    final recommendations = ref.watch(recommendationsNotifierProvider).valueOrNull;
    final answered = ref.watch(
      profileFormControllerProvider.select((c) => c.totalAnswered),
    );

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const EyebrowLabel('Personal overview'),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _todayLabel().toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: context.colors.brand,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'The support that fits your life, in one place.',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'SchemeMedia helps you move from "maybe" to a clear next step — without the portal maze.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Search schemes, e.g. "farmer subsidy"',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward),
              tooltip: 'Search',
              onPressed: _submit,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        _HeroCard(recommendations: recommendations),
        const SizedBox(height: AppSpacing.xl),
        if (!wide) ...[_ProfileConfidenceCard(answered: answered), const SizedBox(height: AppSpacing.xl)],
        Row(
          children: [
            Expanded(child: Text('Picked for you', style: theme.textTheme.titleMedium)),
            TextButton(
              onPressed: () => context.go(AppRoutes.recommendations),
              child: const Text('View all'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _PickedForYou(recommendations: recommendations),
      ],
    );

    if (!wide) {
      return Scaffold(
        appBar: AppBar(title: const Text('SchemeMedia')),
        body: SafeArea(
          child: ResponsiveContainer(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: mainColumn,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('SchemeMedia')),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: AppSpacing.maxWideContentWidth,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: mainColumn),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 300,
                  child: Column(
                    children: [
                      _ProfileConfidenceCard(answered: answered),
                      const SizedBox(height: AppSpacing.lg),
                      const _ShortcutsCard(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Real when a For You run has happened this session
/// (`recommendationsNotifierProvider` is app-wide, not per-screen, so it
/// already holds the last real result if one exists); an honest "get
/// started" prompt otherwise -- never a fabricated match count.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.recommendations});

  final RecommendationResponse? recommendations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final categories = recommendations == null
        ? const <String>[]
        : recommendations!.recommendations
              .map((r) => r.category)
              .whereType<String>()
              .toSet()
              .take(3)
              .toList();
    final hasMatches = recommendations != null && recommendations!.totalReturned > 0;

    final String eyebrow = hasMatches ? 'A fresh look at your profile' : 'Get started';
    final String headline = hasMatches
        ? '${recommendations!.totalReturned} match${recommendations!.totalReturned == 1 ? '' : 'es'} found'
        : 'Find schemes made for you';
    final String body = hasMatches
        ? (categories.isEmpty
              ? 'You have real, ranked matches waiting in For You.'
              : 'You may be eligible for help with ${categories.join(', ')}.')
        : "Answer a few optional questions and we'll rank real government schemes by how well they fit.";
    final String buttonLabel = hasMatches ? 'See my matches' : 'Get my matches';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.primaryAction,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.raised(colors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.brand,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Icon(Icons.auto_awesome, color: colors.brand),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            headline,
            style: theme.textTheme.titleLarge?.copyWith(color: colors.onPrimaryAction),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onPrimaryAction.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: colors.brand, foregroundColor: Colors.white),
            onPressed: () => context.go(AppRoutes.recommendations),
            icon: const Icon(Icons.arrow_forward),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _ProfileConfidenceCard extends StatelessWidget {
  const _ProfileConfidenceCard({required this.answered});

  final int answered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final ratio = answered / _totalAttributes;
    final percent = (ratio * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Profile confidence', style: theme.textTheme.titleMedium)),
              Text('$percent%', style: theme.textTheme.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            answered == 0
                ? 'Answer a few questions to get started.'
                : 'Enough to make a useful first pass.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.brandTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, size: AppSpacing.iconSm, color: colors.brand),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private by design',
                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Your answers are used only to explain your matches.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.recommendations),
              child: Text(answered == 0 ? 'Get started' : 'Review $answered detail${answered == 1 ? '' : 's'}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Shortcuts', style: theme.textTheme.titleMedium),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ShortcutRow(
            icon: Icons.search,
            label: 'Search for schemes',
            onTap: () => context.go(AppRoutes.search),
          ),
          _ShortcutRow(
            icon: Icons.auto_awesome_outlined,
            label: 'See my recommendations',
            onTap: () => context.go(AppRoutes.recommendations),
          ),
          _ShortcutRow(
            icon: Icons.chat_bubble_outline,
            label: 'Ask the assistant',
            onTap: () => context.go(AppRoutes.assistant),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, size: AppSpacing.iconMd, color: colors.brand),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
            Icon(Icons.chevron_right, size: AppSpacing.iconMd, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PickedForYou extends StatelessWidget {
  const _PickedForYou({required this.recommendations});

  final RecommendationResponse? recommendations;

  @override
  Widget build(BuildContext context) {
    if (recommendations == null || recommendations!.recommendations.isEmpty) {
      final theme = Theme.of(context);
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nothing picked yet', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Answer a few questions in For You to see personalized picks here.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => context.go(AppRoutes.recommendations),
              child: const Text('Go to For You'),
            ),
          ],
        ),
      );
    }

    final top = recommendations!.recommendations.take(2).toList();
    return Column(
      children: [
        for (final rec in top)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RecommendationCard(recommendation: rec),
          ),
      ],
    );
  }
}
