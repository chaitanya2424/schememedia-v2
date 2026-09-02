import 'package:flutter/material.dart';

/// A Yes / No answer that starts, and can always return to, "not
/// answered." Tapping the already-selected choice clears it back to null.
/// This is what "never force disclosure" looks like as an interaction:
/// every boolean attribute is skippable, not merely optional in theory.
class TriStateAnswer extends StatelessWidget {
  const TriStateAnswer({super.key, required this.label, required this.value, required this.onChanged});

  final String label;
  final bool? value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          _Choice(label: 'Yes', selected: value == true, onTap: () => onChanged(value == true ? null : true)),
          const SizedBox(width: 6),
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
