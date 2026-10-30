import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_strings.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/language_toggle_button.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../notifications/presentation/widgets/notification_bell_button.dart';
import '../../domain/scheme_summary.dart';
import '../providers/search_providers.dart';
import '../widgets/scheme_result_card.dart';

/// Deep-linkable query (`/search?q=...`) -- screen 2 of the build order.
/// Modernized Gov-Tech Explore & Search experience with trending chips,
/// dynamic category counts, trust breakdown strip, and enhanced sort sheet.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  String? _categoryFilter;
  bool _sortAlphabetically = false;

  static const _popularQueries = [
    'Farmer Subsidy',
    'Scholarship',
    'PMAY Housing',
    'Ayushman Bharat',
    'Mudra Loan',
    'Women SHG',
  ];

  static const _hindiPopularQueries = [
    'किसान सब्सिडी',
    'छात्रवृत्ति',
    'आवास योजना (PMAY)',
    'आयुष्मान भारत',
    'मुद्रा लोन',
    'महिला स्वयं सहायता समूह',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch(widget.initialQuery));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final clean = query.trim();
    if (clean.isEmpty) return;
    _controller.text = clean;
    setState(() => _categoryFilter = null);
    ref.read(searchNotifierProvider.notifier).search(clean);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => _FilterSheet(sortAlphabetically: _sortAlphabetically),
    );
    if (result != null) setState(() => _sortAlphabetically = result);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);
    final popularQueries = strings.isHindi ? _hindiPopularQueries : _popularQueries;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.colors.brandTint,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(Icons.account_balance, color: context.colors.brand, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(strings.exploreTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: const [
          NotificationBellButton(),
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.md),
            child: LanguageToggleButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EyebrowLabel(strings.publicSchemesDirectory),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.searchByNeed,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  strings.searchDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Enhanced Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(color: colors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: strings.searchSchemesHint,
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.textTertiary),
                      prefixIcon: Icon(Icons.search, color: colors.brand),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: strings.clear,
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            ),
                          Container(
                            height: 24,
                            width: 1,
                            color: colors.divider,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.tune_rounded,
                              color: _sortAlphabetically ? colors.brand : colors.textSecondary,
                            ),
                            tooltip: strings.sortAndFilters,
                            onPressed: _openFilters,
                          ),
                        ],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
                    ),
                    onSubmitted: _runSearch,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Quick Search Tags
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Text(
                        strings.searchSuggestions,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      for (final tag in popularQueries)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: InkWell(
                            onTap: () => _runSearch(tag),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: colors.surfaceMuted,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                                border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                tag,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Search Results or Empty Prompt
                AsyncValueView<SearchResponse?>(
                  value: state,
                  onRetry: () => _runSearch(_controller.text),
                  isEmpty: (response) => response != null && response.results.isEmpty,
                  emptyBuilder: (context) => Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    alignment: Alignment.center,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: strings.noSchemesMatched(_controller.text),
                      subtitle: strings.tryDifferentKeywords,
                    ),
                  ),
                  loadingBuilder: (context) => const _SearchSkeleton(),
                  data: (context, response) {
                    if (response == null) {
                      return _InitialExplorePrompt(onSuggestionSelected: _runSearch);
                    }
                    return _ResultsSection(
                      response: response,
                      categoryFilter: _categoryFilter,
                      onCategorySelected: (c) => setState(() => _categoryFilter = c),
                      sortAlphabetically: _sortAlphabetically,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialExplorePrompt extends ConsumerWidget {
  const _InitialExplorePrompt({required this.onSuggestionSelected});

  final ValueChanged<String> onSuggestionSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    final categories = [
      (label: strings.isHindi ? 'कृषि एवं ग्रामीण' : 'Agriculture & Farming', query: strings.isHindi ? 'कृषि' : 'Agriculture', icon: Icons.grass_rounded, color: const Color(0xFF059669)),
      (label: strings.isHindi ? 'शिक्षा एवं कौशल' : 'Education & Grants', query: strings.isHindi ? 'शिक्षा' : 'Education', icon: Icons.school_rounded, color: const Color(0xFF2563EB)),
      (label: strings.isHindi ? 'स्वास्थ्य एवं चिकित्सा' : 'Healthcare Subsidies', query: strings.isHindi ? 'स्वास्थ्य' : 'Health', icon: Icons.favorite_rounded, color: const Color(0xFFE11D48)),
      (label: strings.isHindi ? 'आवास एवं आश्रय' : 'Housing & Urban Welfare', query: strings.isHindi ? 'आवास' : 'Housing', icon: Icons.home_rounded, color: const Color(0xFFD97706)),
      (label: strings.isHindi ? 'महिला एवं बाल विकास' : 'Women & Child Welfare', query: strings.isHindi ? 'महिला' : 'Women', icon: Icons.family_restroom_rounded, color: const Color(0xFF7C3AED)),
      (label: strings.isHindi ? 'व्यवसाय एवं ऋण' : 'Business & Loans', query: strings.isHindi ? 'व्यवसाय' : 'Business', icon: Icons.account_balance_rounded, color: const Color(0xFF16A34A)),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 20, color: context.colors.brand),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings.popularWelfareDomains,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 250,
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisExtent: 54,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return InkWell(
                onTap: () => onSuggestionSelected(cat.query),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(color: cat.color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 18, color: cat.color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          cat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cat.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet({required this.sortAlphabetically});

  final bool sortAlphabetically;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(stringsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sort_rounded, size: 20, color: context.colors.brand),
              const SizedBox(width: AppSpacing.sm),
              Text(strings.sortSchemes, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            leading: const Icon(Icons.auto_awesome_outlined),
            title: Text(strings.relevanceMatch, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(strings.relevanceSubtitle),
            trailing: sortAlphabetically ? null : Icon(Icons.check_circle_rounded, color: context.colors.brand),
            onTap: () => Navigator.of(context).pop(false),
          ),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
            leading: const Icon(Icons.sort_by_alpha_rounded),
            title: Text(strings.nameAtoZ, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(strings.nameAtoZSubtitle),
            trailing: sortAlphabetically ? Icon(Icons.check_circle_rounded, color: context.colors.brand) : null,
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(6, (_) => const SkeletonListTile()));
  }
}

class _ResultsSection extends ConsumerWidget {
  const _ResultsSection({
    required this.response,
    required this.categoryFilter,
    required this.onCategorySelected,
    required this.sortAlphabetically,
  });

  final SearchResponse response;
  final String? categoryFilter;
  final ValueChanged<String?> onCategorySelected;
  final bool sortAlphabetically;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.colors;
    final strings = ref.watch(stringsProvider);

    // Collect category counts
    final categoryCounts = <String, int>{};
    for (final r in response.results) {
      if (r.category != null) {
        categoryCounts[r.category!] = (categoryCounts[r.category!] ?? 0) + 1;
      }
    }

    final categories = categoryCounts.keys.toList()..sort();

    var results = categoryFilter == null
        ? response.results
        : response.results.where((r) => r.category == categoryFilter).toList();
    if (sortAlphabetically) {
      results = [...results]..sort((a, b) => a.name.compareTo(b.name));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (categories.isNotEmpty) ...[
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: strings.isHindi
                      ? 'सभी (${response.results.length})'
                      : 'All (${response.results.length})',
                  selected: categoryFilter == null,
                  onTap: () => onCategorySelected(null),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: _CategoryChip(
                      label: strings.isHindi
                          ? '${strings.categoryName(c)} (${categoryCounts[c]})'
                          : '$c (${categoryCounts[c]})',
                      selected: categoryFilter == c,
                      onTap: () => onCategorySelected(c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // Verification & Count Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surfaceMuted,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Row(
            children: [
              Text(
                strings.schemesFound(results.length),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              if (response.verificationBreakdown.isNotEmpty)
                _VerificationBreakdownBadges(response),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _ResultsList(results: results),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: colors.surfaceMuted,
      selectedColor: colors.primaryAction,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimaryAction : colors.textPrimary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 13,
      ),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        side: BorderSide(
          color: selected ? colors.primaryAction : colors.divider,
        ),
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results});

  final List<SchemeSummary> results;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    if (wide) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 420,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: 220,
        ),
        itemCount: results.length,
        itemBuilder: (context, index) => _resultCard(context, results[index]),
      );
    }
    return Column(
      children: [
        for (final scheme in results)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _resultCard(context, scheme),
          ),
      ],
    );
  }

  Widget _resultCard(BuildContext context, SchemeSummary scheme) {
    return SchemeResultCard(
      scheme: scheme,
      onTap: () => context.push(AppRoutes.schemeDetailPath(scheme.schemeId)),
    );
  }
}

class _VerificationBreakdownBadges extends ConsumerWidget {
  const _VerificationBreakdownBadges(this.response);

  final SearchResponse response;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(stringsProvider);
    final verifiedCount = response.verificationBreakdown['officially_verified'] ?? 0;

    if (verifiedCount == 0) return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;
    final verifiedColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_rounded, size: 14, color: verifiedColor),
        const SizedBox(width: 4),
        Text(
          strings.verifiedCount(verifiedCount),
          style: theme.textTheme.labelSmall?.copyWith(
            color: verifiedColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
