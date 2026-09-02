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

  /// The wire-format profile map -- only answered keys, ready to send as
  /// `/recommendations`'s `profile` field.
  Map<String, dynamic> toProfileJson() => {
    for (final entry in _answers.entries) entry.key.wireKey: entry.value,
  };
}
