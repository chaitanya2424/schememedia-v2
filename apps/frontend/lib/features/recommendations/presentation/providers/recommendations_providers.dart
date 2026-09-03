import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/recommendations_api.dart';
import '../../data/recommendations_repository.dart';
import '../../domain/recommendation.dart';

final recommendationsApiProvider = Provider<RecommendationsApi>(
  (ref) => RecommendationsApi(ref.watch(apiClientProvider)),
);

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepository(ref.watch(recommendationsApiProvider)),
);

/// Screen-level notifier. Signed out: unchanged -- calls the public
/// `/recommendations` with whatever profile the wizard collected this
/// session (or none). Signed in: persists that same collected profile to
/// the backend first (best-effort -- a failed persist still lets the
/// fetch proceed against whatever was already saved server-side, since
/// the wizard's own answers are never lost, only not yet synced), then
/// calls `/recommendations/me`, which always ranks against the persisted
/// profile server-side. Either way this is the one and only place a
/// recommendations fetch happens -- no second ranking implementation.
class RecommendationsNotifier extends StateNotifier<AsyncValue<RecommendationResponse?>> {
  RecommendationsNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  final RecommendationsRepository _repository;
  final Ref _ref;
  String _lastQuery = '';
  Map<String, dynamic>? _lastProfile;

  Future<void> fetch({required String query, Map<String, dynamic>? profile}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = const AsyncValue.data(null);
      return;
    }
    _lastQuery = trimmed;
    _lastProfile = profile;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (_ref.read(isSignedInProvider)) {
        if (profile != null && profile.isNotEmpty) {
          try {
            await _ref.read(profileRepositoryProvider).updateProfile(profile);
            _ref.invalidate(myProfileProvider);
          } catch (_) {
            // Best-effort persist -- see class doc.
          }
        }
        return _repository.getMyRecommendations(query: trimmed, limit: 20);
      }
      return _repository.getRecommendations(query: trimmed, profile: profile);
    });
  }

  /// Re-issues the same request after a failure -- the wizard's query
  /// field is no longer visible once a fetch is in flight/failed (it's
  /// a separate step in the new flow), so retry has to remember what was
  /// actually sent rather than re-reading a currently-visible field.
  Future<void> retry() => fetch(query: _lastQuery, profile: _lastProfile);

  /// Back to the wizard from results ("Edit answers") -- the in-progress
  /// profile itself isn't cleared (profileFormControllerProvider is a
  /// separate provider), so re-entering the wizard keeps prior answers.
  void reset() => state = const AsyncValue.data(null);
}

final recommendationsNotifierProvider =
    StateNotifierProvider<RecommendationsNotifier, AsyncValue<RecommendationResponse?>>(
      (ref) => RecommendationsNotifier(ref.watch(recommendationsRepositoryProvider), ref),
    );
