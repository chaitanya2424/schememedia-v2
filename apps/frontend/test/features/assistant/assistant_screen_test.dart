// Widget-level tests for the Assistant screen: rendering and interaction
// against realistic response shapes. Three of the four fixtures in
// test/fixtures/assistant/ are exactly what they claim to be:
//
//   - service_unavailable_response.json is an UNEDITED capture of a real
//     503 from the live local backend (the Gemini free-tier daily quota was
//     exhausted at the time -- a previously-documented condition, see
//     assistant_repository_live_test.dart).
//   - off_topic_response.json is an UNEDITED capture of a real reply from a
//     later structured user-testing pass (Gemini's own quota/availability
//     varies by day): asked an off-topic question, it correctly refused
//     rather than hallucinating, with zero evidence results and zero
//     grounding warnings. The first live attempt at this same question hit
//     a real, transient Gemini ServerError (5xx) -- correctly surfaced as a
//     503 by the same path service_unavailable_response.json exercises --
//     and this fixture is the retry that succeeded.
//   - normal_response.json and grounding_warning_response.json could not
//     be captured live (quota, at the time), so they are constructed from
//     the real EvidenceResultOut schema (api/v1/routers/assistant.py) using
//     real scheme data already verified via the recommendations fixtures
//     (SCH_1F47743B / "Biju Patnaik Sports Award..."), and the real
//     grounding-warning wording taken verbatim from
//     services/assistant.py's verify_grounded() --
//     "fabricated or unsupported URL: {url}" -- not invented text.
//
// See recommendations_screen_test.dart's module docstring for why this is
// a widget test rather than a live one: Flutter's own test HttpOverrides
// block real network calls the instant a widget is pumped.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/network/api_client.dart';
import 'package:schememedia_app/core/network/api_exception.dart';
import 'package:schememedia_app/features/assistant/data/assistant_api.dart';
import 'package:schememedia_app/features/assistant/data/assistant_repository.dart';
import 'package:schememedia_app/features/assistant/domain/assistant_message.dart';
import 'package:schememedia_app/features/assistant/presentation/providers/assistant_providers.dart';
import 'package:schememedia_app/features/assistant/presentation/screens/assistant_screen.dart';
import 'package:schememedia_app/features/assistant/presentation/widgets/evidence_card.dart';

AssistantTurn _loadFixture(String name) {
  final raw = File('test/fixtures/assistant/$name').readAsStringSync();
  return AssistantTurn.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// Returns a fixed turn (or throws a fixed exception) instead of calling
/// the network -- seeded from real captured/schema-accurate data, never
/// invented shapes.
class FakeAssistantRepository extends AssistantRepository {
  FakeAssistantRepository({this.turn, this.error}) : super(AssistantApi(ApiClient()));

  final AssistantTurn? turn;
  final ApiException? error;
  int callCount = 0;
  String? lastMessage;

  @override
  Future<AssistantTurn> sendMessage(String message) async {
    callCount++;
    lastMessage = message;
    if (error != null) throw error!;
    return turn!;
  }
}

void main() {
  Future<ProviderContainer> pumpWithFake(WidgetTester tester, AssistantRepository fake) async {
    final container = ProviderContainer(overrides: [assistantRepositoryProvider.overrideWithValue(fake)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const MaterialApp(home: AssistantScreen())),
    );
    return container;
  }

  Future<void> sendMessage(WidgetTester tester, String message) async {
    await tester.enterText(find.byKey(const ValueKey('assistant_message_field')), message);
    await tester.tap(find.byKey(const ValueKey('assistant_send_button')));
    await tester.pumpAndSettle();
  }

  group('Assistant screen rendering', () {
    testWidgets('normal grounded response: reply, no warnings, evidence available but collapsed', (
      tester,
    ) async {
      final fake = FakeAssistantRepository(turn: _loadFixture('normal_response.json'));
      final container = await pumpWithFake(tester, fake);
      await sendMessage(tester, "I'm SC/ST, are there any sports or journalism awards for me?");

      expect(fake.callCount, 1);
      expect(container.read(assistantNotifierProvider).isSending, isFalse);
      expect(
        find.textContaining('Biju Patnaik Sports Award for Excellence in Sports Journalism'),
        findsOneWidget,
      );
      // No grounding warning banner on a clean reply.
      expect(find.textContaining('may not be fully accurate'), findsNothing);
      // Sources exist but start collapsed -- the reply is the primary content.
      expect(find.textContaining('Sources (1)'), findsOneWidget);
      expect(find.byType(EvidenceCard), findsNothing);
    });

    testWidgets('grounding warnings are always visible, never hidden behind an expand', (tester) async {
      final fake = FakeAssistantRepository(turn: _loadFixture('grounding_warning_response.json'));
      await pumpWithFake(tester, fake);
      await sendMessage(tester, 'sports journalism award, apply where?');

      expect(find.textContaining('This reply may not be fully accurate'), findsOneWidget);
      expect(
        find.textContaining('fabricated or unsupported URL: https://totally-made-up.example.com/apply'),
        findsOneWidget,
      );
    });

    testWidgets('off-topic message: honest refusal renders cleanly with no Sources button', (
      tester,
    ) async {
      // Real captured response (see fixtures/assistant/off_topic_response.json's
      // module docstring reference): a real transient Gemini ServerError hit
      // live during structured user testing, and the retry captured this --
      // the model correctly refuses to answer an off-topic question rather
      // than hallucinating, with zero evidence results and zero warnings.
      final fake = FakeAssistantRepository(turn: _loadFixture('off_topic_response.json'));
      await pumpWithFake(tester, fake);
      await sendMessage(tester, 'What is the best recipe for chocolate cake?');

      expect(
        find.textContaining("I am SchemeMedia's assistant and can only help"),
        findsOneWidget,
      );
      // No sources to show -- the toggle must not appear for zero evidence.
      expect(find.textContaining('Sources ('), findsNothing);
      // No grounding warning banner on a clean (if empty) response.
      expect(find.textContaining('may not be fully accurate'), findsNothing);
    });

    testWidgets('evidence card expands to show eligibility explanation and verification status', (
      tester,
    ) async {
      final fake = FakeAssistantRepository(turn: _loadFixture('normal_response.json'));
      await pumpWithFake(tester, fake);
      await sendMessage(tester, "I'm SC/ST, are there any sports or journalism awards for me?");

      final sourcesToggle = find.textContaining('Sources (1)');
      await tester.ensureVisible(sourcesToggle);
      await tester.pumpAndSettle();
      await tester.tap(sourcesToggle);
      await tester.pumpAndSettle();

      expect(find.byType(EvidenceCard), findsOneWidget);
      // Redesign-v2 wording (matches reference mockups): "Likely eligible",
      // not a bare "Eligible" -- more honest about a rule-based match.
      expect(find.text('Likely eligible'), findsOneWidget); // EligibilityStateBadge for eligibility_state: pass
      expect(find.text('Unverified'), findsOneWidget); // VerificationBadge for verification_status: unverified

      final whyButton = find.textContaining('Why this scheme?');
      await tester.ensureVisible(whyButton);
      await tester.pumpAndSettle();
      await tester.tap(whyButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Scheduled Caste'), findsOneWidget);
    });

    testWidgets('503 / provider unavailable renders the backend\'s own message as an error bubble', (
      tester,
    ) async {
      // The real, unedited captured 503 body -- decode it exactly the way
      // ApiClient's error-mapping interceptor does, so the fixture drives
      // the same ApiException the real app would construct.
      final raw = jsonDecode(File('test/fixtures/assistant/service_unavailable_response.json').readAsStringSync())
          as Map<String, dynamic>;
      final message = (raw['error'] as Map<String, dynamic>)['message'] as String;
      expect(message, 'The assistant is temporarily unavailable. Please try again shortly.');

      final fake = FakeAssistantRepository(error: ApiException.unavailable(message));
      await pumpWithFake(tester, fake);
      await sendMessage(tester, "I'm a farmer, what schemes help me?");

      expect(find.text(message), findsOneWidget);
      // User message still visible above the error -- history isn't wiped.
      expect(find.text("I'm a farmer, what schemes help me?"), findsOneWidget);
    });

    testWidgets('network failure renders as an error bubble too', (tester) async {
      final fake = FakeAssistantRepository(error: const ApiException.network());
      await pumpWithFake(tester, fake);
      await sendMessage(tester, 'hello');

      expect(find.text('No connection. Check your network and try again.'), findsOneWidget);
    });

    testWidgets('empty input: send is a no-op, no request is made', (tester) async {
      final fake = FakeAssistantRepository(turn: _loadFixture('normal_response.json'));
      await pumpWithFake(tester, fake);

      // Nothing typed -- tapping send must not call the repository.
      await tester.tap(find.byKey(const ValueKey('assistant_send_button')));
      await tester.pump();
      expect(fake.callCount, 0);

      // Whitespace-only input is equally a no-op.
      await tester.enterText(find.byKey(const ValueKey('assistant_message_field')), '   ');
      await tester.tap(find.byKey(const ValueKey('assistant_send_button')));
      await tester.pump();
      expect(fake.callCount, 0);
    });

    testWidgets('sending state: input disables and a typing indicator shows while in flight', (
      tester,
    ) async {
      final completer = Completer<AssistantTurn>();
      final fake = _DelayedFakeAssistantRepository(completer.future);
      await pumpWithFake(tester, fake);

      await tester.enterText(find.byKey(const ValueKey('assistant_message_field')), 'hello');
      await tester.tap(find.byKey(const ValueKey('assistant_send_button')));
      await tester.pump();

      expect(find.text('Thinking…'), findsOneWidget);
      final field = tester.widget<TextField>(find.byKey(const ValueKey('assistant_message_field')));
      expect(field.enabled, isFalse);

      completer.complete(_loadFixture('normal_response.json'));
      await tester.pumpAndSettle();
      expect(find.text('Thinking…'), findsNothing);
    });

    testWidgets('send button has an accessible label, enabled and while sending', (tester) async {
      // Audit finding M3: the send button had no tooltip at all -- a
      // screen reader announced nothing meaningful for it.
      final completer = Completer<AssistantTurn>();
      final fake = _DelayedFakeAssistantRepository(completer.future);
      await pumpWithFake(tester, fake);

      expect(find.byTooltip('Send message'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('assistant_message_field')), 'hello');
      await tester.tap(find.byKey(const ValueKey('assistant_send_button')));
      await tester.pump();

      // Different label while disabled/sending -- still never unlabeled.
      expect(find.byTooltip('Sending…'), findsOneWidget);
      expect(find.byTooltip('Send message'), findsNothing);

      completer.complete(_loadFixture('normal_response.json'));
      await tester.pumpAndSettle();
    });
  });
}

class _DelayedFakeAssistantRepository extends AssistantRepository {
  _DelayedFakeAssistantRepository(this.future) : super(AssistantApi(ApiClient()));

  final Future<AssistantTurn> future;

  @override
  Future<AssistantTurn> sendMessage(String message) => future;
}
