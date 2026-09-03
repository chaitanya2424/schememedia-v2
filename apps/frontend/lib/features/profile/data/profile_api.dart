import '../../../core/network/api_client.dart';

/// Talks to `GET`/`PUT /me/profile`. `attributes` is a plain
/// `Map<String, dynamic>` keyed by the same EligibilityAttribute wire keys
/// `ProfileFormController.toProfileJson()` already produces -- no separate
/// request/response model needed, same reasoning as RecommendationsApi's
/// `profile` parameter.
class ProfileApi {
  ProfileApi(this._client);

  final ApiClient _client;

  /// Returns `{attributes: {...}, answered_count: N, total_count: N}`.
  Future<Map<String, dynamic>> getProfile() async {
    final json = await _client.get('/me/profile');
    return json as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> attributes) async {
    final json = await _client.put('/me/profile', data: {'attributes': attributes});
    return json as Map<String, dynamic>;
  }
}
