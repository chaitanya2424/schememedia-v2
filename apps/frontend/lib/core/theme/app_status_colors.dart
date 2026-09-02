import 'package:flutter/material.dart';

import '../domain/enums.dart';
import 'status_colors.dart';

/// Makes [StatusColors] reachable via `Theme.of(context)` alongside the
/// rest of the theme, instead of only as a separate static class taking a
/// [ColorScheme] parameter. The color *values* and *logic* are unchanged --
/// this only adds a second, theme-integrated access path for new widgets;
/// [StatusColors] itself remains the single source of truth and existing
/// call sites are untouched.
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  const AppStatusColors(this.colorScheme);

  final ColorScheme colorScheme;

  Color warning() => StatusColors.warning(colorScheme);

  Color verification(VerificationStatus status) => StatusColors.verification(status, colorScheme);

  Color eligibility(EligibilityState state) => StatusColors.eligibility(state, colorScheme);

  @override
  AppStatusColors copyWith({ColorScheme? colorScheme}) =>
      AppStatusColors(colorScheme ?? this.colorScheme);

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    // Brightness switches are a hard cutover (see StatusColors' own
    // light/dark pairs), not an interpolation -- there is no meaningful
    // halfway color between the light and dark palettes.
    if (other is AppStatusColors && t >= 0.5) return other;
    return this;
  }
}
