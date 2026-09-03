import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/auth_token_storage.dart';
import 'api_client.dart';
import 'auth_token_cache.dart';

/// The root of every feature's provider graph -- swappable in tests via
/// `ProviderScope(overrides: [dioProvider.overrideWithValue(...)])` (or
/// `apiClientProvider` directly) instead of hitting a real network.
///
/// Wires [authTokenCacheProvider] into Dio's interceptors (see
/// api_client.dart) without depending on the auth feature's own
/// controller -- `onTokensRefreshed`/`onRefreshFailed` persist to secure
/// storage directly, breaking what would otherwise be a provider cycle
/// (dioProvider -> authControllerProvider -> ... -> dioProvider). See
/// auth_token_cache.dart's module docstring.
final dioProvider = Provider<Dio>((ref) {
  final tokenCache = ref.watch(authTokenCacheProvider);
  return ApiClient.buildDio(
    tokenCache: tokenCache,
    onTokensRefreshed: (accessToken, refreshToken) async {
      try {
        await ref
            .read(authTokenStorageProvider)
            .writeTokens(accessToken: accessToken, refreshToken: refreshToken);
      } catch (_) {
        // Storage unavailable -- the in-memory cache (already updated by
        // the caller) still keeps the session working for the rest of
        // this app run.
      }
    },
    onRefreshFailed: () async {
      try {
        await ref.read(authTokenStorageProvider).clear();
      } catch (_) {
        // Nothing durable to clean up if storage isn't available anyway.
      }
    },
  );
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(dio: ref.watch(dioProvider)));
