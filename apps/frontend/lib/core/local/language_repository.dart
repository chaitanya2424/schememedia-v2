import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'saved_schemes_repository.dart' show sharedPreferencesProvider;

/// Supported application languages.
enum AppLanguage {
  english(code: 'en', label: 'English', nativeLabel: 'English'),
  hindi(code: 'hi', label: 'Hindi', nativeLabel: 'हिंदी');

  const AppLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
  });

  final String code;
  final String label;
  final String nativeLabel;
}

/// Local-only persistence for citizen language selection (English / Hindi).
class LanguageRepository {
  LanguageRepository(this._prefs);

  static const _key = 'app_language_code';

  final SharedPreferences _prefs;

  AppLanguage load() {
    final code = _prefs.getString(_key);
    return switch (code) {
      'hi' => AppLanguage.hindi,
      _ => AppLanguage.english,
    };
  }

  Future<void> save(AppLanguage language) => _prefs.setString(_key, language.code);
}

final languageRepositoryProvider = Provider<LanguageRepository>((ref) {
  return LanguageRepository(ref.watch(sharedPreferencesProvider));
});

class LanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    try {
      return ref.watch(languageRepositoryProvider).load();
    } catch (_) {
      return AppLanguage.english;
    }
  }

  void setLanguage(AppLanguage language) {
    state = language;
    try {
      ref.read(languageRepositoryProvider).save(language);
    } catch (_) {
      // Local storage not ready
    }
  }

  void toggle() {
    setLanguage(state == AppLanguage.english ? AppLanguage.hindi : AppLanguage.english);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, AppLanguage>(LanguageNotifier.new);
