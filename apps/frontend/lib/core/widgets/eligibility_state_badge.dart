import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../localization/app_strings.dart';
import '../theme/status_colors.dart';
import 'status_pill.dart';

/// Renders `eligibility_state` consistently everywhere it appears.
/// Supports both English and Hindi with verified localized terminology.
class EligibilityStateBadge extends ConsumerWidget {
  const EligibilityStateBadge({super.key, required this.state});

  final EligibilityState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final strings = ref.watch(stringsProvider);

    return StatusPill(
      color: StatusColors.eligibility(state, scheme),
      label: _label(state, strings),
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

  String _label(EligibilityState state, AppStrings strings) => switch (state) {
    EligibilityState.pass => strings.likelyEligible,
    EligibilityState.fail => strings.notEligible,
    EligibilityState.unknown => strings.unknownEligibility,
    EligibilityState.notApplicable => strings.isHindi ? 'लागू नहीं' : 'Not applicable',
    EligibilityState.unrecognized => strings.unknownEligibility,
  };
}
