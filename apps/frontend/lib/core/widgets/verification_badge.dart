import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../localization/app_strings.dart';
import '../theme/app_spacing.dart';
import '../theme/status_colors.dart';
import 'status_pill.dart';

/// Renders `verification_status` (+ `needs_review`, when true) consistently
/// everywhere a scheme appears. Supports both English and Hindi.
class VerificationBadge extends ConsumerWidget {
  const VerificationBadge({super.key, required this.status, this.needsReview = false});

  final VerificationStatus status;
  final bool needsReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.watch(stringsProvider);

    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs,
      children: [
        StatusPill(
          color: StatusColors.verification(status, scheme),
          label: _label(status, strings),
          icon: _icon(status),
        ),
        if (needsReview)
          StatusPill(
            color: StatusColors.warning(scheme),
            label: strings.isHindi ? 'समीक्षा आवश्यक' : 'Needs review',
            icon: Icons.flag_outlined,
          ),
      ],
    );
  }

  IconData _icon(VerificationStatus status) => switch (status) {
    VerificationStatus.officiallyVerified => Icons.check_circle,
    VerificationStatus.sourceProvided => Icons.description_outlined,
    VerificationStatus.unverified => Icons.help_outline,
    VerificationStatus.unrecognized => Icons.help_outline,
  };

  String _label(VerificationStatus status, AppStrings strings) => switch (status) {
    VerificationStatus.officiallyVerified =>
      strings.isHindi ? 'आधिकारिक सत्यापित' : 'Officially verified',
    VerificationStatus.sourceProvided =>
      strings.isHindi ? 'स्रोत उपलब्ध' : 'Source provided',
    VerificationStatus.unverified =>
      strings.isHindi ? 'असत्यापित' : 'Unverified',
    VerificationStatus.unrecognized =>
      strings.isHindi ? 'अज्ञात' : 'Unknown',
  };
}
