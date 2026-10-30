import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/status_colors.dart';
import '../../domain/assistant_message.dart';
import '../providers/assistant_providers.dart';
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.18),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

class _AssistantBubble extends ConsumerStatefulWidget {
  const _AssistantBubble({required this.turn});

  final AssistantTurn turn;

  @override
  ConsumerState<_AssistantBubble> createState() => _AssistantBubbleState();
}

class _AssistantBubbleState extends ConsumerState<_AssistantBubble> {
  bool _sourcesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
    final turn = widget.turn;
    final hasWarnings = turn.groundingWarnings.isNotEmpty;
    final hasEvidence = turn.evidence.results.isNotEmpty;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              bottomLeft: Radius.circular(4),
            ),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.brandTint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.auto_awesome, size: 12, color: colors.brand),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    strings.isHindi ? 'कल्याण सहायक' : 'Welfare Assistant',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.brand,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      strings.isHindi ? 'नियम आधारित' : 'Rule Grounded',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                turn.reply,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  height: 1.45,
                ),
              ),
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
                        ? strings.hideSources
                        : strings.sourcesWithCount(turn.evidence.results.length),
                  ),
                ),
                if (_sourcesExpanded) ...[
                  Text(
                    turn.evidence.profileProvided
                        ? (strings.isHindi
                            ? 'आपकी जानकारी के आधार पर "${turn.evidence.query}" के लिए खोज की गई।'
                            : 'Based on what you told me, searched for "${turn.evidence.query}".')
                        : (strings.isHindi
                            ? '"${turn.evidence.query}" के लिए खोज की गई -- प्रोफ़ाइल विवरण के बिना अधिकांश पात्रता अस्पष्ट है।'
                            : 'Searched for "${turn.evidence.query}" -- no profile details yet, so eligibility below is mostly unknown.'),
                    style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
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

class _GroundingWarningBanner extends ConsumerWidget {
  const _GroundingWarningBanner({required this.warnings});

  final List<String> warnings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
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
                  strings.replyAccuracyWarning,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                for (final warning in warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '• $warning',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.textPrimary,
                      ),
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

class _ErrorBanner extends ConsumerWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final isRetryable = message.contains('No connection') ||
        message.contains('unavailable') ||
        message.contains('went wrong');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.error_outline, size: AppSpacing.iconSm, color: scheme.onErrorContainer),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
          if (isRetryable) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: () => ref.read(assistantNotifierProvider.notifier).retryLastMessage(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry Send'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
