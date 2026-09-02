import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../theme/app_spacing.dart';
import '../theme/status_colors.dart';
import 'status_pill.dart';

/// Renders `verification_status` (+ `needs_review`, when true) consistently
/// everywhere a scheme appears -- see the frontend architecture plan's note
/// that these two fields are the product's core honesty requirement, not
/// an afterthought on one screen.
///
/// Each state now carries its own icon (previously text-only, unlike
/// [EligibilityStateBadge]'s icon+text pattern -- inconsistent visual
/// grammar for two badges representing the same "honesty requirement").
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status, this.needsReview = false});

  final VerificationStatus status;
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: AppSpacing.xs + 2,
      runSpacing: AppSpacing.xs,
      children: [
        StatusPill(
          color: StatusColors.verification(status, scheme),
          label: _label(status),
          icon: _icon(status),
        ),
        if (needsReview)
          StatusPill(
            color: StatusColors.warning(scheme),
            label: 'Needs review',
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

  String _label(VerificationStatus status) => switch (status) {
    VerificationStatus.officiallyVerified => 'Officially verified',
    VerificationStatus.sourceProvided => 'Source provided',
    VerificationStatus.unverified => 'Unverified',
    VerificationStatus.unrecognized => 'Unknown',
  };
}
