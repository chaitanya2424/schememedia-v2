"""Router for DigiLocker fast-fetch and AI document KYC extraction."""

from __future__ import annotations

import uuid
from typing import Annotated, Any

from fastapi import APIRouter, Body, Depends
from pydantic import BaseModel, Field

from schememedia.core.config import Settings
from schememedia.core.deps import (
    OptionalCurrentUserIdDep,
    SettingsDep,
    UserProfileRepositoryDep,
)
from schememedia.services.profile_automation import (
    extract_document,
    fetch_digilocker_profile,
)
from schememedia.services.user_profile import apply_partial_update

router = APIRouter(prefix="/profile-automation", tags=["profile-automation"])


class DigiLockerFetchRequest(BaseModel):
    aadhaar_number: str | None = Field(default=None, description="Optional 12-digit Aadhaar number")
    mobile_number: str | None = Field(default=None, description="Optional 10-digit mobile number")
    otp: str | None = Field(default=None, description="Optional 6-digit OTP")
    demo_persona: str | None = Field(
        default=None,
        description="Optional persona for sandbox testing: farmer, student, woman_artisan, senior_citizen",
    )
    auto_save: bool = Field(
        default=True,
        description="Whether to automatically save extracted attributes to profile if user is signed in",
    )


class DocumentExtractRequest(BaseModel):
    image_base64: str | None = Field(
        default=None,
        description="Base64-encoded image string (with or without data URI prefix)",
    )
    ocr_text: str | None = Field(
        default=None,
        description="Optional raw text extracted from document",
    )
    document_hint: str | None = Field(
        default=None,
        description="Optional hint: aadhaar, pan, voter_id, ration_card, auto",
    )
    auto_save: bool = Field(
        default=True,
        description="Whether to automatically save extracted attributes to profile if user is signed in",
    )


@router.post(
    "/digilocker-fetch",
    summary="Fetch verified KYC data from DigiLocker / UIDAI Identity Gateway",
    operation_id="digilockerFetch",
)
async def digilocker_fetch(
    body: Annotated[DigiLockerFetchRequest, Body()],
    settings: SettingsDep,
    profiles: UserProfileRepositoryDep,
    user_id: OptionalCurrentUserIdDep = None,
) -> dict[str, Any]:
    """Retrieves verified demographic attributes from DigiLocker sandbox / UIDAI identity."""
    result = fetch_digilocker_profile(
        aadhaar_number=body.aadhaar_number,
        mobile_number=body.mobile_number,
        otp=body.otp,
        demo_persona=body.demo_persona,
    )

    # If the user is signed in and requested auto_save, persist directly
    if user_id and body.auto_save and result.get("attributes"):
        try:
            profile = await profiles.get_or_create(user_id)
            apply_partial_update(profile, result["attributes"])
            result["saved_to_profile"] = True
        except Exception:
            result["saved_to_profile"] = False

    return result


@router.post(
    "/extract-document",
    summary="Extract demographic data from Aadhaar, PAN, Voter ID, or Ration Card photo",
    operation_id="extractDocument",
)
async def extract_document_endpoint(
    body: Annotated[DocumentExtractRequest, Body()],
    settings: SettingsDep,
    profiles: UserProfileRepositoryDep,
    user_id: OptionalCurrentUserIdDep = None,
) -> dict[str, Any]:
    """Uses multimodal vision / heuristic OCR to extract KYC fields from government documents."""
    result = extract_document(
        image_base64=body.image_base64,
        ocr_text=body.ocr_text,
        document_hint=body.document_hint,
        settings=settings,
    )

    # If the user is signed in and requested auto_save, persist directly
    if user_id and body.auto_save and result.get("attributes"):
        try:
            profile = await profiles.get_or_create(user_id)
            apply_partial_update(profile, result["attributes"])
            result["saved_to_profile"] = True
        except Exception:
            result["saved_to_profile"] = False

    return result
