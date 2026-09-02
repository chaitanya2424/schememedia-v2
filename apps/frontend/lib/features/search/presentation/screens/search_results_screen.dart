import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/eyebrow_label.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/scheme_summary.dart';
import '../providers/search_providers.dart';
import '../widgets/scheme_result_card.dart';

/// Deep-linkable query (`/search?q=...`) -- screen 2 of the build order.
/// "Same to same" fidelity pass: exact copy from the reference, the
/// search box moved from the AppBar into the body (matching the
/// mockup's full header treatment), category chips added.
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
    setState(() => _categoryFilter = null);
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FilterSheet(sortAlphabetically: _sortAlphabetically),
    );
    if (result != null) setState(() => _sortAlphabetically = result);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('SchemeMedia')),
      body: SafeArea(
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const EyebrowLabel('Explore support'),
                const SizedBox(height: AppSpacing.xs),
                Text('Find what may help.', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Search by the help you need, not by a government department.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search schemes, benefits or documents',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      tooltip: 'Filters',
                      onPressed: _openFilters,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: _runSearch,
                ),
                const SizedBox(height: AppSpacing.lg),
                AsyncValueView<SearchResponse?>(
                  value: state,
                  onRetry: () => _runSearch(_controller.text),
                  isEmpty: (response) => response != null && response.results.isEmpty,
                  emptyBuilder: (context) => const EmptyState(
                    icon: Icons.search_off,
                    title: 'No schemes matched this search.',
                    subtitle: 'Try a different or more general term.',
                  ),
                  loadingBuilder: (context) => const _SearchSkeleton(),
                  data: (context, response) {
                    if (response == null) {
                      return const Center(child: Text('Search for a scheme to get started.'));
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

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.sortAlphabetically});

  final bool sortAlphabetically;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sort results', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Relevance (default)'),
            trailing: sortAlphabetically ? null : const Icon(Icons.check),
            onTap: () => Navigator.of(context).pop(false),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Name, A to Z'),
            trailing: sortAlphabetically ? const Icon(Icons.check) : null,
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

/// Category chips filter the already-loaded result page client-side --
/// `/search` has no category parameter to query server-side with. See
/// the redesign plan's addendum on this being a scoped interim measure.
class _ResultsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final categories = response.results.map((r) => r.category).whereType<String>().toSet().toList()
      ..sort();

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
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: categoryFilter == null,
                  onTap: () => onCategorySelected(null),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: _CategoryChip(
                      label: c,
                      selected: categoryFilter == c,
                      onTap: () => onCategorySelected(c),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (response.verificationBreakdown.isNotEmpty) ...[
          _VerificationBreakdownLine(response),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          '${results.length} scheme${results.length == 1 ? '' : 's'} to explore',
          style: Theme.of(context).textTheme.bodyMedium,
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
      selectedColor: colors.primaryAction,
      labelStyle: TextStyle(color: selected ? colors.onPrimaryAction : null),
      showCheckmark: false,
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
          maxCrossAxisExtent: 400,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: 190,
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

/// Already fetched from the API but previously never rendered -- displaying
/// it is completing an already-designed-for UI treatment, not adding new
/// filter behavior (it stays non-interactive).
class _VerificationBreakdownLine extends StatelessWidget {
  const _VerificationBreakdownLine(this.response);

  final SearchResponse response;

  static const _labels = {
    'officially_verified': 'officially verified',
    'source_provided': 'source provided',
    'unverified': 'unverified',
  };

  @override
  Widget build(BuildContext context) {
    final parts = _labels.entries
        .map((e) => (count: response.verificationBreakdown[e.key] ?? 0, label: e.value))
        .where((p) => p.count > 0)
        .map((p) => '${p.count} ${p.label}')
        .join(' · ');
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
    );
  }
}
