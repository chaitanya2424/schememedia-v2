import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/scheme_summary.dart';
import 'search_api.dart';

/// The only layer `presentation/` talks to for search -- converts any Dio
/// failure into the shared [ApiException] type before it ever reaches a
/// screen.
class SearchRepository {
  SearchRepository(this._api);

  final SearchApi _api;

  Future<SearchResponse> search(String query, {int limit = 20}) async {
    try {
      return await _api.search(query, limit: limit);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
