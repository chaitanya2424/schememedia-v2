// Live integration tests against the REAL local backend, exercising the
// exact code path the Recommendations screen calls
// (RecommendationsRepository -> RecommendationsApi -> ApiClient) with
// realistic profiles: a fairly complete profile, a partial profile, an
// empty profile, a profile producing a known real failure, and both
// validation and network error cases.
//
// Deliberately plain `test()`, not `testWidgets()`: importing
// `flutter_test`'s widget-testing surface and pumping any widget in this
// process initializes `TestWidgetsFlutterBinding`, which installs test
// `HttpOverrides` that intercept ALL real `HttpClient` traffic (verified
// directly -- a bare GET to the local backend returns a synthetic 400 with
// an empty body the instant a `testWidgets` runs in the same file, even
// via an unrelated dummy widget). That is Flutter's own network isolation
// for widget tests, not something this app's code can opt out of, so a
// widget test cannot make a real network call. This file makes the real
// call; `recommendations_screen_test.dart` verifies the screen's
// *rendering* of realistic (real, captured) response shapes instead.
//
// Real, documented scenarios reused from the backend's own test suite
// (test_recommendation.py) so expected outcomes are already verified
// server-side, not guessed:
//   - PASS: "sports journalism award" + {is_sc_st: true} -> SCH_1F47743B
//   - FAIL: "avivahita pension unmarried woman" +
//     {is_woman: false, annual_income: 500000, age: 20, is_taxpayer: false}
//     -> SCH_EBE5D9CA, demoted but still present.
//
// Port 8000 currently has two stale/duplicate listeners on this machine
// (netstat shows two PIDs bound to 127.0.0.1:8000); 8001 is the single
// clean instance, so tests target it explicitly.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/core/network/api_exception.dart';
import 'package:schememedia_app/features/recommendations/data/recommendations_api.dart';
import 'package:schememedia_app/features/recommendations/data/recommendations_repository.dart';

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
  late RecommendationsRepository repository;

  setUpAll(() async {
    backendAvailable = await _isBackendReachable();
  });

  setUp(() {
    final dio = ApiClient.buildDio()..options.baseUrl = '$_backendUrl/api/v1';
    repository = RecommendationsRepository(RecommendationsApi(ApiClient(dio: dio)));
  });

  group('RecommendationsRepository (real local backend)', () {
    test('empty profile: profile_provided is false, results still returned', () async {
      if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

      final response = await repository.getRecommendations(query: 'farmer subsidy');

      expect(response.profileProvided, isFalse);
      expect(response.recommendations, isNotEmpty);
      // With no profile, nothing can be confirmed PASS/FAIL -- see the
      // backend's own eligibility_matcher.py invariant.
      expect(
        response.recommendations.every(
          (r) => r.eligibilityRules.every((rule) => rule.state.name == 'unknown' || rule.state.name == 'notApplicable'),
        ),
        isTrue,
      );
    });

    test('partial profile: one attribute is enough to surface a real PASS (SCH_1F47743B)', () async {
      if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

      final response = await repository.getRecommendations(
        query: 'sports journalism award',
        profile: {'is_sc_st': true},
      );

      expect(response.profileProvided, isTrue);
      final match = response.recommendations.firstWhere((r) => r.schemeId == 'SCH_1F47743B');
      expect(match.eligibilityState.name, 'pass');
      expect(match.eligibilityRules.any((r) => r.explanation.contains('Scheduled Caste')), isTrue);
    });

    test('known-failure profile: FAIL is demoted but still present (SCH_EBE5D9CA)', () async {
      if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

      final response = await repository.getRecommendations(
        query: 'avivahita pension unmarried woman',
        profile: {'is_woman': false, 'annual_income': 500000, 'age': 20, 'is_taxpayer': false},
      );

      final ids = response.recommendations.map((r) => r.schemeId).toList();
      expect(ids, contains('SCH_EBE5D9CA'), reason: 'a known FAIL must still be returned, never filtered out');

      final index = ids.indexOf('SCH_EBE5D9CA');
      final match = response.recommendations[index];
      expect(match.eligibilityState.name, 'fail');
      // Ranks, never filters: everything from this FAIL's position onward
      // must also be FAIL (the real property the backend guarantees).
      expect(response.recommendations.skip(index).every((r) => r.eligibilityState.name == 'fail'), isTrue);
    });

    test('fairly complete multi-attribute profile round-trips correctly', () async {
      if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

      final response = await repository.getRecommendations(
        query: 'farmer subsidy',
        profile: {
          'age': 45,
          'is_sc_st': true,
          'annual_income': 80000,
          'is_ews': true,
          'is_farmer': true,
          'owns_cultivable_land': true,
          'is_rural': true,
          'state_code': 'MH',
        },
      );

      expect(response.profileProvided, isTrue);
      expect(response.recommendations, isNotEmpty);
      expect(
        response.recommendations.any((r) => r.eligibilityState.name == 'pass'),
        isTrue,
        reason: 'a fairly complete matching profile should resolve at least one scheme to PASS',
      );
    });

    test('validation error: an over-length query surfaces as ApiException.validation', () async {
      if (!backendAvailable) return markTestSkipped('Backend not reachable at $_backendUrl.');

      try {
        await repository.getRecommendations(query: 'a' * 250);
        fail('expected an ApiException.validation to be thrown');
      } on ApiException catch (e) {
        expect(e, isA<ApiValidationException>());
      }
    });

    test('network error: an unreachable backend surfaces as ApiException.network', () async {
      final dio = ApiClient.buildDio()
        ..options.baseUrl = 'http://localhost:59999/api/v1'
        ..options.connectTimeout = const Duration(seconds: 2);
      final unreachableRepository = RecommendationsRepository(RecommendationsApi(ApiClient(dio: dio)));

      try {
        await unreachableRepository.getRecommendations(query: 'farmer subsidy');
        fail('expected an ApiException.network to be thrown');
      } on ApiException catch (e) {
        expect(e, isA<ApiNetworkException>());
      }
    });
  });
}
