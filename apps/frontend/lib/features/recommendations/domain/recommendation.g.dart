// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommendation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EligibilityRule _$EligibilityRuleFromJson(
  Map<String, dynamic> json,
) => _EligibilityRule(
  ruleGroup: const RuleGroupConverter().fromJson(json['rule_group'] as String),
  attributeKey: json['attribute_key'] as String,
  operator: const RuleOperatorConverter().fromJson(json['operator'] as String),
  state: const EligibilityStateConverter().fromJson(json['state'] as String),
  label: json['label'] as String,
  labelHi: json['label_hi'] as String?,
  explanation: json['explanation'] as String,
);

Map<String, dynamic> _$EligibilityRuleToJson(_EligibilityRule instance) =>
    <String, dynamic>{
      'rule_group': const RuleGroupConverter().toJson(instance.ruleGroup),
      'attribute_key': instance.attributeKey,
      'operator': const RuleOperatorConverter().toJson(instance.operator),
      'state': const EligibilityStateConverter().toJson(instance.state),
      'label': instance.label,
      'label_hi': instance.labelHi,
      'explanation': instance.explanation,
    };

_Recommendation _$RecommendationFromJson(Map<String, dynamic> json) =>
    _Recommendation(
      schemeId: json['scheme_id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      descriptionShort: json['description_short'] as String?,
      category: json['category'] as String?,
      jurisdiction: const JurisdictionConverter().fromJson(
        json['jurisdiction'] as String,
      ),
      stateCode: json['state_code'] as String?,
      schemeType: const SchemeTypeConverter().fromJson(
        json['scheme_type'] as String,
      ),
      score: (json['score'] as num).toDouble(),
      verificationStatus: const VerificationStatusConverter().fromJson(
        json['verification_status'] as String,
      ),
      needsReview: json['needs_review'] as bool,
      officialUrl: json['official_url'] as String?,
      eligibilityState: const EligibilityStateConverter().fromJson(
        json['eligibility_state'] as String,
      ),
      eligibilityRules: (json['eligibility_rules'] as List<dynamic>)
          .map((e) => EligibilityRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$RecommendationToJson(
  _Recommendation instance,
) => <String, dynamic>{
  'scheme_id': instance.schemeId,
  'slug': instance.slug,
  'name': instance.name,
  'description_short': instance.descriptionShort,
  'category': instance.category,
  'jurisdiction': const JurisdictionConverter().toJson(instance.jurisdiction),
  'state_code': instance.stateCode,
  'scheme_type': const SchemeTypeConverter().toJson(instance.schemeType),
  'score': instance.score,
  'verification_status': const VerificationStatusConverter().toJson(
    instance.verificationStatus,
  ),
  'needs_review': instance.needsReview,
  'official_url': instance.officialUrl,
  'eligibility_state': const EligibilityStateConverter().toJson(
    instance.eligibilityState,
  ),
  'eligibility_rules': instance.eligibilityRules
      .map((e) => e.toJson())
      .toList(),
};

_RecommendationResponse _$RecommendationResponseFromJson(
  Map<String, dynamic> json,
) => _RecommendationResponse(
  query: json['query'] as String,
  profileProvided: json['profile_provided'] as bool,
  totalReturned: (json['total_returned'] as num).toInt(),
  eligibilityBreakdown: Map<String, int>.from(
    json['eligibility_breakdown'] as Map,
  ),
  recommendations: (json['recommendations'] as List<dynamic>)
      .map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$RecommendationResponseToJson(
  _RecommendationResponse instance,
) => <String, dynamic>{
  'query': instance.query,
  'profile_provided': instance.profileProvided,
  'total_returned': instance.totalReturned,
  'eligibility_breakdown': instance.eligibilityBreakdown,
  'recommendations': instance.recommendations.map((e) => e.toJson()).toList(),
};
