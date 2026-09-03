import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/comment.dart';
import 'comments_api.dart';

class CommentsRepository {
  CommentsRepository(this._api);

  final CommentsApi _api;

  Future<List<SchemeComment>> list(String schemeId) async {
    try {
      return await _api.list(schemeId);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<SchemeComment> create(String schemeId, String content) async {
    try {
      return await _api.create(schemeId, content);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<void> delete(String schemeId, String commentId) async {
    try {
      await _api.delete(schemeId, commentId);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
