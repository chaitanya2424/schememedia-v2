import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/eligibility_attribute.dart';
import 'attribute_groups.dart';
import 'attribute_labels.dart';
import 'profile_form_controller.dart';
import 'tri_state_answer.dart';

/// Every field optional, grouped Demographic/Economic/Occupation/
/// Housing & location/Health -- so the user is never forced to disclose
/// more than they choose to. See the frontend architecture plan's
/// Recommendations + eligibility explanations section.
class ProfileForm extends StatelessWidget {
  const ProfileForm({super.key, required this.controller});

  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        children: [for (final group in kAttributeGroups) _GroupPanel(group: group, controller: controller)],
      ),
    );
  }
}

class _GroupPanel extends StatelessWidget {
  const _GroupPanel({required this.group, required this.controller});

  final AttributeGroup group;
  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final answered = group.attributes.where((a) => controller.valueOf(a) != null).length;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(child: Text(group.title)),
            // A stronger "never forced" signal than the form's one static
            // paragraph of copy alone -- every section says so itself.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text('Optional', style: theme.textTheme.labelSmall),
            ),
          ],
        ),
        subtitle: answered > 0 ? Text('$answered answered') : null,
        childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
        children: [for (final attribute in group.attributes) _FieldFor(attribute: attribute, controller: controller)],
      ),
    );
  }
}

class _FieldFor extends StatelessWidget {
  const _FieldFor({required this.attribute, required this.controller});

  final EligibilityAttribute attribute;
  final ProfileFormController controller;

  @override
  Widget build(BuildContext context) {
    switch (attribute.kind) {
      case AttributeKind.boolean:
        return TriStateAnswer(
          key: ValueKey('answer_${attribute.wireKey}'),
          label: attributeLabel(attribute),
          value: controller.valueOf(attribute) as bool?,
          onChanged: (value) => controller.setBoolean(attribute, value),
        );
      case AttributeKind.numeric:
        return _NumericField(attribute: attribute, controller: controller);
      case AttributeKind.text:
        return _TextField(attribute: attribute, controller: controller);
    }
  }
}

class _NumericField extends StatefulWidget {
  const _NumericField({required this.attribute, required this.controller});

  final EligibilityAttribute attribute;
  final ProfileFormController controller;

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  late final _textController = TextEditingController(
    text: widget.controller.valueOf(widget.attribute)?.toString() ?? '',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Previously silently discarded unparseable input as "not answered",
    // with no error shown -- e.g. "12.3.4" (multiple dots still pass the
    // digits-and-dots input formatter) parsed to null and vanished.
    final text = _textController.text;
    final hasError = text.isNotEmpty && double.tryParse(text) == null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: TextField(
        key: ValueKey('field_${widget.attribute.wireKey}'),
        controller: _textController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        decoration: InputDecoration(
          labelText: attributeLabel(widget.attribute),
          isDense: true,
          errorText: hasError ? 'Enter a valid number' : null,
          suffixIcon: text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Clear ${attributeLabel(widget.attribute)}',
                  onPressed: () {
                    _textController.clear();
                    widget.controller.setNumeric(widget.attribute, null);
                    setState(() {});
                  },
                ),
        ),
        onChanged: (text) {
          widget.controller.setNumeric(widget.attribute, double.tryParse(text));
          setState(() {}); // refresh clear-icon visibility + error text
        },
      ),
    );
  }
}

class _TextField extends StatefulWidget {
  const _TextField({required this.attribute, required this.controller});

  final EligibilityAttribute attribute;
  final ProfileFormController controller;

  @override
  State<_TextField> createState() => _TextFieldState();
}

class _TextFieldState extends State<_TextField> {
  late final _textController = TextEditingController(
    text: widget.controller.valueOf(widget.attribute) as String? ?? '',
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      child: TextField(
        key: ValueKey('field_${widget.attribute.wireKey}'),
        controller: _textController,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: attributeLabel(widget.attribute),
          hintText: 'e.g. MH, UP, KA (optional)',
          isDense: true,
        ),
        onChanged: (text) => widget.controller.setText(widget.attribute, text),
      ),
    );
  }
}
