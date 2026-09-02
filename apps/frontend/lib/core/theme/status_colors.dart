import 'package:flutter/material.dart';

import '../domain/enums.dart';

/// The **one** place `verification_status` and `eligibility_state` map to
/// color (and the one place a "warning" amber is defined). [VerificationBadge],
/// [EligibilityStateBadge], and every scheme/evidence/rule card read from
/// here -- so the four screens that show these fields never disagree. See
/// the frontend architecture plan's Theme section.
///
/// Audit finding M4: every color below used to be one fixed literal
/// regardless of light/dark theme. Verified by computing actual WCAG
/// contrast ratios (not eyeballed) against Material 3's default light
/// (#FFFBFE) and dark (#141218) surface tones: the original saturated
/// tones (e.g. green #2E7D32) read fine on light (5.0:1) but fell to
/// 3.6:1 on dark -- under the 4.5:1 AA threshold these ~12px bold labels
/// need (they're bold but not large enough to qualify for the relaxed
/// 3:1 large-text threshold). The original amber had the *opposite*
/// problem: 9.4:1 on dark, but only 1.9:1 on light -- already failing
/// today, in light mode, independent of dark-mode support. Every value
/// below is chosen so both directions clear 4.5:1.
abstract final class StatusColors {
  static const _greenLight = Color(0xFF2E7D32);
  static const _greenDark = Color(0xFF81C784);
  static const _redLight = Color(0xFFC62828);
  static const _redDark = Color(0xFFE57373);
  static const _amberLight = Color(0xFF996600);
  static const _amberDark = Color(0xFFF9A825);
  static const _blueLight = Color(0xFF1565C0);
  static const _blueDark = Color(0xFF64B5F6);
  static const _greyLight = Color(0xFF6E6E6E);
  static const _greyDark = Color(0xFFBDBDBD);

  static bool _isDark(ColorScheme scheme) => scheme.brightness == Brightness.dark;

  /// The shared warning/attention amber -- "needs review" badges, unknown
  /// eligibility, grounding warnings. Previously duplicated as a raw
  /// literal in verification_badge.dart, chat_entry_view.dart, and
  /// evidence_card.dart; those now call this instead.
  static Color warning(ColorScheme scheme) => _isDark(scheme) ? _amberDark : _amberLight;

  static Color verification(VerificationStatus status, ColorScheme scheme) {
    final dark = _isDark(scheme);
    return switch (status) {
      VerificationStatus.officiallyVerified => dark ? _greenDark : _greenLight,
      VerificationStatus.sourceProvided => dark ? _blueDark : _blueLight,
      VerificationStatus.unverified => dark ? _greyDark : _greyLight,
      VerificationStatus.unrecognized => scheme.outline,
    };
  }

  static Color eligibility(EligibilityState state, ColorScheme scheme) {
    final dark = _isDark(scheme);
    return switch (state) {
      EligibilityState.pass => dark ? _greenDark : _greenLight,
      EligibilityState.fail => dark ? _redDark : _redLight,
      EligibilityState.unknown => warning(scheme),
      EligibilityState.notApplicable => dark ? _greyDark : _greyLight,
      EligibilityState.unrecognized => scheme.outline,
    };
  }
}
