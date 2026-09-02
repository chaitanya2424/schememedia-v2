import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The one "status pill" primitive -- icon + label on a tinted,
/// fully-rounded background. Previously reimplemented three times
/// ([VerificationBadge]'s `_StatusChip`, [EligibilityStateBadge]'s inline
/// markup, and `RecommendationCard`'s `_InfoChip`), each with its own copy
/// of the same tint formula. Every status-pill usage in the app now
/// builds on this instead.
///
/// Redesign-v2: no border (was `Border.all(color, alpha: 0.4)`) -- the
/// tinted fill + icon + text is enough signal on its own; a ring around
/// every pill was part of what made v1 read as bordered/dashboard-like.
///
/// Icon and label are merged into one [Semantics] node so a screen reader
/// announces "Eligible" once, not an unlabelled icon followed by a
/// redundant text node.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final textStyle = (Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12))
        .copyWith(color: color, fontWeight: FontWeight.w600);

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSpacing.iconSm, color: color),
                const SizedBox(width: AppSpacing.xs),
              ],
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
