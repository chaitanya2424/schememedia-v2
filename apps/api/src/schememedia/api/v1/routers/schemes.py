"""Scheme detail.

No profile/eligibility on this route yet, deliberately: a rich ~26-attribute
profile is awkward as query parameters, and the natural fit -- pulling a
signed-in user's saved profile server-side -- needs auth, which is a later
phase. SchemeDetailService already accepts an optional profile
(services/scheme_detail.py), so wiring that in later is additive, not a
redesign.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Path, Request
from fastapi.concurrency import run_in_threadpool
from pydantic import BaseModel, ConfigDict, Field

from schememedia.api.v1.schemas.common import (
    JurisdictionOut,
    SchemeTypeOut,
    VerificationStatusOut,
)
from schememedia.core.deps import SchemeDetailServiceDep
from schememedia.core.errors import ErrorEnvelopeOut, NotFoundError
from schememedia.core.rate_limit import SCHEME_DETAIL_LIMIT, limiter

router = APIRouter(prefix="/schemes", tags=["schemes"])


class BenefitOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    stage: str | None
    amount_text: str
    amount_numeric: float | None
    currency: str
    is_truncated: bool = Field(
        description="True for the source strings cut off mid-word at ~200 characters."
    )


class DocumentOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    name: str
    is_mandatory: bool
    needs_review: bool = Field(
        description="True if the importer could not confidently split this document."
    )


class SchemeDetailOut(BaseModel):
    scheme_id: str
    slug: str
    name: str
    name_hi: str | None
    ministry: str | None
    category: str | None
    scheme_type: SchemeTypeOut
    jurisdiction: JurisdictionOut
    state_code: str | None
    description_short: str | None
    description_long: str | None
    official_url: str | None
    application_deadline: str | None
    verification_status: VerificationStatusOut
    needs_review: bool
    last_verified_at: str | None
    tags: list[str]
    benefits: list[BenefitOut]
    documents: list[DocumentOut]
    like_count: int
    save_count: int
    comment_count: int
    average_rating: float | None = Field(
        default=None, description="1-5, null if unrated."
    )


@router.get(
    "/{identifier}",
    response_model=SchemeDetailOut,
    operation_id="getSchemeDetail",
    summary="Full detail for one scheme, by scheme_id or slug",
    responses={
        404: {
            "model": ErrorEnvelopeOut,
            "description": "No active scheme matches the given scheme_id or slug.",
        },
        429: {"description": f"Rate limited -- {SCHEME_DETAIL_LIMIT} per client."},
    },
)
@limiter.limit(SCHEME_DETAIL_LIMIT)
async def get_scheme_detail(
    request: Request,  # required by @limiter.limit -- see its own docstring on why
    service: SchemeDetailServiceDep,
    identifier: Annotated[
        str,
        Path(description="A scheme's scheme_id (e.g. SCH_1F47743B) or its URL slug."),
    ],
) -> SchemeDetailOut:
    detail = await run_in_threadpool(service.get_detail, identifier)
    if detail is None:
        raise NotFoundError(f"No scheme found for {identifier!r}.")

    s = detail.scheme
    return SchemeDetailOut(
        scheme_id=s.scheme_id,
        slug=s.slug,
        name=s.name,
        name_hi=s.name_hi,
        ministry=s.ministry,
        category=detail.category_name,
        scheme_type=s.scheme_type.value,
        jurisdiction=s.jurisdiction.value,
        state_code=s.state_code,
        description_short=s.description_short,
        description_long=s.description_long,
        official_url=s.official_url,
        application_deadline=(
            s.application_deadline.isoformat() if s.application_deadline else None
        ),
        verification_status=s.verification_status.value,
        needs_review=s.needs_review,
        last_verified_at=(s.last_verified_at.isoformat() if s.last_verified_at else None),
        tags=detail.tags,
        benefits=[BenefitOut.model_validate(b) for b in detail.benefits],
        documents=[DocumentOut.model_validate(d) for d in detail.documents],
        like_count=s.like_count,
        save_count=s.save_count,
        comment_count=s.comment_count,
        average_rating=s.average_rating,
    )
