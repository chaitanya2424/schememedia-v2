import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import 'profile_api.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ProfileApi _api;

  /// The full response (`attributes` + `answered_count` + `total_count`)
  /// -- callers that only need the attribute map (the wizard's prefill)
  /// read `response['attributes']` themselves; callers that show a
  /// completion count (Home, Profile) get it without a second request.
  Future<Map<String, dynamic>> getProfile() async {
    try {
      return await _api.getProfile();
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> attributes) async {
    try {
      return await _api.updateProfile(attributes);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
