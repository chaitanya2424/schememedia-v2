import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../local/saved_schemes_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_card.dart';
import 'eligibility_state_badge.dart';
import 'verification_badge.dart';

/// A one-line "what you may receive" highlight -- real data only. See the
/// redesign plan's Scheme Card section: `SchemeSummary`/`Recommendation`
/// (Explore/For You results) carry no benefit data at all, only
/// `SchemeDetail` does -- so this is null on those cards, not
/// invented/placeholder text. Scheme Detail (which already loads real
/// benefits) is the only place this is populated today.
class BenefitHighlight {
  const BenefitHighlight({required this.label, required this.value});

  final String label;
  final String value;
}

/// The one reusable consumer-product scheme card -- category icon chip,
/// bookmark toggle (real, on-device persistence via
/// [savedSchemeIdsProvider]), name, meta line, description, an optional
/// real benefit highlight, verification + optional eligibility pills, and
/// a single clear primary CTA. `SchemeResultCard` (Explore),
/// `RecommendationCard` (For You), and `EvidenceCard` (Assistant) each
/// map their own wire model onto this instead of independently
/// hand-rolling a card layout -- [trailing], when given, lets each of
/// them append their own extra content (e.g. an expandable per-rule
/// explanation list) below the standard fields, inside the same shell.
class SchemeCard extends ConsumerWidget {
  const SchemeCard({
    super.key,
    required this.schemeId,
    required this.name,
    required this.category,
    this.metaSuffix,
    this.description,
    required this.verificationStatus,
    required this.needsReview,
    this.eligibilityState,
    this.benefitHighlight,
    required this.onTap,
    this.ctaLabel = 'View details',
    this.onSecondaryTap,
    this.secondaryLabel,
    this.trailing,
  });

  final String schemeId;
  final String name;

  /// Free-text category from the API (e.g. "Agriculture") -- drives both
  /// the meta line and the icon-chip's icon via [_iconForCategory].
  final String? category;

  /// Appended to the meta line after category (e.g. a jurisdiction/state
  /// label) -- "Agriculture · Government of India" / "Agriculture ·
  /// State (MH)".
  final String? metaSuffix;

  final String? description;
  final VerificationStatus verificationStatus;
  final bool needsReview;

  /// Null in a non-eligibility-aware context (Explore's plain search
  /// results never carry this field) -- the pill is simply omitted then,
  /// matching what the API actually returns, not a fabricated "unknown"
  /// for a field the endpoint never had an opinion on.
  final EligibilityState? eligibilityState;

  final BenefitHighlight? benefitHighlight;
  final VoidCallback onTap;
  final String ctaLabel;

  /// When given (For You/Home's eligibility-aware cards), renders a
  /// second, secondary-styled button alongside the primary one -- e.g.
  /// "See eligibility" (primary, jumps to Scheme Detail's eligibility
  /// section) + "Details" (secondary, lands at the top). Null on
  /// Explore's plain cards, which have no eligibility section to jump to.
  final VoidCallback? onSecondaryTap;
  final String? secondaryLabel;

  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSaved = ref.watch(savedSchemeIdsProvider.select((ids) => ids.contains(schemeId)));

    final metaParts = [if (category != null) category!, if (metaSuffix != null) metaSuffix!];

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      semanticLabel: '$name. ${metaParts.join(', ')}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CategoryIcon(category: category),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    if (metaParts.isNotEmpty)
                      Text(
                        metaParts.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              _SaveButton(
                saved: isSaved,
                onTap: () => ref.read(savedSchemeIdsProvider.notifier).toggle(schemeId),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (benefitHighlight != null) ...[
            const SizedBox(height: AppSpacing.md),
            _BenefitBox(highlight: benefitHighlight!),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (eligibilityState != null) EligibilityStateBadge(state: eligibilityState!),
              VerificationBadge(status: verificationStatus, needsReview: needsReview),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (onSecondaryTap != null && secondaryLabel != null)
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward, size: AppSpacing.iconSm),
                    label: Text(ctaLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(onPressed: onSecondaryTap, child: Text(secondaryLabel!)),
                ),
              ],
            )
          else
            FilledButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward, size: AppSpacing.iconSm),
              label: Text(ctaLabel),
            ),
          if (trailing != null) ...[const SizedBox(height: AppSpacing.xs), trailing!],
        ],
      ),
    );
  }
}

class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({required this.category});

  final String? category;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: colors.brandTint,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Icon(_iconForCategory(category), color: colors.brand, size: AppSpacing.iconMd),
    );
  }

  static IconData _iconForCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('agri') || c.contains('farm')) return Icons.grass_outlined;
    if (c.contains('health')) return Icons.favorite_border;
    if (c.contains('educat') || c.contains('scholar')) return Icons.school_outlined;
    if (c.contains('hous')) return Icons.home_outlined;
    if (c.contains('employ') || c.contains('skill') || c.contains('labour') || c.contains('labor')) {
      return Icons.work_outline;
    }
    if (c.contains('women') || c.contains('child')) return Icons.family_restroom_outlined;
    if (c.contains('pension') || c.contains('senior') || c.contains('elder')) {
      return Icons.elderly_outlined;
    }
    if (c.contains('social') || c.contains('welfare')) return Icons.groups_outlined;
    if (c.contains('financ') || c.contains('loan') || c.contains('subsidy')) {
      return Icons.account_balance_outlined;
    }
    if (c.contains('insur')) return Icons.shield_outlined;
    return Icons.description_outlined;
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});

  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onTap,
      tooltip: saved ? 'Remove from saved' : 'Save for later',
      icon: Icon(
        saved ? Icons.bookmark : Icons.bookmark_outline,
        color: saved ? colors.brand : colors.textSecondary,
      ),
    );
  }
}

class _BenefitBox extends StatelessWidget {
  const _BenefitBox({required this.highlight});

  final BenefitHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.mail_outline, size: AppSpacing.iconMd, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  highlight.label,
                  style: theme.textTheme.labelMedium?.copyWith(color: colors.textSecondary),
                ),
                Text(
                  highlight.value,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
