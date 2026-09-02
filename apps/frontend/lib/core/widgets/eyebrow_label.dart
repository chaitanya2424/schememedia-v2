import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Small-caps-weight, letter-spaced, saffron-colored label line above a
/// headline -- e.g. "PERSONAL RECOMMENDATIONS", "A GROUNDED GUIDE". A
/// recurring pattern across nearly every screen in the reference
/// mockups, not in the original written spec; shared here rather than
/// each screen rebuilding it.
class EyebrowLabel extends StatelessWidget {
  const EyebrowLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: context.colors.brand,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}
