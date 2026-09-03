import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/env.dart';
import 'api_exception.dart';
import 'auth_token_cache.dart';
import 'error_envelope_dto.dart';

/// Thin wrapper over one [Dio] instance. This, [api_exception.dart],
/// [auth_token_cache.dart], and [error_envelope_dto.dart] are the only
/// files in the app allowed to import `package:dio` -- every feature's
/// `data/*_api.dart` calls through this class instead. See the frontend
/// architecture plan's "Convention" note under Folder structure.
///
/// Deliberately returns raw decoded JSON (`dynamic`), not `Future<T>` with
/// a `fromJson` callback: keeping this class free of any feature's model
/// types is what keeps the "only core/network touches Dio" boundary real,
/// rather than nominal.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? buildDio();

  final Dio _dio;

  /// [tokenCache] is optional so every existing bare `ApiClient()`/
  /// `buildDio()` call site (mostly tests) keeps working unauthenticated.
  /// [onTokensRefreshed]/[onRefreshFailed] are plain callbacks, not a
  /// dependency on the auth feature's own provider -- see
  /// auth_token_cache.dart's module docstring for why that boundary
  /// matters (breaking a provider dependency cycle).
  static Dio buildDio({
    AuthTokenCache? tokenCache,
    Future<void> Function(String accessToken, String refreshToken)? onTokensRefreshed,
    Future<void> Function()? onRefreshFailed,
  }) {
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

    if (tokenCache != null) {
      dio.interceptors.add(_AuthHeaderInterceptor(tokenCache));
    }
    dio.interceptors.add(_ErrorMappingInterceptor());
    if (tokenCache != null) {
      dio.interceptors.add(
        _SilentRefreshInterceptor(dio, tokenCache, onTokensRefreshed, onRefreshFailed),
      );
    }
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

  Future<dynamic> put(String path, {Object? data}) async {
    final response = await _dio.put(path, data: data);
    return response.data;
  }

  Future<void> delete(String path) async {
    await _dio.delete(path);
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
    // `reject(..., true)` -- the second, `callFollowingErrorInterceptor`
    // argument -- is required, not optional polish: `ErrorInterceptorHandler
    // .reject()` defaults to `false`, which skips every interceptor added
    // after this one entirely (Dio's error queue only re-invokes the next
    // interceptor when the previous result type is `next` or
    // `rejectCallFollowing`; a plain `reject` just rethrows straight past
    // the rest of the chain). This interceptor is always added before
    // _SilentRefreshInterceptor (see ApiClient.buildDio) specifically so a
    // 401 still reaches it to attempt a silent refresh -- without `true`
    // here, that interceptor's onError silently never runs at all, found
    // by a real failing test (api_client_auth_test.dart) that watched for
    // the token cache actually clearing on a refresh failure.
    handler.reject(err.copyWith(error: _toApiException(err)), true);
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

/// Attaches `Authorization: Bearer <token>` to every request except the
/// auth endpoints themselves (register/login/refresh/logout are either
/// public or take their own token in the body, never in a header).
class _AuthHeaderInterceptor extends Interceptor {
  _AuthHeaderInterceptor(this._tokenCache);

  final AuthTokenCache _tokenCache;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenCache.accessToken;
    if (token != null && !options.path.startsWith('/auth/')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// On a 401 from anything other than the auth endpoints themselves, tries
/// exactly one silent `/auth/refresh` and retries the original request
/// once with the new token. Talks to `/auth/refresh` directly on the same
/// [Dio] instance (bypassing the auth feature's own repository layer) so
/// this stays a plain network-layer concern with no dependency on
/// features/auth -- see auth_token_cache.dart's module docstring.
///
/// If the refresh itself fails (the refresh token is also dead), the
/// token cache is cleared and [onRefreshFailed] runs (persisting that
/// sign-out), then the *original* error is what the caller sees -- this
/// interceptor does not attempt to update any UI-visible auth state
/// itself, only the network-layer token cache/storage. A screen that acts
/// on a signed-in-only request failing this way should treat it as "sign
/// in again", same as any other 401.
class _SilentRefreshInterceptor extends Interceptor {
  _SilentRefreshInterceptor(
    this._dio,
    this._tokenCache,
    this._onTokensRefreshed,
    this._onRefreshFailed,
  );

  final Dio _dio;
  final AuthTokenCache _tokenCache;
  final Future<void> Function(String accessToken, String refreshToken)? _onTokensRefreshed;
  final Future<void> Function()? _onRefreshFailed;

  static const _retriedFlag = 'schememedia_retried_after_refresh';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;
    final isAuthEndpoint = err.requestOptions.path.startsWith('/auth/');
    final refreshToken = _tokenCache.refreshToken;

    if (err.response?.statusCode != 401 || alreadyRetried || isAuthEndpoint || refreshToken == null) {
      handler.next(err);
      return;
    }

    try {
      final refreshResponse = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final body = refreshResponse.data as Map<String, dynamic>;
      final newAccessToken = body['access_token'] as String;
      final newRefreshToken = body['refresh_token'] as String;
      _tokenCache.set(accessToken: newAccessToken, refreshToken: newRefreshToken);
      await _onTokensRefreshed?.call(newAccessToken, newRefreshToken);

      final retryOptions = err.requestOptions;
      retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
      retryOptions.extra[_retriedFlag] = true;
      final retryResponse = await _dio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      _tokenCache.clear();
      await _onRefreshFailed?.call();
      handler.next(err);
    }
  }
}
