"""Schema integration tests.

These run against a real PostgreSQL with pgvector, not a mock. Check
constraints, triggers, and generated columns are database behaviour -- testing
them against a fake would prove nothing.

Skipped automatically when TEST_DATABASE_URL is unset, so the unit suite still
runs without a database.
"""

from __future__ import annotations

import uuid

import pytest
import pytest_asyncio
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine

from tests.conftest import database_is_reachable, resolve_test_database_url

TEST_DATABASE_URL = resolve_test_database_url()
# Probed once at collection time rather than per test.
DATABASE_AVAILABLE = database_is_reachable(TEST_DATABASE_URL)

pytestmark = [
    pytest.mark.asyncio,
    pytest.mark.skipif(
        not DATABASE_AVAILABLE,
        reason=(
            "PostgreSQL is not reachable. Install it and run "
            "`python scripts/dev.py init-db && python scripts/dev.py migrate`. "
            "See README section 1."
        ),
    ),
]


@pytest_asyncio.fixture
async def session():
    """A session on a transaction that is always rolled back.

    Each test therefore sees a clean database without re-running migrations.
    """
    url = TEST_DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)
    engine = create_async_engine(url, poolclass=None)
    factory = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    async with factory() as s:
        yield s
        await s.rollback()
    await engine.dispose()


async def _seed(session: AsyncSession) -> tuple[str, uuid.UUID, uuid.UUID]:
    """Create one category, one scheme, and two users. Returns their ids."""
    suffix = uuid.uuid4().hex[:8]
    scheme_id = f"SCH_T_{suffix}"

    cat_id = (
        await session.execute(
            text("INSERT INTO categories (slug, name) VALUES (:s, 'Test') RETURNING id"),
            {"s": f"cat-{suffix}"},
        )
    ).scalar_one()

    await session.execute(
        text("""
            INSERT INTO schemes (scheme_id, slug, name, category_id, description_long)
            VALUES (:id, :slug, 'Test Farmer Scheme', :cat,
                    'Income support for landholding farmer families.')
        """),
        {"id": scheme_id, "slug": f"slug-{suffix}", "cat": cat_id},
    )

    user_a = (
        await session.execute(
            text(
                "INSERT INTO users (email, password_hash) VALUES (:e, 'x') RETURNING id"
            ),
            {"e": f"a-{suffix}@example.com"},
        )
    ).scalar_one()
    user_b = (
        await session.execute(
            text(
                "INSERT INTO users (email, password_hash) VALUES (:e, 'x') RETURNING id"
            ),
            {"e": f"b-{suffix}@example.com"},
        )
    ).scalar_one()

    return scheme_id, user_a, user_b


async def _count(session: AsyncSession, scheme_id: str, column: str) -> int:
    result = await session.execute(
        text(f"SELECT {column} FROM schemes WHERE scheme_id = :id"),
        {"id": scheme_id},
    )
    return int(result.scalar_one())


# ---------------------------------------------------------------------------
# Constraints
# ---------------------------------------------------------------------------


async def test_rating_outside_range_is_rejected(session: AsyncSession) -> None:
    scheme_id, user_a, _ = await _seed(session)
    with pytest.raises(IntegrityError, match="rating_range"):
        await session.execute(
            text(
                "INSERT INTO scheme_ratings (user_id, scheme_id, rating) "
                "VALUES (:u, :s, 7)"
            ),
            {"u": user_a, "s": scheme_id},
        )


async def test_duplicate_like_is_rejected(session: AsyncSession) -> None:
    """v1's single interactions table allowed the same scheme to be liked twice."""
    scheme_id, user_a, _ = await _seed(session)
    stmt = text("INSERT INTO scheme_likes (user_id, scheme_id) VALUES (:u, :s)")
    await session.execute(stmt, {"u": user_a, "s": scheme_id})
    with pytest.raises(IntegrityError, match="pk_scheme_likes"):
        await session.execute(stmt, {"u": user_a, "s": scheme_id})


async def test_unknown_attribute_key_is_rejected(session: AsyncSession) -> None:
    """A typo in the importer must fail loudly, not create an unmatchable rule."""
    scheme_id, _, _ = await _seed(session)
    with pytest.raises(IntegrityError, match="known_attribute_key"):
        await session.execute(
            text("""
                INSERT INTO scheme_eligibility_rules
                    (scheme_id, rule_group, attribute_key, operator, value_bool, label)
                VALUES (:s, 'all', 'is_farmerr', 'eq', true, 'typo')
            """),
            {"s": scheme_id},
        )


async def test_rule_with_two_values_is_rejected(session: AsyncSession) -> None:
    scheme_id, _, _ = await _seed(session)
    with pytest.raises(IntegrityError, match="exactly_one_value"):
        await session.execute(
            text("""
                INSERT INTO scheme_eligibility_rules
                    (scheme_id, rule_group, attribute_key, operator,
                     value_bool, value_numeric, label)
                VALUES (:s, 'all', 'is_farmer', 'eq', true, 5, 'both')
            """),
            {"s": scheme_id},
        )


async def test_state_scheme_requires_state_code(session: AsyncSession) -> None:
    with pytest.raises(IntegrityError, match="state_scheme_requires_state_code"):
        await session.execute(
            text("""
                INSERT INTO schemes (scheme_id, slug, name, jurisdiction)
                VALUES ('SCH_BAD_X', 'bad-x', 'Bad', 'state')
            """)
        )


async def test_email_uniqueness_is_case_insensitive(session: AsyncSession) -> None:
    suffix = uuid.uuid4().hex[:8]
    stmt = text("INSERT INTO users (email, password_hash) VALUES (:e, 'x')")
    await session.execute(stmt, {"e": f"Person-{suffix}@Example.com"})
    with pytest.raises(IntegrityError, match="uq_users_email_lower"):
        await session.execute(stmt, {"e": f"person-{suffix}@example.com"})


# ---------------------------------------------------------------------------
# Counter triggers
# ---------------------------------------------------------------------------


async def test_like_counter_increments_and_decrements(session: AsyncSession) -> None:
    scheme_id, user_a, user_b = await _seed(session)
    stmt = text("INSERT INTO scheme_likes (user_id, scheme_id) VALUES (:u, :s)")

    await session.execute(stmt, {"u": user_a, "s": scheme_id})
    await session.execute(stmt, {"u": user_b, "s": scheme_id})
    assert await _count(session, scheme_id, "like_count") == 2

    await session.execute(
        text("DELETE FROM scheme_likes WHERE user_id = :u AND scheme_id = :s"),
        {"u": user_b, "s": scheme_id},
    )
    assert await _count(session, scheme_id, "like_count") == 1


async def test_rating_update_adjusts_sum_but_not_count(session: AsyncSession) -> None:
    """The subtle case: changing 5 to 2 must not inflate rating_count."""
    scheme_id, user_a, _ = await _seed(session)
    await session.execute(
        text(
            "INSERT INTO scheme_ratings (user_id, scheme_id, rating) VALUES (:u, :s, 5)"
        ),
        {"u": user_a, "s": scheme_id},
    )
    assert await _count(session, scheme_id, "rating_sum") == 5
    assert await _count(session, scheme_id, "rating_count") == 1

    await session.execute(
        text("UPDATE scheme_ratings SET rating = 2 WHERE user_id = :u"),
        {"u": user_a},
    )
    assert await _count(session, scheme_id, "rating_sum") == 2
    assert await _count(session, scheme_id, "rating_count") == 1


async def test_comment_soft_delete_decrements_counter(session: AsyncSession) -> None:
    scheme_id, user_a, _ = await _seed(session)
    comment_id = (
        await session.execute(
            text("""
                INSERT INTO comments (scheme_id, user_id, content)
                VALUES (:s, :u, 'Very helpful.') RETURNING id
            """),
            {"s": scheme_id, "u": user_a},
        )
    ).scalar_one()
    assert await _count(session, scheme_id, "comment_count") == 1

    await session.execute(
        text("UPDATE comments SET deleted_at = now() WHERE id = :id"),
        {"id": comment_id},
    )
    assert await _count(session, scheme_id, "comment_count") == 0


# ---------------------------------------------------------------------------
# Search infrastructure
# ---------------------------------------------------------------------------


async def test_search_vector_is_generated(session: AsyncSession) -> None:
    """The tsvector is computed by Postgres and cannot drift from its sources."""
    scheme_id, _, _ = await _seed(session)
    result = await session.execute(
        text("""
            SELECT ts_rank(search_vector, plainto_tsquery('english', :q))
            FROM schemes WHERE scheme_id = :id
        """),
        {"q": "farmer income support", "id": scheme_id},
    )
    assert result.scalar_one() > 0


async def test_vector_column_accepts_and_ranks_embeddings(
    session: AsyncSession,
) -> None:
    scheme_id, _, _ = await _seed(session)
    embedding = "[" + ",".join(["0.1"] * 384) + "]"
    await session.execute(
        text("UPDATE schemes SET embedding = :e ::vector WHERE scheme_id = :id"),
        {"e": embedding, "id": scheme_id},
    )
    result = await session.execute(
        text("""
            SELECT embedding <=> :e ::vector
            FROM schemes WHERE scheme_id = :id
        """),
        {"e": embedding, "id": scheme_id},
    )
    assert float(result.scalar_one()) == pytest.approx(0.0, abs=1e-6)
