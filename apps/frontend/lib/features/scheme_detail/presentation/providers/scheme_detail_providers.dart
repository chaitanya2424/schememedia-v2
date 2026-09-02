import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../data/scheme_detail_api.dart';
import '../../data/scheme_detail_repository.dart';
import '../../domain/scheme_detail.dart';

final schemeDetailApiProvider = Provider<SchemeDetailApi>(
  (ref) => SchemeDetailApi(ref.watch(apiClientProvider)),
);

final schemeDetailRepositoryProvider = Provider<SchemeDetailRepository>(
  (ref) => SchemeDetailRepository(ref.watch(schemeDetailApiProvider)),
);

/// Parameterized (family) provider keyed by identifier -- each distinct
/// scheme_id/slug gets its own cached fetch, auto-disposed when no screen
/// is watching it.
final schemeDetailProvider = FutureProvider.family<SchemeDetail, String>((ref, identifier) {
  return ref.watch(schemeDetailRepositoryProvider).getDetail(identifier);
});
