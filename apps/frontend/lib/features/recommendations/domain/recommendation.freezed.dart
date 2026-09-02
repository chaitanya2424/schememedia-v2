// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EligibilityRule {

@RuleGroupConverter() RuleGroup get ruleGroup; String get attributeKey;@RuleOperatorConverter() RuleOperator get operator;@EligibilityStateConverter() EligibilityState get state; String get label; String? get labelHi; String get explanation;
/// Create a copy of EligibilityRule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EligibilityRuleCopyWith<EligibilityRule> get copyWith => _$EligibilityRuleCopyWithImpl<EligibilityRule>(this as EligibilityRule, _$identity);

  /// Serializes this EligibilityRule to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EligibilityRule&&(identical(other.ruleGroup, ruleGroup) || other.ruleGroup == ruleGroup)&&(identical(other.attributeKey, attributeKey) || other.attributeKey == attributeKey)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.state, state) || other.state == state)&&(identical(other.label, label) || other.label == label)&&(identical(other.labelHi, labelHi) || other.labelHi == labelHi)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ruleGroup,attributeKey,operator,state,label,labelHi,explanation);

@override
String toString() {
  return 'EligibilityRule(ruleGroup: $ruleGroup, attributeKey: $attributeKey, operator: $operator, state: $state, label: $label, labelHi: $labelHi, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class $EligibilityRuleCopyWith<$Res>  {
  factory $EligibilityRuleCopyWith(EligibilityRule value, $Res Function(EligibilityRule) _then) = _$EligibilityRuleCopyWithImpl;
@useResult
$Res call({
@RuleGroupConverter() RuleGroup ruleGroup, String attributeKey,@RuleOperatorConverter() RuleOperator operator,@EligibilityStateConverter() EligibilityState state, String label, String? labelHi, String explanation
});




}
/// @nodoc
class _$EligibilityRuleCopyWithImpl<$Res>
    implements $EligibilityRuleCopyWith<$Res> {
  _$EligibilityRuleCopyWithImpl(this._self, this._then);

  final EligibilityRule _self;
  final $Res Function(EligibilityRule) _then;

/// Create a copy of EligibilityRule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ruleGroup = null,Object? attributeKey = null,Object? operator = null,Object? state = null,Object? label = null,Object? labelHi = freezed,Object? explanation = null,}) {
  return _then(_self.copyWith(
ruleGroup: null == ruleGroup ? _self.ruleGroup : ruleGroup // ignore: cast_nullable_to_non_nullable
as RuleGroup,attributeKey: null == attributeKey ? _self.attributeKey : attributeKey // ignore: cast_nullable_to_non_nullable
as String,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as RuleOperator,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as EligibilityState,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,labelHi: freezed == labelHi ? _self.labelHi : labelHi // ignore: cast_nullable_to_non_nullable
as String?,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EligibilityRule].
extension EligibilityRulePatterns on EligibilityRule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EligibilityRule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EligibilityRule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EligibilityRule value)  $default,){
final _that = this;
switch (_that) {
case _EligibilityRule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EligibilityRule value)?  $default,){
final _that = this;
switch (_that) {
case _EligibilityRule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@RuleGroupConverter()  RuleGroup ruleGroup,  String attributeKey, @RuleOperatorConverter()  RuleOperator operator, @EligibilityStateConverter()  EligibilityState state,  String label,  String? labelHi,  String explanation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EligibilityRule() when $default != null:
return $default(_that.ruleGroup,_that.attributeKey,_that.operator,_that.state,_that.label,_that.labelHi,_that.explanation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@RuleGroupConverter()  RuleGroup ruleGroup,  String attributeKey, @RuleOperatorConverter()  RuleOperator operator, @EligibilityStateConverter()  EligibilityState state,  String label,  String? labelHi,  String explanation)  $default,) {final _that = this;
switch (_that) {
case _EligibilityRule():
return $default(_that.ruleGroup,_that.attributeKey,_that.operator,_that.state,_that.label,_that.labelHi,_that.explanation);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@RuleGroupConverter()  RuleGroup ruleGroup,  String attributeKey, @RuleOperatorConverter()  RuleOperator operator, @EligibilityStateConverter()  EligibilityState state,  String label,  String? labelHi,  String explanation)?  $default,) {final _that = this;
switch (_that) {
case _EligibilityRule() when $default != null:
return $default(_that.ruleGroup,_that.attributeKey,_that.operator,_that.state,_that.label,_that.labelHi,_that.explanation);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EligibilityRule implements EligibilityRule {
  const _EligibilityRule({@RuleGroupConverter() required this.ruleGroup, required this.attributeKey, @RuleOperatorConverter() required this.operator, @EligibilityStateConverter() required this.state, required this.label, this.labelHi, required this.explanation});
  factory _EligibilityRule.fromJson(Map<String, dynamic> json) => _$EligibilityRuleFromJson(json);

@override@RuleGroupConverter() final  RuleGroup ruleGroup;
@override final  String attributeKey;
@override@RuleOperatorConverter() final  RuleOperator operator;
@override@EligibilityStateConverter() final  EligibilityState state;
@override final  String label;
@override final  String? labelHi;
@override final  String explanation;

/// Create a copy of EligibilityRule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EligibilityRuleCopyWith<_EligibilityRule> get copyWith => __$EligibilityRuleCopyWithImpl<_EligibilityRule>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EligibilityRuleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EligibilityRule&&(identical(other.ruleGroup, ruleGroup) || other.ruleGroup == ruleGroup)&&(identical(other.attributeKey, attributeKey) || other.attributeKey == attributeKey)&&(identical(other.operator, operator) || other.operator == operator)&&(identical(other.state, state) || other.state == state)&&(identical(other.label, label) || other.label == label)&&(identical(other.labelHi, labelHi) || other.labelHi == labelHi)&&(identical(other.explanation, explanation) || other.explanation == explanation));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ruleGroup,attributeKey,operator,state,label,labelHi,explanation);

@override
String toString() {
  return 'EligibilityRule(ruleGroup: $ruleGroup, attributeKey: $attributeKey, operator: $operator, state: $state, label: $label, labelHi: $labelHi, explanation: $explanation)';
}


}

/// @nodoc
abstract mixin class _$EligibilityRuleCopyWith<$Res> implements $EligibilityRuleCopyWith<$Res> {
  factory _$EligibilityRuleCopyWith(_EligibilityRule value, $Res Function(_EligibilityRule) _then) = __$EligibilityRuleCopyWithImpl;
@override @useResult
$Res call({
@RuleGroupConverter() RuleGroup ruleGroup, String attributeKey,@RuleOperatorConverter() RuleOperator operator,@EligibilityStateConverter() EligibilityState state, String label, String? labelHi, String explanation
});




}
/// @nodoc
class __$EligibilityRuleCopyWithImpl<$Res>
    implements _$EligibilityRuleCopyWith<$Res> {
  __$EligibilityRuleCopyWithImpl(this._self, this._then);

  final _EligibilityRule _self;
  final $Res Function(_EligibilityRule) _then;

/// Create a copy of EligibilityRule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ruleGroup = null,Object? attributeKey = null,Object? operator = null,Object? state = null,Object? label = null,Object? labelHi = freezed,Object? explanation = null,}) {
  return _then(_EligibilityRule(
ruleGroup: null == ruleGroup ? _self.ruleGroup : ruleGroup // ignore: cast_nullable_to_non_nullable
as RuleGroup,attributeKey: null == attributeKey ? _self.attributeKey : attributeKey // ignore: cast_nullable_to_non_nullable
as String,operator: null == operator ? _self.operator : operator // ignore: cast_nullable_to_non_nullable
as RuleOperator,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as EligibilityState,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,labelHi: freezed == labelHi ? _self.labelHi : labelHi // ignore: cast_nullable_to_non_nullable
as String?,explanation: null == explanation ? _self.explanation : explanation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Recommendation {

 String get schemeId; String get slug; String get name; String? get descriptionShort; String? get category;@JurisdictionConverter() Jurisdiction get jurisdiction; String? get stateCode;@SchemeTypeConverter() SchemeType get schemeType; double get score;@VerificationStatusConverter() VerificationStatus get verificationStatus; bool get needsReview; String? get officialUrl;@EligibilityStateConverter() EligibilityState get eligibilityState; List<EligibilityRule> get eligibilityRules;
/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationCopyWith<Recommendation> get copyWith => _$RecommendationCopyWithImpl<Recommendation>(this as Recommendation, _$identity);

  /// Serializes this Recommendation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Recommendation&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.descriptionShort, descriptionShort) || other.descriptionShort == descriptionShort)&&(identical(other.category, category) || other.category == category)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.score, score) || other.score == score)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl)&&(identical(other.eligibilityState, eligibilityState) || other.eligibilityState == eligibilityState)&&const DeepCollectionEquality().equals(other.eligibilityRules, eligibilityRules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemeId,slug,name,descriptionShort,category,jurisdiction,stateCode,schemeType,score,verificationStatus,needsReview,officialUrl,eligibilityState,const DeepCollectionEquality().hash(eligibilityRules));

@override
String toString() {
  return 'Recommendation(schemeId: $schemeId, slug: $slug, name: $name, descriptionShort: $descriptionShort, category: $category, jurisdiction: $jurisdiction, stateCode: $stateCode, schemeType: $schemeType, score: $score, verificationStatus: $verificationStatus, needsReview: $needsReview, officialUrl: $officialUrl, eligibilityState: $eligibilityState, eligibilityRules: $eligibilityRules)';
}


}

/// @nodoc
abstract mixin class $RecommendationCopyWith<$Res>  {
  factory $RecommendationCopyWith(Recommendation value, $Res Function(Recommendation) _then) = _$RecommendationCopyWithImpl;
@useResult
$Res call({
 String schemeId, String slug, String name, String? descriptionShort, String? category,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode,@SchemeTypeConverter() SchemeType schemeType, double score,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? officialUrl,@EligibilityStateConverter() EligibilityState eligibilityState, List<EligibilityRule> eligibilityRules
});




}
/// @nodoc
class _$RecommendationCopyWithImpl<$Res>
    implements $RecommendationCopyWith<$Res> {
  _$RecommendationCopyWithImpl(this._self, this._then);

  final Recommendation _self;
  final $Res Function(Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemeId = null,Object? slug = null,Object? name = null,Object? descriptionShort = freezed,Object? category = freezed,Object? jurisdiction = null,Object? stateCode = freezed,Object? schemeType = null,Object? score = null,Object? verificationStatus = null,Object? needsReview = null,Object? officialUrl = freezed,Object? eligibilityState = null,Object? eligibilityRules = null,}) {
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
as String?,eligibilityState: null == eligibilityState ? _self.eligibilityState : eligibilityState // ignore: cast_nullable_to_non_nullable
as EligibilityState,eligibilityRules: null == eligibilityRules ? _self.eligibilityRules : eligibilityRules // ignore: cast_nullable_to_non_nullable
as List<EligibilityRule>,
  ));
}

}


/// Adds pattern-matching-related methods to [Recommendation].
extension RecommendationPatterns on Recommendation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Recommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Recommendation value)  $default,){
final _that = this;
switch (_that) {
case _Recommendation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Recommendation value)?  $default,){
final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String schemeId,  String slug,  String name,  String? descriptionShort,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType,  double score, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl, @EligibilityStateConverter()  EligibilityState eligibilityState,  List<EligibilityRule> eligibilityRules)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.schemeId,_that.slug,_that.name,_that.descriptionShort,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.score,_that.verificationStatus,_that.needsReview,_that.officialUrl,_that.eligibilityState,_that.eligibilityRules);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String schemeId,  String slug,  String name,  String? descriptionShort,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType,  double score, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl, @EligibilityStateConverter()  EligibilityState eligibilityState,  List<EligibilityRule> eligibilityRules)  $default,) {final _that = this;
switch (_that) {
case _Recommendation():
return $default(_that.schemeId,_that.slug,_that.name,_that.descriptionShort,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.score,_that.verificationStatus,_that.needsReview,_that.officialUrl,_that.eligibilityState,_that.eligibilityRules);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String schemeId,  String slug,  String name,  String? descriptionShort,  String? category, @JurisdictionConverter()  Jurisdiction jurisdiction,  String? stateCode, @SchemeTypeConverter()  SchemeType schemeType,  double score, @VerificationStatusConverter()  VerificationStatus verificationStatus,  bool needsReview,  String? officialUrl, @EligibilityStateConverter()  EligibilityState eligibilityState,  List<EligibilityRule> eligibilityRules)?  $default,) {final _that = this;
switch (_that) {
case _Recommendation() when $default != null:
return $default(_that.schemeId,_that.slug,_that.name,_that.descriptionShort,_that.category,_that.jurisdiction,_that.stateCode,_that.schemeType,_that.score,_that.verificationStatus,_that.needsReview,_that.officialUrl,_that.eligibilityState,_that.eligibilityRules);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Recommendation implements Recommendation {
  const _Recommendation({required this.schemeId, required this.slug, required this.name, this.descriptionShort, this.category, @JurisdictionConverter() required this.jurisdiction, this.stateCode, @SchemeTypeConverter() required this.schemeType, required this.score, @VerificationStatusConverter() required this.verificationStatus, required this.needsReview, this.officialUrl, @EligibilityStateConverter() required this.eligibilityState, required final  List<EligibilityRule> eligibilityRules}): _eligibilityRules = eligibilityRules;
  factory _Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);

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
@override@EligibilityStateConverter() final  EligibilityState eligibilityState;
 final  List<EligibilityRule> _eligibilityRules;
@override List<EligibilityRule> get eligibilityRules {
  if (_eligibilityRules is EqualUnmodifiableListView) return _eligibilityRules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eligibilityRules);
}


/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationCopyWith<_Recommendation> get copyWith => __$RecommendationCopyWithImpl<_Recommendation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Recommendation&&(identical(other.schemeId, schemeId) || other.schemeId == schemeId)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.descriptionShort, descriptionShort) || other.descriptionShort == descriptionShort)&&(identical(other.category, category) || other.category == category)&&(identical(other.jurisdiction, jurisdiction) || other.jurisdiction == jurisdiction)&&(identical(other.stateCode, stateCode) || other.stateCode == stateCode)&&(identical(other.schemeType, schemeType) || other.schemeType == schemeType)&&(identical(other.score, score) || other.score == score)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.needsReview, needsReview) || other.needsReview == needsReview)&&(identical(other.officialUrl, officialUrl) || other.officialUrl == officialUrl)&&(identical(other.eligibilityState, eligibilityState) || other.eligibilityState == eligibilityState)&&const DeepCollectionEquality().equals(other._eligibilityRules, _eligibilityRules));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemeId,slug,name,descriptionShort,category,jurisdiction,stateCode,schemeType,score,verificationStatus,needsReview,officialUrl,eligibilityState,const DeepCollectionEquality().hash(_eligibilityRules));

@override
String toString() {
  return 'Recommendation(schemeId: $schemeId, slug: $slug, name: $name, descriptionShort: $descriptionShort, category: $category, jurisdiction: $jurisdiction, stateCode: $stateCode, schemeType: $schemeType, score: $score, verificationStatus: $verificationStatus, needsReview: $needsReview, officialUrl: $officialUrl, eligibilityState: $eligibilityState, eligibilityRules: $eligibilityRules)';
}


}

/// @nodoc
abstract mixin class _$RecommendationCopyWith<$Res> implements $RecommendationCopyWith<$Res> {
  factory _$RecommendationCopyWith(_Recommendation value, $Res Function(_Recommendation) _then) = __$RecommendationCopyWithImpl;
@override @useResult
$Res call({
 String schemeId, String slug, String name, String? descriptionShort, String? category,@JurisdictionConverter() Jurisdiction jurisdiction, String? stateCode,@SchemeTypeConverter() SchemeType schemeType, double score,@VerificationStatusConverter() VerificationStatus verificationStatus, bool needsReview, String? officialUrl,@EligibilityStateConverter() EligibilityState eligibilityState, List<EligibilityRule> eligibilityRules
});




}
/// @nodoc
class __$RecommendationCopyWithImpl<$Res>
    implements _$RecommendationCopyWith<$Res> {
  __$RecommendationCopyWithImpl(this._self, this._then);

  final _Recommendation _self;
  final $Res Function(_Recommendation) _then;

/// Create a copy of Recommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemeId = null,Object? slug = null,Object? name = null,Object? descriptionShort = freezed,Object? category = freezed,Object? jurisdiction = null,Object? stateCode = freezed,Object? schemeType = null,Object? score = null,Object? verificationStatus = null,Object? needsReview = null,Object? officialUrl = freezed,Object? eligibilityState = null,Object? eligibilityRules = null,}) {
  return _then(_Recommendation(
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
as String?,eligibilityState: null == eligibilityState ? _self.eligibilityState : eligibilityState // ignore: cast_nullable_to_non_nullable
as EligibilityState,eligibilityRules: null == eligibilityRules ? _self._eligibilityRules : eligibilityRules // ignore: cast_nullable_to_non_nullable
as List<EligibilityRule>,
  ));
}


}


/// @nodoc
mixin _$RecommendationResponse {

 String get query; bool get profileProvided; int get totalReturned; Map<String, int> get eligibilityBreakdown; List<Recommendation> get recommendations;
/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecommendationResponseCopyWith<RecommendationResponse> get copyWith => _$RecommendationResponseCopyWithImpl<RecommendationResponse>(this as RecommendationResponse, _$identity);

  /// Serializes this RecommendationResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecommendationResponse&&(identical(other.query, query) || other.query == query)&&(identical(other.profileProvided, profileProvided) || other.profileProvided == profileProvided)&&(identical(other.totalReturned, totalReturned) || other.totalReturned == totalReturned)&&const DeepCollectionEquality().equals(other.eligibilityBreakdown, eligibilityBreakdown)&&const DeepCollectionEquality().equals(other.recommendations, recommendations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,profileProvided,totalReturned,const DeepCollectionEquality().hash(eligibilityBreakdown),const DeepCollectionEquality().hash(recommendations));

@override
String toString() {
  return 'RecommendationResponse(query: $query, profileProvided: $profileProvided, totalReturned: $totalReturned, eligibilityBreakdown: $eligibilityBreakdown, recommendations: $recommendations)';
}


}

/// @nodoc
abstract mixin class $RecommendationResponseCopyWith<$Res>  {
  factory $RecommendationResponseCopyWith(RecommendationResponse value, $Res Function(RecommendationResponse) _then) = _$RecommendationResponseCopyWithImpl;
@useResult
$Res call({
 String query, bool profileProvided, int totalReturned, Map<String, int> eligibilityBreakdown, List<Recommendation> recommendations
});




}
/// @nodoc
class _$RecommendationResponseCopyWithImpl<$Res>
    implements $RecommendationResponseCopyWith<$Res> {
  _$RecommendationResponseCopyWithImpl(this._self, this._then);

  final RecommendationResponse _self;
  final $Res Function(RecommendationResponse) _then;

/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = null,Object? profileProvided = null,Object? totalReturned = null,Object? eligibilityBreakdown = null,Object? recommendations = null,}) {
  return _then(_self.copyWith(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,profileProvided: null == profileProvided ? _self.profileProvided : profileProvided // ignore: cast_nullable_to_non_nullable
as bool,totalReturned: null == totalReturned ? _self.totalReturned : totalReturned // ignore: cast_nullable_to_non_nullable
as int,eligibilityBreakdown: null == eligibilityBreakdown ? _self.eligibilityBreakdown : eligibilityBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, int>,recommendations: null == recommendations ? _self.recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as List<Recommendation>,
  ));
}

}


/// Adds pattern-matching-related methods to [RecommendationResponse].
extension RecommendationResponsePatterns on RecommendationResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecommendationResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecommendationResponse value)  $default,){
final _that = this;
switch (_that) {
case _RecommendationResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecommendationResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String query,  bool profileProvided,  int totalReturned,  Map<String, int> eligibilityBreakdown,  List<Recommendation> recommendations)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
return $default(_that.query,_that.profileProvided,_that.totalReturned,_that.eligibilityBreakdown,_that.recommendations);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String query,  bool profileProvided,  int totalReturned,  Map<String, int> eligibilityBreakdown,  List<Recommendation> recommendations)  $default,) {final _that = this;
switch (_that) {
case _RecommendationResponse():
return $default(_that.query,_that.profileProvided,_that.totalReturned,_that.eligibilityBreakdown,_that.recommendations);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String query,  bool profileProvided,  int totalReturned,  Map<String, int> eligibilityBreakdown,  List<Recommendation> recommendations)?  $default,) {final _that = this;
switch (_that) {
case _RecommendationResponse() when $default != null:
return $default(_that.query,_that.profileProvided,_that.totalReturned,_that.eligibilityBreakdown,_that.recommendations);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecommendationResponse implements RecommendationResponse {
  const _RecommendationResponse({required this.query, required this.profileProvided, required this.totalReturned, required final  Map<String, int> eligibilityBreakdown, required final  List<Recommendation> recommendations}): _eligibilityBreakdown = eligibilityBreakdown,_recommendations = recommendations;
  factory _RecommendationResponse.fromJson(Map<String, dynamic> json) => _$RecommendationResponseFromJson(json);

@override final  String query;
@override final  bool profileProvided;
@override final  int totalReturned;
 final  Map<String, int> _eligibilityBreakdown;
@override Map<String, int> get eligibilityBreakdown {
  if (_eligibilityBreakdown is EqualUnmodifiableMapView) return _eligibilityBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_eligibilityBreakdown);
}

 final  List<Recommendation> _recommendations;
@override List<Recommendation> get recommendations {
  if (_recommendations is EqualUnmodifiableListView) return _recommendations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_recommendations);
}


/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecommendationResponseCopyWith<_RecommendationResponse> get copyWith => __$RecommendationResponseCopyWithImpl<_RecommendationResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecommendationResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecommendationResponse&&(identical(other.query, query) || other.query == query)&&(identical(other.profileProvided, profileProvided) || other.profileProvided == profileProvided)&&(identical(other.totalReturned, totalReturned) || other.totalReturned == totalReturned)&&const DeepCollectionEquality().equals(other._eligibilityBreakdown, _eligibilityBreakdown)&&const DeepCollectionEquality().equals(other._recommendations, _recommendations));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,query,profileProvided,totalReturned,const DeepCollectionEquality().hash(_eligibilityBreakdown),const DeepCollectionEquality().hash(_recommendations));

@override
String toString() {
  return 'RecommendationResponse(query: $query, profileProvided: $profileProvided, totalReturned: $totalReturned, eligibilityBreakdown: $eligibilityBreakdown, recommendations: $recommendations)';
}


}

/// @nodoc
abstract mixin class _$RecommendationResponseCopyWith<$Res> implements $RecommendationResponseCopyWith<$Res> {
  factory _$RecommendationResponseCopyWith(_RecommendationResponse value, $Res Function(_RecommendationResponse) _then) = __$RecommendationResponseCopyWithImpl;
@override @useResult
$Res call({
 String query, bool profileProvided, int totalReturned, Map<String, int> eligibilityBreakdown, List<Recommendation> recommendations
});




}
/// @nodoc
class __$RecommendationResponseCopyWithImpl<$Res>
    implements _$RecommendationResponseCopyWith<$Res> {
  __$RecommendationResponseCopyWithImpl(this._self, this._then);

  final _RecommendationResponse _self;
  final $Res Function(_RecommendationResponse) _then;

/// Create a copy of RecommendationResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = null,Object? profileProvided = null,Object? totalReturned = null,Object? eligibilityBreakdown = null,Object? recommendations = null,}) {
  return _then(_RecommendationResponse(
query: null == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String,profileProvided: null == profileProvided ? _self.profileProvided : profileProvided // ignore: cast_nullable_to_non_nullable
as bool,totalReturned: null == totalReturned ? _self.totalReturned : totalReturned // ignore: cast_nullable_to_non_nullable
as int,eligibilityBreakdown: null == eligibilityBreakdown ? _self._eligibilityBreakdown : eligibilityBreakdown // ignore: cast_nullable_to_non_nullable
as Map<String, int>,recommendations: null == recommendations ? _self._recommendations : recommendations // ignore: cast_nullable_to_non_nullable
as List<Recommendation>,
  ));
}


}

// dart format on
