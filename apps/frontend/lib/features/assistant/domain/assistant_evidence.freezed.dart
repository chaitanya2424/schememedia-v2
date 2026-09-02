// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'assistant_evidence.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EvidenceResult {

 String get schemeId; String get name; String? get category;@JurisdictionConverter() Jurisdiction get jurisdiction; String? get stateCode;@SchemeTypeConverter() SchemeType get schemeType;@EligibilityStateConverter() EligibilityState get eligibilityState; List<String> get eligibilityExplanations; List<String> get missingAttributes;@VerificationStatusConverter() VerificationStatus get verificationStatus; bool get needsReview; String? get officialUrl;
/// Create a copy of EvidenceResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EvidenceResultCopyWith<EvidenceResult> get copyWith => _$EvidenceResultCopyWithImpl<EvidenceResult>(this as EvidenceResult, _$identity);

  /// Serializes this EvidenceResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EvidenceResult&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.eligibilityState, eligibilityState) || other.eligibilityState == eligibilityState)&&const DeepCollectionEquality().equals(other.eligibilityExplanations, eligibilityExplanations)&&const DeepCollectionEquality().equals(other.missingAttributes, missingAttributes)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemeId,name,category,jurisdiction,stateCode,schemeType,eligibilityState,const DeepCollectionEquality().hash(eligibilityExplanations),const DeepCollectionEquality().hash(missingAttributes),verificationStatus,needsReview,officialUrl);

@override
String toString() {
  return 'EvidenceResult(schemeId: $schemeId, name: $name, category: $category, jurisdiction: $jurisdiction, stateCode: $stateCode, schemeType: $schemeType, eligibilityState: $eligibilityState, eligibilityExplanations: $eligibilityExplanations, missingAttributes: $missingAttributes, verificationStatus: $verificationStatus, needsReview: $needsReview, officialUrl: $officialUrl)';
}


}

/// @nodoc
abstract mixin class $EvidenceResultCopyWith<$Res>  {
  factory $EvidenceResultCopyWith(EvidenceResult value, $Res Function(EvidenceResult) _then) = _$EvidenceResultCopyWithImpl;
@useResult
$Res call({
 String schemeId, String name, String? category,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode,@SchemeTypeConverter() SchemeType schemeType,@EligibilityStateConverter() EligibilityState eligibilityState, List<String> eligibilityExplanations, List<String> missingAttributes,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? officialUrl
});




}
/// @nodoc
class _$EvidenceResultCopyWithImpl<$Res>
    implements $EvidenceResultCopyWith<$Res> {
  _$EvidenceResultCopyWithImpl(this._self, this._then);

  final EvidenceResult _self;
  final $Res Function(EvidenceResult) _then;

/// Create a copy of EvidenceResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemeId = null,Object? name = null,Object? category = freezed,Object? jurisdiction = null,Object? stateCode = freezed,Object? schemeType = null,Object? eligibilityState = null,Object? eligibilityExplanations = null,Object? missingAttributes = null,Object? verificationStatus = null,Object? needsReview = null,Object? officialUrl = freezed,}) {
  return _then(_self.copyWith(
schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as SchemeType,eligibilityState: null == eligibilityState ? _self.eligibilityState : eligibilityState // ignore: cast_nullable_to_non_nullable
as EligibilityState,eligibilityExplanations: null == eligibilityExplanations ? _self.eligibilityExplanations : eligibilityExplanations // ignore: cast_nullable_to_non_nullable
as List<String>,missingAttributes: null == missingAttributes ? _self.missingAttributes : missingAttributes // ignore: cast_nullable_to_non_nullable
as List<String>,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,officialUrl: freezed == officialUrl ? _self.officialUrl : officialUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [EvidenceResult].
extension EvidenceResultPatterns on EvidenceResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EvidenceResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EvidenceResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EvidenceResult value)  $default,){
final _that = this;
switch (_that) {
case _EvidenceResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EvidenceResult value)?  $default,){
final _that = this;
switch (_that) {
case _EvidenceResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schemeId,  String name,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType, @EligibilityStateConverter()  EligibilityState eligibilityState,  List<String> eligibilityExplanations,  List<String> missingAttributes, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EvidenceResult() when $default != null:
return $default(_that.schemeId,_that.name,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.eligibilityState,_that.eligibilityExplanations,_that.missingAttributes,_that.verificationStatus,_that.needsReview,_that.officialUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schemeId,  String name,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType, @EligibilityStateConverter()  EligibilityState eligibilityState,  List<String> eligibilityExplanations,  List<String> missingAttributes, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl)  $default,) {final _that = this;
switch (_that) {
case _EvidenceResult():
return $default(_that.schemeId,_that.name,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.eligibilityState,_that.eligibilityExplanations,_that.missingAttributes,_that.verificationStatus,_that.needsReview,_that.officialUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schemeId,  String name,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType, @EligibilityStateConverter()  EligibilityState eligibilityState,  List<String> eligibilityExplanations,  List<String> missingAttributes, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl)?  $default,) {final _that = this;
switch (_that) {
case _EvidenceResult() when $default != null:
return $default(_that.schemeId,_that.name,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.eligibilityState,_that.eligibilityExplanations,_that.missingAttributes,_that.verificationStatus,_that.needsReview,_that.officialUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EvidenceResult implements EvidenceResult {
  const _EvidenceResult({required this.schemeId, required this.name, this.category, @JurisdictionConverter() required this.jurisdiction, this.stateCode, @SchemeTypeConverter() required this.schemeType, @EligibilityStateConverter() required this.eligibilityState, required final  List<String> eligibilityExplanations, required final  List<String> missingAttributes, @VerificationStatusConverter() required this.verificationStatus, required this.needsReview, this.officialUrl}): _eligibilityExplanations = eligibilityExplanations,_missingAttributes = missingAttributes;
  factory _EvidenceResult.fromJson(Map<String, dynamic> json) => _$EvidenceResultFromJson(json);

@override final  String schemeId;
@override final  String name;
@override final  String? category;
@override@JurisdictionConverter() final  Jurisdiction jurisdiction;
@override final  String? stateCode;
@override@SchemeTypeConverter() final  SchemeType schemeType;
@override@EligibilityStateConverter() final  EligibilityState eligibilityState;
 final  List<String> _eligibilityExplanations;
@override List<String> get eligibilityExplanations {
  if (_eligibilityExplanations is EqualUnmodifiableListView) return _eligibilityExplanations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eligibilityExplanations);
}

 final  List<String> _missingAttributes;
@override List<String> get missingAttributes {
  if (_missingAttributes is EqualUnmodifiableListView) return _missingAttributes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_missingAttributes);
}

@override@VerificationStatusConverter() final  VerificationStatus verificationStatus;
@override final  bool needsReview;
@override final  String? officialUrl;

/// Create a copy of EvidenceResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EvidenceResultCopyWith<_EvidenceResult> get copyWith => __$EvidenceResultCopyWithImpl<_EvidenceResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EvidenceResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EvidenceResult&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.eligibilityState, eligibilityState) || other.eligibilityState == eligibilityState)&&const DeepCollectionEquality().equals(other._eligibilityExplanations, _eligibilityExplanations)&&const DeepCollectionEquality().equals(other._missingAttributes, _missingAttributes)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemeId,name,category,jurisdiction,stateCode,schemeType,eligibilityState,const DeepCollectionEquality().hash(_eligibilityExplanations),const DeepCollectionEquality().hash(_missingAttributes),verificationStatus,needsReview,officialUrl);

@override
String toString() {
  return 'EvidenceResult(schemeId: $schemeId, name: $name, category: $category, jurisdiction: $jurisdiction, stateCode: $stateCode, schemeType: $schemeType, eligibilityState: $eligibilityState, eligibilityExplanations: $eligibilityExplanations, missingAttributes: $missingAttributes, verificationStatus: $verificationStatus, needsReview: $needsReview, officialUrl: $officialUrl)';
}


}

/// @nodoc
abstract mixin class _$EvidenceResultCopyWith<$Res> implements $EvidenceResultCopyWith<$Res> {
  factory _$EvidenceResultCopyWith(_EvidenceResult value, $Res Function(_EvidenceResult) _then) = __$EvidenceResultCopyWithImpl;
@override @useResult
$Res call({
 String schemeId, String name, String? category,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode,@SchemeTypeConverter() SchemeType schemeType,@EligibilityStateConverter() EligibilityState eligibilityState, List<String> eligibilityExplanations, List<String> missingAttributes,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? officialUrl
});




}
/// @nodoc
class __$EvidenceResultCopyWithImpl<$Res>
    implements _$EvidenceResultCopyWith<$Res> {
  __$EvidenceResultCopyWithImpl(this._self, this._then);

  final _EvidenceResult _self;
  final $Res Function(_EvidenceResult) _then;

/// Create a copy of EvidenceResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemeId = null,Object? name = null,Object? category = freezed,Object? jurisdiction = null,Object? stateCode = freezed,Object? schemeType = null,Object? eligibilityState = null,Object? eligibilityExplanations = null,Object? missingAttributes = null,Object? verificationStatus = null,Object? needsReview = null,Object? officialUrl = freezed,}) {
  return _then(_EvidenceResult(
schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as SchemeType,eligibilityState: null == eligibilityState ? _self.eligibilityState : eligibilityState // ignore: cast_nullable_to_non_nullable
as EligibilityState,eligibilityExplanations: null == eligibilityExplanations ? _self._eligibilityExplanations : eligibilityExplanations // ignore: cast_nullable_to_non_nullable
as List<String>,missingAttributes: null == missingAttributes ? _self._missingAttributes : missingAttributes // ignore: cast_nullable_to_non_nullable
as List<String>,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,officialUrl: freezed == officialUrl ? _self.officialUrl : officialUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AssistantEvidence {

 String get query; bool get profileProvided; int get totalReturned; Map<String, int> get eligibilityBreakdown; List<EvidenceResult> get results;
/// Create a copy of AssistantEvidence
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AssistantEvidenceCopyWith<AssistantEvidence> get copyWith => _$AssistantEvidenceCopyWithImpl<AssistantEvidence>(this as AssistantEvidence, _$identity);

  /// Serializes this AssistantEvidence to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AssistantEvidence&&(identical(other.query, query) || other.query == query)&&(identical(other.profileProvided, profileProvided) || other.profileProvided == profileProvided)&&(identical(other.totalReturned, totalReturned) || other.totalReturned == totalReturned)&&const DeepCollectionEquality().equals(other.eligibilityBreakdown, eligibilityBreakdown)&&const DeepCollectionEquality().equals(other.results, results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,profileProvided,totalReturned,const DeepCollectionEquality().hash(eligibilityBreakdown),const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'AssistantEvidence(query: $query, profileProvided: $profileProvided, totalReturned: $totalReturned, eligibilityBreakdown: $eligibilityBreakdown, results: $results)';
}


}

/// @nodoc
abstract mixin class $AssistantEvidenceCopyWith<$Res>  {
  factory $AssistantEvidenceCopyWith(AssistantEvidence value, $Res Function(AssistantEvidence) _then) = _$AssistantEvidenceCopyWithImpl;
@useResult
$Res call({
 String query, bool profileProvided, int totalReturned, Map<String, int> eligibilityBreakdown, List<EvidenceResult> results
});




}
/// @nodoc
class _$AssistantEvidenceCopyWithImpl<$Res>
    implements $AssistantEvidenceCopyWith<$Res> {
  _$AssistantEvidenceCopyWithImpl(this._self, this._then);

  final AssistantEvidence _self;
  final $Res Function(AssistantEvidence) _then;

/// Create a copy of AssistantEvidence
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? profileProvided = null,Object? totalReturned = null,Object? eligibilityBreakdown = null,Object? results = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,profileProvided: null == profileProvided ? _self.profileProvided : profileProvided // ignore: cast_nullable_to_non_nullable
as bool,totalReturned: null == totalReturned ? _self.totalReturned : totalReturned // ignore: cast_nullable_to_non_nullable
as int,eligibilityBreakdown: null == eligibilityBreakdown ? _self.eligibilityBreakdown : eligibilityBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, int>,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<EvidenceResult>,
  ));
}

}


/// Adds pattern-matching-related methods to [AssistantEvidence].
extension AssistantEvidencePatterns on AssistantEvidence {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AssistantEvidence value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AssistantEvidence() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AssistantEvidence value)  $default,){
final _that = this;
switch (_that) {
case _AssistantEvidence():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AssistantEvidence value)?  $default,){
final _that = this;
switch (_that) {
case _AssistantEvidence() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  bool profileProvided,  int totalReturned,  Map<String, int> eligibilityBreakdown,  List<EvidenceResult> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AssistantEvidence() when $default != null:
return $default(_that.query,_that.profileProvided,_that.totalReturned,_that.eligibilityBreakdown,_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  bool profileProvided,  int totalReturned,  Map<String, int> eligibilityBreakdown,  List<EvidenceResult> results)  $default,) {final _that = this;
switch (_that) {
case _AssistantEvidence():
return $default(_that.query,_that.profileProvided,_that.totalReturned,_that.eligibilityBreakdown,_that.results);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  bool profileProvided,  int totalReturned,  Map<String, int> eligibilityBreakdown,  List<EvidenceResult> results)?  $default,) {final _that = this;
switch (_that) {
case _AssistantEvidence() when $default != null:
return $default(_that.query,_that.profileProvided,_that.totalReturned,_that.eligibilityBreakdown,_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AssistantEvidence implements AssistantEvidence {
  const _AssistantEvidence({required this.query, required this.profileProvided, required this.totalReturned, required final  Map<String, int> eligibilityBreakdown, required final  List<EvidenceResult> results}): _eligibilityBreakdown = eligibilityBreakdown,_results = results;
  factory _AssistantEvidence.fromJson(Map<String, dynamic> json) => _$AssistantEvidenceFromJson(json);

@override final  String query;
@override final  bool profileProvided;
@override final  int totalReturned;
 final  Map<String, int> _eligibilityBreakdown;
@override Map<String, int> get eligibilityBreakdown {
  if (_eligibilityBreakdown is EqualUnmodifiableMapView) return _eligibilityBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_eligibilityBreakdown);
}

 final  List<EvidenceResult> _results;
@override List<EvidenceResult> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of AssistantEvidence
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AssistantEvidenceCopyWith<_AssistantEvidence> get copyWith => __$AssistantEvidenceCopyWithImpl<_AssistantEvidence>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AssistantEvidenceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AssistantEvidence&&(identical(other.query, query) || other.query == query)&&(identical(other.profileProvided, profileProvided) || other.profileProvided == profileProvided)&&(identical(other.totalReturned, totalReturned) || other.totalReturned == totalReturned)&&const DeepCollectionEquality().equals(other._eligibilityBreakdown, _eligibilityBreakdown)&&const DeepCollectionEquality().equals(other._results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,profileProvided,totalReturned,const DeepCollectionEquality().hash(_eligibilityBreakdown),const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'AssistantEvidence(query: $query, profileProvided: $profileProvided, totalReturned: $totalReturned, eligibilityBreakdown: $eligibilityBreakdown, results: $results)';
}


}

/// @nodoc
abstract mixin class _$AssistantEvidenceCopyWith<$Res> implements $AssistantEvidenceCopyWith<$Res> {
  factory _$AssistantEvidenceCopyWith(_AssistantEvidence value, $Res Function(_AssistantEvidence) _then) = __$AssistantEvidenceCopyWithImpl;
@override @useResult
$Res call({
 String query, bool profileProvided, int totalReturned, Map<String, int> eligibilityBreakdown, List<EvidenceResult> results
});




}
/// @nodoc
class __$AssistantEvidenceCopyWithImpl<$Res>
    implements _$AssistantEvidenceCopyWith<$Res> {
  __$AssistantEvidenceCopyWithImpl(this._self, this._then);

  final _AssistantEvidence _self;
  final $Res Function(_AssistantEvidence) _then;

/// Create a copy of AssistantEvidence
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? profileProvided = null,Object? totalReturned = null,Object? eligibilityBreakdown = null,Object? results = null,}) {
  return _then(_AssistantEvidence(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,profileProvided: null == profileProvided ? _self.profileProvided : profileProvided // ignore: cast_nullable_to_non_nullable
as bool,totalReturned: null == totalReturned ? _self.totalReturned : totalReturned // ignore: cast_nullable_to_non_nullable
as int,eligibilityBreakdown: null == eligibilityBreakdown ? _self._eligibilityBreakdown : eligibilityBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, int>,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<EvidenceResult>,
  ));
}


}

// dart format on
