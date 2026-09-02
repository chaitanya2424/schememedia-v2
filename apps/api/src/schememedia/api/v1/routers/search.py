"""Hybrid keyword + semantic search.

Thin wrapper over services/search.py's SearchService. Blocking (DB, and for
the semantic retriever, an embedding model call) runs via run_in_threadpool
-- see core/deps.py's module-level note on why this stays a sync service
rather than an async reimplementation.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Query, Request
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, ConfigDict, Field

from schememedia.api.v1.schemas.common import (
    JurisdictionOut,
    SchemeTypeOut,
    VerificationStatusOut,
)
from schememedia.core.deps import SearchServiceDep
from schememedia.core.rate_limit import SEARCH_LIMIT, limiter

router = APIRouter(prefix="/search", tags=["search"])


class SearchResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    scheme_id: str
    slug: str
    name: str
    description_short: str | None
    category: str | None
    jurisdiction: JurisdictionOut
    state_code: str | None = Field(
        default=None,
        description="ISO-ish state code, present only for jurisdiction=state.",
    )
    scheme_type: SchemeTypeOut
    score: float = Field(
        description=(
            "Reciprocal Rank Fusion score. Meaningful only for ordering "
            "results relative to each other within this response -- not a "
            "confidence percentage, not comparable across different queries."
        )
    )
    verification_status: VerificationStatusOut = Field(
        description="Never 'officially_verified' by the importer alone -- see ADR 0003."
    )
    needs_review: bool = Field(
        description="True if this specific record has a known data-quality flag."
    )
    official_url: str | None = Field(
        default=None, description="Link to the official government page, when known."
    )


class SearchResponseOut(BaseModel):
    query: str
    total_returned: int
    verification_breakdown: dict[str, int] = Field(
        description="Count of results per verification_status value."
    )
    results: list[SearchResultOut]


@router.get(
    "",
    response_model=SearchResponseOut,
    operation_id="searchSchemes",
    summary="Hybrid keyword + semantic search over schemes",
    responses={429: {"description": f"Rate limited -- {SEARCH_LIMIT} per client."}},
)
@limiter.limit(SEARCH_LIMIT)
async def search_schemes(
    request: Request,  # required by @limiter.limit -- see its own docstring on why
    service: SearchServiceDep,
    q: Annotated[
        str, Query(min_length=1, max_length=200, description="Natural-language query")
    ],
    limit: Annotated[int, Query(ge=1, le=100)] = 20,
) -> SearchResponseOut:
    response = await run_in_threadpool(service.search, q, limit=limit)
    return SearchResponseOut(
        query=response.query,
        total_returned=response.total_returned,
        verification_breakdown=response.verification_breakdown,
        results=[SearchResultOut.model_validate(r) for r in response.results],
    )
