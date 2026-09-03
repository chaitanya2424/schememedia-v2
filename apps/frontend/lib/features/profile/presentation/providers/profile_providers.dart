import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/profile_api.dart';
import '../../data/profile_repository.dart';

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider)));

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(profileApiProvider)),
);

/// The signed-in user's persisted eligibility profile -- `{attributes:
/// {...}, answered_count, total_count}`, or `null` when signed out (there
/// is no account to have a profile; never attempts the call). Callers that
/// change the profile (the wizard's finish step, a future direct-edit
/// screen) should `ref.invalidate(myProfileProvider)` afterwards so Home/
/// Profile pick up the new completion count.
final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final signedIn = ref.watch(isSignedInProvider);
  if (!signedIn) return null;
  return ref.watch(profileRepositoryProvider).getProfile();
});
