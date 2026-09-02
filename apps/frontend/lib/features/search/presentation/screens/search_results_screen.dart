import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/async_value_view.dart';
import '../../../../core/widgets/responsive.dart';
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
          decoration: const InputDecoration(
            hintText: 'Search schemes',
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
            emptyBuilder: (context) => const _EmptyResults(),
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

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.response});

  final SearchResponse response;

  @override
  Widget build(BuildContext context) {
    final wide = Breakpoints.of(context) == ScreenSize.wide;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Text(
              '${response.totalReturned} result${response.totalReturned == 1 ? '' : 's'} for "${response.query}"',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          sliver: wide
              ? SliverGrid(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisExtent: 180,
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

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) {
    // The backend is honest about a genuine zero-result search; the UI
    // should be too, not imply a bug -- see the frontend architecture plan.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            const Text('No schemes matched this search.', textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Try a different or more general term.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
