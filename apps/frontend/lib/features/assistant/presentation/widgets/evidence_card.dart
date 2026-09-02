import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/eligibility_state_badge.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../domain/assistant_evidence.dart';

/// One evidence/source entry backing an assistant reply -- deliberately
/// not a reuse of `SchemeResultCard` (search's card): `EvidenceResultOut`
/// is a different wire shape (no slug, no score, no description; it does
/// carry eligibility_state/explanations/missing_attributes, which search
/// results never do). Matches SchemeResultCard's visual language exactly
/// (same spacing tokens, same Card/InkWell-to-detail pattern) and reuses
/// its actual shared sub-components (VerificationBadge,
/// EligibilityStateBadge) -- the real "existing scheme-card component"
/// this app has to share across a search result and an evidence result is
/// those badges, not a single monolithic card that would otherwise have to
/// paper over the field mismatch with synthetic data.
class EvidenceCard extends StatefulWidget {
  const EvidenceCard({super.key, required this.evidence});

  final EvidenceResult evidence;

  @override
  State<EvidenceCard> createState() => _EvidenceCardState();
}

class _EvidenceCardState extends State<EvidenceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.evidence;
    final theme = Theme.of(context);
    final hasDetails = e.eligibilityExplanations.isNotEmpty || e.missingAttributes.isNotEmpty;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => context.push(AppRoutes.schemeDetailPath(e.schemeId)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(e.name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  EligibilityStateBadge(state: e.eligibilityState),
                ],
              ),
              if (e.category != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(e.category!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ],
              const SizedBox(height: AppSpacing.sm),
              VerificationBadge(status: e.verificationStatus, needsReview: e.needsReview),
              if (hasDetails) ...[
                const SizedBox(height: AppSpacing.xs),
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  label: Text(_expanded ? 'Hide details' : 'Why this scheme?'),
                ),
                if (_expanded) ...[
                  const Divider(height: 1),
                  const SizedBox(height: AppSpacing.xs),
                  for (final explanation in e.eligibilityExplanations)
                    _Bullet(icon: Icons.check_circle_outline, text: explanation, color: theme.colorScheme.primary),
                  if (e.missingAttributes.isNotEmpty)
                    _Bullet(
                      icon: Icons.help_outline,
                      text: 'Still unknown: ${e.missingAttributes.join(', ')}',
                      color: StatusColors.warning(theme.colorScheme),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.text, required this.color});

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
