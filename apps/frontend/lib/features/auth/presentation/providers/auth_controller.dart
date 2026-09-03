import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/local/auth_token_storage.dart';
import '../../../../core/network/auth_token_cache.dart';
import '../../../../core/network/providers.dart';
import '../../data/auth_api.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_models.dart';
import 'auth_state.dart';

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authApiProvider)),
);

/// The signed-in/out state every screen reads. An [AsyncNotifier] because
/// resolving the initial state means an async secure-storage read
/// ([build]); once resolved, register/login/logout/refresh all settle
/// back into [AsyncData] (never left loading indefinitely, and a failed
/// register/login surfaces as [AsyncError] the caller re-throws from, so a
/// form's own try/catch still sees the real [ApiException]).
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    try {
      final stored = await ref.read(authTokenStorageProvider).readSession();
      if (stored == null) return const AuthState.signedOut();
      ref
          .read(authTokenCacheProvider)
          .set(accessToken: stored.tokens.accessToken, refreshToken: stored.tokens.refreshToken);
      return AuthState.signedIn(stored.user);
    } catch (_) {
      // No secure storage available in this context (e.g. a bare test
      // ProviderContainer) -- degrade to signed-out rather than crash,
      // same defensive pattern as SavedSchemesNotifier/ThemeModeNotifier.
      return const AuthState.signedOut();
    }
  }

  Future<void> register({required String email, required String password, String? fullName}) {
    return _authenticate(
      () => ref
          .read(authRepositoryProvider)
          .register(email: email, password: password, fullName: fullName),
    );
  }

  Future<void> login({required String email, required String password}) {
    return _authenticate(
      () => ref.read(authRepositoryProvider).login(email: email, password: password),
    );
  }

  Future<void> _authenticate(Future<AuthSession> Function() call) async {
    state = const AsyncValue.loading();
    try {
      final session = await call();
      await _persist(session);
      state = AsyncValue.data(AuthState.signedIn(session.user));
    } catch (error, stackTrace) {
      // Restored to the prior signed-out state, not left loading -- the
      // caller (the login/register form) is expected to catch and display
      // the real error itself; this provider's state must still resolve.
      state = const AsyncValue.data(AuthState.signedOut());
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> logout() async {
    final cache = ref.read(authTokenCacheProvider);
    final refreshToken = cache.refreshToken;
    cache.clear();
    try {
      await ref.read(authTokenStorageProvider).clear();
    } catch (_) {
      // Nothing durable to clean up if storage isn't available.
    }
    state = const AsyncValue.data(AuthState.signedOut());
    if (refreshToken != null) {
      // Best-effort: revokes the refresh token server-side, but the local
      // sign-out above has already happened regardless of whether this
      // call succeeds (matches the backend's own logout being idempotent
      // on an unknown/already-revoked token).
      try {
        await ref.read(authRepositoryProvider).logout(refreshToken);
      } catch (_) {}
    }
  }

  Future<void> _persist(AuthSession session) async {
    ref
        .read(authTokenCacheProvider)
        .set(
          accessToken: session.tokens.accessToken,
          refreshToken: session.tokens.refreshToken,
        );
    try {
      await ref.read(authTokenStorageProvider).writeSession(session);
    } catch (_) {
      // In-memory session still works for the rest of this app run even
      // if it can't be persisted.
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Convenience read for widgets that only care about the resolved
/// signed-in/out fact and don't want to handle the loading/error cases of
/// the full [AsyncValue] -- defaults to signed-out while the initial
/// storage read is still in flight or failed, which is always the safe,
/// honest default (never show account-only content before we actually
/// know there is one).
final isSignedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).valueOrNull?.isSignedIn ?? false;
});
