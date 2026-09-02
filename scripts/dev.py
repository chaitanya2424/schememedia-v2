#!/usr/bin/env python3
"""SchemeMedia developer task runner.

Pure Python and cross-platform by design: no make, no bash, no Docker. Every
command works identically in PowerShell, cmd, and a POSIX shell.

    python scripts/dev.py doctor       check the local environment
    python scripts/dev.py init-db      create databases and enable extensions
    python scripts/dev.py migrate      apply migrations to dev and test
    python scripts/dev.py import-data  import schemes.json (re-runnable)
    python scripts/dev.py embed        generate embeddings for imported schemes
    python scripts/dev.py test         run the test suite
    python scripts/dev.py check        lint, format check, type check
    python scripts/dev.py run          start the API with reload
    python scripts/dev.py reset-db     drop and rebuild both databases

Run `doctor` first. It reports exactly what is missing and how to fix it.
"""

from __future__ import annotations

import argparse
import os
import platform
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import urlparse, urlunparse

REPO_ROOT = Path(__file__).resolve().parent.parent
API_DIR = REPO_ROOT / "apps" / "api"
ENV_FILE = REPO_ROOT / ".env"

IS_WINDOWS = platform.system() == "Windows"

# Minimum pgvector version. Earlier releases lack HNSW indexes, which the
# schema requires.
MIN_PGVECTOR = (0, 5, 0)

OK = "[ OK ]"
FAIL = "[FAIL]"
WARN = "[WARN]"


# ---------------------------------------------------------------------------
# Environment loading
# ---------------------------------------------------------------------------


def load_env() -> dict[str, str]:
    """Read .env into a dict and into os.environ.

    Deliberately not requiring the developer to export variables in every new
    PowerShell session -- a common source of "it worked yesterday".
    """
    values: dict[str, str] = {}
    if ENV_FILE.exists():
        for raw in ENV_FILE.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, _, value = line.partition("=")
            key = key.strip()
            value = value.strip().strip('"').strip("'")
            values[key] = value
            os.environ.setdefault(key, value)
    return values


def database_url() -> str:
    url = os.environ.get("DATABASE_URL", "")
    if not url:
        fail(
            "DATABASE_URL is not set.",
            "Copy .env.example to .env and set DATABASE_URL.",
        )
    return url


def test_database_url() -> str:
    """The test database URL, derived from DATABASE_URL when not set."""
    url = os.environ.get("TEST_DATABASE_URL", "")
    if url:
        return url
    parsed = urlparse(database_url())
    return urlunparse(parsed._replace(path=parsed.path.rstrip("/") + "_test"))


def db_name(url: str) -> str:
    return urlparse(url).path.lstrip("/")


def maintenance_url(url: str) -> str:
    """Point at the `postgres` database so we can CREATE/DROP others."""
    parsed = urlparse(url)
    return urlunparse(parsed._replace(path="/postgres"))


def fail(message: str, *hints: str) -> None:
    print(f"\n{FAIL} {message}")
    for hint in hints:
        print(f"       {hint}")
    sys.exit(1)


# ---------------------------------------------------------------------------
# doctor
# ---------------------------------------------------------------------------

PGVECTOR_WINDOWS_HELP = (
    "pgvector must be compiled on Windows -- there is no installer.",
    "",
    "  1. Install Visual Studio Build Tools with 'Desktop development with C++'",
    "  2. Open 'x64 Native Tools Command Prompt for VS' AS ADMINISTRATOR",
    "     (a normal PowerShell window will fail with 'nmake is not recognized')",
    '  3. set "PGROOT=C:\\Program Files\\PostgreSQL\\16"',
    "  4. cd %TEMP%",
    "  5. git clone --branch v0.8.0 https://github.com/pgvector/pgvector.git",
    "  6. cd pgvector",
    "  7. nmake /F Makefile.win",
    "  8. nmake /F Makefile.win install",
    "",
    "  Then re-run: python scripts/dev.py init-db",
    "",
    "  NOTE: some blog posts tell you to add pgvector to",
    "  shared_preload_libraries. Do NOT do this -- it is wrong and will stop",
    "  PostgreSQL from starting. CREATE EXTENSION is all that is needed.",
)


def cmd_doctor(_args: argparse.Namespace) -> int:
    print("SchemeMedia environment check\n" + "=" * 34)
    problems = 0

    # --- Python ---
    version = sys.version_info
    if version >= (3, 12):
        print(f"{OK} Python {version.major}.{version.minor}.{version.micro}")
    else:
        print(f"{FAIL} Python {version.major}.{version.minor} -- 3.12+ required")
        problems += 1

    # --- Virtual environment ---
    in_venv = sys.prefix != sys.base_prefix
    if in_venv:
        print(f"{OK} Virtual environment active ({sys.prefix})")
    else:
        print(f"{WARN} Not running inside a virtual environment")
        print("       python -m venv .venv")
        print(
            "       "
            + (
                r".venv\Scripts\Activate.ps1"
                if IS_WINDOWS
                else "source .venv/bin/activate"
            )
        )

    # --- Dependencies ---
    missing = []
    for module in ("fastapi", "sqlalchemy", "asyncpg", "alembic", "pgvector", "pytest"):
        try:
            __import__(module)
        except ImportError:
            missing.append(module)
    if missing:
        print(f"{FAIL} Missing packages: {', '.join(missing)}")
        print('       cd apps/api && pip install -e ".[dev]"')
        problems += 1
    else:
        print(f"{OK} Python dependencies installed")

    # --- .env ---
    if ENV_FILE.exists():
        print(f"{OK} .env present")
    else:
        print(f"{FAIL} .env missing")
        print("       Copy .env.example to .env and edit DATABASE_URL")
        problems += 1
        return _summary(problems)

    url = os.environ.get("DATABASE_URL", "")
    if not url:
        print(f"{FAIL} DATABASE_URL not set in .env")
        return _summary(problems + 1)

    # --- PostgreSQL connectivity ---
    try:
        import asyncio

        import asyncpg
    except ImportError:
        return _summary(problems + 1)

    async def probe() -> tuple[str, list[str], str | None]:
        conn = await asyncpg.connect(maintenance_url(url))
        try:
            server = await conn.fetchval("SHOW server_version")
            available = await conn.fetch(
                "SELECT name, default_version FROM pg_available_extensions "
                "WHERE name = 'vector'"
            )
            installed = await conn.fetchval(
                "SELECT extversion FROM pg_extension WHERE extname = 'vector'"
            )
            return server, [r["default_version"] for r in available], installed
        finally:
            await conn.close()

    try:
        server_version, vector_available, _ = asyncio.run(probe())
    except Exception as exc:  # noqa: BLE001 - report any failure to the user
        print(f"{FAIL} Cannot connect to PostgreSQL: {type(exc).__name__}")
        print(f"       URL: {redact(url)}")
        print("       Is the PostgreSQL service running?")
        if IS_WINDOWS:
            print('       Check: Services -> "postgresql-x64-16"')
        print("       Check the host, port, user and password in .env")
        return _summary(problems + 1)

    major = int(re.match(r"(\d+)", server_version).group(1))  # type: ignore[union-attr]
    if major >= 16:
        print(f"{OK} PostgreSQL {server_version}")
    else:
        print(f"{WARN} PostgreSQL {server_version} -- 16+ recommended")

    # --- pgvector ---
    if not vector_available:
        print(f"{FAIL} pgvector is not installed on this PostgreSQL server")
        for line in PGVECTOR_WINDOWS_HELP if IS_WINDOWS else UNIX_PGVECTOR_HELP:
            print(f"       {line}" if line else "")
        problems += 1
    else:
        version_text = vector_available[0]
        parts = tuple(int(p) for p in re.findall(r"\d+", version_text)[:3])
        if parts >= MIN_PGVECTOR:
            print(f"{OK} pgvector {version_text} available")
        else:
            print(f"{FAIL} pgvector {version_text} is too old -- 0.5.0+ required")
            print("       HNSW indexes were added in 0.5.0")
            problems += 1

    # --- Databases ---
    for label, target in (("dev", url), ("test", test_database_url())):
        name = db_name(target)
        try:
            import asyncio

            import asyncpg

            async def exists(t: str = target) -> bool:
                conn = await asyncpg.connect(maintenance_url(t))
                try:
                    return bool(
                        await conn.fetchval(
                            "SELECT 1 FROM pg_database WHERE datname = $1", db_name(t)
                        )
                    )
                finally:
                    await conn.close()

            if asyncio.run(exists()):
                print(f"{OK} {label} database '{name}' exists")
            else:
                print(f"{WARN} {label} database '{name}' does not exist")
                print("       python scripts/dev.py init-db")
        except Exception:  # noqa: BLE001, S112
            # Database presence is advisory here; connection problems were
            # already reported above with a proper diagnosis.
            continue

    return _summary(problems)


UNIX_PGVECTOR_HELP = (
    "Install pgvector for your PostgreSQL version:",
    "  Debian/Ubuntu:  sudo apt install postgresql-16-pgvector",
    "  macOS:          brew install pgvector",
    "  From source:    https://github.com/pgvector/pgvector",
)


def redact(url: str) -> str:
    """Hide the password before printing a connection string."""
    return re.sub(r"://([^:/@]+):[^@]*@", r"://\1:****@", url)


def _summary(problems: int) -> int:
    print()
    if problems:
        print(f"{problems} problem(s) found. Fix the items marked {FAIL} above.")
        return 1
    print("Environment looks good. Next: python scripts/dev.py init-db")
    return 0


# ---------------------------------------------------------------------------
# Database setup
# ---------------------------------------------------------------------------


def _run_sql_autocommit(url: str, statements: list[str]) -> None:
    """CREATE/DROP DATABASE cannot run inside a transaction block.

    asyncpg is used directly rather than psql so the workflow does not depend
    on PostgreSQL's client tools being on PATH -- a frequent Windows problem.
    """
    import asyncio

    import asyncpg

    async def run() -> None:
        conn = await asyncpg.connect(maintenance_url(url))
        try:
            for statement in statements:
                await conn.execute(statement)
        finally:
            await conn.close()

    asyncio.run(run())


def _enable_extensions(url: str) -> None:
    import asyncio

    import asyncpg

    async def run() -> None:
        conn = await asyncpg.connect(url)
        try:
            await conn.execute("CREATE EXTENSION IF NOT EXISTS vector")
            await conn.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
        finally:
            await conn.close()

    asyncio.run(run())


def cmd_init_db(_args: argparse.Namespace) -> int:
    dev_url = database_url()
    tst_url = test_database_url()

    for label, url in (("dev", dev_url), ("test", tst_url)):
        name = db_name(url)
        try:
            _run_sql_autocommit(url, [f'CREATE DATABASE "{name}"'])
            print(f"{OK} created {label} database '{name}'")
        except Exception as exc:  # noqa: BLE001
            if "already exists" in str(exc):
                print(f"{OK} {label} database '{name}' already exists")
            else:
                fail(
                    f"Could not create {label} database '{name}': {exc}",
                    f"URL: {redact(url)}",
                    "Run `python scripts/dev.py doctor` to diagnose.",
                )

        try:
            _enable_extensions(url)
            print(f"{OK} extensions enabled on '{name}'")
        except Exception as exc:  # noqa: BLE001
            hints = PGVECTOR_WINDOWS_HELP if IS_WINDOWS else UNIX_PGVECTOR_HELP
            fail(f"Could not enable extensions on '{name}': {exc}", *hints)

    print("\nNext: python scripts/dev.py migrate")
    return 0


def cmd_reset_db(_args: argparse.Namespace) -> int:
    for label, url in (("dev", database_url()), ("test", test_database_url())):
        name = db_name(url)
        _run_sql_autocommit(
            url,
            [
                # Terminate other sessions, or DROP DATABASE fails.
                (
                    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity "
                    f"WHERE datname = '{name}' AND pid <> pg_backend_pid()"
                ),
                f'DROP DATABASE IF EXISTS "{name}"',
            ],
        )
        print(f"{OK} dropped {label} database '{name}'")
    return cmd_init_db(_args)


# ---------------------------------------------------------------------------
# Commands that shell out to the API project
# ---------------------------------------------------------------------------


def _api_run(argv: list[str], extra_env: dict[str, str] | None = None) -> int:
    env = os.environ.copy()
    env["PYTHONPATH"] = str(API_DIR / "src")
    if extra_env:
        env.update(extra_env)
    return subprocess.run(argv, cwd=API_DIR, env=env, check=False).returncode


def cmd_migrate(_args: argparse.Namespace) -> int:
    for label, url in (("dev", database_url()), ("test", test_database_url())):
        print(f"--- migrating {label} ({db_name(url)}) ---")
        code = _api_run(
            [sys.executable, "-m", "alembic", "upgrade", "head"],
            {"DATABASE_URL": url},
        )
        if code:
            return code
    return 0


def cmd_test(args: argparse.Namespace) -> int:
    return _api_run(
        [sys.executable, "-m", "pytest", *args.pytest_args],
        {
            "DATABASE_URL": database_url(),
            "TEST_DATABASE_URL": test_database_url(),
        },
    )


def cmd_check(_args: argparse.Namespace) -> int:
    steps = [
        ("lint", [sys.executable, "-m", "ruff", "check", "src", "tests"]),
        ("format", [sys.executable, "-m", "ruff", "format", "--check", "src", "tests"]),
        ("types", [sys.executable, "-m", "mypy", "src"]),
    ]
    failures = 0
    for name, argv in steps:
        print(f"--- {name} ---")
        if _api_run(argv):
            failures += 1
    return 1 if failures else 0


def cmd_import_data(args: argparse.Namespace) -> int:
    argv = [sys.executable, "-m", "schememedia.cli.import_schemes"]
    if args.path:
        argv.append(args.path)
    return _api_run(argv, {"DATABASE_URL": database_url()})


def cmd_embed(args: argparse.Namespace) -> int:
    argv = [sys.executable, "-m", "schememedia.cli.generate_embeddings"]
    if args.force:
        argv.append("--force")
    return _api_run(argv, {"DATABASE_URL": database_url()})


def cmd_run(args: argparse.Namespace) -> int:
    return _api_run(
        [
            sys.executable,
            "-m",
            "uvicorn",
            "schememedia.main:create_app",
            "--factory",
            "--reload",
            "--port",
            str(args.port),
        ],
        {"DATABASE_URL": database_url()},
    )


# ---------------------------------------------------------------------------


def main() -> int:
    load_env()

    parser = argparse.ArgumentParser(
        prog="dev.py", description="SchemeMedia developer tasks"
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("doctor", help="check the local environment").set_defaults(
        func=cmd_doctor
    )
    sub.add_parser("init-db", help="create databases and extensions").set_defaults(
        func=cmd_init_db
    )
    sub.add_parser("reset-db", help="drop and recreate databases").set_defaults(
        func=cmd_reset_db
    )
    sub.add_parser("migrate", help="apply migrations").set_defaults(func=cmd_migrate)
    sub.add_parser("check", help="lint, format, types").set_defaults(func=cmd_check)

    import_parser = sub.add_parser(
        "import-data", help="import schemes.json into the database (re-runnable)"
    )
    import_parser.add_argument(
        "path", nargs="?", default=None, help="path to schemes.json (default: repo root)"
    )
    import_parser.set_defaults(func=cmd_import_data)

    embed_parser = sub.add_parser(
        "embed", help="generate embeddings for schemes missing one"
    )
    embed_parser.add_argument(
        "--force", action="store_true", help="regenerate every embedding, not just missing"
    )
    embed_parser.set_defaults(func=cmd_embed)

    test_parser = sub.add_parser(
        "test",
        help="run the test suite",
        # Anything after the subcommand is forwarded verbatim to pytest, so
        # `dev.py test -q -k schema` works without needing a -- separator.
        prefix_chars="\x00",
    )
    test_parser.add_argument("pytest_args", nargs="*", default=[])
    test_parser.set_defaults(func=cmd_test)

    run_parser = sub.add_parser("run", help="start the API")
    run_parser.add_argument("--port", type=int, default=8000)
    run_parser.set_defaults(func=cmd_run)

    args = parser.parse_args()
    return int(args.func(args))


if __name__ == "__main__":
    sys.exit(main())
