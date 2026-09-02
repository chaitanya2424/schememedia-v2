"""Recommendation: hybrid search + eligibility matching, combined.

Given a natural-language query and an optional user profile, retrieve
candidates via SearchService (keyword + semantic RRF, services/search.py)
and evaluate each candidate against the profile via
eligibility_matcher.evaluate_scheme. Neither layer knows about the other --
this module is the composition, so search stays testable without eligibility
and eligibility stays testable without search (both already are).

RANKING, NOT FILTERING
------------------------
REBUILD_PLAN Assumption A-3 -- and the explicit instruction this module was
built under -- is that eligibility must never hard-filter retrieval. Every
scheme search finds is still returned. The only adjustment: schemes with a
*known* FAIL sink to the end of the results, in their original relevance
order; everything else (PASS, UNKNOWN, NOT_APPLICABLE) keeps exactly the
order search produced.

This is deliberately conservative. A stronger design would boost PASS above
UNKNOWN, or blend eligibility into the RRF score directly -- but a profile
is usually incomplete (most real schemes resolve to UNKNOWN for a partial
profile; see the eligibility engine's own report), and promoting NOT_APPLICABLE
or PASS ahead of a highly-relevant UNKNOWN result on partial information would
bias the feed toward whichever schemes happen to have less rule data, not
whichever schemes are actually most relevant. That tuning question needs a
measured fixture query set to answer, not a guess (REBUILD_PLAN R-4's own
standard) -- deferred, not forgotten. Demoting a *known* failure is the one
adjustment that is unambiguously correct regardless of tuning: showing a
citizen a scheme first that we already know they don't qualify for, ahead of
one we simply have no information about, is never the better ordering.
"""

from __future__ import annotations

from dataclasses import dataclass, field

from schememedia.repositories.eligibility import SqlEligibilityRuleRepository
from schememedia.services.eligibility_matcher import (
    EligibilityState,
    Profile,
    SchemeEligibilityResult,
    evaluate_scheme,
)
from schememedia.services.search import SearchResult, SearchService

DEFAULT_LIMIT = 20


@dataclass(frozen=True)
class Recommendation:
    """One scheme, with both why it was retrieved and whether it matches.

    Deliberately a composition of the two existing result types rather than
    a flattened, duplicated set of fields -- verification_status and
    needs_review already live on `result` (repositories/search.py's hydrate,
    ADR 0003) and stay visible here unchanged, exactly as required.
    """

    result: SearchResult
    eligibility: SchemeEligibilityResult

    @property
    def scheme_id(self) -> str:
        return self.result.scheme_id


@dataclass
class RecommendationResponse:
    query: str
    profile_provided: bool
    recommendations: list[Recommendation] = field(default_factory=list)
    total_returned: int = 0
    # How many recommendations landed in each eligibility state, so a caller
    # can show "3 you may qualify for, 8 unknown, 2 you likely don't" without
    # recomputing it -- the same honesty SearchResponse already gives for
    # verification_status (services/search.py).
    eligibility_breakdown: dict[str, int] = field(default_factory=dict)


@dataclass
class RecommendationService:
    search: SearchService
    rules: SqlEligibilityRuleRepository

    def recommend(
        self,
        query: str,
        *,
        profile: Profile | None = None,
        limit: int = DEFAULT_LIMIT,
    ) -> RecommendationResponse:
        search_response = self.search.search(query, limit=limit)
        effective_profile: Profile = profile or {}

        scheme_ids = [r.scheme_id for r in search_response.results]
        rules_by_scheme = self.rules.rules_by_scheme(scheme_ids)

        recommendations = [
            Recommendation(
                result=result,
                eligibility=evaluate_scheme(
                    result.scheme_id,
                    rules_by_scheme.get(result.scheme_id, []),
                    effective_profile,
                    needs_review=result.needs_review,
                ),
            )
            for result in search_response.results
        ]

        # Stable sort: only demotes a *known* FAIL to the end. Every other
        # state keeps the relative order search already produced -- see
        # module docstring for why this is the only adjustment made today.
        recommendations.sort(
            key=lambda rec: rec.eligibility.state is EligibilityState.FAIL
        )

        breakdown: dict[str, int] = {}
        for rec in recommendations:
            state = rec.eligibility.state.value
            breakdown[state] = breakdown.get(state, 0) + 1

        return RecommendationResponse(
            query=query,
            profile_provided=profile is not None,
            recommendations=recommendations,
            total_returned=len(recommendations),
            eligibility_breakdown=breakdown,
        )
