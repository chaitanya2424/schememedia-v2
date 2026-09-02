import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/responsive.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../domain/scheme_summary.dart';
import '../providers/search_providers.dart';
import '../widgets/scheme_result_card.dart';

/// Deep-linkable query (`/search?q=...`) -- screen 2 of the build order.
class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.initialQuery});

  final String initialQuery;

  @override
  ConsumerState<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);

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
    ref.read(searchNotifierProvider.notifier).search(query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          // Previously had no icon at all, unlike Home's search box for
          // "the same kind of control" -- restyled to match.
          decoration: const InputDecoration(
            hintText: 'Search schemes',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
          ),
          onSubmitted: _runSearch,
        ),
      ),
      body: SafeArea(
        child: ResponsiveContainer(
          child: AsyncValueView<SearchResponse?>(
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
              return _ResultsList(response: response);
            },
          ),
        ),
      ),
    );
  }
}

class _SearchSkeleton extends StatelessWidget {
  const _SearchSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 6,
      itemBuilder: (context, index) => const SkeletonListTile(),
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.response});

  final SearchResponse response;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${response.totalReturned} result${response.totalReturned == 1 ? '' : 's'} for "${response.query}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        if (response.verificationBreakdown.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            sliver: SliverToBoxAdapter(child: _VerificationBreakdownLine(response)),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: wide
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 190,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _resultCard(context, response.results[index]),
                    childCount: response.results.length,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _resultCard(context, response.results[index]),
                    ),
                    childCount: response.results.length,
                  ),
                ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.xl)),
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
