// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'error_envelope_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ErrorDetailDto {

 String get code; String get message; String? get requestId; Map<String, dynamic>? get details;
/// Create a copy of ErrorDetailDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorDetailDtoCopyWith<ErrorDetailDto> get copyWith => _$ErrorDetailDtoCopyWithImpl<ErrorDetailDto>(this as ErrorDetailDto, _$identity);

  /// Serializes this ErrorDetailDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorDetailDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&const DeepCollectionEquality().equals(other.details, details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,requestId,const DeepCollectionEquality().hash(details));

@override
String toString() {
  return 'ErrorDetailDto(code: $code, message: $message, requestId: $requestId, details: $details)';
}


}

/// @nodoc
abstract mixin class $ErrorDetailDtoCopyWith<$Res>  {
  factory $ErrorDetailDtoCopyWith(ErrorDetailDto value, $Res Function(ErrorDetailDto) _then) = _$ErrorDetailDtoCopyWithImpl;
@useResult
$Res call({
 String code, String message, String? requestId, Map<String, dynamic>? details
});




}
/// @nodoc
class _$ErrorDetailDtoCopyWithImpl<$Res>
    implements $ErrorDetailDtoCopyWith<$Res> {
  _$ErrorDetailDtoCopyWithImpl(this._self, this._then);

  final ErrorDetailDto _self;
  final $Res Function(ErrorDetailDto) _then;

/// Create a copy of ErrorDetailDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,Object? requestId = freezed,Object? details = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self.details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ErrorDetailDto].
extension ErrorDetailDtoPatterns on ErrorDetailDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorDetailDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorDetailDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorDetailDto value)  $default,){
final _that = this;
switch (_that) {
case _ErrorDetailDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorDetailDto value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorDetailDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message,  String? requestId,  Map<String, dynamic>? details)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorDetailDto() when $default != null:
return $default(_that.code,_that.message,_that.requestId,_that.details);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message,  String? requestId,  Map<String, dynamic>? details)  $default,) {final _that = this;
switch (_that) {
case _ErrorDetailDto():
return $default(_that.code,_that.message,_that.requestId,_that.details);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message,  String? requestId,  Map<String, dynamic>? details)?  $default,) {final _that = this;
switch (_that) {
case _ErrorDetailDto() when $default != null:
return $default(_that.code,_that.message,_that.requestId,_that.details);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorDetailDto implements ErrorDetailDto {
  const _ErrorDetailDto({required this.code, required this.message, this.requestId, final  Map<String, dynamic>? details}): _details = details;
  factory _ErrorDetailDto.fromJson(Map<String, dynamic> json) => _$ErrorDetailDtoFromJson(json);

@override final  String code;
@override final  String message;
@override final  String? requestId;
 final  Map<String, dynamic>? _details;
@override Map<String, dynamic>? get details {
  final value = _details;
  if (value == null) return null;
  if (_details is EqualUnmodifiableMapView) return _details;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ErrorDetailDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorDetailDtoCopyWith<_ErrorDetailDto> get copyWith => __$ErrorDetailDtoCopyWithImpl<_ErrorDetailDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorDetailDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorDetailDto&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&const DeepCollectionEquality().equals(other._details, _details));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message,requestId,const DeepCollectionEquality().hash(_details));

@override
String toString() {
  return 'ErrorDetailDto(code: $code, message: $message, requestId: $requestId, details: $details)';
}


}

/// @nodoc
abstract mixin class _$ErrorDetailDtoCopyWith<$Res> implements $ErrorDetailDtoCopyWith<$Res> {
  factory _$ErrorDetailDtoCopyWith(_ErrorDetailDto value, $Res Function(_ErrorDetailDto) _then) = __$ErrorDetailDtoCopyWithImpl;
@override @useResult
$Res call({
 String code, String message, String? requestId, Map<String, dynamic>? details
});




}
/// @nodoc
class __$ErrorDetailDtoCopyWithImpl<$Res>
    implements _$ErrorDetailDtoCopyWith<$Res> {
  __$ErrorDetailDtoCopyWithImpl(this._self, this._then);

  final _ErrorDetailDto _self;
  final $Res Function(_ErrorDetailDto) _then;

/// Create a copy of ErrorDetailDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? requestId = freezed,Object? details = freezed,}) {
  return _then(_ErrorDetailDto(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,details: freezed == details ? _self._details : details // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,
  ));
}


}


/// @nodoc
mixin _$ErrorEnvelopeDto {

 ErrorDetailDto get error;
/// Create a copy of ErrorEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorEnvelopeDtoCopyWith<ErrorEnvelopeDto> get copyWith => _$ErrorEnvelopeDtoCopyWithImpl<ErrorEnvelopeDto>(this as ErrorEnvelopeDto, _$identity);

  /// Serializes this ErrorEnvelopeDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorEnvelopeDto&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'ErrorEnvelopeDto(error: $error)';
}


}

/// @nodoc
abstract mixin class $ErrorEnvelopeDtoCopyWith<$Res>  {
  factory $ErrorEnvelopeDtoCopyWith(ErrorEnvelopeDto value, $Res Function(ErrorEnvelopeDto) _then) = _$ErrorEnvelopeDtoCopyWithImpl;
@useResult
$Res call({
 ErrorDetailDto error
});


$ErrorDetailDtoCopyWith<$Res> get error;

}
/// @nodoc
class _$ErrorEnvelopeDtoCopyWithImpl<$Res>
    implements $ErrorEnvelopeDtoCopyWith<$Res> {
  _$ErrorEnvelopeDtoCopyWithImpl(this._self, this._then);

  final ErrorEnvelopeDto _self;
  final $Res Function(ErrorEnvelopeDto) _then;

/// Create a copy of ErrorEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? error = null,}) {
  return _then(_self.copyWith(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ErrorDetailDto,
  ));
}
/// Create a copy of ErrorEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorDetailDtoCopyWith<$Res> get error {
  
  return $ErrorDetailDtoCopyWith<$Res>(_self.error, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}


/// Adds pattern-matching-related methods to [ErrorEnvelopeDto].
extension ErrorEnvelopeDtoPatterns on ErrorEnvelopeDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ErrorEnvelopeDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ErrorEnvelopeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ErrorEnvelopeDto value)  $default,){
final _that = this;
switch (_that) {
case _ErrorEnvelopeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ErrorEnvelopeDto value)?  $default,){
final _that = this;
switch (_that) {
case _ErrorEnvelopeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ErrorDetailDto error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ErrorEnvelopeDto() when $default != null:
return $default(_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ErrorDetailDto error)  $default,) {final _that = this;
switch (_that) {
case _ErrorEnvelopeDto():
return $default(_that.error);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ErrorDetailDto error)?  $default,) {final _that = this;
switch (_that) {
case _ErrorEnvelopeDto() when $default != null:
return $default(_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ErrorEnvelopeDto implements ErrorEnvelopeDto {
  const _ErrorEnvelopeDto({required this.error});
  factory _ErrorEnvelopeDto.fromJson(Map<String, dynamic> json) => _$ErrorEnvelopeDtoFromJson(json);

@override final  ErrorDetailDto error;

/// Create a copy of ErrorEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ErrorEnvelopeDtoCopyWith<_ErrorEnvelopeDto> get copyWith => __$ErrorEnvelopeDtoCopyWithImpl<_ErrorEnvelopeDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ErrorEnvelopeDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ErrorEnvelopeDto&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,error);

@override
String toString() {
  return 'ErrorEnvelopeDto(error: $error)';
}


}

/// @nodoc
abstract mixin class _$ErrorEnvelopeDtoCopyWith<$Res> implements $ErrorEnvelopeDtoCopyWith<$Res> {
  factory _$ErrorEnvelopeDtoCopyWith(_ErrorEnvelopeDto value, $Res Function(_ErrorEnvelopeDto) _then) = __$ErrorEnvelopeDtoCopyWithImpl;
@override @useResult
$Res call({
 ErrorDetailDto error
});


@override $ErrorDetailDtoCopyWith<$Res> get error;

}
/// @nodoc
class __$ErrorEnvelopeDtoCopyWithImpl<$Res>
    implements _$ErrorEnvelopeDtoCopyWith<$Res> {
  __$ErrorEnvelopeDtoCopyWithImpl(this._self, this._then);

  final _ErrorEnvelopeDto _self;
  final $Res Function(_ErrorEnvelopeDto) _then;

/// Create a copy of ErrorEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? error = null,}) {
  return _then(_ErrorEnvelopeDto(
error: null == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as ErrorDetailDto,
  ));
}

/// Create a copy of ErrorEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ErrorDetailDtoCopyWith<$Res> get error {
  
  return $ErrorDetailDtoCopyWith<$Res>(_self.error, (value) {
    return _then(_self.copyWith(error: value));
  });
}
}

// dart format on
