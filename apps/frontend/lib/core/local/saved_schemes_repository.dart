import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/presentation/providers/auth_controller.dart';
import '../../features/saved/data/saved_schemes_api.dart';
import '../../features/saved/data/saved_schemes_remote_repository.dart';
import '../domain/enums.dart';
import '../network/providers.dart';

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

final savedSchemesApiProvider = Provider<SavedSchemesApi>(
  (ref) => SavedSchemesApi(ref.watch(apiClientProvider)),
);

final savedSchemesRemoteRepositoryProvider = Provider<SavedSchemesRemoteRepository>(
  (ref) => SavedSchemesRemoteRepository(ref.watch(savedSchemesApiProvider)),
);

/// The saved schemes, held in memory and mirrored to storage on every
/// change. `SchemeCard`'s bookmark toggle reads/writes this directly --
/// no screen needs its own copy of the toggle logic.
///
/// Dual-mode, behind the same provider API every existing call site
/// already uses (`savedSchemesProvider`/`.toggle()`/`.isSaved()`) -- see
/// the redesign plan's Phase A/B capability table:
///   * Signed out: unchanged from before -- local-only via
///     `shared_preferences`, real persistence, no sync.
///   * Signed in: authoritative on the backend (`/me/saved-schemes`).
///     `build()` `ref.listen`s the auth controller and re-syncs from the
///     server the moment sign-in completes (fresh login, or a restored
///     session at boot) and resets back to the local list on sign-out, so
///     a screen never keeps rendering one account's saves after switching
///     to another (or to no account at all). `toggle()` still updates
///     `state` optimistically first (instant UI feedback either way) and
///     mirrors to local storage regardless of mode, then additionally
///     calls the backend when signed in -- a failed remote call is not
///     surfaced as an error here (SchemeCard's toggle has no error UI);
///     the next sign-in-triggered sync reconciles it.
class SavedSchemesNotifier extends Notifier<Map<String, SavedScheme>> {
  @override
  Map<String, SavedScheme> build() {
    ref.listen(authControllerProvider, (previous, next) {
      final wasSignedIn = previous?.valueOrNull?.isSignedIn ?? false;
      final nowSignedIn = next.valueOrNull?.isSignedIn ?? false;
      if (nowSignedIn && !wasSignedIn) {
        unawaited(syncFromRemote());
      } else if (!nowSignedIn && wasSignedIn) {
        state = _loadLocal();
      }
    });

    // Degrades to in-memory-only rather than crashing every screen that
    // renders a SchemeCard: several widget tests build a bare
    // ProviderContainer with no sharedPreferencesProvider override (only
    // main.dart provides the real one, after awaiting
    // SharedPreferences.getInstance()).
    return _loadLocal();
  }

  Map<String, SavedScheme> _loadLocal() {
    try {
      return ref.read(savedSchemesRepositoryProvider).load();
    } catch (_) {
      return {};
    }
  }

  /// Replaces `state` with the signed-in user's server-side saved list.
  /// A no-op when signed out (nothing to sync) or on a network failure
  /// (whatever's already showing -- local or a prior sync -- stands).
  Future<void> syncFromRemote() async {
    final signedIn = ref.read(isSignedInProvider);
    if (!signedIn) return;
    try {
      final remote = await ref.read(savedSchemesRemoteRepositoryProvider).list();
      state = remote;
      try {
        await ref.read(savedSchemesRepositoryProvider).save(remote);
      } catch (_) {
        // Local mirror is a convenience cache -- fine if it can't write.
      }
    } catch (_) {
      // Keep whatever is already showing rather than clear it on a
      // transient failure.
    }
  }

  Future<void> toggle(SavedScheme scheme) async {
    final next = {...state};
    final wasSaved = next.containsKey(scheme.schemeId);
    if (wasSaved) {
      next.remove(scheme.schemeId);
    } else {
      next[scheme.schemeId] = scheme;
    }
    state = next;
    try {
      await ref.read(savedSchemesRepositoryProvider).save(next);
    } catch (_) {
      // No local storage available in this context -- in-memory only.
    }

    if (ref.read(isSignedInProvider)) {
      try {
        if (wasSaved) {
          await ref.read(savedSchemesRemoteRepositoryProvider).unsave(scheme.schemeId);
        } else {
          await ref.read(savedSchemesRemoteRepositoryProvider).save(scheme);
        }
      } catch (_) {
        // Best-effort sync -- the optimistic local state above stands;
        // the next sign-in-triggered syncFromRemote() reconciles it.
      }
    }
  }

  bool isSaved(String schemeId) => state.containsKey(schemeId);
}

final savedSchemesProvider = NotifierProvider<SavedSchemesNotifier, Map<String, SavedScheme>>(
  SavedSchemesNotifier.new,
);
