import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../../../core/widgets/scheme_card.dart';
import '../../domain/assistant_evidence.dart';

/// One evidence/source entry backing an assistant reply -- maps onto the
/// shared [SchemeCard], with the expandable eligibility-explanation/
/// missing-attributes list as [SchemeCard.trailing]. Deliberately not a
/// reuse of `SchemeResultCard` (search's mapping) at the *data* layer --
/// `EvidenceResultOut` is a different wire shape (no slug, no score, no
/// description; it does carry eligibility_state/explanations/
/// missing_attributes, which search results never do) -- but both map
/// onto the same shared card shell, which is the actual "reuse" that
/// matters visually.
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
    final hasDetails = e.eligibilityExplanations.isNotEmpty || e.missingAttributes.isNotEmpty;

    return SchemeCard(
      schemeId: e.schemeId,
      name: e.name,
      category: e.category,
      verificationStatus: e.verificationStatus,
      needsReview: e.needsReview,
      eligibilityState: e.eligibilityState,
      onTap: () => context.push(AppRoutes.schemeDetailPath(e.schemeId)),
      ctaLabel: 'View details',
      trailing: !hasDetails
          ? null
          : _DetailsSection(
              evidence: e,
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({required this.evidence, required this.expanded, required this.onToggle});

  final EvidenceResult evidence;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onToggle,
          icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
          label: Text(expanded ? 'Hide details' : 'Why this scheme?'),
        ),
        if (expanded) ...[
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.xs),
          for (final explanation in evidence.eligibilityExplanations)
            _Bullet(icon: Icons.check_circle_outline, text: explanation, color: theme.colorScheme.primary),
          if (evidence.missingAttributes.isNotEmpty)
            _Bullet(
              icon: Icons.help_outline,
              text: 'Still unknown: ${evidence.missingAttributes.join(', ')}',
              color: StatusColors.warning(theme.colorScheme),
            ),
        ],
      ],
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
          Icon(icon, size: AppSpacing.iconSm, color: color),
          const SizedBox(width: AppSpacing.xs + 2),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}
