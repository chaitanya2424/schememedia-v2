import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which scheme IDs are saved, on this device only -- real persistence
/// (survives app restarts), not synced to an account. See the redesign
/// plan's Phase A/B capability table: account-linked saved schemes with
/// cross-device sync needs backend work not yet done; this is the honest
/// Phase A version, not a placeholder pretending to be one.
class SavedSchemesRepository {
  SavedSchemesRepository(this._prefs);

  static const _key = 'saved_scheme_ids';

  final SharedPreferences _prefs;

  Set<String> load() => _prefs.getStringList(_key)?.toSet() ?? {};

  Future<void> save(Set<String> ids) => _prefs.setStringList(_key, ids.toList());
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('overridden in main() once SharedPreferences.getInstance() resolves');
});

final savedSchemesRepositoryProvider = Provider<SavedSchemesRepository>((ref) {
  return SavedSchemesRepository(ref.watch(sharedPreferencesProvider));
});

/// The saved scheme IDs, held in memory and mirrored to local storage on
/// every change. `SchemeCard`'s bookmark toggle reads/writes this
/// directly -- no screen needs its own copy of the toggle logic.
class SavedSchemeIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // Degrades to in-memory-only rather than crashing every screen that
    // renders a SchemeCard: several widget tests build a bare
    // ProviderContainer with no sharedPreferencesProvider override (only
    // main.dart provides the real one, after awaiting
    // SharedPreferences.getInstance()).
    try {
      return ref.watch(savedSchemesRepositoryProvider).load();
    } catch (_) {
      return {};
    }
  }

  void toggle(String schemeId) {
    final next = {...state};
    if (!next.remove(schemeId)) next.add(schemeId);
    state = next;
    try {
      ref.read(savedSchemesRepositoryProvider).save(next);
    } catch (_) {
      // No local storage available in this context -- in-memory only.
    }
  }

  bool isSaved(String schemeId) => state.contains(schemeId);
}

final savedSchemeIdsProvider = NotifierProvider<SavedSchemeIdsNotifier, Set<String>>(
  SavedSchemeIdsNotifier.new,
);
