import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import 'profile_automation_api.dart';

final profileAutomationApiProvider = Provider<ProfileAutomationApi>(
  (ref) => ProfileAutomationApi(ApiClient()),
);

final profileAutomationRepositoryProvider = Provider<ProfileAutomationRepository>(
  (ref) => ProfileAutomationRepository(ref.watch(profileAutomationApiProvider)),
);

class ProfileAutomationRepository {
  ProfileAutomationRepository(this._api);

  final ProfileAutomationApi _api;

  Future<Map<String, dynamic>> digilockerFetch({
    String? aadhaarNumber,
    String? mobileNumber,
    String? otp,
    String? demoPersona,
    bool autoSave = true,
  }) async {
    try {
      return await _api.digilockerFetch(
        aadhaarNumber: aadhaarNumber,
        mobileNumber: mobileNumber,
        otp: otp,
        demoPersona: demoPersona,
        autoSave: autoSave,
      );
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }

  Future<Map<String, dynamic>> extractDocument({
    String? imageBase64,
    String? ocrText,
    String? documentHint,
    bool autoSave = true,
  }) async {
    try {
      return await _api.extractDocument(
        imageBase64: imageBase64,
        ocrText: ocrText,
        documentHint: documentHint,
        autoSave: autoSave,
      );
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
