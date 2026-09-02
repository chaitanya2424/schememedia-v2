"""Split blob-style required-document strings into individual documents.

997 of the 1,000 source records pack every required document into a single
string -- median 307 characters, longest 8,155 -- with no consistent
separator and no newlines anywhere.

The approach is a cascade of separator rules, most explicit first. The first
rule producing two or more usable parts wins. If none does, the blob is kept
whole rather than guessed at.

Governing principle: **correctness over aggressive splitting.** A blob left
whole is still readable by a citizen; a shredded document name is confident
nonsense. Under-splitting is flagged for review, so nothing is lost silently.

Measured over the real dataset (997 blobs):
    numbered   123   bullet   3   semicolon  10
    sentence   624   unsplit 237
    5,472 document rows, median 4 per blob.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Literal

SplitRule = Literal["numbered", "bullet", "semicolon", "sentence", "unsplit"]

# Zero-width and byte-order marks appear in 241 blobs, sometimes as a real
# delimiter, more often as trailing junk.
ZERO_WIDTH = "﻿​‌‍"

# A part shorter than this is punctuation debris, not a document name.
MIN_PART_LENGTH = 3

# An unsplit blob longer than this probably contains several documents joined
# without a separator. Verified against the data: the shortest unsplit blobs
# are "Aadhar Card" and "e-Nirman Card"; the longest is 1,039 characters.
UNSPLIT_REVIEW_LENGTH = 120

# No genuine document name runs this long.
PART_REVIEW_LENGTH = 200

_NUMBERED = re.compile(r"(?:^|\s)\d{1,2}\s*[).]\s")
_BULLET = re.compile(r"[•▪●*]\s")
# Candidate sentence boundary: a period after a lowercase letter, digit or
# closing bracket, followed by a capital or digit. Candidates are then
# filtered by _is_abbreviation below -- Python's re requires fixed-width
# lookbehind, so a regex alone cannot express "unless preceded by Dr/No/etc".
_SENTENCE = re.compile(r"(?<=[a-z0-9)\]])\.\s+(?=[A-Z0-9])")

# Tokens that take a full stop without ending a document name.
_ABBREVIATIONS = frozenset(
    {
        "dr",
        "mr",
        "mrs",
        "ms",
        "sh",
        "smt",
        "kum",
        "no",
        "nos",
        "sr",
        "jr",
        "st",
        "vs",
        "viz",
        "etc",
        "rs",
        "approx",
        "dept",
        "govt",
        "ltd",
        "pvt",
        "co",
        "inc",
    }
)

_TRAILING_TOKEN = re.compile(r"([A-Za-z.]+)$")

_WHITESPACE = re.compile(r"\s+")
_TRIM = " .,;:-•\t"


@dataclass(frozen=True)
class SplitResult:
    """Outcome of splitting one blob."""

    parts: list[str]
    rule: SplitRule
    needs_review: bool


def _normalise(text: str) -> str:
    for char in ZERO_WIDTH:
        text = text.replace(char, " ")
    text = text.replace("\t", " ")
    return _WHITESPACE.sub(" ", text).strip(_TRIM)


def _clean(parts: list[str]) -> list[str]:
    cleaned = [p.strip(_TRIM) for p in parts]
    return [p for p in cleaned if len(p) >= MIN_PART_LENGTH]


def _by_numbered(text: str) -> list[str] | None:
    # Two markers required: a single "1." is a prefix, not a list.
    if len(_NUMBERED.findall(text)) < 2:
        return None
    return _clean(_NUMBERED.split(text))


def _by_bullet(text: str) -> list[str] | None:
    if len(_BULLET.findall(text)) < 2:
        return None
    return _clean(_BULLET.split(text))


def _by_semicolon(text: str) -> list[str] | None:
    if ";" not in text:
        return None
    return _clean(text.split(";"))


def _is_abbreviation(preceding: str) -> bool:
    """Whether the text before a candidate boundary ends in an abbreviation.

    Also treats any one- or two-letter token as an abbreviation, which covers
    initials such as "B.R." and "i.e." without listing every combination.
    """
    match = _TRAILING_TOKEN.search(preceding)
    if not match:
        return False
    token = match.group(1).strip(".").lower()
    return len(token) <= 2 or token in _ABBREVIATIONS


def _by_sentence(text: str) -> list[str] | None:
    parts: list[str] = []
    start = 0
    for match in _SENTENCE.finditer(text):
        if _is_abbreviation(text[start : match.start()]):
            continue
        parts.append(text[start : match.start()])
        start = match.end()
    parts.append(text[start:])
    return _clean(parts)


# Order matters: most explicit separator first.
_CASCADE: list[tuple[SplitRule, object]] = [
    ("numbered", _by_numbered),
    ("bullet", _by_bullet),
    ("semicolon", _by_semicolon),
    ("sentence", _by_sentence),
]


def split_documents(blob: str) -> SplitResult:
    """Split one required-documents blob.

    Deterministic: the same input always produces the same output, so
    re-importing does not churn stored rows.
    """
    text = _normalise(blob or "")

    if not text:
        # 3 schemes have an empty documents_required array.
        return SplitResult(parts=[], rule="unsplit", needs_review=True)

    for rule, splitter in _CASCADE:
        parts = splitter(text)  # type: ignore[operator]
        if parts and len(parts) >= 2:
            return SplitResult(
                parts=parts,
                rule=rule,
                needs_review=any(len(p) > PART_REVIEW_LENGTH for p in parts),
            )

    # Nothing split it. Keep it whole; flag only if it is long enough to
    # suggest several documents were joined without a separator.
    return SplitResult(
        parts=[text],
        rule="unsplit",
        needs_review=len(text) > UNSPLIT_REVIEW_LENGTH,
    )
