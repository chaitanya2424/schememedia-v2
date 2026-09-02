import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../domain/assistant_message.dart';
import 'evidence_card.dart';

/// Renders one turn of local-only chat history. A `switch` over
/// [ChatEntry]'s three variants -- user / assistant / error -- covers every
/// case at compile time (a `sealed class`, so a future variant is a
/// compile error here, not a silent gap).
class ChatEntryView extends StatelessWidget {
  const ChatEntryView({super.key, required this.entry});

  final ChatEntry entry;

  @override
  Widget build(BuildContext context) {
    return switch (entry) {
      ChatEntryUser(:final message) => _UserBubble(message: message),
      ChatEntryAssistant(:final turn) => _AssistantBubble(turn: turn),
      ChatEntryError(:final message) => _ErrorBanner(message: message),
    };
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Text(message, style: TextStyle(color: scheme.onPrimary)),
        ),
      ),
    );
  }
}

class _AssistantBubble extends StatefulWidget {
  const _AssistantBubble({required this.turn});

  final AssistantTurn turn;

  @override
  State<_AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends State<_AssistantBubble> {
  bool _sourcesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final turn = widget.turn;
    final hasWarnings = turn.groundingWarnings.isNotEmpty;
    final hasEvidence = turn.evidence.results.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(turn.reply),
              // Never swept under the rug: this is the system telling the
              // UI the reply may not be fully trustworthy, so it is always
              // visible, never behind an expand.
              if (hasWarnings) ...[
                const SizedBox(height: AppSpacing.sm),
                _GroundingWarningBanner(warnings: turn.groundingWarnings),
              ],
              if (hasEvidence) ...[
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => setState(() => _sourcesExpanded = !_sourcesExpanded),
                  icon: Icon(_sourcesExpanded ? Icons.expand_less : Icons.expand_more),
                  label: Text(
                    _sourcesExpanded
                        ? 'Hide sources'
                        : 'Sources (${turn.evidence.results.length})',
                  ),
                ),
                if (_sourcesExpanded) ...[
                  Text(
                    turn.evidence.profileProvided
                        ? 'Based on what you told me, searched for "${turn.evidence.query}".'
                        : 'Searched for "${turn.evidence.query}" -- no profile details yet, so eligibility below is mostly unknown.',
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.outline),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final result in turn.evidence.results)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: EvidenceCard(evidence: result),
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GroundingWarningBanner extends StatelessWidget {
  const _GroundingWarningBanner({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StatusColors.warning(theme.colorScheme);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: AppSpacing.iconSm, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This reply may not be fully accurate:',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                for (final warning in warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('• $warning', style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: AppSpacing.iconSm, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
        ],
      ),
    );
  }
}
