"""Search orchestration.

Hybrid: full-text keyword retrieval fused with semantic (embedding) retrieval
via Reciprocal Rank Fusion. Either retriever alone can miss what the other
finds -- a query using words absent from a scheme's text still matches
semantically, and a semantic retriever alone can miss an exact, rare term
with little training signal. Fusing both, rather than picking one, is why
RRF takes a list of ranked lists instead of one.

The semantic retriever is optional: a SearchService built with only a
keyword retriever (as every earlier test in this module already does)
degrades gracefully to keyword-only search, unchanged.

Every result carries its verification status. A caller must not be able to
render a scheme without knowing how much we actually trust it.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

from schememedia.repositories.search import (
    Candidate,
    PgVectorRetriever,
    SqlKeywordRetriever,
    hydrate,
)

DEFAULT_LIMIT = 20
MAX_LIMIT = 100

# Reciprocal Rank Fusion constant. 60 is the value from the original TREC
# work and the common default; it damps the influence of the very top ranks
# just enough that one retriever cannot dominate.
RRF_K = 60


@dataclass(frozen=True)
class SearchResult:
    scheme_id: str
    slug: str
    name: str
    description_short: str | None
    category: str | None
    jurisdiction: str
    state_code: str | None
    scheme_type: str
    score: float
    # Provenance travels with every result. A UI cannot accidentally present
    # an unverified legacy record as authoritative government information.
    verification_status: str
    needs_review: bool
    official_url: str | None

    @property
    def is_officially_verified(self) -> bool:
        return self.verification_status == "officially_verified"


@dataclass
class SearchResponse:
    query: str
    results: list[SearchResult] = field(default_factory=list)
    total_returned: int = 0
    # How many results carry each verification status, so a caller can warn
    # the user honestly rather than in the abstract.
    verification_breakdown: dict[str, int] = field(default_factory=dict)


def reciprocal_rank_fusion(
    ranked_lists: list[list[Candidate]], *, k: int = RRF_K
) -> list[tuple[str, float]]:
    """Fuse ranked lists by rank position rather than by score.

    Scores from different retrievers are not comparable: BM25-style ranks and
    cosine distances live on entirely different scales. v1 subtracted a flat
    0.5 from a cosine distance, so any keyword hit beat every semantic match
    regardless of relevance.

    RRF sidesteps this by using only the ordinal position, which is why it is
    the standard approach for hybrid retrieval: keyword and semantic hits are
    fused here without either one's score ever being compared to the other's.
    """
    totals: dict[str, float] = {}
    for ranked in ranked_lists:
        for position, candidate in enumerate(ranked, start=1):
            totals[candidate.scheme_id] = totals.get(candidate.scheme_id, 0.0) + 1.0 / (
                k + position
            )
    return sorted(totals.items(), key=lambda pair: (-pair[1], pair[0]))


@dataclass
class SearchService:
    keyword: SqlKeywordRetriever
    semantic: PgVectorRetriever | None = None

    def search(self, query: str, *, limit: int = DEFAULT_LIMIT) -> SearchResponse:
        limit = max(1, min(limit, MAX_LIMIT))

        # A query with no real content word -- empty, or stopwords only, e.g.
        # "the and of" -- is not a meaningful search at all. Gated here
        # rather than left to each retriever individually: unlike keyword
        # search, embedding similarity has no natural "no match" outcome --
        # every query embeds to *some* vector, so a semantic retriever asked
        # for "zzzqqqxwv" or "the and of" returns its nearest neighbours
        # regardless of how little signal the query carried. Without this
        # gate, hybrid search would surface results for input a keyword-only
        # search correctly rejected as too weak to search on at all.
        if not query.strip() or not self.keyword.has_searchable_terms(query):
            return SearchResponse(query=query)

        # Over-fetch so fusion has room to reorder before truncation.
        keyword_hits = self.keyword.search(query, limit=limit * 3)
        semantic_hits = (
            self.semantic.search(query, limit=limit * 3) if self.semantic else []
        )

        # Only lists that found something contribute to fusion. A query with
        # zero keyword hits can still be answered semantically (and vice
        # versa) -- that asymmetry is the entire reason to fuse two
        # retrievers instead of running one and falling back to the other.
        ranked_lists = [hits for hits in (keyword_hits, semantic_hits) if hits]
        if not ranked_lists:
            return SearchResponse(query=query)

        fused = reciprocal_rank_fusion(ranked_lists)[:limit]
        scheme_ids = [scheme_id for scheme_id, _ in fused]

        rows: dict[str, Any] = hydrate(self.keyword.session, scheme_ids)

        results: list[SearchResult] = []
        breakdown: dict[str, int] = {}
        for scheme_id, score in fused:
            row = rows.get(scheme_id)
            if row is None:
                continue
            status = row["verification_status"]
            breakdown[status] = breakdown.get(status, 0) + 1
            results.append(
                SearchResult(
                    scheme_id=scheme_id,
                    slug=row["slug"],
                    name=row["name"],
                    description_short=row["description_short"],
                    category=row["category"],
                    jurisdiction=row["jurisdiction"],
                    state_code=row["state_code"],
                    scheme_type=row["scheme_type"],
                    score=score,
                    verification_status=status,
                    needs_review=row["needs_review"],
                    official_url=row["official_url"],
                )
            )

        return SearchResponse(
            query=query,
            results=results,
            total_returned=len(results),
            verification_breakdown=breakdown,
        )
