import '../../../core/network/api_client.dart';
import '../domain/comment.dart';

/// Talks to `GET`/`POST /schemes/{scheme_id}/comments` and
/// `DELETE /schemes/{scheme_id}/comments/{comment_id}`. Listing is public;
/// creating and deleting go through the usual auth interceptor (see
/// ApiClient) and 401 like any other authenticated call.
class CommentsApi {
  CommentsApi(this._client);

  final ApiClient _client;

  Future<List<SchemeComment>> list(String schemeId) async {
    final json = await _client.get('/schemes/$schemeId/comments');
    final body = json as Map<String, dynamic>;
    return (body['comments'] as List)
        .cast<Map<String, dynamic>>()
        .map(SchemeComment.fromJson)
        .toList();
  }

  Future<SchemeComment> create(String schemeId, String content) async {
    final json = await _client.post(
      '/schemes/$schemeId/comments',
      data: {'content': content},
    );
    return SchemeComment.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(String schemeId, String commentId) =>
      _client.delete('/schemes/$schemeId/comments/$commentId');
}
