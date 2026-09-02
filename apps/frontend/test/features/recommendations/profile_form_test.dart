// Audit finding M3: the numeric field's clear (X) button had no
// accessibility label -- a screen reader announced nothing meaningful for
// it. Verifies the fix directly against ProfileForm in isolation, which is
// simpler and faster than driving it through the whole Recommendations
// screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/features/recommendations/presentation/widgets/profile_form.dart';
import 'package:schememedia_app/features/recommendations/presentation/widgets/profile_form_controller.dart';

void main() {
  Future<ProfileFormController> pumpForm(WidgetTester tester) async {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: ProfileForm(controller: controller))),
      ),
    );
    return controller;
  }

  testWidgets('numeric field clear button has an accessible tooltip once a value is entered', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.tap(find.text('Demographic'));
    await tester.pumpAndSettle();

    // No value yet -- the clear button (and any tooltip for it) must not exist.
    expect(find.byTooltip('Clear Age'), findsNothing);

    final ageField = find.byKey(const ValueKey('field_age'));
    await tester.ensureVisible(ageField);
    await tester.pumpAndSettle();
    await tester.enterText(ageField, '30');
    await tester.pump();

    final clearButton = find.byTooltip('Clear Age');
    expect(clearButton, findsOneWidget);

    await tester.ensureVisible(clearButton);
    await tester.pumpAndSettle();
    await tester.tap(clearButton);
    await tester.pump();

    expect(find.text('30'), findsNothing);
    expect(find.byTooltip('Clear Age'), findsNothing);
  });
}
