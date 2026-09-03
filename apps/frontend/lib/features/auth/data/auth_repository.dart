import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/auth_models.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._api);

  final AuthApi _api;

  Future<AuthSession> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      return await _api.register(email: email, password: password, fullName: fullName);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<AuthSession> login({required String email, required String password}) async {
    try {
      return await _api.login(email: email, password: password);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    try {
      return await _api.refresh(refreshToken);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _api.logout(refreshToken);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<AuthUser> me() async {
    try {
      return await _api.me();
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
