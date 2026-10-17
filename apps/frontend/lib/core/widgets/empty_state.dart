import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// The shared "nothing here, and that's not a bug" state -- enhanced with
/// a soft tinted icon container and clear Gov-Tech typography.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.xxl,
          horizontal: AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.brandTint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.brand.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                size: AppSpacing.iconXl,
                color: colors.brand,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

