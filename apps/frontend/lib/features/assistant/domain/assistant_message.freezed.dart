// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AssistantTurn {

 String get reply; AssistantEvidence get evidence; List<String> get groundingWarnings;
/// Create a copy of AssistantTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantTurnCopyWith<AssistantTurn> get copyWith => _$AssistantTurnCopyWithImpl<AssistantTurn>(this as AssistantTurn, _$identity);

  /// Serializes this AssistantTurn to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantTurn&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&const DeepCollectionEquality().equals(other.groundingWarnings, groundingWarnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,evidence,const DeepCollectionEquality().hash(groundingWarnings));

@override
String toString() {
  return 'AssistantTurn(reply: $reply, evidence: $evidence, groundingWarnings: $groundingWarnings)';
}


}

/// @nodoc
abstract mixin class $AssistantTurnCopyWith<$Res>  {
  factory $AssistantTurnCopyWith(AssistantTurn value, $Res Function(AssistantTurn) _then) = _$AssistantTurnCopyWithImpl;
@useResult
$Res call({
 String reply, AssistantEvidence evidence, List<String> groundingWarnings
});


$AssistantEvidenceCopyWith<$Res> get evidence;

}
/// @nodoc
class _$AssistantTurnCopyWithImpl<$Res>
    implements $AssistantTurnCopyWith<$Res> {
  _$AssistantTurnCopyWithImpl(this._self, this._then);

  final AssistantTurn _self;
  final $Res Function(AssistantTurn) _then;

/// Create a copy of AssistantTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reply = null,Object? evidence = null,Object? groundingWarnings = null,}) {
  return _then(_self.copyWith(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as AssistantEvidence,groundingWarnings: null == groundingWarnings ? _self.groundingWarnings : groundingWarnings // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}
/// Create a copy of AssistantTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantEvidenceCopyWith<$Res> get evidence {
  
  return $AssistantEvidenceCopyWith<$Res>(_self.evidence, (value) {
    return _then(_self.copyWith(evidence: value));
  });
}
}


/// Adds pattern-matching-related methods to [AssistantTurn].
extension AssistantTurnPatterns on AssistantTurn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantTurn value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantTurn() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantTurn value)  $default,){
final _that = this;
switch (_that) {
case _AssistantTurn():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantTurn value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantTurn() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reply,  AssistantEvidence evidence,  List<String> groundingWarnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantTurn() when $default != null:
return $default(_that.reply,_that.evidence,_that.groundingWarnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reply,  AssistantEvidence evidence,  List<String> groundingWarnings)  $default,) {final _that = this;
switch (_that) {
case _AssistantTurn():
return $default(_that.reply,_that.evidence,_that.groundingWarnings);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reply,  AssistantEvidence evidence,  List<String> groundingWarnings)?  $default,) {final _that = this;
switch (_that) {
case _AssistantTurn() when $default != null:
return $default(_that.reply,_that.evidence,_that.groundingWarnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantTurn implements AssistantTurn {
  const _AssistantTurn({required this.reply, required this.evidence, required final  List<String> groundingWarnings}): _groundingWarnings = groundingWarnings;
  factory _AssistantTurn.fromJson(Map<String, dynamic> json) => _$AssistantTurnFromJson(json);

@override final  String reply;
@override final  AssistantEvidence evidence;
 final  List<String> _groundingWarnings;
@override List<String> get groundingWarnings {
  if (_groundingWarnings is EqualUnmodifiableListView) return _groundingWarnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groundingWarnings);
}


/// Create a copy of AssistantTurn
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantTurnCopyWith<_AssistantTurn> get copyWith => __$AssistantTurnCopyWithImpl<_AssistantTurn>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantTurnToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantTurn&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.evidence, evidence) || other.evidence == evidence)&&const DeepCollectionEquality().equals(other._groundingWarnings, _groundingWarnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,evidence,const DeepCollectionEquality().hash(_groundingWarnings));

@override
String toString() {
  return 'AssistantTurn(reply: $reply, evidence: $evidence, groundingWarnings: $groundingWarnings)';
}


}

/// @nodoc
abstract mixin class _$AssistantTurnCopyWith<$Res> implements $AssistantTurnCopyWith<$Res> {
  factory _$AssistantTurnCopyWith(_AssistantTurn value, $Res Function(_AssistantTurn) _then) = __$AssistantTurnCopyWithImpl;
@override @useResult
$Res call({
 String reply, AssistantEvidence evidence, List<String> groundingWarnings
});


@override $AssistantEvidenceCopyWith<$Res> get evidence;

}
/// @nodoc
class __$AssistantTurnCopyWithImpl<$Res>
    implements _$AssistantTurnCopyWith<$Res> {
  __$AssistantTurnCopyWithImpl(this._self, this._then);

  final _AssistantTurn _self;
  final $Res Function(_AssistantTurn) _then;

/// Create a copy of AssistantTurn
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reply = null,Object? evidence = null,Object? groundingWarnings = null,}) {
  return _then(_AssistantTurn(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,evidence: null == evidence ? _self.evidence : evidence // ignore: cast_nullable_to_non_nullable
as AssistantEvidence,groundingWarnings: null == groundingWarnings ? _self._groundingWarnings : groundingWarnings // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

/// Create a copy of AssistantTurn
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantEvidenceCopyWith<$Res> get evidence {
  
  return $AssistantEvidenceCopyWith<$Res>(_self.evidence, (value) {
    return _then(_self.copyWith(evidence: value));
  });
}
}

/// @nodoc
mixin _$ChatEntry {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEntry);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ChatEntry()';
}


}

/// @nodoc
class $ChatEntryCopyWith<$Res>  {
$ChatEntryCopyWith(ChatEntry _, $Res Function(ChatEntry) __);
}


/// Adds pattern-matching-related methods to [ChatEntry].
extension ChatEntryPatterns on ChatEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ChatEntryUser value)?  user,TResult Function( ChatEntryAssistant value)?  assistant,TResult Function( ChatEntryError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ChatEntryUser() when user != null:
return user(_that);case ChatEntryAssistant() when assistant != null:
return assistant(_that);case ChatEntryError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ChatEntryUser value)  user,required TResult Function( ChatEntryAssistant value)  assistant,required TResult Function( ChatEntryError value)  error,}){
final _that = this;
switch (_that) {
case ChatEntryUser():
return user(_that);case ChatEntryAssistant():
return assistant(_that);case ChatEntryError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ChatEntryUser value)?  user,TResult? Function( ChatEntryAssistant value)?  assistant,TResult? Function( ChatEntryError value)?  error,}){
final _that = this;
switch (_that) {
case ChatEntryUser() when user != null:
return user(_that);case ChatEntryAssistant() when assistant != null:
return assistant(_that);case ChatEntryError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String message)?  user,TResult Function( AssistantTurn turn)?  assistant,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ChatEntryUser() when user != null:
return user(_that.message);case ChatEntryAssistant() when assistant != null:
return assistant(_that.turn);case ChatEntryError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String message)  user,required TResult Function( AssistantTurn turn)  assistant,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ChatEntryUser():
return user(_that.message);case ChatEntryAssistant():
return assistant(_that.turn);case ChatEntryError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String message)?  user,TResult? Function( AssistantTurn turn)?  assistant,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ChatEntryUser() when user != null:
return user(_that.message);case ChatEntryAssistant() when assistant != null:
return assistant(_that.turn);case ChatEntryError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ChatEntryUser implements ChatEntry {
  const ChatEntryUser(this.message);
  

 final  String message;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatEntryUserCopyWith<ChatEntryUser> get copyWith => _$ChatEntryUserCopyWithImpl<ChatEntryUser>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEntryUser&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ChatEntry.user(message: $message)';
}


}

/// @nodoc
abstract mixin class $ChatEntryUserCopyWith<$Res> implements $ChatEntryCopyWith<$Res> {
  factory $ChatEntryUserCopyWith(ChatEntryUser value, $Res Function(ChatEntryUser) _then) = _$ChatEntryUserCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ChatEntryUserCopyWithImpl<$Res>
    implements $ChatEntryUserCopyWith<$Res> {
  _$ChatEntryUserCopyWithImpl(this._self, this._then);

  final ChatEntryUser _self;
  final $Res Function(ChatEntryUser) _then;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ChatEntryUser(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ChatEntryAssistant implements ChatEntry {
  const ChatEntryAssistant(this.turn);
  

 final  AssistantTurn turn;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatEntryAssistantCopyWith<ChatEntryAssistant> get copyWith => _$ChatEntryAssistantCopyWithImpl<ChatEntryAssistant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEntryAssistant&&(identical(other.turn, turn) || other.turn == turn));
}


@override
int get hashCode => Object.hash(runtimeType,turn);

@override
String toString() {
  return 'ChatEntry.assistant(turn: $turn)';
}


}

/// @nodoc
abstract mixin class $ChatEntryAssistantCopyWith<$Res> implements $ChatEntryCopyWith<$Res> {
  factory $ChatEntryAssistantCopyWith(ChatEntryAssistant value, $Res Function(ChatEntryAssistant) _then) = _$ChatEntryAssistantCopyWithImpl;
@useResult
$Res call({
 AssistantTurn turn
});


$AssistantTurnCopyWith<$Res> get turn;

}
/// @nodoc
class _$ChatEntryAssistantCopyWithImpl<$Res>
    implements $ChatEntryAssistantCopyWith<$Res> {
  _$ChatEntryAssistantCopyWithImpl(this._self, this._then);

  final ChatEntryAssistant _self;
  final $Res Function(ChatEntryAssistant) _then;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? turn = null,}) {
  return _then(ChatEntryAssistant(
null == turn ? _self.turn : turn // ignore: cast_nullable_to_non_nullable
as AssistantTurn,
  ));
}

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AssistantTurnCopyWith<$Res> get turn {
  
  return $AssistantTurnCopyWith<$Res>(_self.turn, (value) {
    return _then(_self.copyWith(turn: value));
  });
}
}

/// @nodoc


class ChatEntryError implements ChatEntry {
  const ChatEntryError(this.message);
  

 final  String message;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatEntryErrorCopyWith<ChatEntryError> get copyWith => _$ChatEntryErrorCopyWithImpl<ChatEntryError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatEntryError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ChatEntry.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ChatEntryErrorCopyWith<$Res> implements $ChatEntryCopyWith<$Res> {
  factory $ChatEntryErrorCopyWith(ChatEntryError value, $Res Function(ChatEntryError) _then) = _$ChatEntryErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ChatEntryErrorCopyWithImpl<$Res>
    implements $ChatEntryErrorCopyWith<$Res> {
  _$ChatEntryErrorCopyWithImpl(this._self, this._then);

  final ChatEntryError _self;
  final $Res Function(ChatEntryError) _then;

/// Create a copy of ChatEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ChatEntryError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
