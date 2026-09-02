import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_schemes_repository.dart' show sharedPreferencesProvider;

/// Whether onboarding has been shown on this device -- real, local-only
/// state (same category as a theme preference), not user data. See the
/// redesign plan's Phase A/B capability table.
class OnboardingRepository {
  OnboardingRepository(this._prefs);

  static const _key = 'has_seen_onboarding';

  final SharedPreferences _prefs;

  bool hasSeen() => _prefs.getBool(_key) ?? false;

  Future<void> markSeen() => _prefs.setBool(_key, true);
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(sharedPreferencesProvider));
});

/// Defaults to "seen" (true) when local storage isn't available (e.g. a
/// widget test's bare ProviderContainer) -- degrades to "don't force
/// onboarding" rather than throwing, same pattern as
/// SavedSchemeIdsNotifier.
class HasSeenOnboardingNotifier extends Notifier<bool> {
  @override
  bool build() {
    try {
      return ref.watch(onboardingRepositoryProvider).hasSeen();
    } catch (_) {
      return true;
    }
  }

  void markSeen() {
    state = true;
    try {
      ref.read(onboardingRepositoryProvider).markSeen();
    } catch (_) {
      // No local storage available in this context.
    }
  }
}

final hasSeenOnboardingProvider = NotifierProvider<HasSeenOnboardingNotifier, bool>(
  HasSeenOnboardingNotifier.new,
);
