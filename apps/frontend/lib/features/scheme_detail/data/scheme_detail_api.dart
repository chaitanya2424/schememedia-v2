import '../../../core/network/api_client.dart';
import '../domain/scheme_detail.dart';

/// Talks to `GET /schemes/{identifier}` (accepts a scheme_id or slug,
/// matching the backend's own dual lookup).
class SchemeDetailApi {
  SchemeDetailApi(this._client);

  final ApiClient _client;

  Future<SchemeDetail> getDetail(String identifier) async {
    final json = await _client.get('/schemes/$identifier');
    return SchemeDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<void> like(String schemeId) => _client.post('/schemes/$schemeId/like');

  Future<void> unlike(String schemeId) => _client.delete('/schemes/$schemeId/like');
}
