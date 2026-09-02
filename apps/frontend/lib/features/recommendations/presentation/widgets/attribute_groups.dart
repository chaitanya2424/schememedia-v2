import '../../domain/eligibility_attribute.dart';

/// UI grouping for the profile form -- mirrors the grouping already present
/// as comments on `EligibilityAttribute` (db/models/enums.py): Demographic,
/// Economic, Occupation, Housing/location, Health.
class AttributeGroup {
  const AttributeGroup(this.title, this.attributes);

  final String title;
  final List<EligibilityAttribute> attributes;
}

const kAttributeGroups = [
  AttributeGroup('Demographic', [
    EligibilityAttribute.age,
    EligibilityAttribute.isWoman,
    EligibilityAttribute.isScSt,
    EligibilityAttribute.isObc,
    EligibilityAttribute.isMinority,
    EligibilityAttribute.isDivyang,
  ]),
  AttributeGroup('Economic', [
    EligibilityAttribute.annualIncome,
    EligibilityAttribute.isEws,
    EligibilityAttribute.isLig,
    EligibilityAttribute.isMig,
    EligibilityAttribute.hasBplCard,
    EligibilityAttribute.hasYellowRationCard,
    EligibilityAttribute.hasOrangeRationCard,
    EligibilityAttribute.isTaxpayer,
    EligibilityAttribute.isPensionerAbove10k,
  ]),
  AttributeGroup('Occupation', [
    EligibilityAttribute.isFarmer,
    EligibilityAttribute.ownsCultivableLand,
    EligibilityAttribute.isMgnregaWorker,
    EligibilityAttribute.isUnorganizedWorker,
    EligibilityAttribute.hasEshramCard,
    EligibilityAttribute.isGovtEmployee,
    EligibilityAttribute.isStudent,
    EligibilityAttribute.hasBusinessPlan,
  ]),
  AttributeGroup('Housing & location', [
    EligibilityAttribute.isRural,
    EligibilityAttribute.noPuccaHouse,
    EligibilityAttribute.stateCode,
  ]),
  AttributeGroup('Health', [EligibilityAttribute.isPregnantOrLactating]),
];
