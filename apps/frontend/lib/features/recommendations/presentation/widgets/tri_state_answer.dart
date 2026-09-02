import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

/// A Yes / No answer that starts, and can always return to, "not
/// answered." Tapping the already-selected choice clears it back to null.
/// This is what "never force disclosure" looks like as an interaction:
/// every boolean attribute is skippable, not merely optional in theory.
///
/// Touch target is raised toward 48dp via the app-wide ChipThemeData
/// (core/theme/app_theme.dart) -- previously ~32px, the single
/// highest-impact accessibility gap found in the redesign audit, since
/// this renders 26x per form.
class TriStateAnswer extends StatelessWidget {
  const TriStateAnswer({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: AppSpacing.sm),
          _Choice(label: 'Yes', selected: value == true, onTap: () => onChanged(value == true ? null : true)),
          const SizedBox(width: AppSpacing.xs + 2),
          _Choice(label: 'No', selected: value == false, onTap: () => onChanged(value == false ? null : false)),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: scheme.primaryContainer,
      labelStyle: TextStyle(color: selected ? scheme.onPrimaryContainer : null),
    );
  }
}
