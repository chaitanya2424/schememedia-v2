import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../domain/scheme_summary.dart';

/// One scheme result: name, category, jurisdiction, [VerificationBadge]
/// (+ needs_review), short description. Reused for every result list this
/// app renders -- search results today; recommendations/assistant evidence
/// as those screens land.
class SchemeResultCard extends StatelessWidget {
  const SchemeResultCard({super.key, required this.scheme, required this.onTap});

  final SchemeSummary scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scheme.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (scheme.category != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  scheme.category!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
              if (scheme.descriptionShort != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  scheme.descriptionShort!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              VerificationBadge(status: scheme.verificationStatus, needsReview: scheme.needsReview),
            ],
          ),
        ),
      ),
    );
  }
}
