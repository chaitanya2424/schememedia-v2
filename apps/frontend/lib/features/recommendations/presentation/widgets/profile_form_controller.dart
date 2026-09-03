import 'package:flutter/foundation.dart';

import '../../domain/eligibility_attribute.dart';

/// Transient, screen-local form state for the recommendations profile --
/// not app-wide state, so a plain [ChangeNotifier] rather than a Riverpod
/// provider (that stays reserved for the actual network request/response).
///
/// Only answered fields are ever kept: every attribute is optional, and
/// clearing a field back to "not answered" removes its key entirely rather
/// than sending an explicit null -- so `toProfileJson()` always matches
/// exactly what the user chose to disclose.
class ProfileFormController extends ChangeNotifier {
  final Map<EligibilityAttribute, Object> _answers = {};

  Object? valueOf(EligibilityAttribute attribute) => _answers[attribute];

  void setBoolean(EligibilityAttribute attribute, bool? value) => _set(attribute, value);

  void setNumeric(EligibilityAttribute attribute, double? value) => _set(attribute, value);

  void setText(EligibilityAttribute attribute, String? value) {
    final trimmed = value?.trim();
    _set(attribute, (trimmed == null || trimmed.isEmpty) ? null : trimmed);
  }

  void _set(EligibilityAttribute attribute, Object? value) {
    if (value == null) {
      _answers.remove(attribute);
    } else {
      _answers[attribute] = value;
    }
    notifyListeners();
  }

  bool get isEmpty => _answers.isEmpty;

  /// Answered attributes across every group -- drives the form's overall
  /// "N of 27 answered" progress indicator (computed client-side, no
  /// backend change).
  int get totalAnswered => _answers.length;

  /// The wire-format profile map -- only answered keys, ready to send as
  /// `/recommendations`'s `profile` field.
  Map<String, dynamic> toProfileJson() => {
    for (final entry in _answers.entries) entry.key.wireKey: entry.value,
  };

  /// Replaces the in-progress answers with `attributes` (keyed the same
  /// way `toProfileJson()` produces them) -- used to prefill the wizard
  /// from a signed-in user's persisted profile (GET /me/profile) so a
  /// returning user doesn't have to re-answer everything. A null/absent
  /// value for a key stays unanswered; a value of the wrong type for its
  /// attribute is skipped rather than stored malformed.
  void loadFrom(Map<String, dynamic> attributes) {
    _answers.clear();
    for (final attribute in EligibilityAttribute.values) {
      final value = attributes[attribute.wireKey];
      if (value == null) continue;
      switch (attribute.kind) {
        case AttributeKind.boolean:
          if (value is bool) _answers[attribute] = value;
        case AttributeKind.numeric:
          if (value is num) _answers[attribute] = value.toDouble();
        case AttributeKind.text:
          if (value is String && value.isNotEmpty) _answers[attribute] = value;
      }
    }
    notifyListeners();
  }
}
