// Verifies the two auth-aware interceptors ApiClient.buildDio wires in
// when given an AuthTokenCache (core/network/api_client.dart):
//   * _AuthHeaderInterceptor -- attaches the cached access token, except
//     to /auth/* endpoints.
//   * _SilentRefreshInterceptor -- on a 401 from anything else, tries
//     exactly one /auth/refresh and retries the original request once.
//
// A fake HttpClientAdapter stands in for the network -- real Dio request/
// response handling (headers, retry, interceptor order) runs exactly as
// in production; only the actual HTTP transport is replaced, same
// "capture what Dio was asked to do" spirit as assistant_api_timeout_test.

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/core/network/auth_token_cache.dart';

typedef _ResponseBuilder = ResponseBody Function(RequestOptions options);

class _QueuedFakeAdapter implements HttpClientAdapter {
  final Map<String, List<_ResponseBuilder>> _queues = {};
  final List<RequestOptions> requests = [];

  void queue(String path, _ResponseBuilder builder) {
    _queues.putIfAbsent(path, () => []).add(builder);
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final queue = _queues[options.path];
    if (queue == null || queue.isEmpty) {
      throw StateError('No fake response queued for ${options.path}');
    }
    return queue.removeAt(0)(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(int statusCode, Map<String, dynamic> body) {
  final bytes = utf8.encode(jsonEncode(body));
  return ResponseBody.fromBytes(
    bytes,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('_AuthHeaderInterceptor', () {
    test('attaches the cached access token to a normal request', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue('/me/profile', (_) => _jsonResponse(200, {'ok': true}));
      final tokenCache = AuthTokenCache()..set(accessToken: 'tok-abc', refreshToken: 'ref-abc');
      final dio = ApiClient.buildDio(tokenCache: tokenCache)..httpClientAdapter = adapter;

      await ApiClient(dio: dio).get('/me/profile');

      expect(adapter.requests.single.headers['Authorization'], 'Bearer tok-abc');
    });

    test('does not attach a token to /auth/ endpoints', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue(
          '/auth/login',
          (_) => _jsonResponse(200, {
            'user': {'id': '1', 'email': 'a@b.com', 'full_name': null},
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          }),
        );
      final tokenCache = AuthTokenCache()..set(accessToken: 'tok-abc', refreshToken: 'ref-abc');
      final dio = ApiClient.buildDio(tokenCache: tokenCache)..httpClientAdapter = adapter;

      await ApiClient(dio: dio).post('/auth/login', data: {});

      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });

    test('adds no Authorization header when no token is cached', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue('/me/profile', (_) => _jsonResponse(200, {'ok': true}));
      final dio = ApiClient.buildDio(tokenCache: AuthTokenCache())..httpClientAdapter = adapter;

      await ApiClient(dio: dio).get('/me/profile');

      expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('_SilentRefreshInterceptor', () {
    test('refreshes once and retries a 401, returning the retried response', () async {
      final adapter = _QueuedFakeAdapter();
      var protectedCalls = 0;
      // Queued twice -- once per expected call to /me/profile (the queue
      // is single-use per entry; see _QueuedFakeAdapter.fetch). Both
      // entries share the same `protectedCalls` closure to distinguish
      // "first, unauthenticated" from "second, retried" without needing
      // two differently-shaped builders.
      ResponseBody protectedBuilder(RequestOptions options) {
        protectedCalls++;
        if (protectedCalls == 1) {
          return _jsonResponse(401, {
            'error': {'code': 'authentication_required', 'message': 'Invalid or expired access token.'},
          });
        }
        // Second call -- must carry the refreshed token.
        expect(options.headers['Authorization'], 'Bearer new-access');
        return _jsonResponse(200, {'attributes': {}});
      }

      adapter.queue('/me/profile', protectedBuilder);
      adapter.queue('/me/profile', protectedBuilder);
      adapter.queue(
        '/auth/refresh',
        (_) => _jsonResponse(200, {
          'user': {'id': '1', 'email': 'a@b.com', 'full_name': null},
          'access_token': 'new-access',
          'refresh_token': 'new-refresh',
        }),
      );

      final tokenCache = AuthTokenCache()..set(accessToken: 'stale-access', refreshToken: 'ref-1');
      String? persistedAccess;
      String? persistedRefresh;
      final dio =
          ApiClient.buildDio(
            tokenCache: tokenCache,
            onTokensRefreshed: (access, refresh) async {
              persistedAccess = access;
              persistedRefresh = refresh;
            },
          )..httpClientAdapter =
              adapter;

      final result = await ApiClient(dio: dio).get('/me/profile');

      expect(result, {'attributes': {}});
      expect(protectedCalls, 2);
      expect(tokenCache.accessToken, 'new-access');
      expect(tokenCache.refreshToken, 'new-refresh');
      expect(persistedAccess, 'new-access');
      expect(persistedRefresh, 'new-refresh');
    });

    test('a dead refresh token propagates the original 401 and clears the cache', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue(
          '/me/profile',
          (_) => _jsonResponse(401, {
            'error': {'code': 'authentication_required', 'message': 'Invalid or expired access token.'},
          }),
        )
        ..queue(
          '/auth/refresh',
          (_) => _jsonResponse(401, {
            'error': {'code': 'authentication_required', 'message': 'Please sign in again.'},
          }),
        );

      final tokenCache = AuthTokenCache()..set(accessToken: 'stale-access', refreshToken: 'dead-refresh');
      var refreshFailedCalled = false;
      final dio =
          ApiClient.buildDio(
            tokenCache: tokenCache,
            onRefreshFailed: () async => refreshFailedCalled = true,
          )..httpClientAdapter =
              adapter;

      await expectLater(ApiClient(dio: dio).get('/me/profile'), throwsA(isA<DioException>()));

      expect(tokenCache.accessToken, isNull);
      expect(tokenCache.refreshToken, isNull);
      expect(refreshFailedCalled, isTrue);
    });

    test('never attempts a refresh when no refresh token is cached', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue(
          '/me/profile',
          (_) => _jsonResponse(401, {
            'error': {'code': 'authentication_required', 'message': 'nope'},
          }),
        );
      final dio = ApiClient.buildDio(tokenCache: AuthTokenCache())..httpClientAdapter = adapter;

      await expectLater(ApiClient(dio: dio).get('/me/profile'), throwsA(isA<DioException>()));

      // Only the one call -- no /auth/refresh was ever queued/consumed.
      expect(adapter.requests, hasLength(1));
    });

    test('a 401 from /auth/login itself is never retried', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue(
          '/auth/login',
          (_) => _jsonResponse(401, {
            'error': {'code': 'authentication_required', 'message': 'Invalid email or password.'},
          }),
        );
      final tokenCache = AuthTokenCache()..set(accessToken: 'irrelevant', refreshToken: 'ref-1');
      final dio = ApiClient.buildDio(tokenCache: tokenCache)..httpClientAdapter = adapter;

      await expectLater(
        ApiClient(dio: dio).post('/auth/login', data: {}),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('a non-401 error is never retried', () async {
      final adapter = _QueuedFakeAdapter()
        ..queue(
          '/me/profile',
          (_) => _jsonResponse(404, {
            'error': {'code': 'not_found', 'message': 'Not found.'},
          }),
        );
      final tokenCache = AuthTokenCache()..set(accessToken: 'tok', refreshToken: 'ref-1');
      final dio = ApiClient.buildDio(tokenCache: tokenCache)..httpClientAdapter = adapter;

      await expectLater(ApiClient(dio: dio).get('/me/profile'), throwsA(isA<DioException>()));
      expect(adapter.requests, hasLength(1));
    });
  });
}
