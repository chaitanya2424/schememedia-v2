import 'package:flutter/material.dart';

import '../domain/enums.dart';
import '../theme/status_colors.dart';
import 'status_pill.dart';

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
    return StatusPill(
      color: StatusColors.eligibility(state, scheme),
      label: _label(state),
      icon: _icon(state),
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
