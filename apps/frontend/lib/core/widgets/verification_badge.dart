import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../theme/status_colors.dart';

/// Renders `verification_status` (+ `needs_review`, when true) consistently
/// everywhere a scheme appears -- see the frontend architecture plan's note
/// that these two fields are the product's core honesty requirement, not
/// an afterthought on one screen.
class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status, this.needsReview = false});

  final VerificationStatus status;
  final bool needsReview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        _StatusChip(color: StatusColors.verification(status, scheme), label: _label(status)),
        if (needsReview) _StatusChip(color: StatusColors.warning(scheme), label: 'Needs review'),
      ],
    );
  }

  String _label(VerificationStatus status) => switch (status) {
    VerificationStatus.officiallyVerified => 'Officially verified',
    VerificationStatus.sourceProvided => 'Source provided',
    VerificationStatus.unverified => 'Unverified',
    VerificationStatus.unrecognized => 'Unknown',
  };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
