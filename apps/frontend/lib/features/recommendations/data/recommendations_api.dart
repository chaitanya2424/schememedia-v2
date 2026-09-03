import '../../../core/network/api_client.dart';
import '../domain/recommendation.dart';

/// Talks to `POST /recommendations`. `profile` is a simple
/// `Map<String, dynamic>` here, not a generated request model -- the
/// backend already treats it as an open, all-optional bag of ~26 keys
/// (unrecognised keys ignored server-side), so a request DTO would only
/// duplicate that shape without adding safety.
class RecommendationsApi {
  RecommendationsApi(this._client);

  final ApiClient _client;

  Future<RecommendationResponse> getRecommendations({
    required String query,
    Map<String, dynamic>? profile,
    int limit = 20,
  }) async {
    final json = await _client.post(
      '/recommendations',
      data: {'query': query, if (profile != null) 'profile': profile, 'limit': limit},
    );
    return RecommendationResponse.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /recommendations/me` -- no `profile` field at all: the backend
  /// always ranks against the signed-in caller's own persisted profile
  /// (see /me/profile), never one supplied here. Requires the caller to
  /// already be signed in (ApiClient attaches the access token
  /// automatically when one is cached -- see core/network/api_client.dart).
  Future<RecommendationResponse> getMyRecommendations({
    required String query,
    int limit = 20,
  }) async {
    final json = await _client.post(
      '/recommendations/me',
      data: {'query': query, 'limit': limit},
    );
    return RecommendationResponse.fromJson(json as Map<String, dynamic>);
  }
}
