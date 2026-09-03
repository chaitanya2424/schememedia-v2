import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/auth_models.dart';

/// Durable storage for the current session (user + tokens) --
/// [FlutterSecureStorage], not `shared_preferences`: Keychain-backed on
/// iOS, Keystore-backed (EncryptedSharedPreferences) on Android, and
/// `window.localStorage` on web (flutter_secure_storage's own documented
/// web limitation -- no encryption-at-rest there, since browsers give a
/// web app no secure-enclave equivalent to call into; still isolated per
/// origin, and strictly better than storing a refresh token in a plain
/// `shared_preferences` key next to unrelated app data).
///
/// One key, one JSON blob (not one key per field): a session is read/
/// written as a unit everywhere except the silent-refresh path
/// ([writeTokens]), which updates just the token pair in place.
class AuthTokenStorage {
  AuthTokenStorage(this._storage);

  static const _key = 'auth_session';

  final FlutterSecureStorage _storage;

  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return AuthSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // A blob from an incompatible past shape -- treat as signed out
      // rather than crash the app on launch.
      return null;
    }
  }

  Future<void> writeSession(AuthSession session) {
    return _storage.write(key: _key, value: jsonEncode(session.toJson()));
  }

  /// Used by the silent-refresh interceptor (core/network/api_client.dart)
  /// -- updates only the token pair, preserving whatever user is already
  /// stored. A no-op if no session is stored yet (nothing to update
  /// against; the interceptor only ever fires for an already-authenticated
  /// request in the first place).
  Future<void> writeTokens({required String accessToken, required String refreshToken}) async {
    final existing = await readSession();
    if (existing == null) return;
    await writeSession(
      AuthSession(
        user: existing.user,
        tokens: AuthTokens(accessToken: accessToken, refreshToken: refreshToken),
      ),
    );
  }

  Future<void> clear() => _storage.delete(key: _key);
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => AuthTokenStorage(ref.watch(secureStorageProvider)),
);
