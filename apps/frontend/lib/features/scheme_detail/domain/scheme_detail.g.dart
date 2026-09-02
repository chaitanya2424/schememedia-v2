// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scheme_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Benefit _$BenefitFromJson(Map<String, dynamic> json) => _Benefit(
  stage: json['stage'] as String?,
  amountText: json['amount_text'] as String,
  amountNumeric: (json['amount_numeric'] as num?)?.toDouble(),
  currency: json['currency'] as String,
  isTruncated: json['is_truncated'] as bool,
);

Map<String, dynamic> _$BenefitToJson(_Benefit instance) => <String, dynamic>{
  'stage': instance.stage,
  'amount_text': instance.amountText,
  'amount_numeric': instance.amountNumeric,
  'currency': instance.currency,
  'is_truncated': instance.isTruncated,
};

_SchemeDocument _$SchemeDocumentFromJson(Map<String, dynamic> json) =>
    _SchemeDocument(
      name: json['name'] as String,
      isMandatory: json['is_mandatory'] as bool,
      needsReview: json['needs_review'] as bool,
    );

Map<String, dynamic> _$SchemeDocumentToJson(_SchemeDocument instance) =>
    <String, dynamic>{
      'name': instance.name,
      'is_mandatory': instance.isMandatory,
      'needs_review': instance.needsReview,
    };

_SchemeDetail _$SchemeDetailFromJson(Map<String, dynamic> json) =>
    _SchemeDetail(
      schemeId: json['scheme_id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      nameHi: json['name_hi'] as String?,
      ministry: json['ministry'] as String?,
      category: json['category'] as String?,
      schemeType: const SchemeTypeConverter().fromJson(
        json['scheme_type'] as String,
      ),
      jurisdiction: const JurisdictionConverter().fromJson(
        json['jurisdiction'] as String,
      ),
      stateCode: json['state_code'] as String?,
      descriptionShort: json['description_short'] as String?,
      descriptionLong: json['description_long'] as String?,
      officialUrl: json['official_url'] as String?,
      applicationDeadline: json['application_deadline'] as String?,
      verificationStatus: const VerificationStatusConverter().fromJson(
        json['verification_status'] as String,
      ),
      needsReview: json['needs_review'] as bool,
      lastVerifiedAt: json['last_verified_at'] as String?,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
      benefits: (json['benefits'] as List<dynamic>)
          .map((e) => Benefit.fromJson(e as Map<String, dynamic>))
          .toList(),
      documents: (json['documents'] as List<dynamic>)
          .map((e) => SchemeDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      likeCount: (json['like_count'] as num).toInt(),
      saveCount: (json['save_count'] as num).toInt(),
      commentCount: (json['comment_count'] as num).toInt(),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SchemeDetailToJson(
  _SchemeDetail instance,
) => <String, dynamic>{
  'scheme_id': instance.schemeId,
  'slug': instance.slug,
  'name': instance.name,
  'name_hi': instance.nameHi,
  'ministry': instance.ministry,
  'category': instance.category,
  'scheme_type': const SchemeTypeConverter().toJson(instance.schemeType),
  'jurisdiction': const JurisdictionConverter().toJson(instance.jurisdiction),
  'state_code': instance.stateCode,
  'description_short': instance.descriptionShort,
  'description_long': instance.descriptionLong,
  'official_url': instance.officialUrl,
  'application_deadline': instance.applicationDeadline,
  'verification_status': const VerificationStatusConverter().toJson(
    instance.verificationStatus,
  ),
  'needs_review': instance.needsReview,
  'last_verified_at': instance.lastVerifiedAt,
  'tags': instance.tags,
  'benefits': instance.benefits.map((e) => e.toJson()).toList(),
  'documents': instance.documents.map((e) => e.toJson()).toList(),
  'like_count': instance.likeCount,
  'save_count': instance.saveCount,
  'comment_count': instance.commentCount,
  'average_rating': instance.averageRating,
};
