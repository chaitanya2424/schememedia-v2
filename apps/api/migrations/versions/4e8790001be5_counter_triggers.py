"""counter triggers

Maintains the denormalised counters on `schemes` (like_count, save_count,
comment_count, rating_sum, rating_count).

Why triggers rather than application code: the counters must stay correct no
matter what writes to the tables -- the API, the importer, an admin in psql, or
a future background job. Doing this in the service layer would leave the
counters wrong the first time anything else writes a row, and v1's alternative
(recomputing counts with correlated subqueries on every feed request) is the
query most likely to fall over under load.

Ratings store sum and count rather than an average so an update is O(1) and
avoids the floating-point drift of repeatedly averaging an average.
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = "4e8790001be5"
down_revision: Union[str, Sequence[str], None] = "195d03b4db39"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ---------- Likes ----------
    op.execute("""
        CREATE OR REPLACE FUNCTION trg_scheme_like_count() RETURNS trigger AS $fn$
        BEGIN
            IF TG_OP = 'INSERT' THEN
                UPDATE schemes SET like_count = like_count + 1
                 WHERE scheme_id = NEW.scheme_id;
            ELSIF TG_OP = 'DELETE' THEN
                UPDATE schemes SET like_count = GREATEST(like_count - 1, 0)
                 WHERE scheme_id = OLD.scheme_id;
            END IF;
            RETURN NULL;
        END;
        $fn$ LANGUAGE plpgsql;
    """)
    op.execute("""
        CREATE TRIGGER scheme_likes_count_trigger
        AFTER INSERT OR DELETE ON scheme_likes
        FOR EACH ROW EXECUTE FUNCTION trg_scheme_like_count();
    """)

    # ---------- Saves ----------
    op.execute("""
        CREATE OR REPLACE FUNCTION trg_scheme_save_count() RETURNS trigger AS $fn$
        BEGIN
            IF TG_OP = 'INSERT' THEN
                UPDATE schemes SET save_count = save_count + 1
                 WHERE scheme_id = NEW.scheme_id;
            ELSIF TG_OP = 'DELETE' THEN
                UPDATE schemes SET save_count = GREATEST(save_count - 1, 0)
                 WHERE scheme_id = OLD.scheme_id;
            END IF;
            RETURN NULL;
        END;
        $fn$ LANGUAGE plpgsql;
    """)
    op.execute("""
        CREATE TRIGGER scheme_saves_count_trigger
        AFTER INSERT OR DELETE ON scheme_saves
        FOR EACH ROW EXECUTE FUNCTION trg_scheme_save_count();
    """)

    # ---------- Ratings ----------
    # UPDATE is handled explicitly: changing a 5 to a 2 must adjust the sum
    # without touching the count.
    op.execute("""
        CREATE OR REPLACE FUNCTION trg_scheme_rating_stats() RETURNS trigger AS $fn$
        BEGIN
            IF TG_OP = 'INSERT' THEN
                UPDATE schemes
                   SET rating_sum = rating_sum + NEW.rating,
                       rating_count = rating_count + 1
                 WHERE scheme_id = NEW.scheme_id;
            ELSIF TG_OP = 'UPDATE' THEN
                UPDATE schemes
                   SET rating_sum = rating_sum - OLD.rating + NEW.rating
                 WHERE scheme_id = NEW.scheme_id;
            ELSIF TG_OP = 'DELETE' THEN
                UPDATE schemes
                   SET rating_sum = GREATEST(rating_sum - OLD.rating, 0),
                       rating_count = GREATEST(rating_count - 1, 0)
                 WHERE scheme_id = OLD.scheme_id;
            END IF;
            RETURN NULL;
        END;
        $fn$ LANGUAGE plpgsql;
    """)
    op.execute("""
        CREATE TRIGGER scheme_ratings_stats_trigger
        AFTER INSERT OR UPDATE OF rating OR DELETE ON scheme_ratings
        FOR EACH ROW EXECUTE FUNCTION trg_scheme_rating_stats();
    """)

    # ---------- Comments ----------
    # Comments are soft-deleted, so the counter follows deleted_at rather than
    # row removal. Only visible comments are counted.
    op.execute("""
        CREATE OR REPLACE FUNCTION trg_scheme_comment_count() RETURNS trigger AS $fn$
        BEGIN
            IF TG_OP = 'INSERT' THEN
                IF NEW.deleted_at IS NULL THEN
                    UPDATE schemes SET comment_count = comment_count + 1
                     WHERE scheme_id = NEW.scheme_id;
                END IF;
            ELSIF TG_OP = 'UPDATE' THEN
                IF OLD.deleted_at IS NULL AND NEW.deleted_at IS NOT NULL THEN
                    UPDATE schemes SET comment_count = GREATEST(comment_count - 1, 0)
                     WHERE scheme_id = NEW.scheme_id;
                ELSIF OLD.deleted_at IS NOT NULL AND NEW.deleted_at IS NULL THEN
                    UPDATE schemes SET comment_count = comment_count + 1
                     WHERE scheme_id = NEW.scheme_id;
                END IF;
            ELSIF TG_OP = 'DELETE' THEN
                IF OLD.deleted_at IS NULL THEN
                    UPDATE schemes SET comment_count = GREATEST(comment_count - 1, 0)
                     WHERE scheme_id = OLD.scheme_id;
                END IF;
            END IF;
            RETURN NULL;
        END;
        $fn$ LANGUAGE plpgsql;
    """)
    op.execute("""
        CREATE TRIGGER scheme_comments_count_trigger
        AFTER INSERT OR UPDATE OF deleted_at OR DELETE ON comments
        FOR EACH ROW EXECUTE FUNCTION trg_scheme_comment_count();
    """)


def downgrade() -> None:
    for trigger, table in [
        ("scheme_likes_count_trigger", "scheme_likes"),
        ("scheme_saves_count_trigger", "scheme_saves"),
        ("scheme_ratings_stats_trigger", "scheme_ratings"),
        ("scheme_comments_count_trigger", "comments"),
    ]:
        op.execute(f"DROP TRIGGER IF EXISTS {trigger} ON {table}")

    for function in [
        "trg_scheme_like_count",
        "trg_scheme_save_count",
        "trg_scheme_rating_stats",
        "trg_scheme_comment_count",
    ]:
        op.execute(f"DROP FUNCTION IF EXISTS {function}()")
