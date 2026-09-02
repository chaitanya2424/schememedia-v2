import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// The shared "nothing here, and that's not a bug" state -- previously
/// copy-pasted near-verbatim between Search's `_EmptyResults` and
/// Recommendations' `_EmptyResults` (same icon, same two-line copy
/// structure, same padding).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconXl + AppSpacing.md, color: theme.colorScheme.outline),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
