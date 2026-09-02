import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'error_envelope_dto.dart';

/// Thin wrapper over one [Dio] instance. This, [api_exception.dart], and
/// [error_envelope_dto.dart] are the only files in the app allowed to
/// import `package:dio` -- every feature's `data/*_api.dart` calls through
/// this class instead. See the frontend architecture plan's "Convention"
/// note under Folder structure.
///
/// Deliberately returns raw decoded JSON (`dynamic`), not `Future<T>` with
/// a `fromJson` callback: keeping this class free of any feature's model
/// types is what keeps the "only core/network touches Dio" boundary real,
/// rather than nominal.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? buildDio();

  final Dio _dio;

  static Dio buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }

    dio.interceptors.add(_ErrorMappingInterceptor());
    return dio;
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters}) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return response.data;
  }

  /// [receiveTimeout] overrides the client-wide default for this one call --
  /// needed by the assistant endpoint, which can involve up to two
  /// sequential LLM calls server-side (see the backend's
  /// providers/gemini_provider.py and anthropic_provider.py, each budgeted
  /// 20s per call). The 15s default is otherwise right for every other
  /// endpoint, which is a single fast DB query.
  Future<dynamic> post(String path, {Object? data, Duration? receiveTimeout}) async {
    final response = await _dio.post(
      path,
      data: data,
      options: receiveTimeout == null ? null : Options(receiveTimeout: receiveTimeout),
    );
    return response.data;
  }
}

/// The single place a [DioException] is ever interpreted. Parses the
/// backend's `{error:{...}}` envelope when present and attaches a typed
/// [ApiException] to `DioException.error`, so every caller downstream
/// (`DioExceptionApiExceptionX.asApiException`) gets a consistent typed
/// failure regardless of which endpoint failed or how.
class _ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(err.copyWith(error: _toApiException(err)));
  }

  ApiException _toApiException(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const ApiException.network();
      default:
        break;
    }

    final statusCode = err.response?.statusCode;
    final envelope = _tryParseEnvelope(err.response?.data);

    if (statusCode == 404) {
      return ApiException.notFound(envelope?.error.message ?? 'Not found.');
    }
    if (statusCode == 422) {
      final fields = envelope?.error.details ?? const <String, dynamic>{};
      return ApiException.validation(fields);
    }
    if (statusCode == 503) {
      return ApiException.unavailable(
        envelope?.error.message ?? 'Temporarily unavailable. Please try again shortly.',
      );
    }
    if (envelope != null) {
      return ApiException.server(
        code: envelope.error.code,
        message: envelope.error.message,
        requestId: envelope.error.requestId,
      );
    }
    return ApiException.unknown(err.message ?? 'Something went wrong.');
  }

  ErrorEnvelopeDto? _tryParseEnvelope(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    if (data['error'] is! Map<String, dynamic>) return null;
    try {
      return ErrorEnvelopeDto.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}
