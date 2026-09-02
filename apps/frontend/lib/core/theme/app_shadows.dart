import 'package:flutter/material.dart';

/// Soft, navy-tinted shadows -- the redesign-v2 replacement for v1's
/// `outlineVariant` border on every card. Hierarchy comes from depth, not
/// rings; no card has a visible border by default. `base` is
/// `AppColors.shadow` -- navy in light mode, black in dark -- passed in
/// rather than hardcoded so both themes get a shadow that actually reads
/// as depth instead of a flat grey smear.
abstract final class AppShadows {
  static List<BoxShadow> card(Color base) => [
    BoxShadow(color: base.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 4)),
  ];

  /// Sheets, dialogs, a pressed/active card -- one step heavier than
  /// [card].
  static List<BoxShadow> raised(Color base) => [
    BoxShadow(color: base.withValues(alpha: 0.10), blurRadius: 28, offset: const Offset(0, 8)),
  ];

  /// An upward shadow separating the bottom nav bar from content --
  /// replaces v1's hard `Divider`/`VerticalDivider` line between the nav
  /// rail and the page.
  static List<BoxShadow> nav(Color base) => [
    BoxShadow(color: base.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4)),
  ];
}
