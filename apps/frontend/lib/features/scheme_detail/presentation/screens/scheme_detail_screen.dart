import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
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
    // The scheme's own name, once loaded, instead of the generic literal
    // "Scheme details" the AppBar previously always showed -- watched
    // independently of the body below so the title updates the moment
    // data arrives without needing its own AsyncValueView.
    final title = detailAsync.value?.name ?? 'Scheme details';

    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: AppSpacing.maxWideContentWidth,
          child: AsyncValueView<SchemeDetail>(
            value: detailAsync,
            onRetry: () => ref.invalidate(schemeDetailProvider(identifier)),
            loadingBuilder: (context) => const _DetailSkeleton(),
            data: (context, detail) => _DetailBody(detail: detail),
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        SkeletonBox(width: 260, height: 26),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 120),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 80),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 80),
      ],
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final SchemeDetail detail;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    final primary = _PrimaryColumn(detail: detail, includeKeyFacts: !wide);

    if (!wide) {
      return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [primary]);
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: primary),
            const SizedBox(width: AppSpacing.lg),
            SizedBox(width: 300, child: _KeyFactsCard(detail: detail)),
          ],
        ),
      ],
    );
  }
}

class _PrimaryColumn extends StatelessWidget {
  const _PrimaryColumn({required this.detail, required this.includeKeyFacts});

  final SchemeDetail detail;

  /// True on mobile/tablet, where there's no sidebar to hold the key-facts
  /// card -- it renders inline near the top instead.
  final bool includeKeyFacts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.name, style: theme.textTheme.headlineSmall),
        if (detail.nameHi != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail.nameHi!,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
        if (includeKeyFacts) ...[
          const SizedBox(height: AppSpacing.lg),
          _KeyFactsCard(detail: detail),
        ],
        const SizedBox(height: AppSpacing.lg),
        _OverviewCard(detail: detail),
        if (detail.descriptionLong != null || detail.descriptionShort != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('About'),
          _ExpandableText(detail.descriptionLong ?? detail.descriptionShort!),
        ],
        if (detail.benefits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Benefits'),
          _BenefitsList(benefits: detail.benefits),
        ],
        if (detail.documents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Documents required'),
          ...detail.documents.map((d) => _DocumentLine(document: d)),
        ],
        if (detail.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('Tags'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final tag in detail.tags) Chip(label: Text(tag))],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Ministry/category/jurisdiction/deadline -- previously a dense, unstyled
/// two-column text list (fixed 110px label column, no icons). Grouped into
/// one card with an icon per fact for scannability.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.detail});

  final SchemeDetail detail;

  @override
  Widget build(BuildContext context) {
    final jurisdictionLabel = switch (detail.jurisdiction) {
      Jurisdiction.central => 'Central government',
      Jurisdiction.state => detail.stateCode != null ? 'State (${detail.stateCode})' : 'State',
      Jurisdiction.unrecognized => null,
    };
    final rows = [
      (icon: Icons.account_balance_outlined, label: 'Ministry', value: detail.ministry),
      (icon: Icons.category_outlined, label: 'Category', value: detail.category),
      (icon: Icons.public_outlined, label: 'Jurisdiction', value: jurisdictionLabel),
      (
        icon: Icons.event_outlined,
        label: 'Application deadline',
        value: detail.applicationDeadline,
      ),
    ].where((r) => r.value != null).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _OverviewRow(icon: rows[i].icon, label: rows[i].label, value: rows[i].value!),
          ],
        ],
      ),
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.iconMd, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Verification status, the official-link CTA, and the read-only stat
/// counts -- grouped as one card so they can move as a unit into a sticky
/// sidebar on wide layouts instead of being scattered through the page.
class _KeyFactsCard extends StatelessWidget {
  const _KeyFactsCard({required this.detail});

  final SchemeDetail detail;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VerificationBadge(status: detail.verificationStatus, needsReview: detail.needsReview),
          const SizedBox(height: AppSpacing.md),
          _OfficialLink(url: detail.officialUrl),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              _StatCount(
                icon: Icons.favorite_border,
                count: detail.likeCount,
                label: 'likes',
              ),
              _StatCount(
                icon: Icons.bookmark_border,
                count: detail.saveCount,
                label: 'saves',
              ),
              _StatCount(
                icon: Icons.comment_outlined,
                count: detail.commentCount,
                label: 'comments',
              ),
              if (detail.averageRating != null)
                _StatCount(
                  icon: Icons.star_border,
                  count: detail.averageRating!.toStringAsFixed(1),
                  label: 'average rating',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Long descriptions previously rendered as one unbounded block of text --
/// collapses to 4 lines with a "Read more"/"Show less" toggle.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSize(
          duration: AppSpacing.durationMedium,
          alignment: Alignment.topLeft,
          child: Text(
            widget.text,
            maxLines: _expanded ? null : 4,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more'),
        ),
      ],
    );
  }
}

/// Benefits grouped by their `stage` field -- previously fetched from the
/// API but never rendered; every benefit rendered as one flat, ungrouped
/// list regardless of stage.
class _BenefitsList extends StatelessWidget {
  const _BenefitsList({required this.benefits});

  final List<Benefit> benefits;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Benefit>>{};
    for (final b in benefits) {
      grouped.putIfAbsent(b.stage ?? 'General', () => []).add(b);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in grouped.entries) ...[
          if (grouped.length > 1) ...[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
              child: Text(
                entry.key,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ),
          ],
          for (final b in entry.value) _BulletLine(text: b.amountText, truncated: b.isTruncated),
        ],
      ],
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.truncated});

  final String text;
  final bool truncated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(text)),
          // Distinct from a "needs review" flag (_DocumentLine below) --
          // previously both used the identical warning-amber icon,
          // disambiguated only by hover/long-press tooltip text.
          if (truncated) ...[
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: 'This amount was cut off in the source data.',
              child: Icon(Icons.unfold_more, size: AppSpacing.iconSm, color: scheme.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentLine extends StatelessWidget {
  const _DocumentLine({required this.document});

  final SchemeDocument document;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
          Expanded(child: Text(document.name)),
          if (document.isMandatory) ...[
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text('Required', style: theme.textTheme.labelSmall),
            ),
          ],
          if (document.needsReview) ...[
            const SizedBox(width: AppSpacing.xs),
            Tooltip(
              message: 'This document could not be confidently parsed -- worth double-checking.',
              child: Icon(
                Icons.flag_outlined,
                size: AppSpacing.iconSm,
                color: theme.colorScheme.tertiary,
              ),
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
    final theme = Theme.of(context);
    // Never silently omitted -- an absent official_url is shown explicitly,
    // matching the backend/assistant's own honesty rule. Given slightly
    // more visual presence than a bare italic caption, while staying calm
    // rather than alarming.
    if (url == null) {
      return Row(
        children: [
          Icon(Icons.link_off, size: AppSpacing.iconSm, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              'No official link available for this scheme.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      );
    }
    // Promoted to a filled primary button -- likely the single most
    // important action on the page, previously an OutlinedButton.
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Visit official page'),
      ),
    );
  }
}

class _StatCount extends StatelessWidget {
  const _StatCount({required this.icon, required this.count, required this.label});

  final IconData icon;
  final Object count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$count $label',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpacing.iconSm, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.xs),
          Text('$count', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
