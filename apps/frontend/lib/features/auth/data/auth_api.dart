import '../../../core/network/api_client.dart';
import '../domain/auth_models.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<AuthSession> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final json = await _client.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
      },
    );
    return AuthSession.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthSession> login({required String email, required String password}) async {
    final json = await _client.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return AuthSession.fromJson(json as Map<String, dynamic>);
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final json = await _client.post(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    return AuthTokens.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) {
    return _client.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<AuthUser> me() async {
    final json = await _client.get('/auth/me');
    return AuthUser.fromJson(json as Map<String, dynamic>);
  }
}
