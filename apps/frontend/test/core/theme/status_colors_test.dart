// Audit finding M4: every status color used to be one fixed literal
// regardless of light/dark theme. Verified originally by computing actual
// WCAG contrast ratios (not eyeballed) -- this test file keeps that
// verification alive as a regression guard: it recomputes the same
// standard WCAG 2.x contrast formula against this app's *real* theme
// (AppTheme.light()/.dark(), not a hypothetical baseline), so a future
// color change that quietly drops below 4.5:1 fails here instead of only
// being caught by eye.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/core/domain/enums.dart';
import 'package:schememedia_app/core/theme/app_theme.dart';
import 'package:schememedia_app/core/theme/status_colors.dart';

/// Standard WCAG 2.x relative luminance / contrast ratio formulas.
double _channel(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color color) =>
    0.2126 * _channel(color.r) + 0.7152 * _channel(color.g) + 0.0722 * _channel(color.b);

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

// 4.5:1 is WCAG AA for normal text. These badge labels are ~12px bold --
// bold but not large enough (needs >=~18.7px/14pt bold) to qualify for the
// relaxed 3:1 large-text threshold, so 4.5:1 is the real bar.
const _minContrast = 4.5;

void main() {
  // AppTheme now builds its TextTheme via google_fonts, which needs the
  // Flutter binding initialized to load font assets -- this file uses
  // plain test(), not testWidgets(), so that never happens implicitly.
  TestWidgetsFlutterBinding.ensureInitialized();

  final lightScheme = AppTheme.light().colorScheme;
  final darkScheme = AppTheme.dark().colorScheme;

  group('StatusColors picks a different color per brightness', () {
    test('every defined eligibility state differs between light and dark', () {
      for (final state in [
        EligibilityState.pass,
        EligibilityState.fail,
        EligibilityState.unknown,
        EligibilityState.notApplicable,
      ]) {
        final light = StatusColors.eligibility(state, lightScheme);
        final dark = StatusColors.eligibility(state, darkScheme);
        expect(light, isNot(equals(dark)), reason: '$state must use a different color in dark mode');
      }
    });

    test('every defined verification status differs between light and dark', () {
      for (final status in [
        VerificationStatus.officiallyVerified,
        VerificationStatus.sourceProvided,
        VerificationStatus.unverified,
      ]) {
        final light = StatusColors.verification(status, lightScheme);
        final dark = StatusColors.verification(status, darkScheme);
        expect(light, isNot(equals(dark)), reason: '$status must use a different color in dark mode');
      }
    });

    test('the shared warning color differs between light and dark', () {
      expect(StatusColors.warning(lightScheme), isNot(equals(StatusColors.warning(darkScheme))));
    });

    test('unrecognized values fall back to scheme.outline directly, not a fixed literal', () {
      expect(
        StatusColors.eligibility(EligibilityState.unrecognized, lightScheme),
        lightScheme.outline,
      );
      expect(
        StatusColors.eligibility(EligibilityState.unrecognized, darkScheme),
        darkScheme.outline,
      );
      expect(
        StatusColors.verification(VerificationStatus.unrecognized, lightScheme),
        lightScheme.outline,
      );
      expect(
        StatusColors.verification(VerificationStatus.unrecognized, darkScheme),
        darkScheme.outline,
      );
    });
  });

  group('StatusColors meets WCAG AA (4.5:1) against this app\'s real surface', () {
    test('every eligibility state, both themes', () {
      for (final state in [
        EligibilityState.pass,
        EligibilityState.fail,
        EligibilityState.unknown,
        EligibilityState.notApplicable,
      ]) {
        final lightRatio = _contrastRatio(
          StatusColors.eligibility(state, lightScheme),
          lightScheme.surface,
        );
        final darkRatio = _contrastRatio(
          StatusColors.eligibility(state, darkScheme),
          darkScheme.surface,
        );
        expect(
          lightRatio,
          greaterThanOrEqualTo(_minContrast),
          reason: 'eligibility($state) on light surface: ${lightRatio.toStringAsFixed(2)}:1',
        );
        expect(
          darkRatio,
          greaterThanOrEqualTo(_minContrast),
          reason: 'eligibility($state) on dark surface: ${darkRatio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('every verification status, both themes', () {
      for (final status in [
        VerificationStatus.officiallyVerified,
        VerificationStatus.sourceProvided,
        VerificationStatus.unverified,
      ]) {
        final lightRatio = _contrastRatio(
          StatusColors.verification(status, lightScheme),
          lightScheme.surface,
        );
        final darkRatio = _contrastRatio(
          StatusColors.verification(status, darkScheme),
          darkScheme.surface,
        );
        expect(
          lightRatio,
          greaterThanOrEqualTo(_minContrast),
          reason: 'verification($status) on light surface: ${lightRatio.toStringAsFixed(2)}:1',
        );
        expect(
          darkRatio,
          greaterThanOrEqualTo(_minContrast),
          reason: 'verification($status) on dark surface: ${darkRatio.toStringAsFixed(2)}:1',
        );
      }
    });

    test('the shared warning color, both themes', () {
      final lightRatio = _contrastRatio(StatusColors.warning(lightScheme), lightScheme.surface);
      final darkRatio = _contrastRatio(StatusColors.warning(darkScheme), darkScheme.surface);
      expect(lightRatio, greaterThanOrEqualTo(_minContrast), reason: '${lightRatio.toStringAsFixed(2)}:1');
      expect(darkRatio, greaterThanOrEqualTo(_minContrast), reason: '${darkRatio.toStringAsFixed(2)}:1');
    });
  });
}
