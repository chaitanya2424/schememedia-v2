import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'scheme_summary.freezed.dart';
part 'scheme_summary.g.dart';

/// Mirrors `SearchResultOut` (api/v1/routers/search.py). Wire-string enums
/// are already resolved to Dart enums here via the converters in
/// core/domain/enums.dart -- per the plan's model-mapping pragmatism note,
/// this thin, converted model *is* the domain entity; no raw JSON or wire
/// string crosses into `presentation/`.
@freezed
sealed class SchemeSummary with _$SchemeSummary {
  const factory SchemeSummary({
    required String schemeId,
    required String slug,
    required String name,
    String? descriptionShort,
    String? category,
    @JurisdictionConverter() required Jurisdiction jurisdiction,
    String? stateCode,
    @SchemeTypeConverter() required SchemeType schemeType,
    required double score,
    @VerificationStatusConverter() required VerificationStatus verificationStatus,
    required bool needsReview,
    String? officialUrl,
  }) = _SchemeSummary;

  factory SchemeSummary.fromJson(Map<String, dynamic> json) => _$SchemeSummaryFromJson(json);
}

/// Mirrors `SearchResponseOut`.
@freezed
sealed class SearchResponse with _$SearchResponse {
  const factory SearchResponse({
    required String query,
    required int totalReturned,
    required Map<String, int> verificationBreakdown,
    required List<SchemeSummary> results,
  }) = _SearchResponse;

  factory SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);
}
