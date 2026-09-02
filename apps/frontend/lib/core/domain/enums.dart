/// Wire enums shared by every feature's models -- the six closed
/// vocabularies documented in the backend's `api/v1/schemas/common.py`
/// (VerificationStatusOut, EligibilityStateOut, JurisdictionOut,
/// SchemeTypeOut, RuleGroupOut, RuleOperatorOut). Kept in one place, not
/// duplicated per feature, because VerificationStatus and EligibilityState
/// already each appear in Search, Recommendations, SchemeDetail, and
/// Assistant evidence.
///
/// Every enum carries an `unrecognized` fallback, decoded by the matching
/// [JsonConverter] below. This is what makes a future backend enum
/// addition degrade gracefully in an already-installed app build instead of
/// crashing JSON parsing outright.
library;

import 'package:json_annotation/json_annotation.dart';

enum VerificationStatus { unverified, sourceProvided, officiallyVerified, unrecognized }

class VerificationStatusConverter implements JsonConverter<VerificationStatus, String> {
  const VerificationStatusConverter();

  @override
  VerificationStatus fromJson(String json) => switch (json) {
    'unverified' => VerificationStatus.unverified,
    'source_provided' => VerificationStatus.sourceProvided,
    'officially_verified' => VerificationStatus.officiallyVerified,
    _ => VerificationStatus.unrecognized,
  };

  @override
  String toJson(VerificationStatus object) => switch (object) {
    VerificationStatus.unverified => 'unverified',
    VerificationStatus.sourceProvided => 'source_provided',
    VerificationStatus.officiallyVerified => 'officially_verified',
    VerificationStatus.unrecognized => 'unverified',
  };
}

/// Never treat `unknown` as a failure: it means "we don't have enough
/// profile information," not "you don't qualify" -- see
/// services/eligibility_matcher.py on the backend. Note this is a distinct
/// concept from [unrecognized] below, which means "a wire value this build
/// doesn't recognize at all."
enum EligibilityState { pass, fail, unknown, notApplicable, unrecognized }

class EligibilityStateConverter implements JsonConverter<EligibilityState, String> {
  const EligibilityStateConverter();

  @override
  EligibilityState fromJson(String json) => switch (json) {
    'pass' => EligibilityState.pass,
    'fail' => EligibilityState.fail,
    'unknown' => EligibilityState.unknown,
    'not_applicable' => EligibilityState.notApplicable,
    _ => EligibilityState.unrecognized,
  };

  @override
  String toJson(EligibilityState object) => switch (object) {
    EligibilityState.pass => 'pass',
    EligibilityState.fail => 'fail',
    EligibilityState.unknown => 'unknown',
    EligibilityState.notApplicable => 'not_applicable',
    EligibilityState.unrecognized => 'unknown',
  };
}

enum Jurisdiction { central, state, unrecognized }

class JurisdictionConverter implements JsonConverter<Jurisdiction, String> {
  const JurisdictionConverter();

  @override
  Jurisdiction fromJson(String json) => switch (json) {
    'central' => Jurisdiction.central,
    'state' => Jurisdiction.state,
    _ => Jurisdiction.unrecognized,
  };

  @override
  String toJson(Jurisdiction object) => switch (object) {
    Jurisdiction.central => 'central',
    Jurisdiction.state => 'state',
    Jurisdiction.unrecognized => 'central',
  };
}

enum SchemeType {
  subsidy,
  scholarship,
  loan,
  pension,
  insurance,
  training,
  award,
  grant,
  other,
  unrecognized,
}

class SchemeTypeConverter implements JsonConverter<SchemeType, String> {
  const SchemeTypeConverter();

  static const _wire = {
    'subsidy': SchemeType.subsidy,
    'scholarship': SchemeType.scholarship,
    'loan': SchemeType.loan,
    'pension': SchemeType.pension,
    'insurance': SchemeType.insurance,
    'training': SchemeType.training,
    'award': SchemeType.award,
    'grant': SchemeType.grant,
    'other': SchemeType.other,
  };

  @override
  SchemeType fromJson(String json) => _wire[json] ?? SchemeType.unrecognized;

  @override
  String toJson(SchemeType object) {
    for (final entry in _wire.entries) {
      if (entry.value == object) return entry.key;
    }
    return 'other';
  }
}

enum RuleGroup { all, any, unrecognized }

class RuleGroupConverter implements JsonConverter<RuleGroup, String> {
  const RuleGroupConverter();

  @override
  RuleGroup fromJson(String json) => switch (json) {
    'all' => RuleGroup.all,
    'any' => RuleGroup.any,
    _ => RuleGroup.unrecognized,
  };

  @override
  String toJson(RuleGroup object) => switch (object) {
    RuleGroup.all => 'all',
    RuleGroup.any => 'any',
    RuleGroup.unrecognized => 'all',
  };
}

enum RuleOperator { eq, gte, lte, unrecognized }

class RuleOperatorConverter implements JsonConverter<RuleOperator, String> {
  const RuleOperatorConverter();

  @override
  RuleOperator fromJson(String json) => switch (json) {
    'eq' => RuleOperator.eq,
    'gte' => RuleOperator.gte,
    'lte' => RuleOperator.lte,
    _ => RuleOperator.unrecognized,
  };

  @override
  String toJson(RuleOperator object) => switch (object) {
    RuleOperator.eq => 'eq',
    RuleOperator.gte => 'gte',
    RuleOperator.lte => 'lte',
    RuleOperator.unrecognized => 'eq',
  };
}
