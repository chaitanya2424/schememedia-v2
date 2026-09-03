import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/enums.dart';

/// The small subset of scheme fields the Saved screen needs to render a
/// real `SchemeCard` without a batch-fetch-by-ids endpoint (none exists).
/// Cached alongside the ID at save time -- every field is real data the
/// card already had in hand, nothing invented.
class SavedScheme {
  const SavedScheme({
    required this.schemeId,
    required this.name,
    required this.category,
    required this.description,
    required this.verificationStatus,
    required this.needsReview,
  });

  final String schemeId;
  final String name;
  final String? category;
  final String? description;
  final VerificationStatus verificationStatus;
  final bool needsReview;

  Map<String, dynamic> toJson() => {
    'schemeId': schemeId,
    'name': name,
    'category': category,
    'description': description,
    'verificationStatus': const VerificationStatusConverter().toJson(verificationStatus),
    'needsReview': needsReview,
  };

  factory SavedScheme.fromJson(Map<String, dynamic> json) => SavedScheme(
    schemeId: json['schemeId'] as String,
    name: json['name'] as String,
    category: json['category'] as String?,
    description: json['description'] as String?,
    verificationStatus: const VerificationStatusConverter().fromJson(
      json['verificationStatus'] as String,
    ),
    needsReview: json['needsReview'] as bool,
  );
}

/// Which schemes are saved, on this device only -- real persistence
/// (survives app restarts), not synced to an account. See the redesign
/// plan's Phase A/B capability table: account-linked saved schemes with
/// cross-device sync needs backend work not yet done; this is the honest
/// Phase A version, not a placeholder pretending to be one.
class SavedSchemesRepository {
  SavedSchemesRepository(this._prefs);

  static const _key = 'saved_schemes';

  final SharedPreferences _prefs;

  Map<String, SavedScheme> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (id, json) => MapEntry(id, SavedScheme.fromJson(json as Map<String, dynamic>)),
    );
  }

  Future<void> save(Map<String, SavedScheme> schemes) {
    final encoded = jsonEncode(schemes.map((id, s) => MapEntry(id, s.toJson())));
    return _prefs.setString(_key, encoded);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('overridden in main() once SharedPreferences.getInstance() resolves');
});

final savedSchemesRepositoryProvider = Provider<SavedSchemesRepository>((ref) {
  return SavedSchemesRepository(ref.watch(sharedPreferencesProvider));
});

/// The saved schemes, held in memory and mirrored to local storage on
/// every change. `SchemeCard`'s bookmark toggle reads/writes this
/// directly -- no screen needs its own copy of the toggle logic.
class SavedSchemesNotifier extends Notifier<Map<String, SavedScheme>> {
  @override
  Map<String, SavedScheme> build() {
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

  void toggle(SavedScheme scheme) {
    final next = {...state};
    if (!next.containsKey(scheme.schemeId)) {
      next[scheme.schemeId] = scheme;
    } else {
      next.remove(scheme.schemeId);
    }
    state = next;
    try {
      ref.read(savedSchemesRepositoryProvider).save(next);
    } catch (_) {
      // No local storage available in this context -- in-memory only.
    }
  }

  bool isSaved(String schemeId) => state.containsKey(schemeId);
}

final savedSchemesProvider = NotifierProvider<SavedSchemesNotifier, Map<String, SavedScheme>>(
  SavedSchemesNotifier.new,
);
