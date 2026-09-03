import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_schemes_repository.dart' show sharedPreferencesProvider;

/// Real, local-only theme preference (light/dark/system) -- see the
/// redesign plan's Phase A/B capability table: same category as
/// onboarding's "seen" flag, device UI state rather than user data, no
/// account needed. `main.dart`/`app.dart` reads this for
/// `MaterialApp.router`'s `themeMode`.
class ThemeModeRepository {
  ThemeModeRepository(this._prefs);

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;

  ThemeMode load() => switch (_prefs.getString(_key)) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> save(ThemeMode mode) => _prefs.setString(_key, mode.name);
}

final themeModeRepositoryProvider = Provider<ThemeModeRepository>((ref) {
  return ThemeModeRepository(ref.watch(sharedPreferencesProvider));
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    try {
      return ref.watch(themeModeRepositoryProvider).load();
    } catch (_) {
      return ThemeMode.system;
    }
  }

  void setMode(ThemeMode mode) {
    state = mode;
    try {
      ref.read(themeModeRepositoryProvider).save(mode);
    } catch (_) {
      // No local storage available in this context.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
