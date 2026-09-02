"""Data access for eligibility matching.

Kept separate from the matcher itself for the same reason as
repositories/search.py: eligibility_matcher.py must stay usable without a
database (it operates on the RuleLike Protocol), and this is the one place
that fetches real SchemeEligibilityRule rows to satisfy it.
"""

from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import select
from sqlalchemy.orm import Session

from schememedia.db.models import SchemeEligibilityRule


@dataclass
class SqlEligibilityRuleRepository:
    session: Session

    def rules_by_scheme(
        self, scheme_ids: list[str]
    ) -> dict[str, list[SchemeEligibilityRule]]:
        """Every rule for each of the given schemes, grouped by scheme_id.

        A scheme with no rules at all (53 of 1,000 real schemes) simply has
        no key in the returned dict -- callers use `.get(id, [])`, matching
        how evaluate_scheme treats an empty rule list as NOT_APPLICABLE
        rather than a special case.
        """
        if not scheme_ids:
            return {}
        rows = (
            self.session.execute(
                select(SchemeEligibilityRule).where(
                    SchemeEligibilityRule.scheme_id.in_(scheme_ids)
                )
            )
            .scalars()
            .all()
        )
        result: dict[str, list[SchemeEligibilityRule]] = {}
        for row in rows:
            result.setdefault(row.scheme_id, []).append(row)
        return result
