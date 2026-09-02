// Live integration tests against the REAL local backend, exercising the
// exact code path the Assistant screen calls
// (AssistantRepository -> AssistantApi -> ApiClient).
//
// Deliberately plain `test()`, not `testWidgets()` -- see
// recommendations_repository_live_test.dart's module docstring for why:
// pumping any widget in the same isolate installs Flutter's test
// `HttpOverrides`, which intercepts all real `HttpClient` traffic.
//
// The live Gemini-backed provider is genuinely returning a real 503 right
// now (free-tier daily quota, a known, previously-documented condition --
// see the backend's own test_api_routes.py, which treats this exact 503 as
// "reached the real API, not a regression"), which this test captures and
// asserts on directly: it is real evidence the ServiceUnavailableError path
// works end to end through the whole stack, including this Flutter client.
// If the quota resets before this runs again, the assertion is relaxed to
// accept either a real reply or the real 503, rather than assuming one.
//
// Port 8000 has two stale/duplicate listeners on this machine; 8001 is the
// clean instance, targeted explicitly.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/core/network/api_exception.dart';
import 'package:schememedia_app/features/assistant/data/assistant_api.dart';
import 'package:schememedia_app/features/assistant/data/assistant_repository.dart';

const _backendUrl = 'http://127.0.0.1:8001';

Future<bool> _isBackendReachable() async {
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    final request = await client.getUrl(Uri.parse('$_backendUrl/health'));
    final response = await request.close();
    await response.drain<void>();
    client.close();
    return response.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  late bool backendAvailable;
  late AssistantRepository repository;

  setUpAll(() async {
    backendAvailable = await _isBackendReachable();
  });

  setUp(() {
    final dio = ApiClient.buildDio()..options.baseUrl = '$_backendUrl/api/v1';
    repository = AssistantRepository(AssistantApi(ApiClient(dio: dio)));
  });

  group('AssistantRepository (real local backend)', () {
    test(
      'a real question either gets a grounded reply or a real 503 -- never crashes',
      () async {
        if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

        try {
          final turn = await repository.sendMessage(
            "I'm SC/ST, are there any sports or journalism awards for me?",
          );
          expect(turn.reply, isNotEmpty);
          expect(turn.groundingWarnings, isA<List<String>>());
        } on ApiException catch (e) {
          // The documented free-tier quota condition -- a real 503 is a
          // legitimate, previously-verified outcome, not a test bug.
          expect(
            e,
            isA<ApiUnavailableException>(),
            reason: 'the only acceptable failure here is a real 503 (provider unavailable)',
          );
          final unavailable = e as ApiUnavailableException;
          expect(unavailable.message, isNotEmpty);
        }
      },
      // Found during structured user testing: package:test's own default
      // 30s test timeout is unrelated to (and was never widened alongside)
      // ApiClient's Dio-level timeouts -- a real assistant round trip
      // measured up to ~31s during live testing (see gemini_provider.py's
      // DEFAULT_TIMEOUT_MS comment), which spuriously killed this test at
      // its framework-level default even though the real request was still
      // in flight and would have succeeded. 120s comfortably clears
      // AssistantApi's own 90s Dio timeout, so the *Dio* timeout -- not
      // this one -- is what actually bounds a hung request.
      timeout: const Timeout(Duration(seconds: 120)),
    );

    test('empty message: real backend 422 surfaces as ApiException.validation', () async {
      if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

      try {
        await repository.sendMessage('');
        fail('expected an ApiException.validation to be thrown');
      } on ApiException catch (e) {
        expect(e, isA<ApiValidationException>());
      }
    });

    test('network error: an unreachable backend surfaces as ApiException.network', () async {
      final dio = ApiClient.buildDio()
        ..options.baseUrl = 'http://localhost:59999/api/v1'
        ..options.connectTimeout = const Duration(seconds: 2);
      final unreachableRepository = AssistantRepository(AssistantApi(ApiClient(dio: dio)));

      try {
        await unreachableRepository.sendMessage('hello');
        fail('expected an ApiException.network to be thrown');
      } on ApiException catch (e) {
        expect(e, isA<ApiNetworkException>());
      }
    });
  });
}
