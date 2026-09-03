// AuthController -- register/login/logout, initial state resolved from
// storage, and that a failed register/login still resolves the provider's
// state (rather than leaving it stuck loading) while still propagating
// the real error to the caller. A fake AuthRepository/AuthTokenStorage
// stand in for the network/secure-storage layers -- neither is reachable
// in a plain `flutter test` environment (no platform channels), and
// faking them directly is simpler than mocking Dio for this level.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/local/auth_token_storage.dart';
import 'package:schememedia_app/core/network/auth_token_cache.dart';
import 'package:schememedia_app/core/network/api_exception.dart';
import 'package:schememedia_app/features/auth/data/auth_repository.dart';
import 'package:schememedia_app/features/auth/domain/auth_models.dart';
import 'package:schememedia_app/features/auth/presentation/providers/auth_controller.dart';

class _FakeAuthTokenStorage implements AuthTokenStorage {
  AuthSession? stored;
  int clearCalls = 0;

  @override
  Future<AuthSession?> readSession() async => stored;

  @override
  Future<void> writeSession(AuthSession session) async {
    stored = session;
  }

  @override
  Future<void> writeTokens({required String accessToken, required String refreshToken}) async {
    final existing = stored;
    if (existing == null) return;
    stored = AuthSession(
      user: existing.user,
      tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    stored = null;
  }
}

class _FakeAuthRepository implements AuthRepository {
  AuthSession? sessionToReturn;
  Object? errorToThrow;
  int logoutCalls = 0;
  String? lastLogoutToken;

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    if (errorToThrow != null) throw errorToThrow!;
    return sessionToReturn!;
  }

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    if (errorToThrow != null) throw errorToThrow!;
    return sessionToReturn!;
  }

  @override
  Future<AuthTokens> refresh(String refreshToken) async => sessionToReturn!.tokens;

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls++;
    lastLogoutToken = refreshToken;
  }

  @override
  Future<AuthUser> me() async => sessionToReturn!.user;
}

const _user = AuthUser(id: 'user-1', email: 'a@b.com', fullName: 'A B');
const _session = AuthSession(
  user: _user,
  tokens: AuthTokens(accessToken: 'access-1', refreshToken: 'refresh-1'),
);

ProviderContainer _buildContainer({
  required _FakeAuthRepository repository,
  required _FakeAuthTokenStorage storage,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(repository),
      authTokenStorageProvider.overrideWithValue(storage),
    ],
  );
  return container;
}

void main() {
  group('build (initial state)', () {
    test('resolves signed out when no session is stored', () async {
      final container = _buildContainer(
        repository: _FakeAuthRepository(),
        storage: _FakeAuthTokenStorage(),
      );
      addTearDown(container.dispose);

      final state = await container.read(authControllerProvider.future);

      expect(state.isSignedIn, isFalse);
    });

    test('resolves signed in with the stored user when a session is stored', () async {
      final storage = _FakeAuthTokenStorage()..stored = _session;
      final container = _buildContainer(repository: _FakeAuthRepository(), storage: storage);
      addTearDown(container.dispose);

      final state = await container.read(authControllerProvider.future);

      expect(state.isSignedIn, isTrue);
      expect(state.user?.email, 'a@b.com');
    });

    test('populates the token cache from the stored session', () async {
      final storage = _FakeAuthTokenStorage()..stored = _session;
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          authTokenStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      await container.read(authControllerProvider.future);

      expect(container.read(authTokenCacheProvider).accessToken, 'access-1');
      expect(container.read(authTokenCacheProvider).refreshToken, 'refresh-1');
    });
  });

  group('register', () {
    test('a successful register resolves to signed in with the new user', () async {
      final repository = _FakeAuthRepository()..sessionToReturn = _session;
      final storage = _FakeAuthTokenStorage();
      final container = _buildContainer(repository: repository, storage: storage);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .register(email: 'a@b.com', password: 'correct-horse-1');

      final state = container.read(authControllerProvider).value;
      expect(state?.isSignedIn, isTrue);
      expect(state?.user?.email, 'a@b.com');
    });

    test('a successful register persists the session to storage', () async {
      final repository = _FakeAuthRepository()..sessionToReturn = _session;
      final storage = _FakeAuthTokenStorage();
      final container = _buildContainer(repository: repository, storage: storage);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .register(email: 'a@b.com', password: 'correct-horse-1');

      expect(storage.stored?.user.email, 'a@b.com');
    });

    test('a failed register resolves back to signed out but rethrows the real error', () async {
      final repository = _FakeAuthRepository()
        ..errorToThrow = const ApiException.server(code: 'conflict', message: 'Already registered.');
      final container = _buildContainer(repository: repository, storage: _FakeAuthTokenStorage());
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .register(email: 'a@b.com', password: 'correct-horse-1'),
        throwsA(isA<ApiException>()),
      );

      // The provider's own state still resolves (not left loading forever).
      final state = container.read(authControllerProvider).value;
      expect(state?.isSignedIn, isFalse);
    });
  });

  group('login', () {
    test('a successful login resolves to signed in', () async {
      final repository = _FakeAuthRepository()..sessionToReturn = _session;
      final container = _buildContainer(repository: repository, storage: _FakeAuthTokenStorage());
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await container
          .read(authControllerProvider.notifier)
          .login(email: 'a@b.com', password: 'correct-horse-1');

      expect(container.read(authControllerProvider).value?.isSignedIn, isTrue);
    });

    test('a failed login resolves back to signed out and rethrows', () async {
      final repository = _FakeAuthRepository()
        ..errorToThrow = const ApiException.server(
          code: 'authentication_required',
          message: 'Invalid email or password.',
        );
      final container = _buildContainer(repository: repository, storage: _FakeAuthTokenStorage());
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);

      await expectLater(
        container
            .read(authControllerProvider.notifier)
            .login(email: 'a@b.com', password: 'wrong'),
        throwsA(isA<ApiException>()),
      );
      expect(container.read(authControllerProvider).value?.isSignedIn, isFalse);
    });
  });

  group('logout', () {
    test('clears the token cache, clears storage, and resolves to signed out', () async {
      final repository = _FakeAuthRepository()..sessionToReturn = _session;
      final storage = _FakeAuthTokenStorage()..stored = _session;
      final container = _buildContainer(repository: repository, storage: storage);
      addTearDown(container.dispose);
      container.read(authTokenCacheProvider).set(accessToken: 'access-1', refreshToken: 'refresh-1');
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(authControllerProvider).value?.isSignedIn, isFalse);
      expect(container.read(authTokenCacheProvider).accessToken, isNull);
      expect(storage.clearCalls, 1);
    });

    test('calls the backend to revoke the refresh token', () async {
      final repository = _FakeAuthRepository()..sessionToReturn = _session;
      final storage = _FakeAuthTokenStorage()..stored = _session;
      final container = _buildContainer(repository: repository, storage: storage);
      addTearDown(container.dispose);
      container.read(authTokenCacheProvider).set(accessToken: 'access-1', refreshToken: 'refresh-1');
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).logout();

      expect(repository.logoutCalls, 1);
      expect(repository.lastLogoutToken, 'refresh-1');
    });

    test('signs out locally even if the backend revoke call fails', () async {
      final repository = _FakeAuthRepository()..sessionToReturn = _session;
      final storage = _FakeAuthTokenStorage()..stored = _session;
      final container = _buildContainer(repository: repository, storage: storage);
      addTearDown(container.dispose);
      container.read(authTokenCacheProvider).set(accessToken: 'access-1', refreshToken: 'refresh-1');
      await container.read(authControllerProvider.future);
      repository.errorToThrow = const ApiException.network();

      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(authControllerProvider).value?.isSignedIn, isFalse);
      expect(container.read(authTokenCacheProvider).accessToken, isNull);
    });
  });
}
