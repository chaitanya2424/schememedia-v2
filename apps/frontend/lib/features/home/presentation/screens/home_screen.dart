import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/local/profile_offline_cache_repository.dart';
import '../../../../core/local/recent_searches_repository.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';
import '../../../recommendations/domain/recommendation.dart';
import '../../../recommendations/presentation/providers/profile_form_provider.dart';
import '../../../recommendations/presentation/providers/recommendations_providers.dart';
import '../../../recommendations/presentation/widgets/recommendation_card.dart';

const _totalAttributes = 27;

/// The 11 official categories in the SchemeMedia database, paired with
/// icons and distinct Gov-Tech color accents for vibrant visual exploration.
const _welfareCategories = [
  _CategoryItem(name: 'Agriculture', icon: Icons.grass_outlined, color: Color(0xFF16A34A)),
  _CategoryItem(name: 'Education', icon: Icons.school_outlined, color: Color(0xFF2563EB)),
  _CategoryItem(name: 'Health', icon: Icons.favorite_border, color: Color(0xFFDC2626)),
  _CategoryItem(name: 'Women Welfare', icon: Icons.family_restroom_outlined, color: Color(0xFF9333EA)),
  _CategoryItem(name: 'Housing', icon: Icons.home_outlined, color: Color(0xFF4F46E5)),
  _CategoryItem(name: 'Business & Entrepreneurship', icon: Icons.storefront_outlined, color: Color(0xFFD97706)),
  _CategoryItem(name: 'Social Welfare', icon: Icons.groups_outlined, color: Color(0xFF0D9488)),
  _CategoryItem(name: 'Employment', icon: Icons.work_outline, color: Color(0xFFEA580C)),
  _CategoryItem(name: 'Insurance', icon: Icons.shield_outlined, color: Color(0xFF0284C7)),
  _CategoryItem(name: 'Sports & Culture', icon: Icons.emoji_events_outlined, color: Color(0xFFCA8A04)),
  _CategoryItem(name: 'General', icon: Icons.account_balance_outlined, color: Color(0xFF475569)),
];

class _CategoryItem {
  const _CategoryItem({required this.name, required this.icon, required this.color});
  final String name;
  final IconData icon;
  final Color color;
}

/// Quick trending query suggestions for citizens
const _quickSearchPrompts = [
  'PM Kisan',
  'Scholarship',
  'Health Insurance',
  'Housing PMAY',
  'Pension',
];

const _hindiQuickSearchPrompts = [
  'पीएम किसान',
  'छात्रवृत्ति',
  'स्वास्थ्य बीमा',
  'आवास योजना (PMAY)',
  'पेंशन',
];

/// Redesigned Modern & Vibrant Gov-Tech Home Screen.
///
/// Features:
/// 1. Gov-Tech verification header with live date & national portal badge.
/// 2. Modern search bar with quick-tap search suggestion chips.
/// 3. Interactive horizontal Category Chips Carousel exploring all 11 sectors.
/// 4. High-impact Gov-Tech gradient Hero Card with live recommendation counters.
/// 5. Quick Trust & Metric Indicators (1,000+ schemes, 28 States, DPDP-safe).
/// 6. Real "Picked for you" feed and profile confidence progress card.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _submit([String? value]) {
    final query = (value ?? _controller.text).trim();
    if (query.isEmpty) return;
    ref.read(recentSearchesProvider.notifier).addQuery(query);
    context.push(AppRoutes.searchPath(query));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    final cachedOfflineRecs = ref.watch(profileOfflineCacheRepositoryProvider).getCachedRecommendations();
    final recommendations = ref.watch(recommendationsNotifierProvider).valueOrNull ?? cachedOfflineRecs;
    final answered = ref.watch(
      profileFormControllerProvider.select((c) => c.totalAnswered),
    );
    final isOffline = ref.watch(profileOfflineCacheRepositoryProvider).isOfflineAvailable;
    final recentSearches = ref.watch(recentSearchesProvider);

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isOffline) ...[
          const _OfflineStatusBar(),
          const SizedBox(height: AppSpacing.xs),
        ],
        // --- 1. Clean Title with Verified National Portal Badge ---
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.brandTint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: colors.brand.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, size: 13, color: colors.brand),
                  const SizedBox(width: 4),
                  Text(
                    strings.nationalWelfarePortal.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),

        // --- 2. Title ---
        Text(
          strings.heroTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // --- 3. Sleek, Modern Search Bar ---
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: colors.divider.withValues(alpha: 0.8), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, color: colors.brand, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: strings.searchPlaceholder,
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.textTertiary,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onSubmitted: _submit,
                ),
              ),
              if (_controller.text.isNotEmpty)
                IconButton(
                  tooltip: strings.clear,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _controller.clear();
                    setState(() {});
                  },
                ),
              Padding(
                padding: const EdgeInsets.only(right: 6, left: 2),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.primaryAction,
                    foregroundColor: colors.onPrimaryAction,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                  ),
                  onPressed: () => _submit(),
                  child: Text(
                    strings.isHindi ? 'खोजें' : 'Search',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // --- 4. Dynamic Recent Searches & Trending Suggestions ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              Text(
                recentSearches.isNotEmpty
                    ? (strings.isHindi ? 'हाल में: ' : 'Recent: ')
                    : (strings.isHindi ? 'लोकप्रिय: ' : 'Popular: '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (final prompt in (recentSearches.isNotEmpty
                  ? recentSearches
                  : (strings.isHindi ? _hindiQuickSearchPrompts : _quickSearchPrompts)))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: recentSearches.isNotEmpty
                        ? Icon(Icons.history, size: 13, color: colors.brand)
                        : null,
                    backgroundColor: colors.surfaceMuted,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    label: Text(
                      prompt,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onPressed: () {
                      _controller.text = prompt;
                      _submit(prompt);
                    },
                  ),
                ),
              if (recentSearches.isNotEmpty)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: strings.isHindi ? 'इतिहास साफ़ करें' : 'Clear search history',
                  icon: Icon(Icons.close, size: 14, color: colors.textTertiary),
                  onPressed: () => ref.read(recentSearchesProvider.notifier).clearAll(),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- 5. Interactive Category Chips Carousel ---
        Row(
          children: [
            Expanded(
              child: Text(
                strings.exploreByCategory,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.search),
              child: Text(strings.isHindi ? 'सभी योजनाएं' : 'All schemes'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _welfareCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final cat = _welfareCategories[index];
              return InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                onTap: () => context.push(AppRoutes.searchPath(cat.name)),
                child: Container(
                  width: 116,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: colors.divider.withValues(alpha: 0.5)),
                    boxShadow: AppShadows.card(colors.shadow.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: cat.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, size: 19, color: cat.color),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        strings.categoryName(cat.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // --- 6. Modern Gov-Tech Gradient Hero Card ---
        _HeroCard(recommendations: recommendations),
        const SizedBox(height: AppSpacing.lg),

        // --- 7. Quick Impact Trust Stats ---
        const _TrustMetricRow(),
        const SizedBox(height: AppSpacing.xl),

        // --- 8. Profile Confidence (on Mobile) ---
        if (!wide) ...[
          _ProfileConfidenceCard(answered: answered),
          const SizedBox(height: AppSpacing.xl),
        ],

        // --- 9. Picked for You Recommendations Section ---
        Row(
          children: [
            Expanded(
              child: Text(
                strings.heroPickedForYou,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.recommendations),
              child: Text(strings.viewAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _PickedForYou(recommendations: recommendations),
      ],
    );

    if (!wide) {
      return Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.brandTint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_balance, size: 20, color: colors.brand),
              ),
              const SizedBox(width: 10),
              const Text('SchemeMedia'),
            ],
          ),
          actions: const [
            NotificationBellButton(),
            LanguageToggleButton(),
            SizedBox(width: AppSpacing.sm),
          ],
        ),
        body: SafeArea(
          child: ResponsiveContainer(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(recommendationsNotifierProvider);
                ref.invalidate(notificationsProvider);
                await Future.delayed(const Duration(milliseconds: 300));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: mainColumn,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.brandTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance, size: 20, color: colors.brand),
            ),
            const SizedBox(width: 10),
            const Text('SchemeMedia'),
          ],
        ),
        actions: const [
          NotificationBellButton(),
          LanguageToggleButton(),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          maxWidth: AppSpacing.maxWideContentWidth,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recommendationsNotifierProvider);
              ref.invalidate(notificationsProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: mainColumn),
                  const SizedBox(width: AppSpacing.lg),
                  SizedBox(
                    width: 320,
                    child: Column(
                      children: [
                        _ProfileConfidenceCard(answered: answered),
                        const SizedBox(height: AppSpacing.lg),
                        const _ShortcutsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Upgraded Gov-Tech Hero Banner with Modern Deep Navy / Teal Gradient
class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.recommendations});

  final RecommendationResponse? recommendations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
    final categories = recommendations == null
        ? const <String>[]
        : recommendations!.recommendations
              .map((r) => r.category)
              .whereType<String>()
              .toSet()
              .take(3)
              .toList();
    final hasMatches = recommendations != null && recommendations!.totalReturned > 0;

    final String eyebrow = hasMatches
        ? (strings.isHindi ? 'सत्यापित योजनाएं उपलब्ध' : 'Verified Matches Found')
        : (strings.isHindi ? 'स्मार्ट पात्रता मिलान' : 'Smart Eligibility Matcher');
    final String headline = hasMatches
        ? (strings.isHindi
            ? '${recommendations!.totalReturned} योजनाएं आपकी पात्रता के अनुकूल हैं'
            : '${recommendations!.totalReturned} Scheme Match${recommendations!.totalReturned == 1 ? '' : 'es'} Waiting')
        : (strings.isHindi
            ? 'जानिए आप किन योजनाओं के लिए पात्र हैं'
            : 'Know Which Schemes You Qualify For');
    final String body = hasMatches
        ? (categories.isEmpty
              ? (strings.isHindi
                  ? 'आपकी जनसांख्यिकीय प्रोफ़ाइल के अनुसार प्राथमिकता दी गई है।'
                  : 'Prioritized according to your verified profile attributes.')
              : (strings.isHindi
                  ? 'पात्रता श्रेणियां: ${categories.map(strings.categoryName).join(', ')}'
                  : 'Eligible categories: ${categories.join(', ')}'))
        : (strings.isHindi
            ? '1,000+ केंद्र और राज्य कल्याणकारी योजनाओं में अपनी पात्रता जांचें।'
            : 'Check verified eligibility across 1,000+ central & state welfare programs.');
    final String buttonLabel = hasMatches
        ? (strings.isHindi ? 'मेरी योजनाएं देखें' : 'See my matches')
        : (strings.isHindi ? 'पात्रता जांचें' : 'Check My Eligibility');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: AppShadows.raised(colors.shadow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 14, color: Color(0xFFF97316)),
                    const SizedBox(width: 4),
                    Text(
                      eyebrow.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.auto_awesome, color: Color(0xFFF97316)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            headline,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          if (ref.watch(profileOfflineCacheRepositoryProvider).isOfflineAvailable) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF065F46).withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.offline_pin, size: 14, color: Color(0xFF34D399)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${strings.offlineReady} · ${ref.watch(profileOfflineCacheRepositoryProvider).cachedProfileLabel ?? (strings.isHindi ? 'नागरिक' : 'Citizen')}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF6EE7B7),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 38),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
            ),
            onPressed: () => context.go(AppRoutes.recommendations),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

/// Trust and Impact Metrics Row
class _TrustMetricRow extends ConsumerWidget {
  const _TrustMetricRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildItem(context, strings.trustSchemesCount, strings.trustSchemesLabel, Icons.verified_outlined, colors.brand),
          ),
          Container(width: 1, height: 28, color: colors.divider),
          Expanded(
            child: _buildItem(context, strings.trustStatesCount, strings.trustStatesLabel, Icons.map_outlined, const Color(0xFF0D9488)),
          ),
          Container(width: 1, height: 28, color: colors.divider),
          Expanded(
            child: _buildItem(context, strings.trustFreeCount, strings.trustFreeLabel, Icons.lock_outline, const Color(0xFF2563EB)),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, String value, String label, IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileConfidenceCard extends ConsumerWidget {
  const _ProfileConfidenceCard({required this.answered});

  final int answered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
    final ratio = answered / _totalAttributes;
    final percent = (ratio * 100).round();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.isHindi ? 'प्रोफ़ाइल सटीकता' : 'Profile Confidence',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.brandTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percent%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.brand,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            answered == 0
                ? (strings.isHindi
                    ? 'सटीक पात्रता मिलान के लिए कुछ प्रश्नों के उत्तर दें।'
                    : 'Answer questions in your profile for accurate eligibility.')
                : (strings.isHindi
                    ? 'उच्च सटीकता के लिए $_totalAttributes में से $answered विवरण दिए गए।'
                    : '$answered of $_totalAttributes parameters answered for high accuracy.'),
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: colors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(colors.brand),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 13, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${strings.dpdpTitle} · ${strings.dpdpSubtitle}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5, color: colors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.go(AppRoutes.recommendations),
              child: Text(answered == 0 ? strings.startQuestionnaire : strings.reviewDetails(answered)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortcutsCard extends ConsumerWidget {
  const _ShortcutsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(stringsProvider);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
            child: Text(
              strings.quickShortcuts,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          _ShortcutRow(
            icon: Icons.search,
            label: strings.shortcutSearch,
            onTap: () => context.go(AppRoutes.search),
          ),
          _ShortcutRow(
            icon: Icons.auto_awesome_outlined,
            label: strings.shortcutRecommendations,
            onTap: () => context.go(AppRoutes.recommendations),
          ),
          _ShortcutRow(
            icon: Icons.chat_bubble_outline,
            label: strings.shortcutAssistant,
            onTap: () => context.go(AppRoutes.assistant),
          ),
          _ShortcutRow(
            icon: Icons.bookmark_outline,
            label: strings.shortcutSaved,
            onTap: () => context.go(AppRoutes.saved),
          ),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colors.brandTint,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: colors.brand),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, size: AppSpacing.iconMd, color: colors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _PickedForYou extends ConsumerWidget {
  const _PickedForYou({required this.recommendations});

  final RecommendationResponse? recommendations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recommendations == null || recommendations!.recommendations.isEmpty) {
      final theme = Theme.of(context);
      final colors = context.colors;
      final strings = ref.watch(stringsProvider);

      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore_outlined, color: colors.brand),
                const SizedBox(width: 8),
                Text(
                  strings.isHindi ? 'अभी कोई व्यक्तिगत अनुशंसा नहीं है' : 'No personalized recommendations yet',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              strings.isHindi
                  ? 'अपने व्यवसाय, आय और राज्य के अनुकूल योजनाएं देखने के लिए "आपके लिए" में अपनी प्रोफ़ाइल पूरी करें।'
                  : 'Complete your profile questionnaire in "For You" to see schemes matched to your occupation, income, and state.',
              style: theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryAction,
                foregroundColor: colors.onPrimaryAction,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              onPressed: () => context.go(AppRoutes.recommendations),
              icon: const Icon(Icons.tune, size: 15),
              label: Text(strings.isHindi ? 'अपनी प्रोफ़ाइल पूरी करें' : 'Complete My Profile'),
            ),
          ],
        ),
      );
    }

    final top = recommendations!.recommendations.take(3).toList();
    return Column(
      children: [
        for (final rec in top)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: RecommendationCard(recommendation: rec),
          ),
      ],
    );
  }
}

class _OfflineStatusBar extends ConsumerWidget {
  const _OfflineStatusBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = ref.watch(stringsProvider);
    final cachedLabel = ref.watch(profileOfflineCacheRepositoryProvider).cachedProfileLabel ??
        (strings.isHindi ? 'नागरिक' : 'Citizen');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF065F46).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_pin, size: 15, color: Color(0xFF059669)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              strings.isHindi
                  ? '⚡ ऑफ़लाइन मोड सक्रिय · $cachedLabel के लिए योजनाएं सुरक्षित हैं'
                  : '⚡ Offline Mode Active · Schemes cached for $cachedLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF047857),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
