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
  static final Map<String, ({DateTime cachedAt, SearchResponse response})> _searchCache = {};
  static const _cacheDuration = Duration(minutes: 5);

  Future<SearchResponse> search(String query, {int limit = 20}) async {
    final cacheKey = '${query.trim().toLowerCase()}|$limit';
    final cached = _searchCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.cachedAt) < _cacheDuration) {
      return cached.response;
    }

    try {
      final response = await _api.search(query, limit: limit);
      _searchCache[cacheKey] = (cachedAt: DateTime.now(), response: response);
      if (_searchCache.length > 200) {
        _searchCache.remove(_searchCache.keys.first);
      }
      return response;
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  static void clearCache() => _searchCache.clear();
}
