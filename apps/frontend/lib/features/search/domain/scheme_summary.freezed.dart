// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scheme_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SchemeSummary {

 String get schemeId; String get slug; String get name; String? get descriptionShort; String? get category;@JurisdictionConverter() Jurisdiction get jurisdiction; String? get stateCode;@SchemeTypeConverter() SchemeType get schemeType; double get score;@VerificationStatusConverter() VerificationStatus get verificationStatus; bool get needsReview; String? get officialUrl;
/// Create a copy of SchemeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SchemeSummaryCopyWith<SchemeSummary> get copyWith => _$SchemeSummaryCopyWithImpl<SchemeSummary>(this as SchemeSummary, _$identity);

  /// Serializes this SchemeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SchemeSummary&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.descriptionShort, descriptionShort) || other.descriptionShort == descriptionShort)&&(identical(other.category, category) || other.category == category)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.score, score) || other.score == score)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemeId,slug,name,descriptionShort,category,jurisdiction,stateCode,schemeType,score,verificationStatus,needsReview,officialUrl);

@override
String toString() {
  return 'SchemeSummary(schemeId: $schemeId, slug: $slug, name: $name, descriptionShort: $descriptionShort, category: $category, jurisdiction: $jurisdiction, stateCode: $stateCode, schemeType: $schemeType, score: $score, verificationStatus: $verificationStatus, needsReview: $needsReview, officialUrl: $officialUrl)';
}


}

/// @nodoc
abstract mixin class $SchemeSummaryCopyWith<$Res>  {
  factory $SchemeSummaryCopyWith(SchemeSummary value, $Res Function(SchemeSummary) _then) = _$SchemeSummaryCopyWithImpl;
@useResult
$Res call({
 String schemeId, String slug, String name, String? descriptionShort, String? category,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode,@SchemeTypeConverter() SchemeType schemeType, double score,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? officialUrl
});




}
/// @nodoc
class _$SchemeSummaryCopyWithImpl<$Res>
    implements $SchemeSummaryCopyWith<$Res> {
  _$SchemeSummaryCopyWithImpl(this._self, this._then);

  final SchemeSummary _self;
  final $Res Function(SchemeSummary) _then;

/// Create a copy of SchemeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemeId = null,Object? slug = null,Object? name = null,Object? descriptionShort = freezed,Object? category = freezed,Object? jurisdiction = null,Object? stateCode = freezed,Object? schemeType = null,Object? score = null,Object? verificationStatus = null,Object? needsReview = null,Object? officialUrl = freezed,}) {
  return _then(_self.copyWith(
schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,descriptionShort: freezed == descriptionShort ? _self.descriptionShort : descriptionShort // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as SchemeType,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,officialUrl: freezed == officialUrl ? _self.officialUrl : officialUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SchemeSummary].
extension SchemeSummaryPatterns on SchemeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SchemeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SchemeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SchemeSummary value)  $default,){
final _that = this;
switch (_that) {
case _SchemeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SchemeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _SchemeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schemeId,  String slug,  String name,  String? descriptionShort,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType,  double score, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SchemeSummary() when $default != null:
return $default(_that.schemeId,_that.slug,_that.name,_that.descriptionShort,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.score,_that.verificationStatus,_that.needsReview,_that.officialUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schemeId,  String slug,  String name,  String? descriptionShort,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType,  double score, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl)  $default,) {final _that = this;
switch (_that) {
case _SchemeSummary():
return $default(_that.schemeId,_that.slug,_that.name,_that.descriptionShort,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.score,_that.verificationStatus,_that.needsReview,_that.officialUrl);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schemeId,  String slug,  String name,  String? descriptionShort,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType,  double score, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl)?  $default,) {final _that = this;
switch (_that) {
case _SchemeSummary() when $default != null:
return $default(_that.schemeId,_that.slug,_that.name,_that.descriptionShort,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.score,_that.verificationStatus,_that.needsReview,_that.officialUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SchemeSummary implements SchemeSummary {
  const _SchemeSummary({required this.schemeId, required this.slug, required this.name, this.descriptionShort, this.category, @JurisdictionConverter() required this.jurisdiction, this.stateCode, @SchemeTypeConverter() required this.schemeType, required this.score, @VerificationStatusConverter() required this.verificationStatus, required this.needsReview, this.officialUrl});
  factory _SchemeSummary.fromJson(Map<String, dynamic> json) => _$SchemeSummaryFromJson(json);

@override final  String schemeId;
@override final  String slug;
@override final  String name;
@override final  String? descriptionShort;
@override final  String? category;
@override@JurisdictionConverter() final  Jurisdiction jurisdiction;
@override final  String? stateCode;
@override@SchemeTypeConverter() final  SchemeType schemeType;
@override final  double score;
@override@VerificationStatusConverter() final  VerificationStatus verificationStatus;
@override final  bool needsReview;
@override final  String? officialUrl;

/// Create a copy of SchemeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SchemeSummaryCopyWith<_SchemeSummary> get copyWith => __$SchemeSummaryCopyWithImpl<_SchemeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SchemeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SchemeSummary&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.descriptionShort, descriptionShort) || other.descriptionShort == descriptionShort)&&(identical(other.category, category) || other.category == category)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.score, score) || other.score == score)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemeId,slug,name,descriptionShort,category,jurisdiction,stateCode,schemeType,score,verificationStatus,needsReview,officialUrl);

@override
String toString() {
  return 'SchemeSummary(schemeId: $schemeId, slug: $slug, name: $name, descriptionShort: $descriptionShort, category: $category, jurisdiction: $jurisdiction, stateCode: $stateCode, schemeType: $schemeType, score: $score, verificationStatus: $verificationStatus, needsReview: $needsReview, officialUrl: $officialUrl)';
}


}

/// @nodoc
abstract mixin class _$SchemeSummaryCopyWith<$Res> implements $SchemeSummaryCopyWith<$Res> {
  factory _$SchemeSummaryCopyWith(_SchemeSummary value, $Res Function(_SchemeSummary) _then) = __$SchemeSummaryCopyWithImpl;
@override @useResult
$Res call({
 String schemeId, String slug, String name, String? descriptionShort, String? category,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode,@SchemeTypeConverter() SchemeType schemeType, double score,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? officialUrl
});




}
/// @nodoc
class __$SchemeSummaryCopyWithImpl<$Res>
    implements _$SchemeSummaryCopyWith<$Res> {
  __$SchemeSummaryCopyWithImpl(this._self, this._then);

  final _SchemeSummary _self;
  final $Res Function(_SchemeSummary) _then;

/// Create a copy of SchemeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemeId = null,Object? slug = null,Object? name = null,Object? descriptionShort = freezed,Object? category = freezed,Object? jurisdiction = null,Object? stateCode = freezed,Object? schemeType = null,Object? score = null,Object? verificationStatus = null,Object? needsReview = null,Object? officialUrl = freezed,}) {
  return _then(_SchemeSummary(
schemeId: null == schemeId ? _self.schemeId : schemeId // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,descriptionShort: freezed == descriptionShort ? _self.descriptionShort : descriptionShort // ignore: cast_nullable_to_non_nullable
as String?,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,jurisdiction: null == jurisdiction ? _self.jurisdiction : jurisdiction // ignore: cast_nullable_to_non_nullable
as Jurisdiction,stateCode: freezed == stateCode ? _self.stateCode : stateCode // ignore: cast_nullable_to_non_nullable
as String?,schemeType: null == schemeType ? _self.schemeType : schemeType // ignore: cast_nullable_to_non_nullable
as SchemeType,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as double,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,needsReview: null == needsReview ? _self.needsReview : needsReview // ignore: cast_nullable_to_non_nullable
as bool,officialUrl: freezed == officialUrl ? _self.officialUrl : officialUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SearchResponse {

 String get query; int get totalReturned; Map<String, int> get verificationBreakdown; List<SchemeSummary> get results;
/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchResponseCopyWith<SearchResponse> get copyWith => _$SearchResponseCopyWithImpl<SearchResponse>(this as SearchResponse, _$identity);

  /// Serializes this SearchResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchResponse&&(identical(other.query, query) || other.query == query)&&(identical(other.totalReturned, totalReturned) || other.totalReturned == totalReturned)&&const DeepCollectionEquality().equals(other.verificationBreakdown, verificationBreakdown)&&const DeepCollectionEquality().equals(other.results, results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,totalReturned,const DeepCollectionEquality().hash(verificationBreakdown),const DeepCollectionEquality().hash(results));

@override
String toString() {
  return 'SearchResponse(query: $query, totalReturned: $totalReturned, verificationBreakdown: $verificationBreakdown, results: $results)';
}


}

/// @nodoc
abstract mixin class $SearchResponseCopyWith<$Res>  {
  factory $SearchResponseCopyWith(SearchResponse value, $Res Function(SearchResponse) _then) = _$SearchResponseCopyWithImpl;
@useResult
$Res call({
 String query, int totalReturned, Map<String, int> verificationBreakdown, List<SchemeSummary> results
});




}
/// @nodoc
class _$SearchResponseCopyWithImpl<$Res>
    implements $SearchResponseCopyWith<$Res> {
  _$SearchResponseCopyWithImpl(this._self, this._then);

  final SearchResponse _self;
  final $Res Function(SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? totalReturned = null,Object? verificationBreakdown = null,Object? results = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,totalReturned: null == totalReturned ? _self.totalReturned : totalReturned // ignore: cast_nullable_to_non_nullable
as int,verificationBreakdown: null == verificationBreakdown ? _self.verificationBreakdown : verificationBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, int>,results: null == results ? _self.results : results // ignore: cast_nullable_to_non_nullable
as List<SchemeSummary>,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchResponse].
extension SearchResponsePatterns on SearchResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchResponse value)  $default,){
final _that = this;
switch (_that) {
case _SearchResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  int totalReturned,  Map<String, int> verificationBreakdown,  List<SchemeSummary> results)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that.query,_that.totalReturned,_that.verificationBreakdown,_that.results);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  int totalReturned,  Map<String, int> verificationBreakdown,  List<SchemeSummary> results)  $default,) {final _that = this;
switch (_that) {
case _SearchResponse():
return $default(_that.query,_that.totalReturned,_that.verificationBreakdown,_that.results);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  int totalReturned,  Map<String, int> verificationBreakdown,  List<SchemeSummary> results)?  $default,) {final _that = this;
switch (_that) {
case _SearchResponse() when $default != null:
return $default(_that.query,_that.totalReturned,_that.verificationBreakdown,_that.results);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SearchResponse implements SearchResponse {
  const _SearchResponse({required this.query, required this.totalReturned, required final  Map<String, int> verificationBreakdown, required final  List<SchemeSummary> results}): _verificationBreakdown = verificationBreakdown,_results = results;
  factory _SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);

@override final  String query;
@override final  int totalReturned;
 final  Map<String, int> _verificationBreakdown;
@override Map<String, int> get verificationBreakdown {
  if (_verificationBreakdown is EqualUnmodifiableMapView) return _verificationBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_verificationBreakdown);
}

 final  List<SchemeSummary> _results;
@override List<SchemeSummary> get results {
  if (_results is EqualUnmodifiableListView) return _results;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_results);
}


/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchResponseCopyWith<_SearchResponse> get copyWith => __$SearchResponseCopyWithImpl<_SearchResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SearchResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchResponse&&(identical(other.query, query) || other.query == query)&&(identical(other.totalReturned, totalReturned) || other.totalReturned == totalReturned)&&const DeepCollectionEquality().equals(other._verificationBreakdown, _verificationBreakdown)&&const DeepCollectionEquality().equals(other._results, _results));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,totalReturned,const DeepCollectionEquality().hash(_verificationBreakdown),const DeepCollectionEquality().hash(_results));

@override
String toString() {
  return 'SearchResponse(query: $query, totalReturned: $totalReturned, verificationBreakdown: $verificationBreakdown, results: $results)';
}


}

/// @nodoc
abstract mixin class _$SearchResponseCopyWith<$Res> implements $SearchResponseCopyWith<$Res> {
  factory _$SearchResponseCopyWith(_SearchResponse value, $Res Function(_SearchResponse) _then) = __$SearchResponseCopyWithImpl;
@override @useResult
$Res call({
 String query, int totalReturned, Map<String, int> verificationBreakdown, List<SchemeSummary> results
});




}
/// @nodoc
class __$SearchResponseCopyWithImpl<$Res>
    implements _$SearchResponseCopyWith<$Res> {
  __$SearchResponseCopyWithImpl(this._self, this._then);

  final _SearchResponse _self;
  final $Res Function(_SearchResponse) _then;

/// Create a copy of SearchResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? totalReturned = null,Object? verificationBreakdown = null,Object? results = null,}) {
  return _then(_SearchResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,totalReturned: null == totalReturned ? _self.totalReturned : totalReturned // ignore: cast_nullable_to_non_nullable
as int,verificationBreakdown: null == verificationBreakdown ? _self._verificationBreakdown : verificationBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, int>,results: null == results ? _self._results : results // ignore: cast_nullable_to_non_nullable
as List<SchemeSummary>,
  ));
}


}

// dart format on
