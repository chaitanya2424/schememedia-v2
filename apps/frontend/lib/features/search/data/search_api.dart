import '../../../core/network/api_client.dart';
import '../domain/scheme_summary.dart';

/// Talks to `GET /search`. The only file in this feature that imports
/// [ApiClient] -- see the architecture plan's data/domain/presentation rule.
class SearchApi {
  SearchApi(this._client);

  final ApiClient _client;

  Future<SearchResponse> search(String query, {int limit = 20}) async {
    final json = await _client.get('/search', queryParameters: {'q': query, 'limit': limit});
    return SearchResponse.fromJson(json as Map<String, dynamic>);
  }
}
