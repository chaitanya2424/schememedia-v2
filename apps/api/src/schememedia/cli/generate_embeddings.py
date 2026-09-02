"""CLI: generate embeddings for imported schemes.

Usage:
    python -m schememedia.cli.generate_embeddings [--force]

fastembed, sentence-transformers/all-MiniLM-L6-v2, 384 dimensions -- ONNX
runtime, no PyTorch, no GPU required (REBUILD_PLAN F).

Embeds `name + category + tags + benefits + ministry`, deliberately NOT
`description_short`: all 1,000 source records share the same generated
boilerplate template (REBUILD_PLAN D.4), so embedding it would produce
near-identical vectors and reduce semantic search to title-matching with
extra steps (R-4).

Batched and resumable: by default only schemes with `embedding IS NULL` are
processed, so an interrupted run can simply be re-run. `--force` regenerates
every embedding.
"""

from __future__ import annotations

import argparse
from collections import defaultdict

from sqlalchemy import create_engine, select, update
from sqlalchemy.orm import Session

from schememedia.core.config import get_settings
from schememedia.db.models import (
    EMBEDDING_MODEL_NAME,
    Category,
    Scheme,
    SchemeBenefit,
    SchemeTag,
    Tag,
)
from schememedia.importer.pipeline import sync_database_url

BATCH_SIZE = 64


def _build_embedding_text(
    *,
    name: str,
    category_name: str | None,
    ministry: str | None,
    tags: list[str],
    benefits: list[str],
) -> str:
    parts = [
        name,
        category_name or "",
        " ".join(tags),
        " ".join(benefits),
        ministry or "",
    ]
    return " ".join(p for p in parts if p).strip()


def _tags_by_scheme(session: Session) -> dict[str, list[str]]:
    rows = session.execute(
        select(SchemeTag.scheme_id, Tag.name).join(Tag, Tag.id == SchemeTag.tag_id)
    ).all()
    result: dict[str, list[str]] = defaultdict(list)
    for scheme_id, name in rows:
        result[scheme_id].append(name)
    return result


def _benefits_by_scheme(session: Session) -> dict[str, list[str]]:
    rows = session.execute(
        select(SchemeBenefit.scheme_id, SchemeBenefit.amount_text)
    ).all()
    result: dict[str, list[str]] = defaultdict(list)
    for scheme_id, amount_text in rows:
        result[scheme_id].append(amount_text)
    return result


def run(session: Session, *, force: bool = False, batch_size: int = BATCH_SIZE) -> int:
    """Generate embeddings for schemes missing one (or all, with force).

    Returns the number of schemes embedded.
    """
    # Imported lazily: fastembed pulls in onnxruntime/numpy, which is slow to
    # import and unnecessary for anything that only calls other functions in
    # this module (e.g. _build_embedding_text, exercised directly in tests).
    from fastembed import TextEmbedding

    query = select(
        Scheme.scheme_id,
        Scheme.name,
        Scheme.ministry,
        Category.name.label("category_name"),
    ).join(Category, Category.id == Scheme.category_id, isouter=True)
    if not force:
        query = query.where(Scheme.embedding.is_(None))
    targets = session.execute(query).all()
    if not targets:
        return 0

    tags_by_scheme = _tags_by_scheme(session)
    benefits_by_scheme = _benefits_by_scheme(session)

    model = TextEmbedding(model_name=EMBEDDING_MODEL_NAME)

    total = 0
    for start in range(0, len(targets), batch_size):
        batch = targets[start : start + batch_size]
        texts = [
            _build_embedding_text(
                name=row.name,
                category_name=row.category_name,
                ministry=row.ministry,
                tags=tags_by_scheme.get(row.scheme_id, []),
                benefits=benefits_by_scheme.get(row.scheme_id, []),
            )
            for row in batch
        ]
        vectors = list(model.embed(texts))
        for row, vector in zip(batch, vectors, strict=True):
            session.execute(
                update(Scheme)
                .where(Scheme.scheme_id == row.scheme_id)
                .values(embedding=vector.tolist())
            )
        session.flush()
        total += len(batch)

    return total


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--force",
        action="store_true",
        help="regenerate every embedding, not just missing",
    )
    args = parser.parse_args(argv)

    settings = get_settings()
    engine = create_engine(sync_database_url(str(settings.database_url)), future=True)
    try:
        with Session(engine) as session:
            count = run(session, force=args.force)
            session.commit()
    finally:
        engine.dispose()

    print(f"Embedded {count} scheme(s) using {EMBEDDING_MODEL_NAME}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
