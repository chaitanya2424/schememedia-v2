// Smoke test: the app boots and the Home screen renders its search entry
// point. Replaces the default counter-app test scaffolded by `flutter
// create` -- there is no counter in this app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/app.dart';

void main() {
  testWidgets('App boots and shows the Home screen search field', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SchemeMediaApp()));
    await tester.pumpAndSettle();

    expect(find.text('SchemeMedia'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
