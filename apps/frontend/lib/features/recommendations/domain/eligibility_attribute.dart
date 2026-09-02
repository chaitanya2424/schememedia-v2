/// Mirrors `EligibilityAttribute` (db/models/enums.py) -- the ~26-key
/// vocabulary accepted by `/recommendations`' `profile` object and
/// implicitly extracted by the assistant. Every key is optional; unknown
/// keys are ignored server-side, never an error.
///
/// Grouped the same way the backend's own comments group them, for the
/// future profile form (build-order screen 4).
enum EligibilityAttribute {
  // Demographic
  age('age', AttributeKind.numeric),
  isWoman('is_woman', AttributeKind.boolean),
  isScSt('is_sc_st', AttributeKind.boolean),
  isObc('is_obc', AttributeKind.boolean),
  isMinority('is_minority', AttributeKind.boolean),
  isDivyang('is_divyang', AttributeKind.boolean),

  // Economic
  annualIncome('annual_income', AttributeKind.numeric),
  isEws('is_ews', AttributeKind.boolean),
  isLig('is_lig', AttributeKind.boolean),
  isMig('is_mig', AttributeKind.boolean),
  hasBplCard('has_bpl_card', AttributeKind.boolean),
  hasYellowRationCard('has_yellow_ration_card', AttributeKind.boolean),
  hasOrangeRationCard('has_orange_ration_card', AttributeKind.boolean),
  isTaxpayer('is_taxpayer', AttributeKind.boolean),
  isPensionerAbove10k('is_pensioner_above_10k', AttributeKind.boolean),

  // Occupation
  isFarmer('is_farmer', AttributeKind.boolean),
  ownsCultivableLand('owns_cultivable_land', AttributeKind.boolean),
  isMgnregaWorker('is_mgnrega_worker', AttributeKind.boolean),
  isUnorganizedWorker('is_unorganized_worker', AttributeKind.boolean),
  hasEshramCard('has_eshram_card', AttributeKind.boolean),
  isGovtEmployee('is_govt_employee', AttributeKind.boolean),
  isStudent('is_student', AttributeKind.boolean),
  hasBusinessPlan('has_business_plan', AttributeKind.boolean),

  // Housing / location
  isRural('is_rural', AttributeKind.boolean),
  noPuccaHouse('no_pucca_house', AttributeKind.boolean),
  stateCode('state_code', AttributeKind.text),

  // Health
  isPregnantOrLactating('is_pregnant_or_lactating', AttributeKind.boolean);

  const EligibilityAttribute(this.wireKey, this.kind);

  final String wireKey;
  final AttributeKind kind;
}

enum AttributeKind { boolean, numeric, text }
