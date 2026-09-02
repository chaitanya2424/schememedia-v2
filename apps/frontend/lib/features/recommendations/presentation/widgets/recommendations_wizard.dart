import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../domain/eligibility_attribute.dart';
import '../../domain/indian_states.dart';
import '../providers/profile_form_provider.dart';
import '../providers/recommendations_providers.dart';
import 'attribute_groups.dart';
import 'attribute_labels.dart';
import 'profile_form_controller.dart';

sealed class _Page {
  const _Page();
}

class _QueryPage extends _Page {
  const _QueryPage();
}

class _GroupIntroPage extends _Page {
  const _GroupIntroPage(this.group);
  final AttributeGroup group;
}

class _QuestionPage extends _Page {
  const _QuestionPage(this.attribute, this.number);
  final EligibilityAttribute attribute;
  final int number;
}

final _totalQuestions = kAttributeGroups.fold(0, (sum, g) => sum + g.attributes.length);

List<_Page> _buildPages() {
  var n = 0;
  return [
    const _QueryPage(),
    for (final group in kAttributeGroups) ...[
      _GroupIntroPage(group),
      for (final attribute in group.attributes) _QuestionPage(attribute, ++n),
    ],
  ];
}

/// "question -> answer/skip -> next -> progress -> results", per the
/// redesign plan: one attribute per screen instead of v1's five
/// collapsible sections. `ProfileFormController` (via
/// `profileFormControllerProvider`) is reused as-is for answer state --
/// only the presentation is new. Query is required (page 1, can't skip);
/// every one of the 27 attribute questions is skippable, and "Skip
/// remaining, show results" is available on every question/group-intro
/// page -- the never-forced-disclosure guarantee as a concrete escape
/// hatch at every step, not just per-field.
class RecommendationsWizard extends ConsumerStatefulWidget {
  const RecommendationsWizard({super.key});

  @override
  ConsumerState<RecommendationsWizard> createState() => _RecommendationsWizardState();
}

class _RecommendationsWizardState extends ConsumerState<RecommendationsWizard> {
  final _pages = _buildPages();
  final _pageController = PageController();
  final _queryController = TextEditingController();
  int _index = 0;
  String? _queryError;

  @override
  void dispose() {
    _pageController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: AppSpacing.durationMedium,
      curve: Curves.easeOut,
    );
  }

  void _submitFromQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty) {
      setState(() => _queryError = 'Enter what you\'re looking for, e.g. "farmer subsidy".');
      return;
    }
    setState(() => _queryError = null);
    _goTo(1);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
      return;
    }
    _goTo(_index + 1);
  }

  void _skipQuestion(EligibilityAttribute attribute) {
    final controller = ref.read(profileFormControllerProvider);
    switch (attribute.kind) {
      case AttributeKind.boolean:
        controller.setBoolean(attribute, null);
      case AttributeKind.numeric:
        controller.setNumeric(attribute, null);
      case AttributeKind.text:
        controller.setText(attribute, null);
    }
    _next();
  }

  void _finish() {
    final query = _queryController.text.trim();
    final controller = ref.read(profileFormControllerProvider);
    final profile = controller.isEmpty ? null : controller.toProfileJson();
    ref.read(recommendationsNotifierProvider.notifier).fetch(query: query, profile: profile);
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final isQuestionOrIntro = page is! _QueryPage;

    return Column(
      children: [
        if (isQuestionOrIntro) _WizardHeader(index: _index, onBack: () => _goTo(_index - 1), onFinish: _finish),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            itemBuilder: (context, i) {
              final p = _pages[i];
              return switch (p) {
                _QueryPage() => _QueryStep(
                  controller: _queryController,
                  error: _queryError,
                  onSubmit: _submitFromQuery,
                ),
                _GroupIntroPage() => _GroupIntroStep(group: p.group, onContinue: _next),
                _QuestionPage() => _QuestionStep(
                  page: p,
                  onSkip: () => _skipQuestion(p.attribute),
                  onNext: _next,
                ),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({required this.index, required this.onBack, required this.onFinish});

  final int index;
  final VoidCallback onBack;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
              Expanded(
                child: Text(
                  'Optional setup · $_totalQuestions signals available',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              TextButton(
                key: const ValueKey('recommendations_wizard_skip_all_button'),
                onPressed: onFinish,
                child: const Text('Skip all'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QueryStep extends StatelessWidget {
  const _QueryStep({required this.controller, required this.error, required this.onSubmit});

  final TextEditingController controller;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EyebrowLabel('Your recommendation path'),
          const SizedBox(height: AppSpacing.xs),
          Text('What are you looking for?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'About 2 min · skip anytime. We\'ll rank real schemes by how well they fit.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            key: const ValueKey('recommendations_query_field'),
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'e.g. farmer subsidy, scholarship',
              errorText: error,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const ValueKey('recommendations_wizard_continue_button'),
            onPressed: onSubmit,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _GroupIntroStep extends StatelessWidget {
  const _GroupIntroStep({required this.group, required this.onContinue});

  final AttributeGroup group;
  final VoidCallback onContinue;

  static const _icons = {
    'Demographic': Icons.groups_outlined,
    'Economic': Icons.account_balance_outlined,
    'Occupation': Icons.work_outline,
    'Housing & location': Icons.home_outlined,
    'Health': Icons.favorite_border,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.brandTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(_icons[group.title] ?? Icons.help_outline, color: colors.brand),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Let\'s talk about your ${group.title.toLowerCase()}.',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${group.attributes.length} optional question${group.attributes.length == 1 ? '' : 's'} -- skip any of them.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class _QuestionStep extends ConsumerWidget {
  const _QuestionStep({required this.page, required this.onSkip, required this.onNext});

  final _QuestionPage page;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.watch(profileFormControllerProvider);
    final attribute = page.attribute;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: page.number / _totalQuestions,
              minHeight: 4,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          EyebrowLabel('Question ${page.number}'),
          const SizedBox(height: AppSpacing.xs),
          Text(attributeLabel(attribute), style: theme.textTheme.headlineSmall),
          if (attribute == EligibilityAttribute.stateCode) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Some support is specific to a state or rural/urban area.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: SingleChildScrollView(
              child: _AnswerControl(attribute: attribute, controller: controller),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: onSkip, child: const Text('Skip for now')),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next question'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerControl extends StatefulWidget {
  const _AnswerControl({required this.attribute, required this.controller});

  final EligibilityAttribute attribute;
  final ProfileFormController controller;

  @override
  State<_AnswerControl> createState() => _AnswerControlState();
}

class _AnswerControlState extends State<_AnswerControl> {
  late final _numericController = TextEditingController(
    text: widget.controller.valueOf(widget.attribute)?.toString() ?? '',
  );

  @override
  void dispose() {
    _numericController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.attribute.kind) {
      case AttributeKind.boolean:
        final value = widget.controller.valueOf(widget.attribute) as bool?;
        return Column(
          children: [
            _ChoiceButton(
              label: 'Yes',
              selected: value == true,
              onTap: () => widget.controller.setBoolean(widget.attribute, true),
            ),
            const SizedBox(height: AppSpacing.sm),
            _ChoiceButton(
              label: 'No',
              selected: value == false,
              onTap: () => widget.controller.setBoolean(widget.attribute, false),
            ),
          ],
        );
      case AttributeKind.numeric:
        return TextField(
          controller: _numericController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(hintText: '0'),
          onChanged: (text) => widget.controller.setNumeric(widget.attribute, double.tryParse(text)),
        );
      case AttributeKind.text:
        return _StatePicker(controller: widget.controller);
    }
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? colors.primaryAction : colors.surface,
          foregroundColor: selected ? colors.onPrimaryAction : colors.textPrimary,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.centerLeft,
        ),
        child: Align(alignment: Alignment.centerLeft, child: Text(label)),
      ),
    );
  }
}

class _StatePicker extends StatelessWidget {
  const _StatePicker({required this.controller});

  final ProfileFormController controller;

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => const _StateSearchSheet(),
    );
    if (selected != null) controller.setText(EligibilityAttribute.stateCode, selected);
  }

  @override
  Widget build(BuildContext context) {
    final code = controller.valueOf(EligibilityAttribute.stateCode) as String?;
    final name = indianStates.where((s) => s.$1 == code).map((s) => s.$2).firstOrNull;
    return Column(
      children: [
        _ChoiceButton(
          label: name ?? 'Select your state',
          selected: code != null,
          onTap: () => _openPicker(context),
        ),
        const SizedBox(height: AppSpacing.sm),
        _ChoiceButton(
          label: "I'm not sure",
          selected: false,
          onTap: () => controller.setText(EligibilityAttribute.stateCode, null),
        ),
      ],
    );
  }
}

class _StateSearchSheet extends StatefulWidget {
  const _StateSearchSheet();

  @override
  State<_StateSearchSheet> createState() => _StateSearchSheetState();
}

class _StateSearchSheetState extends State<_StateSearchSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final results = indianStates
        .where((s) => s.$2.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search states',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.builder(
                itemCount: results.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(results[i].$2),
                  onTap: () => Navigator.of(context).pop(results[i].$1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
