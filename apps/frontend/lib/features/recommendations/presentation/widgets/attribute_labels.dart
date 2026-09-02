import '../../domain/eligibility_attribute.dart';

/// Human-readable prompts for the profile form. Kept separate from
/// [EligibilityAttribute] itself so relabeling copy never touches the part
/// of the code that has to match the backend's wire vocabulary.
String attributeLabel(EligibilityAttribute attribute) => switch (attribute) {
  EligibilityAttribute.age => 'Age',
  EligibilityAttribute.isWoman => 'Are you a woman?',
  EligibilityAttribute.isScSt => 'Are you SC/ST?',
  EligibilityAttribute.isObc => 'Are you OBC?',
  EligibilityAttribute.isMinority => 'Do you belong to a religious minority?',
  EligibilityAttribute.isDivyang => 'Do you have a disability (Divyang)?',
  EligibilityAttribute.annualIncome => 'Annual household income (₹)',
  EligibilityAttribute.isEws => 'Do you hold an EWS certificate?',
  EligibilityAttribute.isLig => 'Are you in the Low Income Group (LIG)?',
  EligibilityAttribute.isMig => 'Are you in the Middle Income Group (MIG)?',
  EligibilityAttribute.hasBplCard => 'Do you have a BPL card?',
  EligibilityAttribute.hasYellowRationCard => 'Do you have a yellow ration card?',
  EligibilityAttribute.hasOrangeRationCard => 'Do you have an orange ration card?',
  EligibilityAttribute.isTaxpayer => 'Do you pay income tax?',
  EligibilityAttribute.isPensionerAbove10k => 'Do you receive a pension above ₹10,000?',
  EligibilityAttribute.isFarmer => 'Are you a farmer?',
  EligibilityAttribute.ownsCultivableLand => 'Do you own cultivable land?',
  EligibilityAttribute.isMgnregaWorker => 'Are you an MGNREGA worker?',
  EligibilityAttribute.isUnorganizedWorker => 'Do you work in the unorganized sector?',
  EligibilityAttribute.hasEshramCard => 'Do you have an e-Shram card?',
  EligibilityAttribute.isGovtEmployee => 'Are you a government employee?',
  EligibilityAttribute.isStudent => 'Are you a student?',
  EligibilityAttribute.hasBusinessPlan => 'Do you have a business plan?',
  EligibilityAttribute.isRural => 'Do you live in a rural area?',
  EligibilityAttribute.noPuccaHouse => 'Do you lack a pucca (permanent) house?',
  EligibilityAttribute.stateCode => 'State/UT code',
  EligibilityAttribute.isPregnantOrLactating => 'Are you pregnant or lactating?',
};
