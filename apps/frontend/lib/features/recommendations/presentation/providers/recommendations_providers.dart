import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../data/recommendations_api.dart';
import '../../data/recommendations_repository.dart';
import '../../domain/recommendation.dart';

final recommendationsApiProvider = Provider<RecommendationsApi>(
  (ref) => RecommendationsApi(ref.watch(apiClientProvider)),
);

final recommendationsRepositoryProvider = Provider<RecommendationsRepository>(
  (ref) => RecommendationsRepository(ref.watch(recommendationsApiProvider)),
);

/// Screen-level notifier -- built out fully when the Recommendations screen
/// (build-order step 4) lands; present now so the repository/provider
/// layer for this feature is already typed and wired.
class RecommendationsNotifier extends StateNotifier<AsyncValue<RecommendationResponse?>> {
  RecommendationsNotifier(this._repository) : super(const AsyncValue.data(null));

  final RecommendationsRepository _repository;
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
    state = await AsyncValue.guard(
      () => _repository.getRecommendations(query: trimmed, profile: profile),
    );
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
      (ref) => RecommendationsNotifier(ref.watch(recommendationsRepositoryProvider)),
    );
