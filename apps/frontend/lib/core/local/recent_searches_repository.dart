import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_schemes_repository.dart' show sharedPreferencesProvider;

class RecentSearchesRepository {
  RecentSearchesRepository(this._prefs);

  final SharedPreferences? _prefs;
  static const _key = 'recent_search_queries';
  static const _maxItems = 6;

  List<String> load() {
    return _prefs?.getStringList(_key) ?? const <String>[];
  }

  Future<void> save(List<String> items) async {
    await _prefs?.setStringList(_key, items);
  }
}

final recentSearchesRepositoryProvider = Provider<RecentSearchesRepository>((ref) {
  SharedPreferences? prefs;
  try {
    prefs = ref.watch(sharedPreferencesProvider);
  } catch (_) {
    // Falls back gracefully if SharedPreferences is not overridden in test
  }
  return RecentSearchesRepository(prefs);
});

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() {
    return ref.watch(recentSearchesRepositoryProvider).load();
  }

  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final updated = [
      trimmed,
      ...state.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ];

    final capped = updated.take(RecentSearchesRepository._maxItems).toList();
    state = capped;
    await ref.read(recentSearchesRepositoryProvider).save(capped);
  }

  Future<void> removeQuery(String query) async {
    final updated = state.where((q) => q.toLowerCase() != query.trim().toLowerCase()).toList();
    state = updated;
    await ref.read(recentSearchesRepositoryProvider).save(updated);
  }

  Future<void> clearAll() async {
    state = const [];
    await ref.read(recentSearchesRepositoryProvider).save(const []);
  }
}

final recentSearchesProvider = NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);
