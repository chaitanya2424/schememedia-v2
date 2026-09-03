// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SchemeComment {

 String get id; String get content; String get createdAt; bool get edited;// null when the author's account was later deleted -- the comment
// survives, the byline just can't be attributed (see the backend
// model's own docstring on User.deleted_at).
 String? get authorName; bool get viewerIsAuthor;
/// Create a copy of SchemeComment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchemeCommentCopyWith<SchemeComment> get copyWith => _$SchemeCommentCopyWithImpl<SchemeComment>(this as SchemeComment, _$identity);

  /// Serializes this SchemeComment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchemeComment&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.edited, edited) || other.edited == edited)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.viewerIsAuthor, viewerIsAuthor) || other.viewerIsAuthor == viewerIsAuthor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,createdAt,edited,authorName,viewerIsAuthor);

@override
String toString() {
  return 'SchemeComment(id: $id, content: $content, createdAt: $createdAt, edited: $edited, authorName: $authorName, viewerIsAuthor: $viewerIsAuthor)';
}


}

/// @nodoc
abstract mixin class $SchemeCommentCopyWith<$Res>  {
  factory $SchemeCommentCopyWith(SchemeComment value, $Res Function(SchemeComment) _then) = _$SchemeCommentCopyWithImpl;
@useResult
$Res call({
 String id, String content, String createdAt, bool edited, String? authorName, bool viewerIsAuthor
});




}
/// @nodoc
class _$SchemeCommentCopyWithImpl<$Res>
    implements $SchemeCommentCopyWith<$Res> {
  _$SchemeCommentCopyWithImpl(this._self, this._then);

  final SchemeComment _self;
  final $Res Function(SchemeComment) _then;

/// Create a copy of SchemeComment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? content = null,Object? createdAt = null,Object? edited = null,Object? authorName = freezed,Object? viewerIsAuthor = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,viewerIsAuthor: null == viewerIsAuthor ? _self.viewerIsAuthor : viewerIsAuthor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SchemeComment].
extension SchemeCommentPatterns on SchemeComment {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchemeComment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchemeComment() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchemeComment value)  $default,){
final _that = this;
switch (_that) {
case _SchemeComment():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchemeComment value)?  $default,){
final _that = this;
switch (_that) {
case _SchemeComment() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String content,  String createdAt,  bool edited,  String? authorName,  bool viewerIsAuthor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchemeComment() when $default != null:
return $default(_that.id,_that.content,_that.createdAt,_that.edited,_that.authorName,_that.viewerIsAuthor);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String content,  String createdAt,  bool edited,  String? authorName,  bool viewerIsAuthor)  $default,) {final _that = this;
switch (_that) {
case _SchemeComment():
return $default(_that.id,_that.content,_that.createdAt,_that.edited,_that.authorName,_that.viewerIsAuthor);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String content,  String createdAt,  bool edited,  String? authorName,  bool viewerIsAuthor)?  $default,) {final _that = this;
switch (_that) {
case _SchemeComment() when $default != null:
return $default(_that.id,_that.content,_that.createdAt,_that.edited,_that.authorName,_that.viewerIsAuthor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SchemeComment implements SchemeComment {
  const _SchemeComment({required this.id, required this.content, required this.createdAt, required this.edited, this.authorName, required this.viewerIsAuthor});
  factory _SchemeComment.fromJson(Map<String, dynamic> json) => _$SchemeCommentFromJson(json);

@override final  String id;
@override final  String content;
@override final  String createdAt;
@override final  bool edited;
// null when the author's account was later deleted -- the comment
// survives, the byline just can't be attributed (see the backend
// model's own docstring on User.deleted_at).
@override final  String? authorName;
@override final  bool viewerIsAuthor;

/// Create a copy of SchemeComment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchemeCommentCopyWith<_SchemeComment> get copyWith => __$SchemeCommentCopyWithImpl<_SchemeComment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SchemeCommentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchemeComment&&(identical(other.id, id) || other.id == id)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.edited, edited) || other.edited == edited)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.viewerIsAuthor, viewerIsAuthor) || other.viewerIsAuthor == viewerIsAuthor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,content,createdAt,edited,authorName,viewerIsAuthor);

@override
String toString() {
  return 'SchemeComment(id: $id, content: $content, createdAt: $createdAt, edited: $edited, authorName: $authorName, viewerIsAuthor: $viewerIsAuthor)';
}


}

/// @nodoc
abstract mixin class _$SchemeCommentCopyWith<$Res> implements $SchemeCommentCopyWith<$Res> {
  factory _$SchemeCommentCopyWith(_SchemeComment value, $Res Function(_SchemeComment) _then) = __$SchemeCommentCopyWithImpl;
@override @useResult
$Res call({
 String id, String content, String createdAt, bool edited, String? authorName, bool viewerIsAuthor
});




}
/// @nodoc
class __$SchemeCommentCopyWithImpl<$Res>
    implements _$SchemeCommentCopyWith<$Res> {
  __$SchemeCommentCopyWithImpl(this._self, this._then);

  final _SchemeComment _self;
  final $Res Function(_SchemeComment) _then;

/// Create a copy of SchemeComment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? content = null,Object? createdAt = null,Object? edited = null,Object? authorName = freezed,Object? viewerIsAuthor = null,}) {
  return _then(_SchemeComment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,edited: null == edited ? _self.edited : edited // ignore: cast_nullable_to_non_nullable
as bool,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,viewerIsAuthor: null == viewerIsAuthor ? _self.viewerIsAuthor : viewerIsAuthor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
