import 'package:dio/dio.dart';

import '../../../core/local/profile_offline_cache_repository.dart';
import '../../../core/network/api_exception.dart';
import '../domain/recommendation.dart';
import 'recommendations_api.dart';

class RecommendationsRepository {
  RecommendationsRepository(this._api, [this._offlineCache]);

  final RecommendationsApi _api;
  final ProfileOfflineCacheRepository? _offlineCache;

  Future<RecommendationResponse> getRecommendations({
    required String query,
    Map<String, dynamic>? profile,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getRecommendations(query: query, profile: profile, limit: limit);
      // Asynchronously cache for offline rural access
      _offlineCache?.saveProfileRecommendations(response: response);
      return response;
    } on DioException catch (e) {
      final apiException = e.asApiException;
      if (apiException is ApiNetworkException && _offlineCache != null) {
        final cached = _offlineCache.getCachedRecommendations();
        if (cached != null && cached.recommendations.isNotEmpty) {
          return cached;
        }
      }
      throw apiException;
    }
  }

  Future<RecommendationResponse> getMyRecommendations({
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _api.getMyRecommendations(query: query, limit: limit);
      _offlineCache?.saveProfileRecommendations(response: response);
      return response;
    } on DioException catch (e) {
      final apiException = e.asApiException;
      if (apiException is ApiNetworkException && _offlineCache != null) {
        final cached = _offlineCache.getCachedRecommendations();
        if (cached != null && cached.recommendations.isNotEmpty) {
          return cached;
        }
      }
      throw apiException;
    }
  }
}

