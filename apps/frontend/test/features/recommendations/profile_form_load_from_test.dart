// ProfileFormController.loadFrom -- prefills the wizard from a signed-in
// user's persisted profile (GET /me/profile). See recommendations_wizard.
// dart's _maybePrefillFromPersistedProfile for the caller.

import 'package:flutter_test/flutter_test.dart';

import 'package:schememedia_app/features/recommendations/domain/eligibility_attribute.dart';
import 'package:schememedia_app/features/recommendations/presentation/widgets/profile_form_controller.dart';

void main() {
  test('loads answered boolean/numeric/text attributes', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);

    controller.loadFrom({'is_farmer': true, 'age': 34, 'state_code': 'KL'});

    expect(controller.valueOf(EligibilityAttribute.isFarmer), true);
    expect(controller.valueOf(EligibilityAttribute.age), 34.0);
    expect(controller.valueOf(EligibilityAttribute.stateCode), 'KL');
    expect(controller.totalAnswered, 3);
  });

  test('a real false is loaded, not treated as unanswered', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);

    controller.loadFrom({'is_taxpayer': false});

    expect(controller.valueOf(EligibilityAttribute.isTaxpayer), false);
    expect(controller.totalAnswered, 1);
  });

  test('null/absent keys stay unanswered', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);

    controller.loadFrom({'is_farmer': true, 'is_woman': null});

    expect(controller.valueOf(EligibilityAttribute.isFarmer), true);
    expect(controller.valueOf(EligibilityAttribute.isWoman), isNull);
    expect(controller.totalAnswered, 1);
  });

  test('an empty map leaves the controller empty', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);

    controller.loadFrom({});

    expect(controller.isEmpty, isTrue);
  });

  test('a value of the wrong type for its attribute is skipped', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);

    // is_farmer is boolean; a string for it must not be stored malformed.
    controller.loadFrom({'is_farmer': 'yes', 'age': 30});

    expect(controller.valueOf(EligibilityAttribute.isFarmer), isNull);
    expect(controller.valueOf(EligibilityAttribute.age), 30.0);
    expect(controller.totalAnswered, 1);
  });

  test('replaces, rather than merges with, any prior in-progress answers', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);
    controller.setBoolean(EligibilityAttribute.isStudent, true);

    controller.loadFrom({'is_farmer': true});

    expect(controller.valueOf(EligibilityAttribute.isStudent), isNull);
    expect(controller.valueOf(EligibilityAttribute.isFarmer), true);
    expect(controller.totalAnswered, 1);
  });

  test('an unrecognised key in the source map is ignored', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);

    controller.loadFrom({'totally_made_up_field': 'xyz', 'is_farmer': true});

    expect(controller.totalAnswered, 1);
    expect(controller.valueOf(EligibilityAttribute.isFarmer), true);
  });

  test('round-trips back through toProfileJson', () {
    final controller = ProfileFormController();
    addTearDown(controller.dispose);
    final original = {'is_farmer': true, 'age': 34.0, 'state_code': 'KL'};

    controller.loadFrom(original);

    expect(controller.toProfileJson(), original);
  });
}
