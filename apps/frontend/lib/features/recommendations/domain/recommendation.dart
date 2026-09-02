import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'recommendation.freezed.dart';
part 'recommendation.g.dart';

/// Mirrors `RuleEvaluationOut`.
@freezed
sealed class EligibilityRule with _$EligibilityRule {
  const factory EligibilityRule({
    @RuleGroupConverter() required RuleGroup ruleGroup,
    required String attributeKey,
    @RuleOperatorConverter() required RuleOperator operator,
    @EligibilityStateConverter() required EligibilityState state,
    required String label,
    String? labelHi,
    required String explanation,
  }) = _EligibilityRule;

  factory EligibilityRule.fromJson(Map<String, dynamic> json) => _$EligibilityRuleFromJson(json);
}

/// Mirrors `RecommendationOut`.
@freezed
sealed class Recommendation with _$Recommendation {
  const factory Recommendation({
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
    @EligibilityStateConverter() required EligibilityState eligibilityState,
    required List<EligibilityRule> eligibilityRules,
  }) = _Recommendation;

  factory Recommendation.fromJson(Map<String, dynamic> json) => _$RecommendationFromJson(json);
}

/// Mirrors `RecommendationResponseOut`.
@freezed
sealed class RecommendationResponse with _$RecommendationResponse {
  const factory RecommendationResponse({
    required String query,
    required bool profileProvided,
    required int totalReturned,
    required Map<String, int> eligibilityBreakdown,
    required List<Recommendation> recommendations,
  }) = _RecommendationResponse;

  factory RecommendationResponse.fromJson(Map<String, dynamic> json) =>
      _$RecommendationResponseFromJson(json);
}
