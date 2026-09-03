import '../../../core/network/api_client.dart';

/// Talks to `GET`/`POST`/`DELETE /me/saved-schemes[/{scheme_id}]`. Returns
/// raw decoded rows -- `SavedSchemesRemoteRepository` maps them onto the
/// existing local `SavedScheme` shape, same "no separate wire model"
/// reasoning as RecommendationsApi/ProfileApi.
class SavedSchemesApi {
  SavedSchemesApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> list() async {
    final json = await _client.get('/me/saved-schemes');
    final body = json as Map<String, dynamic>;
    return (body['schemes'] as List).cast<Map<String, dynamic>>();
  }

  Future<void> save(String schemeId) => _client.post('/me/saved-schemes/$schemeId');

  Future<void> unsave(String schemeId) => _client.delete('/me/saved-schemes/$schemeId');
}
