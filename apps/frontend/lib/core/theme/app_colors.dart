import 'package:flutter/material.dart';

/// Hand-authored neutral/surface/brand tokens -- the redesign-v2 fix for
/// why v1 read as a developer dashboard: `ColorScheme.fromSeed()`'s
/// algorithmically-generated neutral tones are muted/grey-leaning, not the
/// crisp warm-white-background/pure-white-card pair a calm consumer
/// product needs. `AppTheme` still derives `primary`/`primaryContainer`
/// etc. from the saffron seed for harmonious tonal relationships, but the
/// tokens below -- surfaced both as this `ThemeExtension` (for explicit,
/// named use) and copied onto `ColorScheme.surface`/`onSurface`/etc. (so
/// built-in Material widgets pick them up automatically) -- are these
/// exact hand-picked values, not derived ones.
///
/// `background` and `surface` are deliberately different colors (unlike
/// v1, which pointed `scaffoldBackgroundColor` at `colorScheme.surface`):
/// the warm off-white background is what makes a pure-white card actually
/// read as "floating," which a shadow alone can't do if both are the same
/// tone.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.brand,
    required this.brandTint,
    required this.primaryAction,
    required this.onPrimaryAction,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;

  /// Saffron -- reserved for accents: eyebrow labels, icons, badges,
  /// progress indicators, active-nav state, and the one CTA that sits on
  /// a dark [primaryAction] surface (needs a contrasting color there).
  /// *Not* the default button fill -- see [primaryAction].
  final Color brand;
  final Color brandTint;

  /// The actual primary-button/hero-surface fill. Navy in light mode --
  /// confident dark buttons on the warm-light canvas is the calmer,
  /// "fintech" reading; saffron-filled buttons everywhere would tip back
  /// into "flashy." In dark mode the canvas is already dark, so the
  /// primary action becomes [brand] instead (navy-on-navy would have no
  /// contrast) -- the same navy/saffron pairing the whole app uses,
  /// inverted for whichever surface is dark.
  final Color primaryAction;
  final Color onPrimaryAction;

  /// Base color for `AppShadows` -- navy-tinted in light mode, black in
  /// dark, so shadows read as soft depth rather than a grey haze.
  final Color shadow;

  static const light = AppColors(
    background: Color(0xFFF8F7F4),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1EFEA),
    textPrimary: Color(0xFF1A1D24),
    textSecondary: Color(0xFF5C6270),
    textTertiary: Color(0xFF9BA1AC),
    divider: Color(0xFFEAE7E1),
    brand: Color(0xFFEA580C),
    brandTint: Color(0x1AEA580C),
    primaryAction: Color(0xFF1A1D24),
    onPrimaryAction: Colors.white,
    shadow: Color(0xFF1A1D24),
  );

  static const dark = AppColors(
    background: Color(0xFF14171C),
    surface: Color(0xFF1D2128),
    surfaceMuted: Color(0xFF262B33),
    textPrimary: Color(0xFFF1F2F4),
    textSecondary: Color(0xFF9AA1AC),
    textTertiary: Color(0xFF6B7280),
    divider: Color(0xFF2A2F38),
    brand: Color(0xFFF97316),
    brandTint: Color(0x1AF97316),
    primaryAction: Color(0xFFF97316),
    onPrimaryAction: Colors.white,
    shadow: Color(0xFF000000),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? brand,
    Color? brandTint,
    Color? primaryAction,
    Color? onPrimaryAction,
    Color? shadow,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      brand: brand ?? this.brand,
      brandTint: brandTint ?? this.brandTint,
      primaryAction: primaryAction ?? this.primaryAction,
      onPrimaryAction: onPrimaryAction ?? this.onPrimaryAction,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandTint: Color.lerp(brandTint, other.brandTint, t)!,
      primaryAction: Color.lerp(primaryAction, other.primaryAction, t)!,
      onPrimaryAction: Color.lerp(onPrimaryAction, other.onPrimaryAction, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

/// Convenience accessor -- `context.colors` instead of
/// `Theme.of(context).extension<AppColors>()!` at every call site. Falls
/// back to [AppColors.light] rather than force-unwrapping: several widget
/// tests pump a bare `MaterialApp(home: ...)` with no `theme:` (Flutter's
/// own default `ThemeData` carries no `AppColors` extension), and a shared
/// UI primitive like `AppCard` should degrade gracefully there instead of
/// crashing every screen that renders one.
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
