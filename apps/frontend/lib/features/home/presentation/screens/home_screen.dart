import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/responsive.dart';

/// Search entry point + quick links to Recommendations and the Assistant.
/// Screen 1 of the build order (Home/Search) -- see the frontend
/// architecture plan.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    return Scaffold(
      appBar: AppBar(title: const Text('SchemeMedia')),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  'Find government welfare schemes you may be eligible for',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                // Pill-shaped and paired with a visible submit button --
                // previously relied entirely on the keyboard's IME "search"
                // action, with no on-screen affordance for a user who
                // can't trigger it easily.
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
                const SizedBox(height: AppSpacing.xl),
                // Unequal weight, not two identical cards: recommendations
                // is the app's highest-value action (eligibility-ranked
                // results), the assistant is a secondary path. Wrap (not a
                // fixed Row+Expanded) so narrow phones stack instead of
                // cramming -- width computed once here, from the actual
                // available space, and handed to each card.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final available = constraints.maxWidth;
                    final cardWidth = available < 480
                        ? available
                        : (available - AppSpacing.md) / 2;
                    return Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        _QuickLinkCard(
                          width: cardWidth,
                          icon: Icons.fact_check_outlined,
                          title: 'Get recommendations',
                          subtitle:
                              'Answer a few optional questions to see eligibility-ranked results',
                          filled: true,
                          onTap: () => context.push(AppRoutes.recommendations),
                        ),
                        _QuickLinkCard(
                          width: cardWidth,
                          icon: Icons.chat_bubble_outline,
                          title: 'Ask the assistant',
                          subtitle: 'Describe your situation in your own words',
                          filled: false,
                          onTap: () => context.push(AppRoutes.assistant),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  const _QuickLinkCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final double width;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = filled ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.primary;
    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        filled: filled,
        semanticLabel: '$title. $subtitle',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: AppSpacing.iconLg),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: filled ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: filled
                    ? theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
