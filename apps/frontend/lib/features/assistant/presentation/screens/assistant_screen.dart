import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/responsive.dart';
import '../providers/assistant_providers.dart';
import '../widgets/chat_entry_view.dart';

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
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assistantNotifierProvider);
    _scrollToBottomIfGrew(state.history.length);

    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: 900,
          child: Column(
            children: [
              Expanded(
                child: state.history.isEmpty && !state.isSending
                    ? _EmptyState(
                        onExampleTap: (example) {
                          _controller.text = example;
                          _send();
                        },
                      )
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
              _InputBar(controller: _controller, enabled: !state.isSending, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onExampleTap});

  final ValueChanged<String> onExampleTap;

  static const _examples = [
    'I\'m a farmer with 2 acres, what schemes can help me?',
    'Are there any scholarships for SC/ST students?',
    'I\'m pregnant and unemployed -- what support is available?',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Describe your situation in your own words.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'The assistant only answers using real scheme data -- it will tell you '
              'when it doesn\'t know something rather than guess.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              alignment: WrapAlignment.center,
              children: [
                for (final example in _examples)
                  ActionChip(label: Text(example), onPressed: () => onExampleTap(example)),
              ],
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 14,
              width: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
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
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('assistant_message_field'),
              controller: controller,
              enabled: enabled,
              minLines: 1,
              maxLines: 5,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(hintText: 'Ask about a scheme or your eligibility…'),
              onSubmitted: (_) => onSend(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            key: const ValueKey('assistant_send_button'),
            tooltip: enabled ? 'Send message' : 'Sending…',
            onPressed: enabled ? onSend : null,
            icon: enabled
                ? const Icon(Icons.send)
                : const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
          ),
        ],
      ),
    );
  }
}
