import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';

/// The shared card shell every screen builds on. Redesign-v2: a soft
/// navy-tinted shadow, no border -- the direct fix for v1's "outlined box
/// on a grey background" dashboard feel. Built on a plain `Container` +
/// `Material`/`InkWell`, not Material's `Card` widget, specifically to
/// avoid `Card`'s automatic `surfaceTint` elevation overlay, which would
/// otherwise wash a warm tint over the hand-picked surface color.
///
/// [semanticLabel], when given, merges the whole card into one screen-reader
/// announcement (e.g. a scheme's name + verification status read together)
/// instead of each child `Text`/`Icon` being announced separately.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.semanticLabel,
    this.filled = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  /// True for a saffron-tinted "primary" card (e.g. Home's highest-priority
  /// quick link) instead of the default neutral white surface.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    final card = Container(
      decoration: BoxDecoration(
        color: filled ? colors.brandTint : colors.surface,
        borderRadius: radius,
        boxShadow: AppShadows.card(colors.shadow),
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: onTap == null
            ? Padding(padding: padding, child: child)
            : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
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
