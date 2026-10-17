import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/eyebrow_label.dart';
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
          const EyebrowLabel('AI WELFARE ASSISTANT'),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.isHindi ? 'पूछें, और स्पष्ट समझें।' : 'Ask, then understand.',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            strings.isHindi
                ? 'मैं आधिकारिक नियमों का संदर्भ दूंगा, पात्रता स्पष्ट करूंगा और कभी अनुमान नहीं लगाऊंगा।'
                : "I'll point to the rule, explain the uncertainty and never guess on your behalf.",
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  strings.isHindi ? 'आप क्या जानना चाहते हैं?' : 'What would you like to know?',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.isHindi
                      ? 'किसी योजना, लाभ या पात्रता दस्तावेजों के बारे में प्रश्न पूछें।'
                      : 'Try a question about a scheme, a benefit or the documents you may need.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final example in examples) ...[
                  _SuggestionCard(text: example, onTap: () => onExampleTap(example)),
                  if (example != examples.last) const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: Color(0xFF1D4ED8), size: 18),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Answers are grounded in sources',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'We show you where the information comes from so you can check it yourself.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF1E40AF),
                          height: 1.4,
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          side: BorderSide(color: colors.divider),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
        ),
        child: Row(
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF2563EB)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                textAlign: TextAlign.left,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: AppSpacing.iconSm, color: colors.brand),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('Thinking…', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.enabled, required this.onSend});

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider.withValues(alpha: 0.6))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: colors.divider),
              ),
              child: TextField(
                key: const ValueKey('assistant_message_field'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                maxLength: _maxMessageLength,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(
                  hintText: 'Ask about a scheme, benefit, or eligibility…',
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            key: const ValueKey('assistant_send_button'),
            tooltip: enabled ? 'Send message' : 'Sending…',
            onPressed: enabled ? onSend : null,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            icon: enabled
                ? const Icon(Icons.send_rounded)
                : const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
