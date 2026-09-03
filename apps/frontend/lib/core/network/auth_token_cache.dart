import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A plain, dependency-free in-memory box for the current access/refresh
/// token pair.
///
/// Deliberately NOT itself dependent on the auth feature: [dioProvider]
/// (providers.dart) needs to read the current token -- and silently
/// refresh it -- from inside a Dio interceptor, while the auth feature's
/// own controller needs Dio to make its login/register/refresh calls in
/// the first place. Routing both through this one small provider, instead
/// of the interceptor depending on the auth controller directly, is what
/// keeps that graph acyclic. The auth controller
/// (features/auth/presentation/providers/auth_controller.dart) is still
/// the single source of truth for *UI-visible* auth state (signed in/out,
/// current user) -- this cache exists only so the network layer has
/// something synchronous to read on every request.
class AuthTokenCache {
  String? accessToken;
  String? refreshToken;

  void set({required String accessToken, required String refreshToken}) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
  }

  void clear() {
    accessToken = null;
    refreshToken = null;
  }
}

final authTokenCacheProvider = Provider<AuthTokenCache>((ref) => AuthTokenCache());
