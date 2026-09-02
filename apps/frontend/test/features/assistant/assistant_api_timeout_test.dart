// Audit finding L1 (paired with the backend's H1 fix): the assistant
// endpoint can involve up to two sequential LLM calls server-side, each
// budgeted 30s (raised from an original 20s after live testing measured
// real Gemini call latency within a hair of that -- see
// gemini_provider.py's DEFAULT_TIMEOUT_MS comment), so it needs a longer
// client-side receive timeout than the 15s default every other (single
// fast DB query) endpoint uses -- otherwise a slow-but-successful reply
// would show a spurious network error. This verifies the actual
// RequestOptions Dio builds for the call, without ever sending it over the
// network: an interceptor captures the options and rejects immediately.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/features/assistant/data/assistant_api.dart';

void main() {
  test('sendMessage requests a 90s receive timeout, well above the 15s default', () async {
    Duration? capturedReceiveTimeout;

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:9999'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedReceiveTimeout = options.receiveTimeout;
          // Reject instead of letting this reach the network -- this test
          // only cares what Dio was *asked* to send.
          handler.reject(
            DioException(requestOptions: options, type: DioExceptionType.cancel),
          );
        },
      ),
    );

    final api = AssistantApi(ApiClient(dio: dio));

    await expectLater(api.sendMessage('hello'), throwsA(isA<DioException>()));
    expect(capturedReceiveTimeout, const Duration(seconds: 90));
  });

  test('search/recommendations-style calls keep the client-wide default (no override)', () async {
    Duration? capturedReceiveTimeout;
    const clientDefault = Duration(seconds: 15);

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:9999', receiveTimeout: clientDefault));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          capturedReceiveTimeout = options.receiveTimeout;
          handler.reject(
            DioException(requestOptions: options, type: DioExceptionType.cancel),
          );
        },
      ),
    );

    final client = ApiClient(dio: dio);
    await expectLater(client.post('/recommendations', data: {}), throwsA(isA<DioException>()));
    expect(capturedReceiveTimeout, clientDefault);
  });
}
