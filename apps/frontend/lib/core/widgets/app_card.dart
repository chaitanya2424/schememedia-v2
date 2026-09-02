import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The shared card shell every screen previously hand-rolled independently
/// (`Card(InkWell(Padding(...)))`, duplicated 5x across `SchemeResultCard`,
/// `RecommendationCard`, `EvidenceCard`, Home's quick-links, and
/// Recommendations' group panels). Flat and outlined rather than
/// shadow-elevated -- reads as calmer and more "official" than a
/// shadow-heavy UI, matching the redesign's "trustworthy, not flashy"
/// direction.
///
/// [semanticLabel], when given, merges the whole card into one screen-reader
/// announcement (e.g. a scheme's name + verification status read together)
/// instead of each child `Text`/`Icon` being announced separately.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.semanticLabel,
    this.filled = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  /// True for a saffron-tinted "primary" card (e.g. Home's highest-priority
  /// quick link) instead of the default neutral-outlined surface.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final card = Card(
      margin: EdgeInsets.zero,
      color: filled ? scheme.primaryContainer : scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: filled ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );

    if (semanticLabel == null) return card;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: card,
    );
  }
}
