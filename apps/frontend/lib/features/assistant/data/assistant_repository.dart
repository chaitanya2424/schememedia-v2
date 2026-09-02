import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../domain/assistant_message.dart';
import 'assistant_api.dart';

class AssistantRepository {
  AssistantRepository(this._api);

  final AssistantApi _api;

  Future<AssistantTurn> sendMessage(String message) async {
    try {
      return await _api.sendMessage(message);
    } on DioException catch (e) {
      throw e.asApiException;
    }
  }
}
