import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/language_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A compact, high-contrast Gov-Tech language toggle button.
/// Displays `🌐 EN | हिं` with immediate active feedback.
class LanguageToggleButton extends ConsumerWidget {
  const LanguageToggleButton({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final colors = context.colors;
    final isHindi = language == AppLanguage.hindi;

    return InkWell(
      onTap: () => ref.read(languageProvider.notifier).toggle(),
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: colors.brandTint,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: colors.brand.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.translate_rounded,
              size: 14,
              color: colors.brand,
            ),
            const SizedBox(width: 5),
            Text(
              'EN',
              style: TextStyle(
                fontSize: 11,
                fontWeight: !isHindi ? FontWeight.w800 : FontWeight.w500,
                color: !isHindi ? colors.brand : colors.textSecondary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '|',
                style: TextStyle(
                  fontSize: 10,
                  color: colors.brand.withValues(alpha: 0.4),
                ),
              ),
            ),
            Text(
              'हिं',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHindi ? FontWeight.w800 : FontWeight.w500,
                color: isHindi ? colors.brand : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
