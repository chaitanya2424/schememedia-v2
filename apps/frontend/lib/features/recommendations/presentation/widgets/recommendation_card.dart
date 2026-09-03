import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/scheme_card.dart';
import '../../../../core/widgets/status_pill.dart';
import '../../../scheme_detail/domain/scheme_detail_args.dart';
import '../../domain/recommendation.dart';

/// One ranked recommendation: maps onto the shared [SchemeCard], with the
/// per-rule explanation list (including `unknown` rules -- the "missing
/// information" a fuller profile could still resolve, since the backend
/// doesn't ship a separate missing-attributes list on this endpoint, only
/// the assistant's evidence does) as [SchemeCard.trailing]. `fail` results
/// stay visible, just visually muted via [Opacity] -- matching the
/// backend's own "ranks, never filters" design; see the frontend
/// architecture plan.
class RecommendationCard extends StatefulWidget {
  const RecommendationCard({super.key, required this.recommendation});

  final Recommendation recommendation;

  @override
  State<RecommendationCard> createState() => _RecommendationCardState();
}

class _RecommendationCardState extends State<RecommendationCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final muted = rec.eligibilityState == EligibilityState.fail;

    return Opacity(
      opacity: muted ? 0.6 : 1,
      child: SchemeCard(
        schemeId: rec.schemeId,
        name: rec.name,
        category: rec.category,
        description: rec.descriptionShort,
        verificationStatus: rec.verificationStatus,
        needsReview: rec.needsReview,
        eligibilityState: rec.eligibilityState,
        onTap: () => context.push(
          AppRoutes.schemeDetailPath(rec.schemeId),
          extra: SchemeDetailArgs(eligibilityRules: rec.eligibilityRules, scrollToEligibility: true),
        ),
        ctaLabel: 'See eligibility',
        onSecondaryTap: () => context.push(
          AppRoutes.schemeDetailPath(rec.schemeId),
          extra: SchemeDetailArgs(eligibilityRules: rec.eligibilityRules),
        ),
        secondaryLabel: 'Details',
        trailing: rec.eligibilityRules.isEmpty
            ? null
            : _RuleSection(
                rules: rec.eligibilityRules,
                expanded: _expanded,
                onToggle: () => setState(() => _expanded = !_expanded),
              ),
      ),
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({required this.rules, required this.expanded, required this.onToggle});

  final List<EligibilityRule> rules;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final unknownCount = rules.where((r) => r.state == EligibilityState.unknown).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onToggle,
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Hide eligibility details' : 'Why? (${rules.length})'),
            ),
            if (unknownCount > 0)
              StatusPill(
                icon: Icons.help_outline,
                label: '$unknownCount unknown',
                color: Theme.of(context).colorScheme.tertiary,
              ),
          ],
        ),
        if (expanded) ...[
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          for (final rule in rules) _RuleExplanation(rule: rule),
        ],
      ],
    );
  }
}

class _RuleExplanation extends StatelessWidget {
  const _RuleExplanation({required this.rule});

  final EligibilityRule rule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = StatusColors.eligibility(rule.state, scheme);
    final icon = switch (rule.state) {
      EligibilityState.pass => Icons.check_circle_outline,
      EligibilityState.fail => Icons.cancel_outlined,
      EligibilityState.unknown => Icons.help_outline,
      EligibilityState.notApplicable => Icons.remove_circle_outline,
      EligibilityState.unrecognized => Icons.help_outline,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: color),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rule.label,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(rule.explanation, style: theme.textTheme.bodySmall),
                if (rule.labelHi != null)
                  Text(rule.labelHi!, style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
