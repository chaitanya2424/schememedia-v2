"""Tests for DigiLocker fast-fetch and AI document KYC extraction endpoints."""

from __future__ import annotations

import pytest
from httpx import AsyncClient

from schememedia.services.profile_automation import (
    fetch_digilocker_profile,
    parse_document_text_heuristic,
)


def test_fetch_digilocker_profile_predefined() -> None:
    result = fetch_digilocker_profile(demo_persona="farmer")
    assert result["status"] == "success"
    assert result["verified"] is True
    assert result["kyc_data"]["state_code"] == "MH"
    assert result["attributes"]["is_farmer"] is True
    assert result["attributes"]["is_woman"] is True


def test_fetch_digilocker_profile_arbitrary_aadhaar() -> None:
    result = fetch_digilocker_profile(aadhaar_number="123456789012")
    assert result["status"] == "success"
    assert result["verified"] is True
    assert "name" in result["kyc_data"]
    assert "age" in result["attributes"]
    assert result["id_masked"] == "XXXX-XXXX-9012"


def test_parse_document_text_heuristic_aadhaar() -> None:
    text = (
        "GOVERNMENT OF INDIA Unique Identification Authority of India "
        "Name: Ramesh Kumar Sharma "
        "DOB: 12/04/1990 "
        "Gender: Male "
        "Address: Ward 4, Pune, Maharashtra 411001 "
        "9821 7843 1928"
    )
    result = parse_document_text_heuristic(text)
    assert result["status"] == "success"
    assert result["document_type"] == "aadhaar"
    assert result["extracted_fields"]["gender"] == "Male"
    assert result["extracted_fields"]["state_code"] == "MH"
    assert result["attributes"]["is_woman"] is False
    assert result["attributes"]["state_code"] == "MH"


@pytest.mark.asyncio
async def test_digilocker_fetch_endpoint(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/profile-automation/digilocker-fetch",
        json={"demo_persona": "student"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["kyc_data"]["occupation"] == "College Student"
    assert data["attributes"]["is_student"] is True


@pytest.mark.asyncio
async def test_extract_document_endpoint(client: AsyncClient) -> None:
    response = await client.post(
        "/api/v1/profile-automation/extract-document",
        json={
            "ocr_text": "Government of India Name: Sunita Devi DOB: 14/08/1995 Female Rajasthan 302001",
            "document_hint": "aadhaar",
        },
    )
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "success"
    assert data["extracted_fields"]["state_code"] == "RJ"
    assert data["attributes"]["is_woman"] is True
