/// The signed-in account -- identity only. Never carries the eligibility
/// profile (see features/profile) or saved schemes; those are separate,
/// account-scoped resources fetched independently, matching the backend's
/// own separation (users vs. user_profiles).
class AuthUser {
  const AuthUser({required this.id, required this.email, required this.fullName});

  final String id;
  final String email;
  final String? fullName;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    email: json['email'] as String,
    fullName: json['full_name'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'full_name': fullName};
}

/// An access/refresh token pair -- see core/network/auth_token_cache.dart
/// and core/local/auth_token_storage.dart for how these are held in memory
/// and persisted.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
  );
}

/// What register/login/refresh return -- user plus a fresh token pair.
class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final AuthUser user;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    tokens: AuthTokens.fromJson(json),
  );

  Map<String, dynamic> toJson() => {'user': user.toJson(), ...tokens.toJson()};
}
