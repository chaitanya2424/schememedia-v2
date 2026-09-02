import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../domain/scheme_detail.dart';
import '../providers/scheme_detail_providers.dart';

/// Screen 3 of the build order. Renders the full `SchemeDetailOut`: header,
/// ministry/jurisdiction/category, benefits (flagging truncated ones),
/// documents (flagging needs_review), tags, and the official link -- *or*
/// an explicit "no official link available" (never silently omitted,
/// matching the backend/assistant's own honesty rule). Like/save/rating
/// counts are read-only: no auth yet, so no write actions.
class SchemeDetailScreen extends ConsumerWidget {
  const SchemeDetailScreen({super.key, required this.identifier});

  final String identifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(schemeDetailProvider(identifier));

    return Scaffold(
      appBar: AppBar(title: const Text('Scheme details')),
      body: SafeArea(
        child: ResponsiveContainer(
          child: AsyncValueView<SchemeDetail>(
            value: detailAsync,
            onRetry: () => ref.invalidate(schemeDetailProvider(identifier)),
            data: (context, detail) => _DetailBody(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final SchemeDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(detail.name, style: theme.textTheme.headlineSmall),
        if (detail.nameHi != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(detail.nameHi!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline)),
        ],
        const SizedBox(height: AppSpacing.sm),
        VerificationBadge(status: detail.verificationStatus, needsReview: detail.needsReview),
        const SizedBox(height: AppSpacing.lg),
        _InfoRow(label: 'Ministry', value: detail.ministry),
        _InfoRow(label: 'Category', value: detail.category),
        _InfoRow(label: 'Jurisdiction', value: detail.stateCode ?? detail.jurisdiction.name),
        if (detail.applicationDeadline != null)
          _InfoRow(label: 'Application deadline', value: detail.applicationDeadline),
        if (detail.descriptionLong != null || detail.descriptionShort != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('About', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(detail.descriptionLong ?? detail.descriptionShort!),
        ],
        if (detail.benefits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Benefits', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          ...detail.benefits.map(
            (b) => _BulletLine(
              text: b.amountText,
              flagged: b.isTruncated,
              flagLabel: 'truncated in source',
            ),
          ),
        ],
        if (detail.documents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Documents required', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          ...detail.documents.map(
            (d) => _BulletLine(
              text: d.isMandatory ? '${d.name} (mandatory)' : d.name,
              flagged: d.needsReview,
              flagLabel: 'needs review',
            ),
          ),
        ],
        if (detail.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
            for (final tag in detail.tags) Chip(label: Text(tag)),
          ]),
        ],
        const SizedBox(height: AppSpacing.lg),
        _OfficialLink(url: detail.officialUrl),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            _StatCount(icon: Icons.favorite_border, count: detail.likeCount),
            const SizedBox(width: AppSpacing.lg),
            _StatCount(icon: Icons.bookmark_border, count: detail.saveCount),
            const SizedBox(width: AppSpacing.lg),
            _StatCount(icon: Icons.comment_outlined, count: detail.commentCount),
            if (detail.averageRating != null) ...[
              const SizedBox(width: AppSpacing.lg),
              _StatCount(icon: Icons.star_border, count: detail.averageRating!.toStringAsFixed(1)),
            ],
          ],
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ),
          Expanded(child: Text(value!, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.flagged, required this.flagLabel});

  final String text;
  final bool flagged;
  final String flagLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
          if (flagged) ...[
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: flagLabel,
              child: Icon(Icons.warning_amber, size: 16, color: Theme.of(context).colorScheme.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfficialLink extends StatelessWidget {
  const _OfficialLink({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    // Never silently omitted -- an absent official_url is shown explicitly,
    // matching the backend/assistant's own honesty rule.
    if (url == null) {
      return Text(
        'No official link available for this scheme.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
      );
    }
    return OutlinedButton.icon(
      onPressed: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
      icon: const Icon(Icons.open_in_new),
      label: const Text('Visit official page'),
    );
  }
}

class _StatCount extends StatelessWidget {
  const _StatCount({required this.icon, required this.count});

  final IconData icon;
  final Object count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Text('$count', style: theme.textTheme.bodySmall),
      ],
    );
  }
}
