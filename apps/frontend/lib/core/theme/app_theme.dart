import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_status_colors.dart';

/// Preserves the approved saffron visual identity -- REBUILD_PLAN R-11.
/// Only used to derive `primary`/`primaryContainer`-family tonal
/// relationships now; the neutral/surface tones below are hand-authored,
/// not generated from this seed. See AppColors' doc comment for why.
const _seedColorLight = Color(0xFFEA580C);
const _seedColorDark = Color(0xFFF97316);

abstract final class AppTheme {
  static ThemeData light() => _themeFrom(Brightness.light);
  static ThemeData dark() => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.dark : AppColors.light;
    final seeded = ColorScheme.fromSeed(
      seedColor: isDark ? _seedColorDark : _seedColorLight,
      brightness: brightness,
    );

    // The actual redesign-v2 fix: override the seeded scheme's neutral/
    // surface tones (which Material 3's algorithm generates muted and
    // grey-leaning) with AppColors' hand-picked values, so every built-in
    // Material widget that reads `colorScheme.surface`/`onSurface`/etc.
    // automatically gets the calm, light, warm-neutral look -- not just
    // the custom widgets that reach for `context.colors` directly.
    final colorScheme = seeded.copyWith(
      surface: colors.surface,
      onSurface: colors.textPrimary,
      onSurfaceVariant: colors.textSecondary,
      surfaceContainerHighest: colors.surfaceMuted,
      surfaceContainer: colors.surfaceMuted,
      surfaceContainerLow: colors.surface,
      outline: colors.textTertiary,
      outlineVariant: colors.divider,
      primary: colors.brand,
      onPrimary: Colors.white,
      primaryContainer: colors.brandTint,
      onPrimaryContainer: colors.brand,
      // M3's automatic elevation surfaceTint would otherwise wash a warm
      // primary tint over every "elevated" Material widget, quietly
      // undoing the hand-picked neutrals above.
      surfaceTint: Colors.transparent,
    );

    final textTheme = _textTheme(brightness, colors);
    final buttonMinimumSize = const Size(64, 48); // 48dp minimum touch target
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colors.background,
      extensions: [AppStatusColors(colorScheme), colors],

      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.textPrimary),
      ),

      // No Card() left in the widget tree by the end of the redesign --
      // AppCard (core/widgets/app_card.dart) builds its own shadow via a
      // plain Container, not Material's Card, specifically to sidestep
      // surfaceTint. This theme entry is a defensive default for any not-
      // yet-migrated bare Card().
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
      ),

      // No visible border at rest -- only the focus ring and the (
      // intentional, transient) error state show one. See the redesign
      // spec's Inputs section.
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colors.brand, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        filled: true,
        fillColor: colors.surfaceMuted,
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colors.brandTint,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? colors.brand : colors.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color: states.contains(WidgetState.selected) ? colors.brand : colors.textSecondary,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.brandTint,
        selectedIconTheme: IconThemeData(color: colors.brand),
        unselectedIconTheme: IconThemeData(color: colors.textSecondary),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colors.brand,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: colors.textSecondary),
      ),

      // Navy in light mode, saffron in dark -- see AppColors.primaryAction's
      // doc comment. `colorScheme.primary` stays saffron (below) for M3's
      // *other* default accent behaviors -- progress indicators, selected
      // chip/switch state -- which the reference direction keeps saffron;
      // only the explicit button fill is overridden here.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primaryAction,
          foregroundColor: colors.onPrimaryAction,
          minimumSize: buttonMinimumSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: buttonShape,
          elevation: 0,
        ),
      ),
      // Redesign-v2 secondary-button convention: a tonal fill, never an
      // outline -- v1's OutlinedButton-for-secondary-actions was exactly
      // the "heavy border" pattern flagged in the redesign brief. Reusing
      // OutlinedButton's slot (rather than migrating every call site to
      // FilledButton.tonal) keeps every existing `OutlinedButton.icon(...)`
      // call site correct for free.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surfaceMuted,
          foregroundColor: colors.textPrimary,
          side: BorderSide.none,
          minimumSize: buttonMinimumSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.brand,
          minimumSize: buttonMinimumSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: buttonMinimumSize),
      ),

      // No border -- a tinted fill + icon + text is enough signal on its
      // own (StatusPill, TriStateAnswer's Yes/No choices).
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        backgroundColor: colors.surfaceMuted,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),

      dividerTheme: DividerThemeData(color: colors.divider, space: 1, thickness: 1),
    );
  }

  static TextTheme _textTheme(Brightness brightness, AppColors colors) {
    final base = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;
    // Inter is bundled locally (assets/fonts/, declared in pubspec.yaml),
    // not via the google_fonts package -- see pubspec.yaml's comment.
    final inter = base.apply(
      fontFamily: 'Inter',
      bodyColor: colors.textPrimary,
      displayColor: colors.textPrimary,
    );

    // Two deliberate floors (body text at 15sp/13sp, not the M3 default's
    // effective 14sp/12sp) plus a more confident, editorial headline
    // weight than the M3 default -- part of the "premium, not utilitarian"
    // direction, not just a font-family swap.
    return inter.copyWith(
      headlineSmall: inter.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      titleLarge: inter.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: inter.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyMedium: inter.bodyMedium?.copyWith(fontSize: 15),
      bodySmall: inter.bodySmall?.copyWith(fontSize: 13, color: colors.textSecondary),
    );
  }
}
