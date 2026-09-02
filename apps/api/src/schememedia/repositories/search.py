"""Data access for search.

Kept separate from SearchService so the ranking logic can be unit-tested
against a fake repository, and so semantic search can be added here later
without the service changing shape.

This is the retrieval layer that eligibility matching and the grounded
assistant will both reuse, so it returns scored candidates rather than
finished responses.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Protocol

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from schememedia.db.models import EMBEDDING_MODEL_NAME, Scheme


@dataclass(frozen=True)
class Candidate:
    """One retrieved scheme with its score from a single retrieval method.

    Deliberately thin: fusion works on ranks, and callers hydrate the full
    scheme separately. Keeping this small means a retriever can be swapped
    without touching anything downstream.
    """

    scheme_id: str
    score: float


class KeywordRetriever(Protocol):
    def search(self, query: str, *, limit: int) -> list[Candidate]: ...


# Terms are OR-ed rather than AND-ed.
#
# PostgreSQL's plainto_tsquery ANDs every lexeme, which is wrong for natural
# language: measured on the real dataset, "housing for rural poor" returned
# ZERO results under AND because the word "poor" appears nowhere, and 74
# sensible ones under OR. Users type sentences, and a missing word should
# lower a result's rank, not erase every result.
#
# tsvector_to_array(to_tsvector(...)) gives the stemmed, stopword-filtered
# lexemes, so the query passes through the same analysis as the index.
_KEYWORD_SQL = text("""
    WITH q AS (
        SELECT to_tsquery(
            'english',
            array_to_string(
                tsvector_to_array(to_tsvector('english', :query)), ' | '
            )
        ) AS tsq
    )
    SELECT s.scheme_id,
           ts_rank_cd(s.search_vector, q.tsq) AS score
    FROM schemes s, q
    WHERE s.is_active
      AND s.search_vector @@ q.tsq
    ORDER BY score DESC, s.scheme_id
    LIMIT :limit
""")

# Empty after stemming and stopword removal -- e.g. "the and of".
_EMPTY_QUERY_SQL = text("""
    SELECT array_length(tsvector_to_array(to_tsvector('english', :query)), 1)
""")


@dataclass
class SqlKeywordRetriever:
    """Full-text retrieval over the generated tsvector column."""

    session: Session

    def has_searchable_terms(self, query: str) -> bool:
        result = self.session.execute(_EMPTY_QUERY_SQL, {"query": query}).scalar()
        return bool(result)

    def search(self, query: str, *, limit: int = 20) -> list[Candidate]:
        if not query.strip() or not self.has_searchable_terms(query):
            return []
        rows = self.session.execute(_KEYWORD_SQL, {"query": query, "limit": limit}).all()
        return [
            Candidate(scheme_id=row.scheme_id, score=float(row.score)) for row in rows
        ]


# Unlike keyword search, embedding similarity has no natural "no match"
# outcome -- nearest-neighbour search always returns its top K, however
# distant.
#
# Revised during real user-testing (original value: 0.5). "health
# insurance" -- an unambiguous, realistic query -- landed its best real
# match (the actually-correct "...Insurance Scheme For Health Workers...")
# at 0.5433, just outside the original cutoff, so semantic search
# contributed nothing and the fused ranking fell back entirely to keyword
# term-frequency, which put an irrelevant "Soil Health...Health Card"
# scheme first (matches "health" twice) ahead of the genuine match. Full
# measurement against the real 1,000-scheme dataset with all-MiniLM-L6-v2:
#
#   genuine, specific queries land their best match at    0.34 - 0.54
#     (women empowerment 0.337, housing loan 0.396, disability support
#     0.387, senior citizen 0.431, job training 0.453, health insurance
#     0.543)
#   too-vague single words land a *spurious* best match at 0.58 - 0.64
#     (benefits 0.584, money 0.604, scheme 0.636 -- none of these "best
#     matches" are actually meaningful; a vague word just happens to be
#     least-far from something)
#   gibberish/off-topic never gets closer than                0.69
#     (asdkjfh qwepoiu 0.688, xyzabc123 0.728, zzzqqqxwv 0.725, "how to
#     cook pasta" 0.814, "weather forecast tomorrow" 0.847)
#
# 0.56 sits in the real (if narrower than first assumed) gap between the
# worst genuine match (0.543) and the closest false-positive-prone vague
# query (0.584), with clear margin on both sides and a wide margin below
# every gibberish/off-topic score measured.
MAX_COSINE_DISTANCE = 0.56


@dataclass
class PgVectorRetriever:
    """Semantic retrieval over the HNSW-indexed embedding column.

    Optional: a SearchService constructed without one falls back to
    keyword-only search unchanged (see services/search.py). The embedding
    model is loaded lazily, on first use -- fastembed pulls in
    onnxruntime/numpy, weight that a keyword-only caller should never pay.
    """

    session: Session
    _model: Any = field(default=None, init=False, repr=False)

    def _embed_query(self, text_: str) -> list[float]:
        if self._model is None:
            # Imported lazily for the same reason as the field above.
            from fastembed import TextEmbedding

            self._model = TextEmbedding(model_name=EMBEDDING_MODEL_NAME)
        vector = next(self._model.embed([text_]))
        return vector.tolist()  # type: ignore[no-any-return]

    def search(self, query: str, *, limit: int = 20) -> list[Candidate]:
        if not query.strip():
            return []
        distance = Scheme.embedding.cosine_distance(self._embed_query(query))
        rows = self.session.execute(
            select(Scheme.scheme_id, distance.label("distance"))
            .where(distance < MAX_COSINE_DISTANCE)
            .where(Scheme.is_active, Scheme.embedding.is_not(None))
            .order_by(distance)
            .limit(limit)
        ).all()
        # Cosine distance lives in [0, 2]; flipped to a similarity-like score
        # so smaller distance ranks higher. RRF (services/search.py) uses
        # only rank position, never this value -- see its own docstring on
        # why scores from different retrievers are never compared directly.
        return [
            Candidate(scheme_id=row.scheme_id, score=1.0 - float(row.distance))
            for row in rows
        ]


def hydrate(session: Session, scheme_ids: list[str]) -> dict[str, Any]:
    """Load display fields for retrieved schemes, preserving nothing else.

    Explicitly does not SELECT * -- v1 shipped a 384-float embedding to the
    browser on every detail view.
    """
    if not scheme_ids:
        return {}
    rows = session.execute(
        text("""
            SELECT s.scheme_id, s.slug, s.name, s.description_short,
                   s.jurisdiction::text AS jurisdiction, s.state_code,
                   s.scheme_type::text AS scheme_type,
                   s.verification_status::text AS verification_status,
                   s.needs_review, s.official_url, s.last_verified_at,
                   c.name AS category
            FROM schemes s
            LEFT JOIN categories c ON c.id = s.category_id
            WHERE s.scheme_id = ANY(:ids)
        """),
        {"ids": scheme_ids},
    ).mappings()
    return {row["scheme_id"]: dict(row) for row in rows}
