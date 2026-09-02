// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SchemeSummary _$SchemeSummaryFromJson(Map<String, dynamic> json) =>
    _SchemeSummary(
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
    );

Map<String, dynamic> _$SchemeSummaryToJson(
  _SchemeSummary instance,
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
};

_SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    _SearchResponse(
      query: json['query'] as String,
      totalReturned: (json['total_returned'] as num).toInt(),
      verificationBreakdown: Map<String, int>.from(
        json['verification_breakdown'] as Map,
      ),
      results: (json['results'] as List<dynamic>)
          .map((e) => SchemeSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SearchResponseToJson(_SearchResponse instance) =>
    <String, dynamic>{
      'query': instance.query,
      'total_returned': instance.totalReturned,
      'verification_breakdown': instance.verificationBreakdown,
      'results': instance.results.map((e) => e.toJson()).toList(),
    };
