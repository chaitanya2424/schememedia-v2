import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../data/search_api.dart';
import '../../data/search_repository.dart';
import '../../domain/scheme_summary.dart';

final searchApiProvider = Provider<SearchApi>((ref) => SearchApi(ref.watch(apiClientProvider)));

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(searchApiProvider)),
);

/// Manual (non-codegen) Riverpod notifier -- see the frontend architecture
/// plan's dependency-resolution note on why `riverpod_generator` was
/// dropped in favor of plain `flutter_riverpod`.
class SearchNotifier extends StateNotifier<AsyncValue<SearchResponse?>> {
  SearchNotifier(this._repository) : super(const AsyncValue.data(null));

  final SearchRepository _repository;

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.search(trimmed));
  }
}

final searchNotifierProvider = StateNotifierProvider<SearchNotifier, AsyncValue<SearchResponse?>>(
  (ref) => SearchNotifier(ref.watch(searchRepositoryProvider)),
);
