import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Shared header style for a screen's content sections (Scheme Detail's
/// "About"/"Benefits"/"Documents", etc.) -- one consistent visual weight
/// instead of each screen picking its own ad hoc heading style.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
