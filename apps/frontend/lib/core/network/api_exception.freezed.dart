// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_exception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ApiException {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiException()';
}


}

/// @nodoc
class $ApiExceptionCopyWith<$Res>  {
$ApiExceptionCopyWith(ApiException _, $Res Function(ApiException) __);
}


/// Adds pattern-matching-related methods to [ApiException].
extension ApiExceptionPatterns on ApiException {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ApiNetworkException value)?  network,TResult Function( ApiValidationException value)?  validation,TResult Function( ApiNotFoundException value)?  notFound,TResult Function( ApiUnavailableException value)?  unavailable,TResult Function( ApiServerException value)?  server,TResult Function( ApiUnknownException value)?  unknown,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ApiNetworkException() when network != null:
return network(_that);case ApiValidationException() when validation != null:
return validation(_that);case ApiNotFoundException() when notFound != null:
return notFound(_that);case ApiUnavailableException() when unavailable != null:
return unavailable(_that);case ApiServerException() when server != null:
return server(_that);case ApiUnknownException() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ApiNetworkException value)  network,required TResult Function( ApiValidationException value)  validation,required TResult Function( ApiNotFoundException value)  notFound,required TResult Function( ApiUnavailableException value)  unavailable,required TResult Function( ApiServerException value)  server,required TResult Function( ApiUnknownException value)  unknown,}){
final _that = this;
switch (_that) {
case ApiNetworkException():
return network(_that);case ApiValidationException():
return validation(_that);case ApiNotFoundException():
return notFound(_that);case ApiUnavailableException():
return unavailable(_that);case ApiServerException():
return server(_that);case ApiUnknownException():
return unknown(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ApiNetworkException value)?  network,TResult? Function( ApiValidationException value)?  validation,TResult? Function( ApiNotFoundException value)?  notFound,TResult? Function( ApiUnavailableException value)?  unavailable,TResult? Function( ApiServerException value)?  server,TResult? Function( ApiUnknownException value)?  unknown,}){
final _that = this;
switch (_that) {
case ApiNetworkException() when network != null:
return network(_that);case ApiValidationException() when validation != null:
return validation(_that);case ApiNotFoundException() when notFound != null:
return notFound(_that);case ApiUnavailableException() when unavailable != null:
return unavailable(_that);case ApiServerException() when server != null:
return server(_that);case ApiUnknownException() when unknown != null:
return unknown(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  network,TResult Function( Map<String, dynamic> fields)?  validation,TResult Function( String message)?  notFound,TResult Function( String message)?  unavailable,TResult Function( String code,  String message,  String? requestId)?  server,TResult Function( String message)?  unknown,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ApiNetworkException() when network != null:
return network();case ApiValidationException() when validation != null:
return validation(_that.fields);case ApiNotFoundException() when notFound != null:
return notFound(_that.message);case ApiUnavailableException() when unavailable != null:
return unavailable(_that.message);case ApiServerException() when server != null:
return server(_that.code,_that.message,_that.requestId);case ApiUnknownException() when unknown != null:
return unknown(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  network,required TResult Function( Map<String, dynamic> fields)  validation,required TResult Function( String message)  notFound,required TResult Function( String message)  unavailable,required TResult Function( String code,  String message,  String? requestId)  server,required TResult Function( String message)  unknown,}) {final _that = this;
switch (_that) {
case ApiNetworkException():
return network();case ApiValidationException():
return validation(_that.fields);case ApiNotFoundException():
return notFound(_that.message);case ApiUnavailableException():
return unavailable(_that.message);case ApiServerException():
return server(_that.code,_that.message,_that.requestId);case ApiUnknownException():
return unknown(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  network,TResult? Function( Map<String, dynamic> fields)?  validation,TResult? Function( String message)?  notFound,TResult? Function( String message)?  unavailable,TResult? Function( String code,  String message,  String? requestId)?  server,TResult? Function( String message)?  unknown,}) {final _that = this;
switch (_that) {
case ApiNetworkException() when network != null:
return network();case ApiValidationException() when validation != null:
return validation(_that.fields);case ApiNotFoundException() when notFound != null:
return notFound(_that.message);case ApiUnavailableException() when unavailable != null:
return unavailable(_that.message);case ApiServerException() when server != null:
return server(_that.code,_that.message,_that.requestId);case ApiUnknownException() when unknown != null:
return unknown(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ApiNetworkException implements ApiException {
  const ApiNetworkException();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiNetworkException);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ApiException.network()';
}


}




/// @nodoc


class ApiValidationException implements ApiException {
  const ApiValidationException(final  Map<String, dynamic> fields): _fields = fields;
  

 final  Map<String, dynamic> _fields;
 Map<String, dynamic> get fields {
  if (_fields is EqualUnmodifiableMapView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fields);
}


/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiValidationExceptionCopyWith<ApiValidationException> get copyWith => _$ApiValidationExceptionCopyWithImpl<ApiValidationException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiValidationException&&const DeepCollectionEquality().equals(other._fields, _fields));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'ApiException.validation(fields: $fields)';
}


}

/// @nodoc
abstract mixin class $ApiValidationExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ApiValidationExceptionCopyWith(ApiValidationException value, $Res Function(ApiValidationException) _then) = _$ApiValidationExceptionCopyWithImpl;
@useResult
$Res call({
 Map<String, dynamic> fields
});




}
/// @nodoc
class _$ApiValidationExceptionCopyWithImpl<$Res>
    implements $ApiValidationExceptionCopyWith<$Res> {
  _$ApiValidationExceptionCopyWithImpl(this._self, this._then);

  final ApiValidationException _self;
  final $Res Function(ApiValidationException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? fields = null,}) {
  return _then(ApiValidationException(
null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,
  ));
}


}

/// @nodoc


class ApiNotFoundException implements ApiException {
  const ApiNotFoundException(this.message);
  

 final  String message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiNotFoundExceptionCopyWith<ApiNotFoundException> get copyWith => _$ApiNotFoundExceptionCopyWithImpl<ApiNotFoundException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiNotFoundException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.notFound(message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiNotFoundExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ApiNotFoundExceptionCopyWith(ApiNotFoundException value, $Res Function(ApiNotFoundException) _then) = _$ApiNotFoundExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ApiNotFoundExceptionCopyWithImpl<$Res>
    implements $ApiNotFoundExceptionCopyWith<$Res> {
  _$ApiNotFoundExceptionCopyWithImpl(this._self, this._then);

  final ApiNotFoundException _self;
  final $Res Function(ApiNotFoundException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ApiNotFoundException(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiUnavailableException implements ApiException {
  const ApiUnavailableException(this.message);
  

 final  String message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiUnavailableExceptionCopyWith<ApiUnavailableException> get copyWith => _$ApiUnavailableExceptionCopyWithImpl<ApiUnavailableException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiUnavailableException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.unavailable(message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiUnavailableExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ApiUnavailableExceptionCopyWith(ApiUnavailableException value, $Res Function(ApiUnavailableException) _then) = _$ApiUnavailableExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ApiUnavailableExceptionCopyWithImpl<$Res>
    implements $ApiUnavailableExceptionCopyWith<$Res> {
  _$ApiUnavailableExceptionCopyWithImpl(this._self, this._then);

  final ApiUnavailableException _self;
  final $Res Function(ApiUnavailableException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ApiUnavailableException(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class ApiServerException implements ApiException {
  const ApiServerException({required this.code, required this.message, this.requestId});
  

 final  String code;
 final  String message;
 final  String? requestId;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiServerExceptionCopyWith<ApiServerException> get copyWith => _$ApiServerExceptionCopyWithImpl<ApiServerException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiServerException&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message)&&(identical(other.requestId, requestId) || other.requestId == requestId));
}


@override
int get hashCode => Object.hash(runtimeType,code,message,requestId);

@override
String toString() {
  return 'ApiException.server(code: $code, message: $message, requestId: $requestId)';
}


}

/// @nodoc
abstract mixin class $ApiServerExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ApiServerExceptionCopyWith(ApiServerException value, $Res Function(ApiServerException) _then) = _$ApiServerExceptionCopyWithImpl;
@useResult
$Res call({
 String code, String message, String? requestId
});




}
/// @nodoc
class _$ApiServerExceptionCopyWithImpl<$Res>
    implements $ApiServerExceptionCopyWith<$Res> {
  _$ApiServerExceptionCopyWithImpl(this._self, this._then);

  final ApiServerException _self;
  final $Res Function(ApiServerException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,Object? requestId = freezed,}) {
  return _then(ApiServerException(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,requestId: freezed == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class ApiUnknownException implements ApiException {
  const ApiUnknownException(this.message);
  

 final  String message;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiUnknownExceptionCopyWith<ApiUnknownException> get copyWith => _$ApiUnknownExceptionCopyWithImpl<ApiUnknownException>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiUnknownException&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ApiException.unknown(message: $message)';
}


}

/// @nodoc
abstract mixin class $ApiUnknownExceptionCopyWith<$Res> implements $ApiExceptionCopyWith<$Res> {
  factory $ApiUnknownExceptionCopyWith(ApiUnknownException value, $Res Function(ApiUnknownException) _then) = _$ApiUnknownExceptionCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ApiUnknownExceptionCopyWithImpl<$Res>
    implements $ApiUnknownExceptionCopyWith<$Res> {
  _$ApiUnknownExceptionCopyWithImpl(this._self, this._then);

  final ApiUnknownException _self;
  final $Res Function(ApiUnknownException) _then;

/// Create a copy of ApiException
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ApiUnknownException(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
