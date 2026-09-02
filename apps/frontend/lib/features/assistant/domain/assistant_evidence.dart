import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/domain/enums.dart';

part 'assistant_evidence.freezed.dart';
part 'assistant_evidence.g.dart';

/// Mirrors `EvidenceResultOut`.
@freezed
sealed class EvidenceResult with _$EvidenceResult {
  const factory EvidenceResult({
    required String schemeId,
    required String name,
    String? category,
    @JurisdictionConverter() required Jurisdiction jurisdiction,
    String? stateCode,
    @SchemeTypeConverter() required SchemeType schemeType,
    @EligibilityStateConverter() required EligibilityState eligibilityState,
    required List<String> eligibilityExplanations,
    required List<String> missingAttributes,
    @VerificationStatusConverter() required VerificationStatus verificationStatus,
    required bool needsReview,
    String? officialUrl,
  }) = _EvidenceResult;

  factory EvidenceResult.fromJson(Map<String, dynamic> json) => _$EvidenceResultFromJson(json);
}

/// Mirrors `EvidenceOut` -- exactly what the model was shown, present so
/// the UI can render a "sources" section a user can verify the reply
/// against, not just trust it.
@freezed
sealed class AssistantEvidence with _$AssistantEvidence {
  const factory AssistantEvidence({
    required String query,
    required bool profileProvided,
    required int totalReturned,
    required Map<String, int> eligibilityBreakdown,
    required List<EvidenceResult> results,
  }) = _AssistantEvidence;

  factory AssistantEvidence.fromJson(Map<String, dynamic> json) =>
      _$AssistantEvidenceFromJson(json);
}
