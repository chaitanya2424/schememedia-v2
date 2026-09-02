"""Tests for the required-documents splitter.

Written before the implementation. Every fixture marked REAL is a verbatim
blob from schemes.json, identified by scheme_id, so these assert behaviour on
the actual data rather than on invented examples.

The governing rule is correctness over aggressive splitting: a blob left whole
is still readable by a human, whereas a shredded document name is confident
nonsense.
"""

from __future__ import annotations

import pytest

from schememedia.services.document_splitter import SplitResult, split_documents

# ---------------------------------------------------------------------------
# Rule 1 -- numbered lists
# ---------------------------------------------------------------------------


def test_numbered_list_splits() -> None:
    """REAL: SCH_174F1695 -- Maharashtra land-record documents."""
    result = split_documents(
        "1.\tAadhar Card, 2.\t7/12, 3.\t8-A, 4.\tFerfar, 5.\tRation card etc ﻿"
    )
    assert result.rule == "numbered"
    assert result.parts == ["Aadhar Card", "7/12", "8-A", "Ferfar", "Ration card etc"]


def test_single_number_does_not_trigger_numbered_rule() -> None:
    """REAL: SCH_DFFD78D7 -- one marker is a prefix, not a list."""
    result = split_documents("1. copy of the latest electricity bill")
    assert result.rule != "numbered"
    assert len(result.parts) == 1


# ---------------------------------------------------------------------------
# Rule 4 -- sentence boundaries
# ---------------------------------------------------------------------------


def test_sentence_boundary_splits_the_median_blob() -> None:
    """REAL: SCH_DC77A96C -- the median-length blob (307 chars)."""
    blob = (
        "Nativity/Citizenship/Residential Certificate, issued by the Officer "
        "of the Revenue Department not below the rank of a Deputy Tahsildar. "
        "Income Certificate. Birth Certificate. Stamp-sized Photograph. "
        "Aadhaar Card. Secondary School Leaving Certificate (SSLC) Certificate. "
        "Public Information Certificate (PIC)."
    )
    result = split_documents(blob)
    assert result.rule == "sentence"
    assert len(result.parts) == 7
    assert result.parts[1] == "Income Certificate"
    assert result.parts[-1] == "Public Information Certificate (PIC)"


def test_comma_inside_a_document_name_is_preserved() -> None:
    """The reason commas are not a separator.

    Comma-splitting turns this single document into a fragment plus a
    remainder. Measured across the dataset: comma-splitting yields 2,695 rows
    of which 972 begin with a lowercase letter.
    """
    blob = (
        "Nativity/Citizenship/Residential Certificate, issued by the Officer "
        "of the Revenue Department not below the rank of a Deputy Tahsildar. "
        "Income Certificate."
    )
    result = split_documents(blob)
    assert result.parts[0] == (
        "Nativity/Citizenship/Residential Certificate, issued by the Officer "
        "of the Revenue Department not below the rank of a Deputy Tahsildar"
    )


@pytest.mark.parametrize(
    "blob",
    [
        "Dr. B.R. Ambedkar Scholarship Certificate",
        "Certificate No. 5 issued by the department",
        "Proof of income i.e. salary slip or Form 16",
    ],
)
def test_abbreviations_are_not_split(blob: str) -> None:
    """The lookarounds exist to protect Dr., No. and i.e."""
    result = split_documents(blob)
    assert len(result.parts) == 1


# ---------------------------------------------------------------------------
# Rule 5 -- do not split
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    "blob",
    [
        "Aadhar Card",  # REAL: SCH_B2B2FF24, shortest in dataset
        "e-Nirman Card",  # REAL: SCH_96403E5A
        "Date of Birth Proof",  # REAL: SCH_812A55E0
    ],
)
def test_genuine_single_documents_are_not_split_or_flagged(blob: str) -> None:
    result = split_documents(blob)
    assert result.parts == [blob]
    assert result.rule == "unsplit"
    assert result.needs_review is False


def test_long_unsplit_blob_is_flagged() -> None:
    """REAL: shape of SCH_C4637C07 -- 1,039 chars, no usable separator.

    Documents joined by a capital-letter boundary only. A capitalisation rule
    would catch this but would also shred "Aadhaar Card issued by UIDAI", so
    we under-split and flag instead.
    """
    blob = (
        "Legal Status of the organization (enclose certificate of registration) "
        "& whether a National or International organization Establishment date "
        "& summary of registered activities carried out by the applicant "
    ) * 3
    result = split_documents(blob)
    assert result.rule == "unsplit"
    assert result.needs_review is True


def test_documents_joined_without_a_separator_stay_whole() -> None:
    """REAL: SCH_630FEBC9 -- genuinely two documents, deliberately not split.

    Documented limitation, not an oversight.
    """
    result = split_documents("Ration Card Aadhar Card")
    assert result.parts == ["Ration Card Aadhar Card"]


# ---------------------------------------------------------------------------
# Normalisation
# ---------------------------------------------------------------------------


def test_zero_width_and_tabs_are_normalised() -> None:
    """241 blobs contain U+FEFF; 87 contain tabs."""
    result = split_documents("Udyam Registration certificate.\tUAM number. ﻿")
    assert all("﻿" not in p and "\t" not in p for p in result.parts)
    assert all(p == p.strip() for p in result.parts)


def test_empty_input_yields_no_parts_and_is_flagged() -> None:
    """3 schemes have an empty documents_required array."""
    result = split_documents("")
    assert result.parts == []
    assert result.needs_review is True


# ---------------------------------------------------------------------------
# Determinism
# ---------------------------------------------------------------------------


def test_splitting_is_idempotent() -> None:
    """Re-importing must not change stored rows."""
    blob = "Income Certificate. Birth Certificate. Aadhaar Card."
    first = split_documents(blob)
    second = split_documents(blob)
    assert first.parts == second.parts
    assert first.rule == second.rule


def test_result_is_a_split_result() -> None:
    result = split_documents("Aadhar Card")
    assert isinstance(result, SplitResult)
    assert result.rule in {"numbered", "bullet", "semicolon", "sentence", "unsplit"}
