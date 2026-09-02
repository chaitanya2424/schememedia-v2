import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Standard Material breakpoints, centralized here -- no per-screen ad hoc
/// `MediaQuery` checks. See the frontend architecture plan's Responsive
/// layout strategy section.
enum ScreenSize { mobile, tablet, wide }

abstract final class Breakpoints {
  static const double tablet = 600;
  static const double wide = 1024;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= wide) return ScreenSize.wide;
    if (width >= tablet) return ScreenSize.tablet;
    return ScreenSize.mobile;
  }
}

/// Caps content width on wide screens (~840px, centered) so search/detail
/// text doesn't stretch edge-to-edge on desktop web.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
    );
  }
}
