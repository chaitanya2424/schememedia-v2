import 'package:dio/dio.dart';

import '../../../core/local/profile_offline_cache_repository.dart';
import '../../../core/network/api_exception.dart';
import '../domain/scheme_detail.dart';
import 'scheme_detail_api.dart';

class SchemeDetailRepository {
  SchemeDetailRepository(this._api, [this._offlineCache]);

  final SchemeDetailApi _api;
  final ProfileOfflineCacheRepository? _offlineCache;

  Future<SchemeDetail> getDetail(String identifier) async {
    try {
      final detail = await _api.getDetail(identifier);
      _offlineCache?.saveSchemeDetail(detail);
      return detail;
    } on DioException catch (e) {
      final apiException = e.asApiException;
      if (apiException is ApiNetworkException && _offlineCache != null) {
        final cached = _offlineCache.getCachedSchemeDetail(identifier);
        if (cached != null) {
          return cached;
        }
      }
      throw apiException;
    }
  }

  Future<void> like(String schemeId) async {
    try {
      await _api.like(schemeId);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<void> unlike(String schemeId) async {
    try {
      await _api.unlike(schemeId);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
