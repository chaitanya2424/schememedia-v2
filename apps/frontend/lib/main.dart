import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/local/saved_schemes_repository.dart';
import 'core/network/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warm backend (wakes Render instance from sleep asynchronously in background)
  ApiClient().get('/health').ignore();
  // Bounded, and never fatal: local storage is a nice-to-have (saved
  // schemes, preferences), not something the whole app should hang
  // behind forever if it's ever slow or unavailable. If this fails or
  // times out, sharedPreferencesProvider is left un-overridden --
  // SavedSchemesNotifier, ThemeModeNotifier, and HasSeenOnboardingNotifier
  // all already degrade to in-memory-only/default rather than throwing
  // in that case.
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance().timeout(const Duration(seconds: 3));
  } catch (_) {
    prefs = null;
  }
  runApp(
    ProviderScope(
      overrides: [if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const SchemeMediaApp(),
    ),
  );
}
