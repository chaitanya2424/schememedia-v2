// Widget-level tests for the Recommendations screen. These verify
// *rendering and interaction* against realistic, real API response
// shapes -- the three fixtures in test/fixtures/recommendations/ are
// unedited captures from the real local backend (see
// recommendations_repository_live_test.dart's module docstring for why a
// widget test cannot make a real network call: Flutter's own
// `TestWidgetsFlutterBinding` intercepts all real `HttpClient` traffic the
// instant a widget is pumped in the same isolate). Together the two files
// cover the user's ask in full: the repository test proves the real API
// integration is correct; this file proves the screen renders that data
// (and its error states) correctly.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/core/network/api_exception.dart';
import 'package:schememedia_app/core/widgets/verification_badge.dart';
import 'package:schememedia_app/features/recommendations/data/recommendations_api.dart';
import 'package:schememedia_app/features/recommendations/data/recommendations_repository.dart';
import 'package:schememedia_app/features/recommendations/domain/recommendation.dart';
import 'package:schememedia_app/features/recommendations/presentation/providers/recommendations_providers.dart';
import 'package:schememedia_app/features/recommendations/presentation/screens/recommendations_screen.dart';
import 'package:schememedia_app/features/recommendations/presentation/widgets/recommendation_card.dart';

RecommendationResponse _loadFixture(String name) {
  final raw = File('test/fixtures/recommendations/$name').readAsStringSync();
  return RecommendationResponse.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Returns a fixed response (or throws a fixed exception) instead of
/// calling the network -- seeded from real captured data or a real
/// [ApiException] variant, never invented shapes.
class FakeRecommendationsRepository extends RecommendationsRepository {
  FakeRecommendationsRepository({this.response, this.error}) : super(RecommendationsApi(ApiClient()));

  final RecommendationResponse? response;
  final ApiException? error;
  int callCount = 0;

  @override
  Future<RecommendationResponse> getRecommendations({
    required String query,
    Map<String, dynamic>? profile,
    int limit = 20,
  }) async {
    callCount++;
    if (error != null) throw error!;
    return response!;
  }
}

void main() {
  Future<ProviderContainer> pumpWithFake(WidgetTester tester, FakeRecommendationsRepository fake) async {
    final container = ProviderContainer(
      overrides: [recommendationsRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: RecommendationsScreen())),
    );
    return container;
  }

  Future<void> submit(WidgetTester tester, String query) async {
    await tester.enterText(find.byKey(const ValueKey('recommendations_query_field')), query);
    final submitButton = find.byKey(const ValueKey('recommendations_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();
  }

  group('Recommendations screen rendering (real captured response shapes)', () {
    testWidgets('PASS scheme renders eligible badge, verification badge, and rule explanation', (tester) async {
      final fake = FakeRecommendationsRepository(response: _loadFixture('pass_response.json'));
      await pumpWithFake(tester, fake);
      await submit(tester, 'sports journalism award');

      const name = 'Biju Patnaik Sports Award for Excellence in Sports Journalism';
      await tester.scrollUntilVisible(find.text(name), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(name), findsOneWidget);

      final card = find.ancestor(of: find.text(name), matching: find.byType(RecommendationCard));
      expect(find.descendant(of: card, matching: find.text('Eligible')), findsOneWidget);
      expect(find.descendant(of: card, matching: find.byType(VerificationBadge)), findsOneWidget);

      final whyButton = find.descendant(of: card, matching: find.textContaining('Why?'));
      await tester.ensureVisible(whyButton);
      await tester.pumpAndSettle();
      await tester.tap(whyButton);
      await tester.pumpAndSettle();
      // Both the rule's label and its explanation legitimately mention
      // "Scheduled Caste" -- confirms the real explanation text rendered.
      expect(find.descendant(of: card, matching: find.textContaining('Scheduled Caste')), findsWidgets);
    });

    testWidgets('FAIL scheme stays visible and visually muted -- ranked, never filtered', (tester) async {
      final fake = FakeRecommendationsRepository(response: _loadFixture('fail_response.json'));
      await pumpWithFake(tester, fake);
      await submit(tester, 'avivahita pension unmarried woman');

      const name = 'Mukhyamantri Avivahita Pension Yojana';
      await tester.scrollUntilVisible(find.text(name), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text(name), findsOneWidget, reason: 'a known FAIL must still be rendered, never removed');

      final card = find.ancestor(of: find.text(name), matching: find.byType(RecommendationCard));
      expect(find.descendant(of: card, matching: find.text('Not eligible')), findsOneWidget);

      final opacityWidget = tester.widget<Opacity>(
        find.ancestor(of: find.text(name), matching: find.byType(Opacity)).first,
      );
      expect(opacityWidget.opacity, lessThan(1.0));
    });

    testWidgets('no profile: shows the honest "unknown" note, not a fabricated verdict', (tester) async {
      final fake = FakeRecommendationsRepository(response: _loadFixture('empty_profile_response.json'));
      await pumpWithFake(tester, fake);
      await submit(tester, 'farmer subsidy');

      expect(find.textContaining('Add some profile details'), findsOneWidget);
      expect(find.textContaining('unknown'), findsWidgets);
    });

    testWidgets('validation error renders inline with no retry action offered', (tester) async {
      final fake = FakeRecommendationsRepository(error: const ApiException.validation({}));
      await pumpWithFake(tester, fake);
      await submit(tester, 'a' * 250);

      expect(find.text('Some of the information provided was not valid.'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('network error renders with a retry action that re-submits', (tester) async {
      final fake = FakeRecommendationsRepository(error: const ApiException.network());
      await pumpWithFake(tester, fake);
      await submit(tester, 'farmer subsidy');

      expect(find.text('No connection. Check your network and try again.'), findsOneWidget);
      final retryButton = find.widgetWithText(FilledButton, 'Retry');
      expect(retryButton, findsOneWidget);

      expect(fake.callCount, 1);
      await tester.ensureVisible(retryButton);
      await tester.pumpAndSettle();
      await tester.tap(retryButton);
      await tester.pumpAndSettle();
      expect(fake.callCount, 2, reason: 'Retry must re-issue the same request, not just clear the error');
    });

    testWidgets('empty query: client-side validation blocks submission entirely', (tester) async {
      final fake = FakeRecommendationsRepository(response: _loadFixture('empty_profile_response.json'));
      await pumpWithFake(tester, fake);

      final submitButton = find.byKey(const ValueKey('recommendations_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.textContaining('Enter what you\'re looking for'), findsOneWidget);
      expect(fake.callCount, 0);
    });
  });
}
