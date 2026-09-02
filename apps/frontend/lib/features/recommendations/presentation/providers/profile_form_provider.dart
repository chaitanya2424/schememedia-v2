import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/profile_form_controller.dart';

/// Lifted from a local `State` field to an app-wide provider so the
/// in-progress profile survives navigating away from For You -- and so
/// Home's real "N of 27 answered" stat can read the same state. Not
/// `.autoDispose`: answers are meant to persist for the rest of the app
/// session (real, session-local persistence; still lost on a full app
/// restart without backend-linked accounts -- see the redesign plan's
/// Phase A/B capability table).
final profileFormControllerProvider = ChangeNotifierProvider<ProfileFormController>((ref) {
  return ProfileFormController();
});
