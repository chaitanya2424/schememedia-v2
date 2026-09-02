import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/scheme_detail.dart';
import 'scheme_detail_api.dart';

class SchemeDetailRepository {
  SchemeDetailRepository(this._api);

  final SchemeDetailApi _api;

  Future<SchemeDetail> getDetail(String identifier) async {
    try {
      return await _api.getDetail(identifier);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
