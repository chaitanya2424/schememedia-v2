import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../theme/status_colors.dart';

/// Renders `eligibility_state` consistently everywhere it appears
/// (recommendations, assistant evidence). `fail` is intentionally muted,
/// not hidden or alarming -- recommendations only ever demotes a `fail`
/// result, never removes it, and the badge should read that way.
class EligibilityStateBadge extends StatelessWidget {
  const EligibilityStateBadge({super.key, required this.state});

  final EligibilityState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = StatusColors.eligibility(state, scheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(state), size: 14, color: color),
          const SizedBox(width: 4),
          Text(_label(state), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  IconData _icon(EligibilityState state) => switch (state) {
    EligibilityState.pass => Icons.check_circle,
    EligibilityState.fail => Icons.cancel_outlined,
    EligibilityState.unknown => Icons.help_outline,
    EligibilityState.notApplicable => Icons.remove_circle_outline,
    EligibilityState.unrecognized => Icons.help_outline,
  };

  String _label(EligibilityState state) => switch (state) {
    EligibilityState.pass => 'Eligible',
    EligibilityState.fail => 'Not eligible',
    EligibilityState.unknown => 'Unknown',
    EligibilityState.notApplicable => 'Not applicable',
    EligibilityState.unrecognized => 'Unknown',
  };
}
