import '../../domain/auth_models.dart';

enum AuthStatus { signedOut, signedIn }

/// UI-visible auth state -- the single source of truth every screen reads
/// (route guards, Profile, the wizard's persist/prefill hooks, ...). See
/// core/network/auth_token_cache.dart for the separate, lower-level cache
/// the network layer reads from instead of this.
class AuthState {
  const AuthState._(this.status, this.user);

  const AuthState.signedOut() : this._(AuthStatus.signedOut, null);

  factory AuthState.signedIn(AuthUser user) => AuthState._(AuthStatus.signedIn, user);

  final AuthStatus status;
  final AuthUser? user;

  bool get isSignedIn => status == AuthStatus.signedIn;
}
