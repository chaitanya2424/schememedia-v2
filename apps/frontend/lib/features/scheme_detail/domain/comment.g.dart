// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SchemeComment _$SchemeCommentFromJson(Map<String, dynamic> json) =>
    _SchemeComment(
      id: json['id'] as String,
      content: json['content'] as String,
      createdAt: json['created_at'] as String,
      edited: json['edited'] as bool,
      authorName: json['author_name'] as String?,
      viewerIsAuthor: json['viewer_is_author'] as bool,
    );

Map<String, dynamic> _$SchemeCommentToJson(_SchemeComment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'created_at': instance.createdAt,
      'edited': instance.edited,
      'author_name': instance.authorName,
      'viewer_is_author': instance.viewerIsAuthor,
    };
