"""Hybrid search fused with deterministic eligibility -- the ranking
endpoint. See services/recommendation.py's module docstring for why
eligibility only ever demotes a known FAIL and never hard-filters.

POST, not GET: `profile` is a structured object (up to 26 optional
attributes), awkward and easy to get wrong as query-string parameters.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Body, Request
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, ConfigDict, Field

from schememedia.api.v1.schemas.common import (
    EligibilityStateOut,
    JurisdictionOut,
    RuleGroupOut,
    RuleOperatorOut,
    SchemeTypeOut,
    VerificationStatusOut,
)
from schememedia.core.deps import RecommendationServiceDep
from schememedia.core.rate_limit import RECOMMENDATIONS_LIMIT, limiter
from schememedia.db.models.enums import ALL_ATTRIBUTE_KEYS
from schememedia.services.eligibility_matcher import RuleEvaluation
from schememedia.services.recommendation import Recommendation

router = APIRouter(prefix="/recommendations", tags=["recommendations"])

ProfileIn = dict[str, bool | float | str | None]


class RecommendationRequest(BaseModel):
    query: Annotated[str, Field(min_length=1, max_length=200)]
    profile: ProfileIn | None = Field(
        default=None,
        description=(
            "Optional structured user attributes (age, is_sc_st, "
            "annual_income, ...). Unrecognised keys are ignored, never an "
            "error -- see EligibilityAttribute for the full vocabulary."
        ),
    )
    limit: Annotated[int, Field(ge=1, le=100)] = 20


class RuleEvaluationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    rule_group: RuleGroupOut = Field(description="'all' = AND, 'any' = OR.")
    attribute_key: str
    operator: RuleOperatorOut
    state: EligibilityStateOut
    label: str = Field(description="Human-readable, e.g. 'You are a farmer'.")
    label_hi: str | None
    explanation: str = Field(
        description="A plain sentence covering every state, not just PASS."
    )

    @classmethod
    def from_domain(cls, rule: RuleEvaluation) -> RuleEvaluationOut:
        return cls(
            rule_group=rule.rule_group.value,
            attribute_key=rule.attribute_key,
            operator=rule.operator.value,
            state=rule.state.value,
            label=rule.label,
            label_hi=rule.label_hi,
            explanation=rule.explanation,
        )


class RecommendationOut(BaseModel):
    scheme_id: str
    slug: str
    name: str
    description_short: str | None
    category: str | None
    jurisdiction: JurisdictionOut
    state_code: str | None
    scheme_type: SchemeTypeOut
    score: float = Field(
        description="Reciprocal Rank Fusion score -- relative ordering only, see /search."
    )
    verification_status: VerificationStatusOut
    needs_review: bool
    official_url: str | None
    eligibility_state: EligibilityStateOut = Field(
        description=(
            "Combines every rule below via Kleene three-valued logic. "
            "'fail' only demotes this result's position, never removes it."
        )
    )
    eligibility_rules: list[RuleEvaluationOut]

    @classmethod
    def from_domain(cls, rec: Recommendation) -> RecommendationOut:
        r, e = rec.result, rec.eligibility
        return cls(
            scheme_id=r.scheme_id,
            slug=r.slug,
            name=r.name,
            description_short=r.description_short,
            category=r.category,
            jurisdiction=r.jurisdiction,
            state_code=r.state_code,
            scheme_type=r.scheme_type,
            score=r.score,
            verification_status=r.verification_status,
            needs_review=r.needs_review,
            official_url=r.official_url,
            eligibility_state=e.state.value,
            eligibility_rules=[RuleEvaluationOut.from_domain(rule) for rule in e.rules],
        )


class RecommendationResponseOut(BaseModel):
    query: str
    profile_provided: bool
    total_returned: int
    eligibility_breakdown: dict[str, int] = Field(
        description="Count of recommendations per eligibility_state value."
    )
    recommendations: list[RecommendationOut]


@router.post(
    "",
    response_model=RecommendationResponseOut,
    operation_id="getRecommendations",
    summary="Search ranked and annotated with eligibility against an optional profile",
    responses={
        429: {"description": f"Rate limited -- {RECOMMENDATIONS_LIMIT} per client."}
    },
)
@limiter.limit(RECOMMENDATIONS_LIMIT)
async def get_recommendations(
    request: Request,  # required by @limiter.limit -- see its own docstring on why
    service: RecommendationServiceDep,
    body: Annotated[RecommendationRequest, Body()],
) -> RecommendationResponseOut:
    clean_profile = (
        {k: v for k, v in body.profile.items() if k in ALL_ATTRIBUTE_KEYS}
        if body.profile
        else None
    )
    response = await run_in_threadpool(
        service.recommend, body.query, profile=clean_profile, limit=body.limit
    )
    return RecommendationResponseOut(
        query=response.query,
        profile_provided=response.profile_provided,
        total_returned=response.total_returned,
        eligibility_breakdown=response.eligibility_breakdown,
        recommendations=[
            RecommendationOut.from_domain(r) for r in response.recommendations
        ],
    )
