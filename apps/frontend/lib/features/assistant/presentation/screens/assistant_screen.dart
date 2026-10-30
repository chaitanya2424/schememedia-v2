import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/responsive.dart';
import '../providers/assistant_providers.dart';
import '../widgets/chat_entry_view.dart';

/// Example prompts -- shown as the empty state's primary content, and
/// again (collapsed) via _MoreIdeas once a conversation is underway, since
/// previously they vanished permanently after message one with no way
/// back to them.
const _examples = [
  'I\'m a farmer with 2 acres, what schemes can help me?',
  'Are there any scholarships for SC/ST students?',
  'I\'m pregnant and unemployed -- what support is available?',
];

const _hindiExamples = [
  'मैं 2 एकड़ जमीन वाला किसान हूँ, मुझे किन योजनाओं से मदद मिल सकती है?',
  'क्या अनुसूचित जाति/जनजाति (SC/ST) छात्रों के लिए छात्रवृत्तियां हैं?',
  'मातृ वंदना और गर्भवती महिलाओं के लिए वित्तीय सहायता क्या है?',
];

/// The backend's own validated limit (AssistantRequest.message, api/v1/
/// routers/assistant.py) -- surfaced here via TextField's own maxLength so
/// it's discoverable before a failed send, not after.
const _maxMessageLength = 2000;

/// Build-order step 5: natural-language chat against the grounded
/// assistant. Local-only history (the backend is stateless per turn); no
/// auth, no persistence -- matches the current contract exactly.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  int _lastEntryCount = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final message = _controller.text;
    if (message.trim().isEmpty) return;
    ref.read(assistantNotifierProvider.notifier).sendMessage(message);
    _controller.clear();
  }

  void _scrollToBottomIfGrew(int entryCount) {
    if (entryCount <= _lastEntryCount) return;
    _lastEntryCount = entryCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: AppSpacing.durationMedium,
        curve: Curves.easeOut,
      );
    });
  }

  void _useExample(String example) {
    _controller.text = example;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantNotifierProvider);
    final strings = ref.watch(stringsProvider);
    _scrollToBottomIfGrew(state.history.length);
    final isEmpty = state.history.isEmpty && !state.isSending;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.isHindi ? 'कल्याण सहायक' : 'Assistant'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: Column(
            children: [
              Expanded(
                child: isEmpty
                    ? _EmptyState(onExampleTap: _useExample)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.history.length + (state.isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.history.length) {
                            return const _TypingIndicator();
                          }
                          return ChatEntryView(entry: state.history[index]);
                        },
                      ),
              ),
              // Previously the example prompts vanished for good after the
              // first message -- a small always-available way back to them.
              if (!isEmpty) _MoreIdeas(onExampleTap: _useExample),
              _InputBar(controller: _controller, enabled: !state.isSending, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreIdeas extends ConsumerStatefulWidget {
  const _MoreIdeas({required this.onExampleTap});

  final ValueChanged<String> onExampleTap;

  @override
  ConsumerState<_MoreIdeas> createState() => _MoreIdeasState();
}

class _MoreIdeasState extends ConsumerState<_MoreIdeas> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(stringsProvider);
    final examples = strings.isHindi ? _hindiExamples : _examples;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.expand_less : Icons.lightbulb_outline),
              label: Text(
                _expanded
                    ? (strings.isHindi ? 'सुझाव छिपाएं' : 'Hide question ideas')
                    : (strings.isHindi ? 'अन्य प्रश्न सुझाव' : 'More question ideas'),
              ),
            ),
          ),
          if (_expanded) ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final example in examples)
                  ActionChip(label: Text(example), onPressed: () => widget.onExampleTap(example)),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Exact copy from the reference: eyebrow "A GROUNDED GUIDE", headline
/// "Ask, then understand.", suggestion prompts as stacked full-width
/// cards (not chips), a "grounded in sources" trust banner.
class _EmptyState extends ConsumerWidget {
  const _EmptyState({required this.onExampleTap});

  final ValueChanged<String> onExampleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
    final examples = strings.isHindi ? _hindiExamples : _examples;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.brand, const Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.brand.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          strings.isHindi ? 'कल्याण सहायक' : 'Welfare Assistant',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            strings.isHindi ? 'सत्यापित नियम' : 'Grounded AI',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF047857),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      strings.isHindi
                          ? 'आधिकारिक सरकारी नियमों पर आधारित स्पष्ट मार्गदर्शन।'
                          : 'Clear, trusted guidance verified against official rules.',
                      style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.divider.withValues(alpha: 0.8)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, size: 16, color: colors.brand),
                    const SizedBox(width: 6),
                    Text(
                      strings.isHindi ? 'सामान्य प्रश्न सुझाव' : 'Frequently Asked Questions',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final example in examples) ...[
                  _SuggestionCard(text: example, onTap: () => onExampleTap(example)),
                  if (example != examples.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.brandTint,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: colors.brand.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: colors.brand, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.answersGrounded,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.brand,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        strings.answersGroundedSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 14, color: colors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_ios_rounded, size: 11, color: colors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: colors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.brand),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Thinking…', style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends ConsumerWidget {
  const _InputBar({required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider.withValues(alpha: 0.7))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.divider.withValues(alpha: 0.8)),
              ),
              child: TextField(
                key: const ValueKey('assistant_message_field'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 4,
                maxLength: _maxMessageLength,
                textInputAction: TextInputAction.send,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: strings.assistantInputHint,
                  hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13.5),
                  counterText: '',
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            key: const ValueKey('assistant_send_button'),
            tooltip: enabled ? strings.sendMessageTooltip : strings.sendingTooltip,
            onPressed: enabled ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: colors.primaryAction,
              foregroundColor: colors.onPrimaryAction,
              minimumSize: const Size(38, 38),
              padding: EdgeInsets.zero,
            ),
            icon: enabled
                ? const Icon(Icons.arrow_upward_rounded, size: 20)
                : SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colors.onPrimaryAction),
                  ),
          ),
        ],
      ),
    );
  }
}
