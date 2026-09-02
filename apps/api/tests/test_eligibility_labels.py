"""Tests for eligibility label content.

Labels are shown directly to citizens, so gaps are a user-facing defect, not a
cosmetic one. These tests guard completeness rather than wording.
"""

from __future__ import annotations

import pytest

from schememedia.db.models.enums import ALL_ATTRIBUTE_KEYS, AttributeType, attribute_type
from schememedia.db.models.enums import EligibilityAttribute as A
from schememedia.services.eligibility_labels import (
    BOOLEAN_LABELS,
    BOOLEAN_LABELS_HI,
    NUMERIC_LABEL_TEMPLATES,
    NUMERIC_LABEL_TEMPLATES_HI,
    TEXT_LABEL_TEMPLATES,
    format_indian_number,
)


def test_every_boolean_attribute_has_an_english_label() -> None:
    """A missing label would render a blank explanation to the user."""
    expected = {a for a in A if attribute_type(a) is AttributeType.BOOLEAN}
    assert expected - set(BOOLEAN_LABELS) == set()


def test_every_boolean_attribute_has_a_hindi_label() -> None:
    assert set(BOOLEAN_LABELS) - set(BOOLEAN_LABELS_HI) == set()


def test_numeric_and_text_attributes_are_covered() -> None:
    numeric = {a for a in A if attribute_type(a) is AttributeType.NUMERIC}
    covered = {attr for attr, _ in NUMERIC_LABEL_TEMPLATES}
    assert numeric - covered == set()

    text = {a for a in A if attribute_type(a) is AttributeType.TEXT}
    assert text - set(TEXT_LABEL_TEMPLATES) == set()


def test_hindi_numeric_templates_match_english_keys() -> None:
    assert set(NUMERIC_LABEL_TEMPLATES) == set(NUMERIC_LABEL_TEMPLATES_HI)


def test_all_labels_are_non_empty() -> None:
    for true_label, false_label in BOOLEAN_LABELS.values():
        assert true_label.strip()
        assert false_label.strip()


def test_numeric_templates_accept_a_value_placeholder() -> None:
    for template in NUMERIC_LABEL_TEMPLATES.values():
        assert "{value}" in template
        assert template.format(value="18")


@pytest.mark.parametrize(
    ("number", "expected"),
    [
        (100, "100"),
        (1000, "1,000"),
        (72000, "72,000"),
        (100000, "1,00,000"),  # one lakh, not 100,000
        (250000, "2,50,000"),
        (1500000, "15,00,000"),  # fifteen lakh, not 1,500,000
        (10000000, "1,00,00,000"),  # one crore
    ],
)
def test_indian_digit_grouping(number: int, expected: str) -> None:
    """Western grouping reads as wrong to this audience.

    Income thresholds are the numbers users scrutinise most closely.
    """
    assert format_indian_number(number) == expected


def test_attribute_vocabulary_is_shared_with_the_schema() -> None:
    """Labels and the database CHECK constraint must not drift apart."""
    assert set(ALL_ATTRIBUTE_KEYS) == {a.value for a in A}
