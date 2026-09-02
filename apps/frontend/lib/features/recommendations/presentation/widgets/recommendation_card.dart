import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/eligibility_state_badge.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../domain/recommendation.dart';

/// One ranked recommendation: scheme summary + eligibility state + every
/// per-rule explanation, including `unknown` rules -- the "missing
/// information" a fuller profile could still resolve, since the backend
/// doesn't ship a separate missing-attributes list on this endpoint (only
/// the assistant's evidence does). `fail` results stay visible, just
/// visually muted -- matching the backend's own "ranks, never filters"
/// design; see the frontend architecture plan.
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
    final theme = Theme.of(context);
    final muted = rec.eligibilityState == EligibilityState.fail;
    final unknownCount = rec.eligibilityRules.where((r) => r.state == EligibilityState.unknown).length;

    return Opacity(
      opacity: muted ? 0.6 : 1,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => context.push(AppRoutes.schemeDetailPath(rec.schemeId)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        rec.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    EligibilityStateBadge(state: rec.eligibilityState),
                  ],
                ),
                if (rec.category != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    rec.category!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
                if (rec.descriptionShort != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(rec.descriptionShort!, maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    VerificationBadge(status: rec.verificationStatus, needsReview: rec.needsReview),
                    if (unknownCount > 0)
                      _InfoChip(
                        icon: Icons.help_outline,
                        label: '$unknownCount unknown',
                        color: theme.colorScheme.tertiary,
                      ),
                  ],
                ),
                if (rec.eligibilityRules.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    label: Text(_expanded ? 'Hide eligibility details' : 'Why? (${rec.eligibilityRules.length})'),
                  ),
                  if (_expanded) ...[
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.xs),
                    for (final rule in rec.eligibilityRules) _RuleExplanation(rule: rule),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
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
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
