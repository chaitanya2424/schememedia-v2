import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/local/profile_offline_cache_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/language_toggle_button.dart';
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
    final lang = ref.watch(languageProvider);
    final detail = detailAsync.value;
    final title = (lang == AppLanguage.hindi && detail?.nameHi != null)
        ? detail!.nameHi!
        : (detail?.name ?? (lang == AppLanguage.hindi ? 'योजना विवरण' : 'Scheme details'));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: LanguageToggleButton(),
          ),
        ],
      ),
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

class _PrimaryColumn extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    final jurisdictionLabel = switch (detail.jurisdiction) {
      Jurisdiction.central => strings.governmentOfIndia,
      Jurisdiction.state => detail.stateCode != null
          ? (lang == AppLanguage.hindi ? '${detail.stateCode} राज्य सरकार' : 'Government of ${detail.stateCode}')
          : strings.stateGovernment,
      Jurisdiction.unrecognized => null,
    };
    final categoryLabel = detail.category != null ? strings.categoryName(detail.category!) : null;
    final rules = eligibilityRules;

    final primaryName = (lang == AppLanguage.hindi && detail.nameHi != null)
        ? detail.nameHi!
        : detail.name;
    final secondaryName = (lang == AppLanguage.hindi && detail.nameHi != null)
        ? detail.name
        : detail.nameHi;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categoryLabel != null || jurisdictionLabel != null)
          EyebrowLabel(
            [categoryLabel, jurisdictionLabel].whereType<String>().join(' · '),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(primaryName, style: theme.textTheme.headlineSmall),
        if (secondaryName != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            secondaryName,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
        if (ref.watch(profileOfflineCacheRepositoryProvider).isOfflineAvailable) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                  : const Color(0xFF065F46).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF059669).withValues(alpha: 0.45)
                    : const Color(0xFF10B981).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.offline_pin,
                  size: 14,
                  color: theme.brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF059669),
                ),
                const SizedBox(width: 6),
                Text(
                  strings.isHindi ? 'ऑफ़लाइन उपलब्ध · आपकी प्रोफ़ाइल में सहेजा गया' : 'Saved for Offline · Ready Without Internet',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.brightness == Brightness.dark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
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
          SectionHeader(strings.aboutScheme),
          _ExpandableText(detail.descriptionLong!),
        ],
        if (detail.benefits.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(strings.whatYouMayReceive),
          _BenefitsCard(benefits: detail.benefits),
        ],
        if (rules != null && rules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(strings.eligibilityExplained, key: eligibilityKey),
          _EligibilityExplainedCard(rules: rules),
        ],
        if (detail.documents.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _KeepTheseReadyBox(documents: detail.documents),
        ],
        if (detail.tags.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(lang == AppLanguage.hindi ? 'टैग' : 'Tags'),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [for (final tag in detail.tags) Chip(label: Text(tag))],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SectionHeader(lang == AppLanguage.hindi ? 'नागरिक टिप्पणियां' : 'Comments'),
        _CommentsSection(schemeId: detail.schemeId),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// Real, templated from the actual PASS rules carried in from For You/
/// Home -- never hand-written placeholder copy. Absent entirely when no
/// eligibility context was passed in (Explore, Assistant evidence).
class _WhyThisLooksPromisingCard extends ConsumerWidget {
  const _WhyThisLooksPromisingCard({required this.rules});

  final List<EligibilityRule> rules;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    final passLabels = rules
        .where((r) => r.state == EligibilityState.pass)
        .map((r) => (lang == AppLanguage.hindi && r.labelHi != null) ? r.labelHi! : r.label)
        .take(2)
        .toList();
    final unknownCount = rules.where((r) => r.state == EligibilityState.unknown).length;
    if (passLabels.isEmpty) return const SizedBox.shrink();

    final body = StringBuffer(lang == AppLanguage.hindi
        ? 'आपकी ${passLabels.join(' और ')} जानकारी जांची गई प्राथमिक पात्रता शर्तों से मेल खाती है।'
        : 'Your ${passLabels.join(' and ')} match${passLabels.length == 1 ? 'es' : ''} the first eligibility signals we could verify.');
    if (unknownCount > 0) {
      body.write(lang == AppLanguage.hindi
          ? ' $unknownCount विवरण की अभी जांच बाकी है।'
          : ' $unknownCount detail${unknownCount == 1 ? '' : 's'} still need checking.');
    }

    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? const Color(0xFF059669).withValues(alpha: 0.45) : const Color(0xFFA7F3D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF065F46) : const Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.whyThisLooksPromising,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFECFDF5) : const Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? const Color(0xFFD1FAE5) : const Color(0xFF047857),
                    height: 1.4,
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

/// Ministry/category/jurisdiction/deadline -- previously a dense, unstyled
/// two-column text list (fixed 110px label column, no icons). Grouped into
/// one card with an icon per fact for scannability.
class _OverviewCard extends ConsumerWidget {
  const _OverviewCard({required this.detail});

  final SchemeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    final jurisdictionLabel = switch (detail.jurisdiction) {
      Jurisdiction.central => strings.centralGov,
      Jurisdiction.state => detail.stateCode != null ? strings.stateWithCode(detail.stateCode!) : strings.stateGov,
      Jurisdiction.unrecognized => null,
    };
    final categoryVal = detail.category != null ? strings.categoryName(detail.category!) : null;
    final rows = [
      (icon: Icons.account_balance_outlined, label: strings.ministryLabel, value: detail.ministry),
      (icon: Icons.category_outlined, label: strings.categoryLabel, value: categoryVal),
      (icon: Icons.public_outlined, label: strings.jurisdictionFieldLabel, value: jurisdictionLabel),
      (
        icon: Icons.event_outlined,
        label: strings.applicationDeadlineLabel,
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
class _KeyFactsCard extends ConsumerWidget {
  const _KeyFactsCard({required this.detail});

  final SchemeDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
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
                label: strings.savesStat,
              ),
              _StatCount(
                icon: Icons.comment_outlined,
                count: detail.commentCount,
                label: strings.commentsStat,
              ),
              if (detail.averageRating != null)
                _StatCount(
                  icon: Icons.star_border,
                  count: detail.averageRating!.toStringAsFixed(1),
                  label: strings.averageRatingStat,
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
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    final liked = _liked ?? false;
    return Semantics(
      label: '${strings.likesStat}: $_count${liked ? (lang == AppLanguage.hindi ? ', आपकी पसंद' : ', liked by you') : ''}',
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
                    strings.likesStat,
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
class _ExpandableText extends ConsumerStatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  ConsumerState<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends ConsumerState<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
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
          child: Text(_expanded
              ? (lang == AppLanguage.hindi ? 'कम दिखाएं' : 'Show less')
              : (lang == AppLanguage.hindi ? 'और पढ़ें' : 'Read more')),
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
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            for (final b in entry.value) ...[
              Builder(
                builder: (context) {
                  final isDark = theme.brightness == Brightness.dark;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isDark ? const Color(0xFF059669).withValues(alpha: 0.45) : const Color(0xFFBBF7D0),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.currency_rupee,
                          size: 20,
                          color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            b.amountText,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                            ),
                          ),
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
                  );
                },
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
            if (i > 0) const SizedBox(height: AppSpacing.xs),
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
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    final isDark = theme.brightness == Brightness.dark;
    final (icon, color, bgColor, caption) = switch (rule.state) {
      EligibilityState.pass => (
        Icons.check_circle_rounded,
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
        isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4),
        strings.matchedFromProfile,
      ),
      EligibilityState.fail => (
        Icons.cancel_rounded,
        isDark ? const Color(0xFFF87171) : Theme.of(context).colorScheme.error,
        isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : const Color(0xFFFEF2F2),
        strings.doesNotMatchProfile,
      ),
      EligibilityState.unknown => (
        Icons.help_outline_rounded,
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
        isDark ? const Color(0xFF78350F).withValues(alpha: 0.25) : const Color(0xFFFFFBEB),
        strings.weDontHaveThisYet,
      ),
      EligibilityState.notApplicable => (
        Icons.remove_circle_outline_rounded,
        context.colors.textSecondary,
        context.colors.surfaceMuted,
        strings.notApplicable,
      ),
      EligibilityState.unrecognized => (
        Icons.help_outline_rounded,
        context.colors.textSecondary,
        context.colors.surfaceMuted,
        lang == AppLanguage.hindi ? 'अज्ञात' : 'Unknown',
      ),
    };

    final ruleLabel = (lang == AppLanguage.hindi && rule.labelHi != null) ? rule.labelHi! : rule.label;
    final stateLabel = switch (rule.state) {
      EligibilityState.pass => lang == AppLanguage.hindi ? 'सत्यापित' : 'PASS',
      EligibilityState.fail => lang == AppLanguage.hindi ? 'अपात्र' : 'FAIL',
      EligibilityState.unknown => lang == AppLanguage.hindi ? 'जांचें' : 'UNKNOWN',
      EligibilityState.notApplicable => lang == AppLanguage.hindi ? 'लागू नहीं' : 'N/A',
      EligibilityState.unrecognized => lang == AppLanguage.hindi ? 'अज्ञात' : 'UNKNOWN',
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: AppSpacing.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ruleLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                Text(
                  '$caption · $stateLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (rule.state == EligibilityState.unknown)
            FilledButton.tonal(
              onPressed: () {
                ref.read(recommendationsNotifierProvider.notifier).reset();
                context.go(AppRoutes.recommendations);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(strings.checkAction),
            ),
        ],
      ),
    );
  }
}

/// Restyled from a bulleted "Documents required" list into the compact,
/// tinted "Keep these ready" summary box the reference mockups use --
/// real document names, still `SchemeDetail.documents`, not invented.
class _KeepTheseReadyBox extends ConsumerWidget {
  const _KeepTheseReadyBox({required this.documents});

  final List<SchemeDocument> documents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    final needsReviewCount = documents.where((d) => d.needsReview).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(Icons.folder_shared_outlined, size: 20, color: colors.brand),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings.keepTheseReady,
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final doc in documents)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: colors.divider),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.description_outlined, size: 14, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        doc.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (needsReviewCount > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              lang == AppLanguage.hindi
                  ? '$needsReviewCount दस्तावेज़ों की स्पष्ट पुष्टि नहीं हो सकी -- पुनः जांच करना उचित होगा।'
                  : '$needsReviewCount document${needsReviewCount == 1 ? '' : 's'} could not be confidently '
                      'parsed -- worth double-checking.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.tertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfficialLink extends ConsumerWidget {
  const _OfficialLink({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
    if (url == null) {
      return Row(
        children: [
          Icon(Icons.link_off, size: AppSpacing.iconSm, color: theme.colorScheme.outline),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              lang == AppLanguage.hindi
                  ? 'इस योजना के लिए कोई आधिकारिक लिंक उपलब्ध नहीं है।'
                  : 'No official link available for this scheme.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      );
    }
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => launchUrl(Uri.parse(url!), mode: LaunchMode.externalApplication),
        icon: const Icon(Icons.open_in_new),
        label: Text(strings.visitOfficialPage),
        style: FilledButton.styleFrom(
          backgroundColor: context.colors.primaryAction,
          foregroundColor: context.colors.onPrimaryAction,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 1,
        ),
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
    final lang = ref.watch(languageProvider);
    final strings = AppStrings.of(lang);
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
                    lang == AppLanguage.hindi
                        ? 'प्रश्न पूछने या अनुभव साझा करने के लिए साइन इन करें।'
                        : 'Sign in to ask a question or share your experience.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: () => context.push(AppRoutes.login),
                  child: Text(strings.signIn),
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
                  lang == AppLanguage.hindi
                      ? 'अभी कोई टिप्पणी नहीं है। पहला प्रश्न पूछें।'
                      : 'No comments yet. Be the first to ask a question.',
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
                    lang == AppLanguage.hindi
                        ? 'टिप्पणियां लोड नहीं की जा सकीं।'
                        : 'Comments could not be loaded.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => ref.invalidate(commentsProvider(schemeId)),
                  child: Text(strings.retry),
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
    final lang = ref.watch(languageProvider);
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
            decoration: InputDecoration(
              hintText: lang == AppLanguage.hindi
                  ? 'प्रश्न पूछें या टिप्पणी लिखें…'
                  : 'Ask a question or leave a comment…',
            ),
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
          tooltip: lang == AppLanguage.hindi ? 'टिप्पणी पोस्ट करें' : 'Post comment',
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
  String _relativeTime(String iso, bool isHindi) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    final diff = DateTime.now().toUtc().difference(parsed.toUtc());
    if (diff.inMinutes < 1) return isHindi ? 'अभी' : 'just now';
    if (diff.inMinutes < 60) return isHindi ? '${diff.inMinutes} मिनट पहले' : '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return isHindi ? '${diff.inHours} घंटे पहले' : '${diff.inHours}h ago';
    if (diff.inDays < 7) return isHindi ? '${diff.inDays} दिन पहले' : '${diff.inDays}d ago';
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
    final lang = ref.watch(languageProvider);
    final isHindi = lang == AppLanguage.hindi;
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
                      comment.authorName ?? (isHindi ? 'स्कीम मीडिया नागरिक' : 'A SchemeMedia user'),
                      style: theme.textTheme.labelLarge,
                    ),
                    Text(
                      _relativeTime(comment.createdAt, isHindi) + (comment.edited ? (isHindi ? ' · संपादित' : ' · edited') : ''),
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
              if (comment.viewerIsAuthor)
                IconButton(
                  onPressed: () => _delete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: isHindi ? 'अपनी टिप्पणी हटाएं' : 'Delete your comment',
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
