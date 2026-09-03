import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/verification_badge.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../recommendations/domain/recommendation.dart';
import '../../../recommendations/presentation/providers/recommendations_providers.dart';
import '../../domain/comment.dart';
import '../../domain/scheme_detail.dart';
import '../../domain/scheme_detail_args.dart';
import '../providers/comments_providers.dart';
import '../providers/scheme_detail_providers.dart';

/// Screen 3 of the build order. Renders the full `SchemeDetailOut` plus,
/// when reached from an eligibility-aware card (For You/Home --
/// see [SchemeDetailArgs]), a real "Why this looks promising" summary and
/// an "Eligibility, explained" rule list -- never fabricated when that
/// context is absent (Explore's plain cards, the assistant's evidence).
class SchemeDetailScreen extends ConsumerStatefulWidget {
  const SchemeDetailScreen({super.key, required this.identifier, this.args});

  final String identifier;
  final SchemeDetailArgs? args;

  @override
  ConsumerState<SchemeDetailScreen> createState() => _SchemeDetailScreenState();
}

class _SchemeDetailScreenState extends ConsumerState<SchemeDetailScreen> {
  final _eligibilityKey = GlobalKey();
  bool _hasScrolled = false;

  void _maybeScrollToEligibility() {
    if (_hasScrolled || widget.args?.scrollToEligibility != true) return;
    final context = _eligibilityKey.currentContext;
    if (context == null) return;
    _hasScrolled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Scrollable.ensureVisible(context, duration: AppSpacing.durationMedium, curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(schemeDetailProvider(widget.identifier));
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
            onRetry: () => ref.invalidate(schemeDetailProvider(widget.identifier)),
            loadingBuilder: (context) => const _DetailSkeleton(),
            data: (context, detail) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScrollToEligibility());
              return _DetailBody(
                detail: detail,
                eligibilityRules: widget.args?.eligibilityRules,
                eligibilityKey: _eligibilityKey,
              );
            },
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
  const _DetailBody({required this.detail, required this.eligibilityRules, required this.eligibilityKey});

  final SchemeDetail detail;
  final List<EligibilityRule>? eligibilityRules;
  final GlobalKey eligibilityKey;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    final primary = _PrimaryColumn(
      detail: detail,
      eligibilityRules: eligibilityRules,
      eligibilityKey: eligibilityKey,
      includeKeyFacts: !wide,
    );

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
  const _PrimaryColumn({
    required this.detail,
    required this.eligibilityRules,
    required this.eligibilityKey,
    required this.includeKeyFacts,
  });

  final SchemeDetail detail;
  final List<EligibilityRule>? eligibilityRules;
  final GlobalKey eligibilityKey;

  /// True on mobile/tablet, where there's no sidebar to hold the key-facts
  /// card -- it renders inline near the top instead.
  final bool includeKeyFacts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final jurisdictionLabel = switch (detail.jurisdiction) {
      Jurisdiction.central => 'Government of India',
      Jurisdiction.state => detail.stateCode != null ? 'Government of ${detail.stateCode}' : 'State government',
      Jurisdiction.unrecognized => null,
    };
    final rules = eligibilityRules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail.category != null || jurisdictionLabel != null)
          EyebrowLabel(
            [detail.category, jurisdictionLabel].whereType<String>().join(' · '),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(detail.name, style: theme.textTheme.headlineSmall),
        if (detail.nameHi != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            detail.nameHi!,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
        if (detail.descriptionShort != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(detail.descriptionShort!, style: theme.textTheme.bodyMedium),
        ],
        if (includeKeyFacts) ...[
          const SizedBox(height: AppSpacing.lg),
          _KeyFactsCard(detail: detail),
        ],
        if (rules != null && rules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _WhyThisLooksPromisingCard(rules: rules),
        ],
        const SizedBox(height: AppSpacing.lg),
        _OverviewCard(detail: detail),
        if (detail.descriptionLong != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('About'),
          _ExpandableText(detail.descriptionLong!),
        ],
        if (detail.benefits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          const SectionHeader('What you may receive'),
          _BenefitsCard(benefits: detail.benefits),
        ],
        if (rules != null && rules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader('Eligibility, explained', key: eligibilityKey),
          _EligibilityExplainedCard(rules: rules),
        ],
        if (detail.documents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _KeepTheseReadyBox(documents: detail.documents),
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
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader('Comments'),
        _CommentsSection(schemeId: detail.schemeId),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Real, templated from the actual PASS rules carried in from For You/
/// Home -- never hand-written placeholder copy. Absent entirely when no
/// eligibility context was passed in (Explore, Assistant evidence).
class _WhyThisLooksPromisingCard extends StatelessWidget {
  const _WhyThisLooksPromisingCard({required this.rules});

  final List<EligibilityRule> rules;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final passLabels = rules
        .where((r) => r.state == EligibilityState.pass)
        .map((r) => r.label)
        .take(2)
        .toList();
    final unknownCount = rules.where((r) => r.state == EligibilityState.unknown).length;
    if (passLabels.isEmpty) return const SizedBox.shrink();

    final body = StringBuffer('Your ${passLabels.join(' and ')} match');
    body.write(passLabels.length == 1 ? 'es' : '');
    body.write(' the first eligibility signals we could verify.');
    if (unknownCount > 0) {
      body.write(' $unknownCount detail${unknownCount == 1 ? '' : 's'} still need checking.');
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F5EC),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this looks promising',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(body.toString(), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
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
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _LikeButton(
                schemeId: detail.schemeId,
                initialLiked: detail.viewerHasLiked,
                initialCount: detail.likeCount,
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

/// A real like toggle -- was previously a read-only `_StatCount`, so
/// nothing on this screen could actually be liked (see the bug report this
/// fixes). Manages its own optimistic local state rather than going
/// through `schemeDetailProvider`: invalidating that family provider would
/// flash the whole page back to its loading skeleton for one tap, which a
/// like button shouldn't do. Reverts on failure and surfaces the error via
/// a SnackBar, same pattern api_exception.dart's `.message` is used
/// elsewhere.
class _LikeButton extends ConsumerStatefulWidget {
  const _LikeButton({
    required this.schemeId,
    required this.initialLiked,
    required this.initialCount,
  });

  final String schemeId;
  // null means "signed out" (see SchemeDetail.viewerHasLiked's doc).
  final bool? initialLiked;
  final int initialCount;

  @override
  ConsumerState<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<_LikeButton> {
  late bool? _liked = widget.initialLiked;
  late int _count = widget.initialCount;
  bool _busy = false;

  Future<void> _onTap() async {
    if (!ref.read(isSignedInProvider)) {
      context.push(AppRoutes.login);
      return;
    }
    if (_busy) return;

    final wasLiked = _liked ?? false;
    setState(() {
      _busy = true;
      _liked = !wasLiked;
      _count += wasLiked ? -1 : 1;
    });

    final repo = ref.read(schemeDetailRepositoryProvider);
    try {
      if (wasLiked) {
        await repo.unlike(widget.schemeId);
      } else {
        await repo.like(widget.schemeId);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _liked = wasLiked;
        _count -= wasLiked ? -1 : 1;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Same mapping as login_screen.dart's own _messageFor -- see there for
  // why this isn't a shared ApiException.displayMessage extension (each
  // screen's copy is deliberately its own, per the frontend architecture
  // plan's error-handling section).
  String _messageFor(ApiException error) {
    return switch (error) {
      ApiNetworkException() => 'No connection. Check your network and try again.',
      ApiValidationException() => 'Please check the details below.',
      ApiNotFoundException(:final message) => message,
      ApiUnavailableException(:final message) => message,
      ApiServerException(:final message) => message,
      ApiUnknownException(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final liked = _liked ?? false;
    return Semantics(
      label: 'likes: $_count${liked ? ', liked by you' : ''}',
      button: true,
      child: InkWell(
        key: const ValueKey('scheme_detail_like_button'),
        onTap: _onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: AppSpacing.iconMd,
                color: liked ? colors.brand : theme.colorScheme.outline,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'likes',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                  Text(
                    '$_count',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: liked ? colors.brand : null,
                      fontWeight: liked ? FontWeight.w600 : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

/// A strong, singular benefit-value card -- previously a flat bulleted
/// list under a plain "Benefits" heading. Groups by `stage` (fetched from
/// the API, previously never rendered) when more than one exists.
class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.benefits});

  final List<Benefit> benefits;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grouped = <String, List<Benefit>>{};
    for (final b in benefits) {
      grouped.putIfAbsent(b.stage ?? 'Benefit', () => []).add(b);
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in grouped.entries) ...[
            if (entry.key != 'Benefit')
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  entry.key,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            for (final b in entry.value) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(b.amountText, style: theme.textTheme.titleMedium),
                  ),
                  if (b.isTruncated)
                    Tooltip(
                      message: 'This amount was cut off in the source data.',
                      child: Icon(
                        Icons.unfold_more,
                        size: AppSpacing.iconSm,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                ],
              ),
              if (b != grouped.values.last.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

/// Each rule real, from the eligibility context passed in -- label,
/// state-templated sub-caption, and a real "Check" action for UNKNOWN
/// rules (re-enters the For You wizard so the user can actually answer
/// it -- not deep-linked to the exact question; see the redesign plan's
/// scope note on this).
class _EligibilityExplainedCard extends ConsumerWidget {
  const _EligibilityExplainedCard({required this.rules});

  final List<EligibilityRule> rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rules.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg),
            _EligibilityRuleRow(rule: rules[i]),
          ],
        ],
      ),
    );
  }
}

class _EligibilityRuleRow extends ConsumerWidget {
  const _EligibilityRuleRow({required this.rule});

  final EligibilityRule rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final (icon, color, caption) = switch (rule.state) {
      EligibilityState.pass => (Icons.check_circle, const Color(0xFF2E7D32), 'Matched from your profile'),
      EligibilityState.fail => (Icons.cancel, Theme.of(context).colorScheme.error, "Doesn't match your profile"),
      EligibilityState.unknown => (Icons.help_outline, const Color(0xFF996600), "We don't have this yet"),
      EligibilityState.notApplicable => (
        Icons.remove_circle_outline,
        theme.colorScheme.outline,
        'Not applicable',
      ),
      EligibilityState.unrecognized => (Icons.help_outline, theme.colorScheme.outline, 'Unknown'),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: AppSpacing.iconMd),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rule.label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '$caption · ${rule.state.name.toUpperCase()}',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
        if (rule.state == EligibilityState.unknown)
          TextButton(
            onPressed: () {
              ref.read(recommendationsNotifierProvider.notifier).reset();
              context.go(AppRoutes.recommendations);
            },
            child: const Text('Check'),
          ),
      ],
    );
  }
}

/// Restyled from a bulleted "Documents required" list into the compact,
/// tinted "Keep these ready" summary box the reference mockups use --
/// real document names, still `SchemeDetail.documents`, not invented.
class _KeepTheseReadyBox extends StatelessWidget {
  const _KeepTheseReadyBox({required this.documents});

  final List<SchemeDocument> documents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final names = documents.map((d) => d.name).join(', ');
    final needsReviewCount = documents.where((d) => d.needsReview).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.description_outlined, size: AppSpacing.iconMd, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Keep these ready', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.xs),
                Text(names, style: theme.textTheme.bodySmall),
                if (needsReviewCount > 0) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '$needsReviewCount document${needsReviewCount == 1 ? '' : 's'} could not be confidently '
                    'parsed -- worth double-checking.',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
                  ),
                ],
              ],
            ),
          ),
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

/// Public list + composer -- was entirely missing before (see the bug
/// report this fixes: the backend's Comment table, counter trigger, and
/// routes already existed, but nothing on this screen read or wrote to
/// them). Listing works for every visitor; the composer only renders
/// signed in, matching the honest signed-out pattern used elsewhere
/// (Profile, Saved) rather than a fake input that fails on submit.
class _CommentsSection extends ConsumerWidget {
  const _CommentsSection({required this.schemeId});

  final String schemeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(isSignedInProvider);
    final commentsAsync = ref.watch(commentsProvider(schemeId));
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (signedIn)
          _CommentComposer(schemeId: schemeId)
        else
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Sign in to ask a question or share your experience.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No comments yet. Be the first to ask a question.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                ),
              );
            }
            return Column(
              children: [
                for (final comment in comments) ...[
                  _CommentRow(schemeId: schemeId, comment: comment),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Comments could not be loaded.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(commentsProvider(schemeId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentComposer extends ConsumerStatefulWidget {
  const _CommentComposer({required this.schemeId});

  final String schemeId;

  @override
  ConsumerState<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends ConsumerState<_CommentComposer> {
  final _controller = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _posting) return;
    setState(() => _posting = true);
    try {
      await ref.read(commentsProvider(widget.schemeId).notifier).post(content);
      _controller.clear();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_messageFor(e))));
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  String _messageFor(ApiException error) {
    return switch (error) {
      ApiNetworkException() => 'No connection. Check your network and try again.',
      ApiValidationException() => 'Please check your comment and try again.',
      ApiNotFoundException(:final message) => message,
      ApiUnavailableException(:final message) => message,
      ApiServerException(:final message) => message,
      ApiUnknownException(:final message) => message,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('scheme_detail_comment_field'),
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            enabled: !_posting,
            decoration: const InputDecoration(hintText: 'Ask a question or leave a comment…'),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filled(
          key: const ValueKey('scheme_detail_comment_send_button'),
          onPressed: _posting ? null : _submit,
          icon: _posting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          tooltip: 'Post comment',
        ),
      ],
    );
  }
}

class _CommentRow extends ConsumerWidget {
  const _CommentRow({required this.schemeId, required this.comment});

  final String schemeId;
  final SchemeComment comment;

  // No date-formatting dependency in this app yet (see pubspec.yaml) --
  // a short, dependency-free relative label is enough for a comment
  // timestamp; anything past a week falls back to the plain ISO date.
  String _relativeTime(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(commentsProvider(schemeId).notifier).delete(comment.id);
    } on ApiException catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not delete this comment.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: colors.brandTint,
                child: Text(
                  (comment.authorName?.trim().isNotEmpty ?? false)
                      ? comment.authorName!.trim()[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.labelMedium?.copyWith(color: colors.brand),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName ?? 'A SchemeMedia user',
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      _relativeTime(comment.createdAt) + (comment.edited ? ' · edited' : ''),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (comment.viewerIsAuthor)
                IconButton(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete your comment',
                  iconSize: AppSpacing.iconMd,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(comment.content, style: theme.textTheme.bodyMedium),
        ],
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
