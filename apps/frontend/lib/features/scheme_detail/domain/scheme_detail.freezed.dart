// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheme_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Benefit {

 String? get stage; String get amountText; double? get amountNumeric; String get currency; bool get isTruncated;
/// Create a copy of Benefit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BenefitCopyWith<Benefit> get copyWith => _$BenefitCopyWithImpl<Benefit>(this as Benefit, _$identity);

  /// Serializes this Benefit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Benefit&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.amountText, amountText) || other.amountText == amountText)&&(identical(other.amountNumeric, amountNumeric) || other.amountNumeric == amountNumeric)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isTruncated, isTruncated) || other.isTruncated == isTruncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stage,amountText,amountNumeric,currency,isTruncated);

@override
String toString() {
  return 'Benefit(stage: $stage, amountText: $amountText, amountNumeric: $amountNumeric, currency: $currency, isTruncated: $isTruncated)';
}


}

/// @nodoc
abstract mixin class $BenefitCopyWith<$Res>  {
  factory $BenefitCopyWith(Benefit value, $Res Function(Benefit) _then) = _$BenefitCopyWithImpl;
@useResult
$Res call({
 String? stage, String amountText, double? amountNumeric, String currency, bool isTruncated
});




}
/// @nodoc
class _$BenefitCopyWithImpl<$Res>
    implements $BenefitCopyWith<$Res> {
  _$BenefitCopyWithImpl(this._self, this._then);

  final Benefit _self;
  final $Res Function(Benefit) _then;

/// Create a copy of Benefit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = freezed,Object? amountText = null,Object? amountNumeric = freezed,Object? currency = null,Object? isTruncated = null,}) {
  return _then(_self.copyWith(
stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,amountText: null == amountText ? _self.amountText : amountText // ignore: cast_nullable_to_non_nullable
as String,amountNumeric: freezed == amountNumeric ? _self.amountNumeric : amountNumeric // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isTruncated: null == isTruncated ? _self.isTruncated : isTruncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Benefit].
extension BenefitPatterns on Benefit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Benefit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Benefit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Benefit value)  $default,){
final _that = this;
switch (_that) {
case _Benefit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Benefit value)?  $default,){
final _that = this;
switch (_that) {
case _Benefit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? stage,  String amountText,  double? amountNumeric,  String currency,  bool isTruncated)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Benefit() when $default != null:
return $default(_that.stage,_that.amountText,_that.amountNumeric,_that.currency,_that.isTruncated);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? stage,  String amountText,  double? amountNumeric,  String currency,  bool isTruncated)  $default,) {final _that = this;
switch (_that) {
case _Benefit():
return $default(_that.stage,_that.amountText,_that.amountNumeric,_that.currency,_that.isTruncated);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? stage,  String amountText,  double? amountNumeric,  String currency,  bool isTruncated)?  $default,) {final _that = this;
switch (_that) {
case _Benefit() when $default != null:
return $default(_that.stage,_that.amountText,_that.amountNumeric,_that.currency,_that.isTruncated);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Benefit implements Benefit {
  const _Benefit({this.stage, required this.amountText, this.amountNumeric, required this.currency, required this.isTruncated});
  factory _Benefit.fromJson(Map<String, dynamic> json) => _$BenefitFromJson(json);

@override final  String? stage;
@override final  String amountText;
@override final  double? amountNumeric;
@override final  String currency;
@override final  bool isTruncated;

/// Create a copy of Benefit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BenefitCopyWith<_Benefit> get copyWith => __$BenefitCopyWithImpl<_Benefit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BenefitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Benefit&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.amountText, amountText) || other.amountText == amountText)&&(identical(other.amountNumeric, amountNumeric) || other.amountNumeric == amountNumeric)&&(identical(other.currency, currency) || other.currency == currency)&&(identical(other.isTruncated, isTruncated) || other.isTruncated == isTruncated));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stage,amountText,amountNumeric,currency,isTruncated);

@override
String toString() {
  return 'Benefit(stage: $stage, amountText: $amountText, amountNumeric: $amountNumeric, currency: $currency, isTruncated: $isTruncated)';
}


}

/// @nodoc
abstract mixin class _$BenefitCopyWith<$Res> implements $BenefitCopyWith<$Res> {
  factory _$BenefitCopyWith(_Benefit value, $Res Function(_Benefit) _then) = __$BenefitCopyWithImpl;
@override @useResult
$Res call({
 String? stage, String amountText, double? amountNumeric, String currency, bool isTruncated
});




}
/// @nodoc
class __$BenefitCopyWithImpl<$Res>
    implements _$BenefitCopyWith<$Res> {
  __$BenefitCopyWithImpl(this._self, this._then);

  final _Benefit _self;
  final $Res Function(_Benefit) _then;

/// Create a copy of Benefit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = freezed,Object? amountText = null,Object? amountNumeric = freezed,Object? currency = null,Object? isTruncated = null,}) {
  return _then(_Benefit(
stage: freezed == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String?,amountText: null == amountText ? _self.amountText : amountText // ignore: cast_nullable_to_non_nullable
as String,amountNumeric: freezed == amountNumeric ? _self.amountNumeric : amountNumeric // ignore: cast_nullable_to_non_nullable
as double?,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,isTruncated: null == isTruncated ? _self.isTruncated : isTruncated // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SchemeDocument {

 String get name; bool get isMandatory; bool get needsReview;
/// Create a copy of SchemeDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchemeDocumentCopyWith<SchemeDocument> get copyWith => _$SchemeDocumentCopyWithImpl<SchemeDocument>(this as SchemeDocument, _$identity);

  /// Serializes this SchemeDocument to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchemeDocument&&(identical(other.name, name) || other.name == name)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,isMandatory,needsReview);

@override
String toString() {
  return 'SchemeDocument(name: $name, isMandatory: $isMandatory, needsReview: $needsReview)';
}


}

/// @nodoc
abstract mixin class $SchemeDocumentCopyWith<$Res>  {
  factory $SchemeDocumentCopyWith(SchemeDocument value, $Res Function(SchemeDocument) _then) = _$SchemeDocumentCopyWithImpl;
@useResult
$Res call({
 String name, bool isMandatory, bool needsReview
});




}
/// @nodoc
class _$SchemeDocumentCopyWithImpl<$Res>
    implements $SchemeDocumentCopyWith<$Res> {
  _$SchemeDocumentCopyWithImpl(this._self, this._then);

  final SchemeDocument _self;
  final $Res Function(SchemeDocument) _then;

/// Create a copy of SchemeDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? isMandatory = null,Object? needsReview = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SchemeDocument].
extension SchemeDocumentPatterns on SchemeDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchemeDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchemeDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchemeDocument value)  $default,){
final _that = this;
switch (_that) {
case _SchemeDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchemeDocument value)?  $default,){
final _that = this;
switch (_that) {
case _SchemeDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  bool isMandatory,  bool needsReview)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchemeDocument() when $default != null:
return $default(_that.name,_that.isMandatory,_that.needsReview);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  bool isMandatory,  bool needsReview)  $default,) {final _that = this;
switch (_that) {
case _SchemeDocument():
return $default(_that.name,_that.isMandatory,_that.needsReview);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  bool isMandatory,  bool needsReview)?  $default,) {final _that = this;
switch (_that) {
case _SchemeDocument() when $default != null:
return $default(_that.name,_that.isMandatory,_that.needsReview);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SchemeDocument implements SchemeDocument {
  const _SchemeDocument({required this.name, required this.isMandatory, required this.needsReview});
  factory _SchemeDocument.fromJson(Map<String, dynamic> json) => _$SchemeDocumentFromJson(json);

@override final  String name;
@override final  bool isMandatory;
@override final  bool needsReview;

/// Create a copy of SchemeDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchemeDocumentCopyWith<_SchemeDocument> get copyWith => __$SchemeDocumentCopyWithImpl<_SchemeDocument>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SchemeDocumentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchemeDocument&&(identical(other.name, name) || other.name == name)&&(identical(other.isMandatory, isMandatory) || other.isMandatory == isMandatory)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,isMandatory,needsReview);

@override
String toString() {
  return 'SchemeDocument(name: $name, isMandatory: $isMandatory, needsReview: $needsReview)';
}


}

/// @nodoc
abstract mixin class _$SchemeDocumentCopyWith<$Res> implements $SchemeDocumentCopyWith<$Res> {
  factory _$SchemeDocumentCopyWith(_SchemeDocument value, $Res Function(_SchemeDocument) _then) = __$SchemeDocumentCopyWithImpl;
@override @useResult
$Res call({
 String name, bool isMandatory, bool needsReview
});




}
/// @nodoc
class __$SchemeDocumentCopyWithImpl<$Res>
    implements _$SchemeDocumentCopyWith<$Res> {
  __$SchemeDocumentCopyWithImpl(this._self, this._then);

  final _SchemeDocument _self;
  final $Res Function(_SchemeDocument) _then;

/// Create a copy of SchemeDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? isMandatory = null,Object? needsReview = null,}) {
  return _then(_SchemeDocument(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isMandatory: null == isMandatory ? _self.isMandatory : isMandatory // ignore: cast_nullable_to_non_nullable
as bool,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$SchemeDetail {

 String get schemeId; String get slug; String get name; String? get nameHi; String? get ministry; String? get category;@SchemeTypeConverter() SchemeType get schemeType;@JurisdictionConverter() Jurisdiction get jurisdiction; String? get stateCode; String? get descriptionShort; String? get descriptionLong; String? get officialUrl; String? get applicationDeadline;@VerificationStatusConverter() VerificationStatus get verificationStatus; bool get needsReview; String? get lastVerifiedAt; List<String> get tags; List<Benefit> get benefits; List<SchemeDocument> get documents; int get likeCount; int get saveCount; int get commentCount; double? get averageRating;
/// Create a copy of SchemeDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchemeDetailCopyWith<SchemeDetail> get copyWith => _$SchemeDetailCopyWithImpl<SchemeDetail>(this as SchemeDetail, _$identity);

  /// Serializes this SchemeDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchemeDetail&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameHi, nameHi) || other.nameHi == nameHi)&&(identical(other.ministry, ministry) || other.ministry == ministry)&&(identical(other.category, category) || other.category == category)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.descriptionShort, descriptionShort) || other.descriptionShort == descriptionShort)&&(identical(other.descriptionLong, descriptionLong) || other.descriptionLong == descriptionLong)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl)&&(identical(other.applicationDeadline, applicationDeadline) || other.applicationDeadline == applicationDeadline)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.lastVerifiedAt, lastVerifiedAt) || other.lastVerifiedAt == lastVerifiedAt)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.benefits, benefits)&&const DeepCollectionEquality().equals(other.documents, documents)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,schemeId,slug,name,nameHi,ministry,category,schemeType,jurisdiction,stateCode,descriptionShort,descriptionLong,officialUrl,applicationDeadline,verificationStatus,needsReview,lastVerifiedAt,const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(benefits),const DeepCollectionEquality().hash(documents),likeCount,saveCount,commentCount,averageRating]);

@override
String toString() {
  return 'SchemeDetail(schemeId: $schemeId, slug: $slug, name: $name, nameHi: $nameHi, ministry: $ministry, category: $category, schemeType: $schemeType, jurisdiction: $jurisdiction, stateCode: $stateCode, descriptionShort: $descriptionShort, descriptionLong: $descriptionLong, officialUrl: $officialUrl, applicationDeadline: $applicationDeadline, verificationStatus: $verificationStatus, needsReview: $needsReview, lastVerifiedAt: $lastVerifiedAt, tags: $tags, benefits: $benefits, documents: $documents, likeCount: $likeCount, saveCount: $saveCount, commentCount: $commentCount, averageRating: $averageRating)';
}


}

/// @nodoc
abstract mixin class $SchemeDetailCopyWith<$Res>  {
  factory $SchemeDetailCopyWith(SchemeDetail value, $Res Function(SchemeDetail) _then) = _$SchemeDetailCopyWithImpl;
@useResult
$Res call({
 String schemeId, String slug, String name, String? nameHi, String? ministry, String? category,@SchemeTypeConverter() SchemeType schemeType,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode, String? descriptionShort, String? descriptionLong, String? officialUrl, String? applicationDeadline,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? lastVerifiedAt, List<String> tags, List<Benefit> benefits, List<SchemeDocument> documents, int likeCount, int saveCount, int commentCount, double? averageRating
});




}
/// @nodoc
class _$SchemeDetailCopyWithImpl<$Res>
    implements $SchemeDetailCopyWith<$Res> {
  _$SchemeDetailCopyWithImpl(this._self, this._then);

  final SchemeDetail _self;
  final $Res Function(SchemeDetail) _then;

/// Create a copy of SchemeDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemeId = null,Object? slug = null,Object? name = null,Object? nameHi = freezed,Object? ministry = freezed,Object? category = freezed,Object? schemeType = null,Object? jurisdiction = null,Object? stateCode = freezed,Object? descriptionShort = freezed,Object? descriptionLong = freezed,Object? officialUrl = freezed,Object? applicationDeadline = freezed,Object? verificationStatus = null,Object? needsReview = null,Object? lastVerifiedAt = freezed,Object? tags = null,Object? benefits = null,Object? documents = null,Object? likeCount = null,Object? saveCount = null,Object? commentCount = null,Object? averageRating = freezed,}) {
  return _then(_self.copyWith(
schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameHi: freezed == nameHi ? _self.nameHi : nameHi // ignore: cast_nullable_to_non_nullable
as String?,ministry: freezed == ministry ? _self.ministry : ministry // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as SchemeType,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,descriptionShort: freezed == descriptionShort ? _self.descriptionShort : descriptionShort // ignore: cast_nullable_to_non_nullable
as String?,descriptionLong: freezed == descriptionLong ? _self.descriptionLong : descriptionLong // ignore: cast_nullable_to_non_nullable
as String?,officialUrl: freezed == officialUrl ? _self.officialUrl : officialUrl // ignore: cast_nullable_to_non_nullable
as String?,applicationDeadline: freezed == applicationDeadline ? _self.applicationDeadline : applicationDeadline // ignore: cast_nullable_to_non_nullable
as String?,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,lastVerifiedAt: freezed == lastVerifiedAt ? _self.lastVerifiedAt : lastVerifiedAt // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,benefits: null == benefits ? _self.benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<Benefit>,documents: null == documents ? _self.documents : documents // ignore: cast_nullable_to_non_nullable
as List<SchemeDocument>,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,averageRating: freezed == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [SchemeDetail].
extension SchemeDetailPatterns on SchemeDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchemeDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchemeDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchemeDetail value)  $default,){
final _that = this;
switch (_that) {
case _SchemeDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchemeDetail value)?  $default,){
final _that = this;
switch (_that) {
case _SchemeDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schemeId,  String slug,  String name,  String? nameHi,  String? ministry,  String? category, @SchemeTypeConverter()  SchemeType schemeType, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode,  String? descriptionShort,  String? descriptionLong,  String? officialUrl,  String? applicationDeadline, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? lastVerifiedAt,  List<String> tags,  List<Benefit> benefits,  List<SchemeDocument> documents,  int likeCount,  int saveCount,  int commentCount,  double? averageRating)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchemeDetail() when $default != null:
return $default(_that.schemeId,_that.slug,_that.name,_that.nameHi,_that.ministry,_that.category,_that.schemeType,_that.jurisdiction,_that.stateCode,_that.descriptionShort,_that.descriptionLong,_that.officialUrl,_that.applicationDeadline,_that.verificationStatus,_that.needsReview,_that.lastVerifiedAt,_that.tags,_that.benefits,_that.documents,_that.likeCount,_that.saveCount,_that.commentCount,_that.averageRating);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schemeId,  String slug,  String name,  String? nameHi,  String? ministry,  String? category, @SchemeTypeConverter()  SchemeType schemeType, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode,  String? descriptionShort,  String? descriptionLong,  String? officialUrl,  String? applicationDeadline, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? lastVerifiedAt,  List<String> tags,  List<Benefit> benefits,  List<SchemeDocument> documents,  int likeCount,  int saveCount,  int commentCount,  double? averageRating)  $default,) {final _that = this;
switch (_that) {
case _SchemeDetail():
return $default(_that.schemeId,_that.slug,_that.name,_that.nameHi,_that.ministry,_that.category,_that.schemeType,_that.jurisdiction,_that.stateCode,_that.descriptionShort,_that.descriptionLong,_that.officialUrl,_that.applicationDeadline,_that.verificationStatus,_that.needsReview,_that.lastVerifiedAt,_that.tags,_that.benefits,_that.documents,_that.likeCount,_that.saveCount,_that.commentCount,_that.averageRating);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schemeId,  String slug,  String name,  String? nameHi,  String? ministry,  String? category, @SchemeTypeConverter()  SchemeType schemeType, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode,  String? descriptionShort,  String? descriptionLong,  String? officialUrl,  String? applicationDeadline, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? lastVerifiedAt,  List<String> tags,  List<Benefit> benefits,  List<SchemeDocument> documents,  int likeCount,  int saveCount,  int commentCount,  double? averageRating)?  $default,) {final _that = this;
switch (_that) {
case _SchemeDetail() when $default != null:
return $default(_that.schemeId,_that.slug,_that.name,_that.nameHi,_that.ministry,_that.category,_that.schemeType,_that.jurisdiction,_that.stateCode,_that.descriptionShort,_that.descriptionLong,_that.officialUrl,_that.applicationDeadline,_that.verificationStatus,_that.needsReview,_that.lastVerifiedAt,_that.tags,_that.benefits,_that.documents,_that.likeCount,_that.saveCount,_that.commentCount,_that.averageRating);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SchemeDetail implements SchemeDetail {
  const _SchemeDetail({required this.schemeId, required this.slug, required this.name, this.nameHi, this.ministry, this.category, @SchemeTypeConverter() required this.schemeType, @JurisdictionConverter() required this.jurisdiction, this.stateCode, this.descriptionShort, this.descriptionLong, this.officialUrl, this.applicationDeadline, @VerificationStatusConverter() required this.verificationStatus, required this.needsReview, this.lastVerifiedAt, required final  List<String> tags, required final  List<Benefit> benefits, required final  List<SchemeDocument> documents, required this.likeCount, required this.saveCount, required this.commentCount, this.averageRating}): _tags = tags,_benefits = benefits,_documents = documents;
  factory _SchemeDetail.fromJson(Map<String, dynamic> json) => _$SchemeDetailFromJson(json);

@override final  String schemeId;
@override final  String slug;
@override final  String name;
@override final  String? nameHi;
@override final  String? ministry;
@override final  String? category;
@override@SchemeTypeConverter() final  SchemeType schemeType;
@override@JurisdictionConverter() final  Jurisdiction jurisdiction;
@override final  String? stateCode;
@override final  String? descriptionShort;
@override final  String? descriptionLong;
@override final  String? officialUrl;
@override final  String? applicationDeadline;
@override@VerificationStatusConverter() final  VerificationStatus verificationStatus;
@override final  bool needsReview;
@override final  String? lastVerifiedAt;
 final  List<String> _tags;
@override List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<Benefit> _benefits;
@override List<Benefit> get benefits {
  if (_benefits is EqualUnmodifiableListView) return _benefits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_benefits);
}

 final  List<SchemeDocument> _documents;
@override List<SchemeDocument> get documents {
  if (_documents is EqualUnmodifiableListView) return _documents;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_documents);
}

@override final  int likeCount;
@override final  int saveCount;
@override final  int commentCount;
@override final  double? averageRating;

/// Create a copy of SchemeDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchemeDetailCopyWith<_SchemeDetail> get copyWith => __$SchemeDetailCopyWithImpl<_SchemeDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SchemeDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchemeDetail&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameHi, nameHi) || other.nameHi == nameHi)&&(identical(other.ministry, ministry) || other.ministry == ministry)&&(identical(other.category, category) || other.category == category)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.descriptionShort, descriptionShort) || other.descriptionShort == descriptionShort)&&(identical(other.descriptionLong, descriptionLong) || other.descriptionLong == descriptionLong)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl)&&(identical(other.applicationDeadline, applicationDeadline) || other.applicationDeadline == applicationDeadline)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.lastVerifiedAt, lastVerifiedAt) || other.lastVerifiedAt == lastVerifiedAt)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._benefits, _benefits)&&const DeepCollectionEquality().equals(other._documents, _documents)&&(identical(other.likeCount, likeCount) || other.likeCount == likeCount)&&(identical(other.saveCount, saveCount) || other.saveCount == saveCount)&&(identical(other.commentCount, commentCount) || other.commentCount == commentCount)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,schemeId,slug,name,nameHi,ministry,category,schemeType,jurisdiction,stateCode,descriptionShort,descriptionLong,officialUrl,applicationDeadline,verificationStatus,needsReview,lastVerifiedAt,const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_benefits),const DeepCollectionEquality().hash(_documents),likeCount,saveCount,commentCount,averageRating]);

@override
String toString() {
  return 'SchemeDetail(schemeId: $schemeId, slug: $slug, name: $name, nameHi: $nameHi, ministry: $ministry, category: $category, schemeType: $schemeType, jurisdiction: $jurisdiction, stateCode: $stateCode, descriptionShort: $descriptionShort, descriptionLong: $descriptionLong, officialUrl: $officialUrl, applicationDeadline: $applicationDeadline, verificationStatus: $verificationStatus, needsReview: $needsReview, lastVerifiedAt: $lastVerifiedAt, tags: $tags, benefits: $benefits, documents: $documents, likeCount: $likeCount, saveCount: $saveCount, commentCount: $commentCount, averageRating: $averageRating)';
}


}

/// @nodoc
abstract mixin class _$SchemeDetailCopyWith<$Res> implements $SchemeDetailCopyWith<$Res> {
  factory _$SchemeDetailCopyWith(_SchemeDetail value, $Res Function(_SchemeDetail) _then) = __$SchemeDetailCopyWithImpl;
@override @useResult
$Res call({
 String schemeId, String slug, String name, String? nameHi, String? ministry, String? category,@SchemeTypeConverter() SchemeType schemeType,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode, String? descriptionShort, String? descriptionLong, String? officialUrl, String? applicationDeadline,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? lastVerifiedAt, List<String> tags, List<Benefit> benefits, List<SchemeDocument> documents, int likeCount, int saveCount, int commentCount, double? averageRating
});




}
/// @nodoc
class __$SchemeDetailCopyWithImpl<$Res>
    implements _$SchemeDetailCopyWith<$Res> {
  __$SchemeDetailCopyWithImpl(this._self, this._then);

  final _SchemeDetail _self;
  final $Res Function(_SchemeDetail) _then;

/// Create a copy of SchemeDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemeId = null,Object? slug = null,Object? name = null,Object? nameHi = freezed,Object? ministry = freezed,Object? category = freezed,Object? schemeType = null,Object? jurisdiction = null,Object? stateCode = freezed,Object? descriptionShort = freezed,Object? descriptionLong = freezed,Object? officialUrl = freezed,Object? applicationDeadline = freezed,Object? verificationStatus = null,Object? needsReview = null,Object? lastVerifiedAt = freezed,Object? tags = null,Object? benefits = null,Object? documents = null,Object? likeCount = null,Object? saveCount = null,Object? commentCount = null,Object? averageRating = freezed,}) {
  return _then(_SchemeDetail(
schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameHi: freezed == nameHi ? _self.nameHi : nameHi // ignore: cast_nullable_to_non_nullable
as String?,ministry: freezed == ministry ? _self.ministry : ministry // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as SchemeType,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,descriptionShort: freezed == descriptionShort ? _self.descriptionShort : descriptionShort // ignore: cast_nullable_to_non_nullable
as String?,descriptionLong: freezed == descriptionLong ? _self.descriptionLong : descriptionLong // ignore: cast_nullable_to_non_nullable
as String?,officialUrl: freezed == officialUrl ? _self.officialUrl : officialUrl // ignore: cast_nullable_to_non_nullable
as String?,applicationDeadline: freezed == applicationDeadline ? _self.applicationDeadline : applicationDeadline // ignore: cast_nullable_to_non_nullable
as String?,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,lastVerifiedAt: freezed == lastVerifiedAt ? _self.lastVerifiedAt : lastVerifiedAt // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,benefits: null == benefits ? _self._benefits : benefits // ignore: cast_nullable_to_non_nullable
as List<Benefit>,documents: null == documents ? _self._documents : documents // ignore: cast_nullable_to_non_nullable
as List<SchemeDocument>,likeCount: null == likeCount ? _self.likeCount : likeCount // ignore: cast_nullable_to_non_nullable
as int,saveCount: null == saveCount ? _self.saveCount : saveCount // ignore: cast_nullable_to_non_nullable
as int,commentCount: null == commentCount ? _self.commentCount : commentCount // ignore: cast_nullable_to_non_nullable
as int,averageRating: freezed == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
