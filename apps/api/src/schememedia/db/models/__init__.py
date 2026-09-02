"""SQLAlchemy models.

Every model must be imported here so Base.metadata is fully populated before
Alembic autogenerate runs -- an unimported model is silently omitted from
migrations.
"""

from schememedia.db.models.base import Base
from schememedia.db.models.content import Comment, Notification, Report
from schememedia.db.models.interaction import SchemeLike, SchemeRating, SchemeSave
from schememedia.db.models.scheme import (
    EMBEDDING_DIM,
    EMBEDDING_MODEL_NAME,
    Category,
    Scheme,
    SchemeBenefit,
    SchemeDocument,
    SchemeEligibilityRule,
    SchemeTag,
    Tag,
)
from schememedia.db.models.user import RefreshToken, User, UserProfile

__all__ = [
    "EMBEDDING_DIM",
    "EMBEDDING_MODEL_NAME",
    "Base",
    "Category",
    "Comment",
    "Notification",
    "RefreshToken",
    "Report",
    "Scheme",
    "SchemeBenefit",
    "SchemeDocument",
    "SchemeEligibilityRule",
    "SchemeLike",
    "SchemeRating",
    "SchemeSave",
    "SchemeTag",
    "Tag",
    "User",
    "UserProfile",
]
