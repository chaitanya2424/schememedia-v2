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
from schememedia.importer.pipeline import (
    DEFAULT_BATCH_SIZE,
    run_import,
    sync_database_url,
)

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
    parser.add_argument(
        "--batch-size",
        type=int,
        default=DEFAULT_BATCH_SIZE,
        help=(
            "Schemes committed per transaction (default: %(default)s). "
            "See run_import()'s docstring for why this matters over a WAN "
            "connection."
        ),
    )
    args = parser.parse_args(argv)

    if not args.path.exists():
        print(f"No such file: {args.path}", file=sys.stderr)
        return 1

    settings = get_settings()
    engine = create_engine(sync_database_url(str(settings.database_url)), future=True)
    try:
        with Session(engine) as session:
            # run_import() commits per batch itself -- see its docstring --
            # so there is deliberately no trailing session.commit() here.
            report = run_import(session, args.path, batch_size=args.batch_size)
    finally:
        engine.dispose()

    print(report.render())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
