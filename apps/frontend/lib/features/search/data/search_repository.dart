import 'package:dio/dio.dart';

import '../../../core/local/profile_offline_cache_repository.dart';
import '../../../core/network/api_exception.dart';
import '../domain/scheme_summary.dart';
import 'search_api.dart';

/// The only layer `presentation/` talks to for search -- converts any Dio
/// failure into the shared [ApiException] type before it ever reaches a
/// screen.
class SearchRepository {
  SearchRepository(this._api, [this._offlineCache]);

  final SearchApi _api;
  final ProfileOfflineCacheRepository? _offlineCache;
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
      final apiException = e.asApiException;
      if (apiException is ApiNetworkException && _offlineCache != null) {
        final matches = _offlineCache.searchCachedRecommendations(query);
        if (matches.isNotEmpty) {
          final results = matches.map((r) => SchemeSummary(
            schemeId: r.schemeId,
            slug: r.slug,
            name: r.name,
            category: r.category,
            jurisdiction: r.jurisdiction,
            stateCode: r.stateCode,
            schemeType: r.schemeType,
            score: r.score,
            verificationStatus: r.verificationStatus,
            needsReview: r.needsReview,
            officialUrl: r.officialUrl,
            descriptionShort: r.descriptionShort,
          )).toList();
          return SearchResponse(
            query: query,
            totalReturned: results.length,
            verificationBreakdown: {},
            results: results,
          );
        }
      }
      throw apiException;
    }
  }

  static void clearCache() => _searchCache.clear();
}

