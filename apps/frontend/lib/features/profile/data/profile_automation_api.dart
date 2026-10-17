import '../../../core/network/api_client.dart';

class ProfileAutomationApi {
  ProfileAutomationApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> digilockerFetch({
    String? aadhaarNumber,
    String? mobileNumber,
    String? otp,
    String? demoPersona,
    bool autoSave = true,
  }) async {
    final response = await _client.post(
      '/profile-automation/digilocker-fetch',
      data: {
        if (aadhaarNumber != null) 'aadhaar_number': aadhaarNumber,
        if (mobileNumber != null) 'mobile_number': mobileNumber,
        if (otp != null) 'otp': otp,
        if (demoPersona != null) 'demo_persona': demoPersona,
        'auto_save': autoSave,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> extractDocument({
    String? imageBase64,
    String? ocrText,
    String? documentHint,
    bool autoSave = true,
  }) async {
    final response = await _client.post(
      '/profile-automation/extract-document',
      data: {
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (ocrText != null) 'ocr_text': ocrText,
        if (documentHint != null) 'document_hint': documentHint,
        'auto_save': autoSave,
      },
    );
    return response as Map<String, dynamic>;
  }
}
