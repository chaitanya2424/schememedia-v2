import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'scheme_detail.freezed.dart';
part 'scheme_detail.g.dart';

/// Mirrors `BenefitOut`.
@freezed
sealed class Benefit with _$Benefit {
  const factory Benefit({
    String? stage,
    required String amountText,
    double? amountNumeric,
    required String currency,
    required bool isTruncated,
  }) = _Benefit;

  factory Benefit.fromJson(Map<String, dynamic> json) => _$BenefitFromJson(json);
}

/// Mirrors `DocumentOut`.
@freezed
sealed class SchemeDocument with _$SchemeDocument {
  const factory SchemeDocument({
    required String name,
    required bool isMandatory,
    required bool needsReview,
  }) = _SchemeDocument;

  factory SchemeDocument.fromJson(Map<String, dynamic> json) => _$SchemeDocumentFromJson(json);
}

/// Mirrors `SchemeDetailOut` (api/v1/routers/schemes.py).
@freezed
sealed class SchemeDetail with _$SchemeDetail {
  const factory SchemeDetail({
    required String schemeId,
    required String slug,
    required String name,
    String? nameHi,
    String? ministry,
    String? category,
    @SchemeTypeConverter() required SchemeType schemeType,
    @JurisdictionConverter() required Jurisdiction jurisdiction,
    String? stateCode,
    String? descriptionShort,
    String? descriptionLong,
    String? officialUrl,
    String? applicationDeadline,
    @VerificationStatusConverter() required VerificationStatus verificationStatus,
    required bool needsReview,
    String? lastVerifiedAt,
    required List<String> tags,
    required List<Benefit> benefits,
    required List<SchemeDocument> documents,
    required int likeCount,
    required int saveCount,
    required int commentCount,
    double? averageRating,
  }) = _SchemeDetail;

  factory SchemeDetail.fromJson(Map<String, dynamic> json) => _$SchemeDetailFromJson(json);
}
