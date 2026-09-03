import '../../recommendations/domain/recommendation.dart';

/// Optional navigation payload for Scheme Detail -- carries real
/// eligibility rules when the screen is reached from an eligibility-aware
/// context (For You's results, Home's "Picked for you", both built on
/// RecommendationCard). Reached from Explore (plain search, no
/// eligibility concept -- `SearchResultOut` has no `eligibility_state`
/// field at all) or the Assistant's evidence (a different wire shape
/// without per-rule detail), this is simply absent -- the detail screen
/// omits "Why this looks promising"/"Eligibility, explained" rather than
/// fabricating rules it was never given.
class SchemeDetailArgs {
  const SchemeDetailArgs({this.eligibilityRules, this.scrollToEligibility = false});

  final List<EligibilityRule>? eligibilityRules;

  /// True for the "See eligibility" CTA (jumps straight to the
  /// eligibility section); false for "Details" (lands at the top). Both
  /// carry the same rules either way -- only the initial scroll position
  /// differs.
  final bool scrollToEligibility;
}
