import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/recommendation.dart';
import 'recommendations_api.dart';

class RecommendationsRepository {
  RecommendationsRepository(this._api);

  final RecommendationsApi _api;

  Future<RecommendationResponse> getRecommendations({
    required String query,
    Map<String, dynamic>? profile,
    int limit = 20,
  }) async {
    try {
      return await _api.getRecommendations(query: query, profile: profile, limit: limit);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<RecommendationResponse> getMyRecommendations({
    required String query,
    int limit = 20,
  }) async {
    try {
      return await _api.getMyRecommendations(query: query, limit: limit);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
