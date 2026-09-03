import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/providers.dart';
import '../../data/comments_api.dart';
import '../../data/comments_repository.dart';
import '../../domain/comment.dart';

final commentsApiProvider = Provider<CommentsApi>(
  (ref) => CommentsApi(ref.watch(apiClientProvider)),
);

final commentsRepositoryProvider = Provider<CommentsRepository>(
  (ref) => CommentsRepository(ref.watch(commentsApiProvider)),
);

/// Parameterized (family) provider keyed by scheme_id, same shape as
/// [schemeDetailProvider] -- see core/network/providers.dart's dioProvider
/// comment on why a family, not a single shared list.
class CommentsController extends FamilyAsyncNotifier<List<SchemeComment>, String> {
  @override
  Future<List<SchemeComment>> build(String schemeId) {
    return ref.watch(commentsRepositoryProvider).list(schemeId);
  }

  /// Posts, then re-reads the real list from the server rather than
  /// splicing the new comment in locally -- the server response is the
  /// source of truth for id/created_at/viewer_is_author, and comments are
  /// infrequent enough that a second round trip isn't worth optimistic
  /// state for.
  Future<void> post(String content) async {
    final repo = ref.read(commentsRepositoryProvider);
    await repo.create(arg, content);
    state = await AsyncValue.guard(() => repo.list(arg));
  }

  Future<void> delete(String commentId) async {
    final repo = ref.read(commentsRepositoryProvider);
    await repo.delete(arg, commentId);
    state = await AsyncValue.guard(() => repo.list(arg));
  }
}

final commentsProvider =
    AsyncNotifierProvider.family<CommentsController, List<SchemeComment>, String>(
      CommentsController.new,
    );
