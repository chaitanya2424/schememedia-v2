"""CLI: import schemes.json into the database.

Usage:
    python -m schememedia.cli.import_schemes [path/to/schemes.json]

Reads DATABASE_URL from the environment (via application settings, same as
the API and Alembic), so it always targets the same database the app runs
against. Path defaults to schemes.json at the repository root.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from schememedia.core.config import get_settings
from schememedia.importer.pipeline import run_import, sync_database_url

# apps/api/src/schememedia/cli/import_schemes.py -> repo root is 5 parents up.
DEFAULT_PATH = Path(__file__).resolve().parents[5] / "schemes.json"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "path",
        nargs="?",
        type=Path,
        default=DEFAULT_PATH,
        help=f"Path to schemes.json (default: {DEFAULT_PATH})",
    )
    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"No such file: {args.path}", file=sys.stderr)
        return 1

    settings = get_settings()
    engine = create_engine(sync_database_url(str(settings.database_url)), future=True)
    try:
        with Session(engine) as session:
            report = run_import(session, args.path)
            session.commit()
    finally:
        engine.dispose()

    print(report.render())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
