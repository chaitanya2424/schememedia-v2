// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'assistant_evidence.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EvidenceResult _$EvidenceResultFromJson(Map<String, dynamic> json) =>
    _EvidenceResult(
      schemeId: json['scheme_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      jurisdiction: const JurisdictionConverter().fromJson(
        json['jurisdiction'] as String,
      ),
      stateCode: json['state_code'] as String?,
      schemeType: const SchemeTypeConverter().fromJson(
        json['scheme_type'] as String,
      ),
      eligibilityState: const EligibilityStateConverter().fromJson(
        json['eligibility_state'] as String,
      ),
      eligibilityExplanations:
          (json['eligibility_explanations'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      missingAttributes: (json['missing_attributes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      verificationStatus: const VerificationStatusConverter().fromJson(
        json['verification_status'] as String,
      ),
      needsReview: json['needs_review'] as bool,
      officialUrl: json['official_url'] as String?,
    );

Map<String, dynamic> _$EvidenceResultToJson(
  _EvidenceResult instance,
) => <String, dynamic>{
  'scheme_id': instance.schemeId,
  'name': instance.name,
  'category': instance.category,
  'jurisdiction': const JurisdictionConverter().toJson(instance.jurisdiction),
  'state_code': instance.stateCode,
  'scheme_type': const SchemeTypeConverter().toJson(instance.schemeType),
  'eligibility_state': const EligibilityStateConverter().toJson(
    instance.eligibilityState,
  ),
  'eligibility_explanations': instance.eligibilityExplanations,
  'missing_attributes': instance.missingAttributes,
  'verification_status': const VerificationStatusConverter().toJson(
    instance.verificationStatus,
  ),
  'needs_review': instance.needsReview,
  'official_url': instance.officialUrl,
};

_AssistantEvidence _$AssistantEvidenceFromJson(Map<String, dynamic> json) =>
    _AssistantEvidence(
      query: json['query'] as String,
      profileProvided: json['profile_provided'] as bool,
      totalReturned: (json['total_returned'] as num).toInt(),
      eligibilityBreakdown: Map<String, int>.from(
        json['eligibility_breakdown'] as Map,
      ),
      results: (json['results'] as List<dynamic>)
          .map((e) => EvidenceResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AssistantEvidenceToJson(_AssistantEvidence instance) =>
    <String, dynamic>{
      'query': instance.query,
      'profile_provided': instance.profileProvided,
      'total_returned': instance.totalReturned,
      'eligibility_breakdown': instance.eligibilityBreakdown,
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
