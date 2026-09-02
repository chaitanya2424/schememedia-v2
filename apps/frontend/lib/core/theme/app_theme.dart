import 'package:flutter/material.dart';

import 'app_spacing.dart';
import 'app_status_colors.dart';

/// Preserves v1's saffron visual identity -- REBUILD_PLAN R-11.
const _seedColor = Color(0xFFEA580C);

abstract final class AppTheme {
  static ThemeData light() => _themeFrom(Brightness.light);
  static ThemeData dark() => _themeFrom(Brightness.dark);

  static ThemeData _themeFrom(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(seedColor: _seedColor, brightness: brightness);
    final textTheme = _textTheme(brightness);
    final buttonMinimumSize = const Size(64, 48); // 48dp minimum touch target

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      extensions: [AppStatusColors(colorScheme)],

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
      ),

      // Flat, outlined rather than shadow-elevated -- see AppCard, the
      // shared card shell most of the UI now builds on. This theme-level
      // default keeps any not-yet-migrated bare Card() consistent with it.
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
      // Previously unstyled -- silently diverged from the themed bottom
      // NavigationBar used on mobile even though both represent "the same"
      // nav on different breakpoints.
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(color: colorScheme.onSurface),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinimumSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinimumSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinimumSize,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: buttonMinimumSize),
      ),

      // Raises chip touch targets toward the 48dp minimum -- previously
      // default M3 chip sizing (~32px), worst on Recommendations' Yes/No
      // toggles used 26x per form.
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? Typography.material2021().black
        : Typography.material2021().white;
    // Inter is bundled locally (assets/fonts/, declared in pubspec.yaml)
    // rather than via the google_fonts package -- see pubspec.yaml's
    // comment: that package fetches font files from fonts.gstatic.com at
    // runtime by default, a reliability risk for this app's audience.
    final inter = base.apply(fontFamily: 'Inter');

    // Two deliberate floors: the M3 default effectively renders body text
    // at 14sp/12sp, small for a civic-utility app serving a broad,
    // non-technical audience. Every badge/pill/chip label now reads from
    // labelMedium (was a hardcoded `fontSize: 12` literal) so status text
    // scales with system accessibility settings like the rest of the app.
    return inter.copyWith(
      bodyMedium: inter.bodyMedium?.copyWith(fontSize: 15),
      bodySmall: inter.bodySmall?.copyWith(fontSize: 13),
    );
  }
}
