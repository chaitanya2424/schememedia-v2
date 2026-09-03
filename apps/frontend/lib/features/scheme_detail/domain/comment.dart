import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';
part 'comment.g.dart';

/// Mirrors `CommentOut` (api/v1/routers/comments.py). Top-level comments
/// only for this iteration -- see the backend repository's module
/// docstring on why nesting is additive later, not a redesign.
@freezed
sealed class SchemeComment with _$SchemeComment {
  const factory SchemeComment({
    required String id,
    required String content,
    required String createdAt,
    required bool edited,
    // null when the author's account was later deleted -- the comment
    // survives, the byline just can't be attributed (see the backend
    // model's own docstring on User.deleted_at).
    String? authorName,
    required bool viewerIsAuthor,
  }) = _SchemeComment;

  factory SchemeComment.fromJson(Map<String, dynamic> json) =>
      _$SchemeCommentFromJson(json);
}
