import 'package:flutter/material.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../domain/scheme_summary.dart';

/// One scheme result: name, category, jurisdiction, [VerificationBadge]
/// (+ needs_review), short description. Reused for every result list this
/// app renders -- search results today; recommendations/assistant evidence
/// as those screens land.
///
/// Every text element below is `maxLines`-bounded: the desktop grid
/// (`_ResultsList` in search_results_screen.dart) lays these out at a
/// fixed tile height, so unbounded text was a real overflow risk with
/// long scheme names/descriptions.
class SchemeResultCard extends StatelessWidget {
  const SchemeResultCard({super.key, required this.scheme, required this.onTap});

  final SchemeSummary scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jurisdictionLabel = switch (scheme.jurisdiction) {
      Jurisdiction.central => 'Central',
      Jurisdiction.state => scheme.stateCode != null ? 'State (${scheme.stateCode})' : 'State',
      Jurisdiction.unrecognized => null,
    };
    final metaParts = [
      if (scheme.category != null) scheme.category!,
      if (jurisdictionLabel != null) jurisdictionLabel,
    ];

    return AppCard(
      onTap: onTap,
      semanticLabel: '${scheme.name}. ${metaParts.join(', ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scheme.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (metaParts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              metaParts.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
          if (scheme.descriptionShort != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              scheme.descriptionShort!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          VerificationBadge(status: scheme.verificationStatus, needsReview: scheme.needsReview),
        ],
      ),
    );
  }
}
