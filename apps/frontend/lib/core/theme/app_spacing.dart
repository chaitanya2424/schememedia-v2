/// Spacing/radius tokens -- no magic numbers in widget code. See the
/// frontend architecture plan's Theme / design system section.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
  static const double iconXl = 32;

  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationMedium = Duration(milliseconds: 250);

  /// [ResponsiveContainer] max-width per screen -- named here instead of a
  /// raw literal per call site, so a new screen doesn't invent a fourth
  /// value. `content` is the default (reading-width screens: home, scheme
  /// detail); `wide` is for screens with genuine multi-pane layouts at the
  /// `wide` breakpoint (recommendations' form+results split, search's grid).
  static const double maxContentWidth = 840;
  static const double maxWideContentWidth = 1100;
}
